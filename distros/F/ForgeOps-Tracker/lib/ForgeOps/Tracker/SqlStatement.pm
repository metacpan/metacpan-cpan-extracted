package ForgeOps::Tracker::SqlStatement;

use strict;
use warnings;
use Exporter qw(import);

# Finds the SQL behind a database error and reduces it to something safe to send: the names of the
# stored procedures, tables and views it touched, and (only if the configuration's
# capture_sql_statement is on) the statement itself with every string and number replaced by "?".
# Ported from gems/forge_ops_tracker's SqlStatement, which is itself ported from the server's own
# SqlStatementMasker/SqlObjectExtractor: same rules everywhere, and the server applies them again
# on arrival, so a difference here can only ever mean less is masked client-side, never that
# something unmasked gets stored.
#
# Deliberately a single pass over a few patterns, not a SQL parser.
our @EXPORT_OK = qw(find_in mask objects);

use constant MASK            => '?';
use constant MAX_LENGTH      => 4000;
use constant MAX_NAMES       => 10;
use constant MAX_NAME_LENGTH => 200;

# db.system values where "double quotes" are a string, not a name.
my %DOUBLE_QUOTED_STRING_SYSTEMS = map { $_ => 1 } qw(mysql mariadb);

# /a keeps \w and \d to ASCII, as they are in the Ruby original, even on a string Perl holds as
# characters. The prefix only counts as one when it isn't the end of a word, but the quote always
# does: LIKE'%x%', with no space, is still a string. A backslash can be the statement's last
# character ('secret\ cut off mid-escape), and the string is still masked to the end. A string's
# body is the Ruby original's (?:[^'\\]|\\(?:.|\z)|'')* unrolled into runs, which matches exactly
# the same text: Perl stops repeating a group like that one after a fixed count (65534 on Perl 5.34,
# fewer on older ones) and warns, so the original form would leave a string longer than that
# unmasked, where this only runs out at that many escapes in one string.
my $STRING               = qr/(?:(?<![\w\$])(?:[EeXxNnBb]|[Uu]&))?'[^'\\]*(?:(?:\\(?:.|\z)|'')[^'\\]*)*(?:'|\z)/sa;
my $DOUBLE_QUOTED_STRING = qr/"[^"\\]*(?:(?:\\(?:.|\z)|"")[^"\\]*)*(?:"|\z)/s;
my $DOLLAR_QUOTED        = qr/(?<tag>\$[A-Za-z_]*\$).*?(?:\k<tag>|\z)/s;
# [0-9A-Fa-f] where the Ruby original has \h: in Perl, \h is horizontal whitespace.
my $NUMBER = qr/(?<![\w\$.])(?:0[xX][0-9A-Fa-f]+|0[bB][01]+|(?:\d+(?:\.\d+)?|\.\d+)(?:[eE][+-]?\d+)?)(?!\w)/a;

my $LITERAL                    = qr/$STRING|$DOLLAR_QUOTED|$NUMBER/;
my $LITERAL_WITH_DOUBLE_QUOTES = qr/$STRING|$DOUBLE_QUOTED_STRING|$DOLLAR_QUOTED|$NUMBER/;

my $PART = q{(?:[\w$#@]+|"[^"]+"|\[[^\]]+\]|`[^`]+`)};
my $NAME = qr/$PART(?:\.$PART)*/;
my %OPERATIONS = map { $_ => 1 } qw(SELECT INSERT UPDATE DELETE MERGE WITH CALL EXEC EXECUTE CREATE ALTER DROP TRUNCATE);
my $PROCEDURE_CALL = qr/\b(?:CALL|EXEC(?:UTE)?|PERFORM)\s+(?!IMMEDIATE\b|FUNCTION\b|PROCEDURE\b)($NAME)/i;
my $RELATION = qr/\b(FROM|JOIN|INTO|UPDATE|TABLE)\s+($NAME)(\s*\()?/i;
my $SELECT_FUNCTION = qr/\A\s*SELECT\s+($NAME)\s*\(/i;
my %BUILTINS = map { $_ => 1 } qw(
    count sum min max avg now coalesce nullif lower upper length concat cast date_trunc
    current_timestamp current_date row_number rank json_build_object json_agg array_agg
);
my $FROM_INSIDE_FUNCTION = qr/\b(?:EXTRACT|SUBSTRING|TRIM|OVERLAY)\s*\([^()]*\)/i;
my %KEYWORDS_NOT_NAMES = map { $_ => 1 } qw(select set values where lateral only unnest generate_series);

# Perl has no exception type that carries the statement: DBI puts it in the error text itself
# instead, as `[for Statement "SELECT ..."]` when the handle has ShowErrorStatement turned on
# (DBIx::Class turns it on for you), sometimes followed by ` with ParamValues: ...`, which is
# deliberately never read: that part is the values. SQLite's own errors carry `while compiling:
# SELECT ...` at the end instead. Best-effort by nature: an error raised without either marker
# simply has no statement to find, and this returns undef rather than guessing.
my $DBI_STATEMENT     = qr/\[for Statement "(.*?)"(?: with ParamValues:[^\]]*)?\]/s;
my $SQLITE_COMPILING  = qr/while compiling:\s*(.+?)\s*\z/s;

# The raw statement out of an error: a plain string ($@ after die), or an exception object with
# ->message or an overloaded stringification.
sub find_in {
    my ($error) = @_;
    return undef unless defined $error;

    my $text = eval { ref $error && $error->can('message') ? $error->message : "$error" };
    return undef unless defined $text;

    # Copied out of $1 before the /\S/ check: that second match would otherwise reset it.
    for my $pattern ($DBI_STATEMENT, $SQLITE_COMPILING) {
        if ($text =~ $pattern) {
            my $statement = $1;
            return $statement if defined $statement && $statement =~ /\S/;
        }
    }
    return undef;
}

# mask($statement, system => $db_system): pass the query's db.system when it's known. On mysql and
# mariadb "double quotes" are a string too, so they're masked there and left alone everywhere else.
sub mask {
    my ($statement, %options) = @_;
    return undef unless defined $statement && $statement =~ /\S/;

    my $system = defined $options{system} && !ref $options{system} ? lc $options{system} : '';
    my $pattern = $DOUBLE_QUOTED_STRING_SYSTEMS{$system} ? $LITERAL_WITH_DOUBLE_QUOTES : $LITERAL;
    (my $masked = $statement) =~ s/$pattern/MASK/ge;
    return length($masked) > MAX_LENGTH ? substr($masked, 0, MAX_LENGTH) . '...' : $masked;
}

# Takes an already-masked statement (so a keyword inside a string value can't be mistaken for
# SQL). Returns undef when nothing recognizable was found.
sub objects {
    my ($masked) = @_;
    return undef unless defined $masked && $masked =~ /\S/;

    (my $sql = $masked) =~ s/$FROM_INSIDE_FUNCTION/ /g;
    my @procedures = $sql =~ /$PROCEDURE_CALL/g;
    my @relations;

    while ($sql =~ /$RELATION/g) {
        my ($keyword, $name, $paren) = ($1, $2, $3);
        next if $KEYWORDS_NOT_NAMES{ lc $name };
        my $function_call = defined $paren && length $paren && (uc $keyword eq 'FROM' || uc $keyword eq 'JOIN');
        push @{ $function_call ? \@procedures : \@relations }, $name;
    }

    if ($sql =~ $SELECT_FUNCTION) {
        my $function = $1;
        push @procedures, $function if !$BUILTINS{ lc $function } && $sql !~ /\bFROM\b/i;
    }

    my ($operation) = $sql =~ /\A\s*(\w+)/;
    $operation = defined $operation ? uc $operation : '';
    my %result;
    $result{operation} = $operation if $OPERATIONS{$operation};
    $result{procedures} = _clean(@procedures);
    $result{relations}  = _clean(@relations);
    return undef if !@{ $result{procedures} } && !@{ $result{relations} } && !exists $result{operation};
    return \%result;
}

sub _clean {
    my (@names) = @_;
    my (@cleaned, %seen);
    for my $raw (@names) {
        (my $name = $raw) =~ s/\A\s+|\s+\z//g;
        $name = substr($name, 0, MAX_NAME_LENGTH) if length $name > MAX_NAME_LENGTH;
        next unless $name =~ /\A$NAME\z/;
        next if $seen{$name}++;
        push @cleaned, $name;
    }
    splice(@cleaned, MAX_NAMES) if @cleaned > MAX_NAMES;
    return \@cleaned;
}

1;
