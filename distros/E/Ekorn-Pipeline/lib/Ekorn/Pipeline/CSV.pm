use v5.36;

package Ekorn::Pipeline::CSV;

use experimental qw(builtin try);

use builtin          qw(blessed);
use Encode           qw();
use Exporter         qw(import);
use PerlIO::encoding qw();
use Ref::Util        qw(
    is_plain_arrayref is_plain_coderef is_plain_hashref
    is_plain_ref);
use Scalar::Util               qw(openhandle);
use Ekorn::Pipeline::Errors    qw(croakf);
use Ekorn::Pipeline::Factories qw(gather sink_one source stage);
use namespace::clean -except => 'import';

our $VERSION = 'v0.4.5';

our @EXPORT_OK   = qw(from_csv to_csv);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Text::CSV's code for the end of its input, which isn't an error.
my $EOF = 2012;

# What a file's encoding does with text it can't decode or encode:
# croak, rather than warn and carry on.
my $STRICT = Encode::FB_CROAK() | Encode::STOP_AT_PARTIAL();

# Each way of munging a header's names that's named, as Text::CSV's
# munge_column_names has them.
my %MUNGE = (
    lc   => sub ($name) { lc $name },
    uc   => sub ($name) { uc $name },
    db   => sub ($name) { lc($name =~ s( \W+ )(_)xgr =~ s( \A _+ )()xr) },
    none => undef,
);

# A source of the rows read from the file or filehandle. Given neither,
# a stage parsing each value, a text of any number of rows, into its
# rows.
sub from_csv (@options) {
    my %option = _options(
        'from_csv', [qw(file fh csv header munge encoding)], @options,
    );
    return _reader(\%option) if _has_input(\%option);
    my($csv, $header, $munge) = ($option{new}->(), @option{qw(header munge)});
    return stage {
        my($next) = _table(
            $csv,    Ekorn::Pipeline::CSV::Text->new($_), 'a value',
            $header, $munge,
        );
        my @rows;
        while (my $row = $next->()) {
            push @rows, $row;
        }
        return @rows;
    };
}

# A sink writing each row to the file or filehandle, giving how many.
# Given neither, a stage passing on each row as its line, without its
# end of line, after the header's, if it has one.
sub to_csv (@options) {
    my %option = _options('to_csv', [qw(file fh csv header encoding)], @options);
    return _writer(\%option) if _has_input(\%option);
    my($csv, $header) = ($option{new}->(), $option{header});
    unless ($header) {
        my($line) = _formatter($csv, $header, 'chars');
        return stage { $line->($_) };
    }
    return gather {
        my($line, $head) = _formatter($csv, $header, 'chars');    # this run's names
        my $first = 1;
        return (
            # For each row, without a signature: the header's line first.
            sub {
                return $line->($_[0]) unless $first;
                $first = 0;
                return ($head->(), $line->($_[0]));
            },
            sub () { return $first ? $head->() : () },    # no rows: the header
        );
    };
}

# Return the options given, checked, with "new", a sub returning the
# parser, and "encoding", a file's, as _encoding gives it. Load
# Text::CSV first.
sub _options ($function, $known, @given) {
    _load($function);
    croakf 'Expected options as name => value pairs' if @given % 2;
    my %option  = @given;
    my %allowed = map       { $_ => 1 } @$known;
    my @unknown = sort grep { !$allowed{$_} } keys %option;
    croakf 'Expected the options %s, not %s',
        join(', ', @$known[0 .. $#$known - 1]) . " and $known->[-1]", join ', ',
        @unknown
        if @unknown;
    croakf 'Expected file to be a path'
        if exists $option{file} && !defined $option{file};
    croakf 'Expected a file or a filehandle, not both'
        if defined $option{file} && exists $option{fh};
    croakf 'Expected an open filehandle'
        if exists $option{fh} && !defined openhandle($option{fh});
    $option{encoding} = _encoding(\%option);
    _check_header(\%option, $function);
    $option{munge} = _munger(\%option) if exists $option{munge};
    my $raw = defined $option{encoding} && !ref $option{encoding};    # the only one not an object
    $option{new} = _parser($option{csv}, $raw);
    return %option;
}

# Load Text::CSV, croaking for the function given if it can't be.
sub _load ($function) {
    return if eval { require Text::CSV; 1 };
    my $error = $@;
    return croakf q(Can't find Text::CSV, which %s needs; install it from CPAN),
        $function
        if $error =~ m( \A Can't\ locate\ Text/CSV\.pm\ in\ \@INC )x;
    return croakf q(Can't load Text::CSV, which %s needs: %s), $function,
        $error =~ s( \s* \n .* )()xsr;
}

# Return a file's encoding: 'raw', for bytes, or Encode's object for the
# one named, UTF-8 if none is. Only a file is opened, so only a file
# takes one.
sub _encoding ($option) {
    return unless defined $option->{file} || exists $option->{encoding};
    my $encoding = exists $option->{encoding} ? $option->{encoding} : 'UTF-8';
    croakf 'Expected encoding only with a file' unless defined $option->{file};
    return 'raw' if defined $encoding && $encoding eq 'raw';
    my $found = !ref $encoding && Encode::find_encoding($encoding // q());
    croakf 'Expected an encoding Perl knows, not %s', $encoding // 'undef'
        unless $found;
    return $found;
}

# Croak unless the header is one the function takes: true, false, or
# 'skip' to read; true, false, or an array of names to write.
sub _check_header ($option, $function) {
    my $header = $option->{header};
    return if !defined $header || (!ref $header && $header =~ m( \A [01]? \z )x);
    if ($function eq 'from_csv') {
        croakf q(Expected header to be true, false or 'skip')
            if ref $header || $header ne 'skip';
        return;
    }
    croakf q(Expected header to be true, false or an array reference of names)
        if !is_plain_arrayref($header) || grep { !defined || ref } @$header;
    return;
}

# Return a sub munging a header's name as munge says, or nothing, for a
# munge of none.
sub _munger ($option) {
    my $munge = $option->{munge};
    croakf 'Expected munge only with a header' unless $option->{header};
    if (is_plain_coderef($munge)) {
        return sub ($name) { local $_ = $name; $munge->($name) };
    }
    if (is_plain_hashref($munge)) {
        return sub ($name) { exists $munge->{$name} ? $munge->{$name} : $name };
    }
    croakf
        'Expected munge to be lc, uc, db, none, a hash reference or a code reference'
        if ref $munge || !exists $MUNGE{$munge // q()};
    return $MUNGE{$munge};
}

# Return a sub returning the parser: one made from csv's options, over
# the defaults, or csv's object, as it is. Reading a file raw, the
# parser leaves bytes that are UTF-8 as bytes, rather than decode them.
sub _parser ($csv, $raw) {
    if (blessed($csv)) {
        return sub () { $csv };
    }
    croakf 'Expected csv to be a hash reference of options, or a parser object'
        if defined $csv && !is_plain_hashref($csv);
    my %settings = (
        binary    => 1,
        auto_diag => 0,
        ($raw ? (decode_utf8 => 0) : ()),
        %{ $csv // {} },
    );
    croakf 'Expected csv options the parser knows: %s',
        scalar Text::CSV->error_diag
        unless Text::CSV->new({%settings});
    return sub () { Text::CSV->new({%settings}) };
}

# Return true if the options name a file or a filehandle.
sub _has_input ($option) {
    return defined $option->{file} || !!$option->{fh};
}


# Where Perl says an error was raised: its file and line, then the last
# filehandle read and how far, if one has been.
my $PLACE = qr( ,? \s+ at \s+ \S+ \s+ line \s+ \d+ )x;
my $READ  = qr( , \s+ < \S* > \s+ (?: line | chunk ) \s+ \d+ )x;

# Return an error's message without the place it was raised, as a
# message of ours says where.
sub _unplaced ($error) {
    return "$error" =~ s( $PLACE $READ? \.? \s* \z )()xr;
}

# Return a sub giving the next row read from $io, by $from, or nothing
# at its end; and the context, if a header was read, as the header
# says: rows as arrays, or as hashes keyed by the header's names,
# munged.
sub _table ($csv, $io, $from, $header, $munge) {
    my $next = _rows($csv, $io, $from);
    return ($next) unless $header;
    my @names = @{ $next->() // [] };
    @names = map { $munge->($_) } @names if $munge;
    my $context = {columns => \@names};
    return ($next, $context) if $header eq 'skip';
    my %seen;
    for my $name (@names) {
        croakf q(Expected a header naming each column once, not "%s" twice), $name
            if $seen{$name}++;
    }
    # Without a signature, as it's called for each row.
    my $hashes = sub {
        my $row = $next->() or return;
        my %row;
        @row{@names} = @$row;
        return \%row;
    };
    return ($hashes, $context);
}

# Return a sub giving the next row read from $io, by $from, or nothing at
# its end, croaking at a row that won't parse. A byte order mark that
# starts the first row is dropped.
sub _rows ($csv, $io, $from) {
    my $rows_read = 0;
    # Without a signature, as it's called for each row.
    return sub {
        my $row;
        try {
            $row = $csv->getline($io);
        }
        catch ($e) {
            croakf q(Can't read %s: %s), $from, _unplaced($e);
        };    # the ; ends the statement for Perl::Critic, which doesn't know try
        unless ($row) {
            my($code, $why, undef, undef, $field) = $csv->error_diag;
            return if $code == $EOF;
            croakf q(Can't parse CSV from %s, record %d, field %d: %s), $from,
                $rows_read + 1, $field, $why;
        }
        # An undefined first field, as blank_is_undef makes, has no mark.
        $row->[0] =~ s( \A \x{FEFF} )()x if !$rows_read++ && defined $row->[0];
        return $row;
    };
}

# Return a source of the rows in the file or filehandle.
sub _reader ($option) {
    my($path, $given, $new, $encoding, $header, $munge)
        = @{ $option }{qw(file fh new encoding header munge)};
    my $from  = $path // 'the filehandle';
    my $layer = ref $encoding ? sprintf(':encoding(%s)', $encoding->name) : ':raw';
    return source {
        my $fh = $given;
        unless ($fh) {
            # Open for the run, and closed by its end. Text that won't
            # decode croaks as it's read.
            local $PerlIO::encoding::fallback = $STRICT;    ## no critic (Variables::ProhibitPackageVars)
            open $fh, "<$layer", $path                      ## no critic (InputOutput::RequireBriefOpen)
                or croakf q(Can't read %s: %s), $path, $!;
        }
        my($next, $context) = _table($new->(), $fh, $from, $header, $munge);
        return {
            step    => $next,
            end     => $path ? sub ($how) { close $fh } : undef,
            context => $context,
        };
    };
}

# Return a sub giving a row's line, without its end of line, and, if
# there's a header, a sub giving its line: the names given, or the run's
# context's columns, which also order a hash's fields. A line is in the
# form asked for: characters ('chars'), UTF-8 ('utf8'), or the bytes
# its fields hold ('raw'), each of which must be a byte.
sub _formatter ($csv, $header, $form) {
    my $names = is_plain_arrayref($header) ? $header : undef;
    my $cut   = length $csv->eol;                               # combine ends a line with eol
    my $text  = sub ($row) {
        # The parser is given only bytes: Text::CSV_XS's combine gives
        # bytes, characters or a mixture as its fields' flags vary, and
        # a line of bytes is the same from both backends.
        my @fields = @$row;
        for my $at (0 .. $#fields) {
            next unless defined $fields[$at];
            croakf q(Can't write a row as CSV: field %d is a reference), $at + 1
                if is_plain_ref($fields[$at]);
            if ($form eq 'raw') {
                croakf
                    q(Can't write a row as CSV: field %d holds a wide character, and the file is written raw),
                    $at + 1
                    unless utf8::downgrade($fields[$at], 1);
            }
            else {
                utf8::encode($fields[$at]);
            }
        }
        croakf q(Can't write a row as CSV: %s), scalar $csv->error_diag
            unless $csv->combine(@fields);
        my $line = $csv->string;
        substr $line, -$cut, $cut, q() if $cut;
        utf8::decode($line) if $form eq 'chars';
        return $line;
    };
    my $line = sub ($row) {
        return $text->($row) if is_plain_arrayref($row);
        croakf 'Expected a row as an array or a hash reference'
            unless is_plain_hashref($row);
        croakf 'Expected a header naming the columns, to write a hash'
            unless $header;
        # The names are known: the header's line comes first.
        return $text->([@{ $row }{@$names}]);
    };
    return ($line) unless $header;
    # The header's line: the names given, or the run's columns.
    my $head = sub () {
        $names = _columns() unless $names;
        return $text->($names);
    };
    return ($line, $head);
}

# Return the run's context's columns, for a header, croaking if it has
# none.
sub _columns () {
    my $context = Ekorn::Pipeline::run_context();
    my $columns = is_plain_hashref($context) ? $context->{columns} : undef;
    croakf q(Expected the run's context to name its columns, for to_csv's header)
        unless is_plain_arrayref($columns);
    return $columns;
}

# Return the form a writer's lines are made in, for _formatter, and a
# sub encoding each, if it needs one: a filehandle takes characters, for
# its own layers; a file, its encoding's bytes, a character the encoding
# can't hold croaking at its row.
sub _encoder ($encoding, $path) {
    return ('chars') unless defined $encoding;
    return ('raw')   unless ref $encoding;
    return ('utf8')  if $encoding->name =~ m( \A utf-?8 )xi;
    my $encode = sub ($text) {
        my $bytes;
        try {
            $bytes = $encoding->encode($text, $STRICT);
        }
        catch ($e) {
            croakf q(Can't write %s: %s), $path, _unplaced($e);
        }
        return $bytes;
    };
    return ('chars', $encode);
}

# Return a sink writing each row to the file or filehandle, giving how
# many: after the header's line, if it has one, written even if no row
# comes.
sub _writer ($option) {
    my($path, $given, $new, $encoding, $header)
        = @{ $option }{qw(file fh new encoding header)};
    my $to = $path // 'the filehandle';
    my($form, $encode) = _encoder($encoding, $path);
    return sink_one {
        my $fh = $given;
        unless ($fh) {
            # Open for the run, and closed by its end. Each line is
            # encoded as it's made.
            open $fh, '>:raw', $path    ## no critic (InputOutput::RequireBriefOpen)
                or croakf q(Can't write %s: %s), $path, $!;
        }
        my $csv = $new->();
        my($line, $head) = _formatter($csv, $header, $form);
        my $eol   = length $csv->eol ? $csv->eol : "\n";
        my $n     = 0;
        my $write = sub ($text) {
            $text .= $eol;
            print { $fh } $encode ? $encode->($text) : $text
                or croakf q(Can't write %s: %s), $to, $!;
        };
        return {
            # Without a signature, as it's called for each row.
            step => sub {
                $write->($head->()) if $head && !$n;
                $write->($line->($_[0]));
                $n++;
            },
            flush => sub () {
                $write->($head->()) if $head && !$n;
                return $n;
            },
            end => $path
            ? sub ($how) { close $fh or croakf q(Can't write %s: %s), $path, $! }
            : undef,
        };
    };
}

# The rows of a text, a line at a time, for Text::CSV's getline, which
# reads from any object that has one. A filehandle opened on the text
# would need a check on an open that can't fail, which no test reaches.
package Ekorn::Pipeline::CSV::Text {    ## no critic (Modules::ProhibitMultiplePackages)


    sub new ($class, $text) {
        return bless [split m( (?<= \n ) )x, $text], $class;
    }


    sub getline ($self) {
        return shift @$self;
    }
}

1;

__END__

=encoding utf8

=for stopwords CSV TSV fh eol munge munged munges uc lc db csv

=head1 NAME

Ekorn::Pipeline::CSV - read and write CSV and TSV, as sources, stages or sinks

=head1 SYNOPSIS

    use Ekorn::Pipeline::CSV qw(:all);

    # Sources: a row at a time, as arrays, or as hashes keyed by the
    # header's names.
    my $rows   = Ekorn::Pipeline->new(@stages)->iterator(from_csv(file => 'plays.csv'));
    my $tracks = Ekorn::Pipeline->new(@stages)
        ->iterator(from_csv(file => 'tracks.csv', header => 1, munge => 'db'));

    # TSV, or any other separator, by Text::CSV's options.
    my $units = Ekorn::Pipeline->new(@stages)
        ->iterator(from_csv(file => 'units.tsv', header => 'skip', csv => {sep_char => "\t"}));

    # Sinks: each row a line, giving how many; hashes in the header's
    # order, or the run's columns, read from a header.
    my $n = Ekorn::Pipeline->new(@stages, to_csv(file => 'out.csv', header => [qw(title plays)]))
        ->(@rows);
    my($m) = Ekorn::Pipeline->new(@stages, to_csv(file => 'copy.csv', header => 1))
        ->iterator(from_csv(file => 'tracks.csv', header => 1))->all;

    # Stages: parsing texts, and making lines.
    my @parsed = Ekorn::Pipeline->new(from_csv(header => 1))->(@texts);
    my @lines  = Ekorn::Pipeline->new(to_csv())->(@rows);

=head1 DESCRIPTION

Two functions, one for each direction, each making a different part by
the options it's given, as L<Ekorn::Pipeline::JSON>'s do. Given a
C<file> or an C<fh>, C<from_csv> makes a source and C<to_csv> a sink;
given neither, each makes a stage. Each part is made afresh for each
run, so a source read twice reads its header twice, and a run's parser
is its own, unless you give one of your own.

The parser is L<Text::CSV>'s: L<Text::CSV_XS> where it's installed,
L<Text::CSV_PP> otherwise. Ekorn::Pipeline only recommends Text::CSV,
so it may not be installed: it's loaded when C<from_csv> or C<to_csv>
is first called, which croaks if it can't be, and this module, and
L<Ekorn::Pipeline::Tooling>, load without it.

A file is read and written as UTF-8 unless C<encoding> says otherwise,
so its fields are characters. Text that won't decode, or a character
its encoding can't hold, croaks at its row, rather than being written
as something else. A file is opened as the run starts, emptied if it's
written, and closed once the run has ended, however it ended; a
filehandle is read and written as it is, with its own layers, and left
open, for its opener to close.

A row that won't parse croaks, saying where, rather than being taken
for the end of the input. A byte order mark that starts the input is
dropped, unless the file is read C<raw>.

Nothing is exported by default; ask for each, or for C<:all>, or import
them from L<Ekorn::Pipeline::Tooling>'s C<:csv>.

=head1 FUNCTIONS

=head2 from_csv

    from_csv(file => $path, %options)
    from_csv(fh => $fh, %options)
    from_csv(%options)

Given a C<file> or an C<fh>, a source of the rows read from it, a row
at a time as values are pulled, so a stage that stops the run early
stops the reading too. Each row is an array reference of its fields,
or, with C<header> true, a hash reference keyed by the header's names.
When a header is read, with C<header> true or C<skip>, the run's
context, which L<Ekorn::Pipeline/run_context> gives a stage, is a hash
reference whose C<columns> are its names, as
L<DBIx::Squirrel|https://metacpan.org/dist/DBIx-Squirrel>'s sources'
are:

    my $column = sub ($row) {
        my $columns = Ekorn::Pipeline::run_context()->{columns};
        ...
    };

Given neither, a stage parsing each value, a text of any number of
rows, such as a file's contents, and passing on its rows. A quoted
field may hold a newline, so the stage parses the whole value, not a
line at a time. With a C<header>, each value's first row is its
header. A stage can't give the run a context.

=head2 to_csv

    to_csv(file => $path, %options)
    to_csv(fh => $fh, %options)
    to_csv(%options)

Given a C<file> or an C<fh>, a sink writing each row as a line, and
giving how many rows it wrote, not counting the header. A row is an
array reference of its fields, or a hash reference, whose fields are
written in the header's order; a field that's undefined is written
empty. With a C<header>, its line is written first, even if no row
comes.

Given neither, a stage passing on each row's line, without its end of
line, ready for L<Ekorn::Pipeline::Sinks/to_file>, after the header's
line, if there's a header.

Fields are quoted as Text::CSV quotes them: those holding the
separator, a quote, a newline, a space or some other characters, such
as C<"a b">.

=head1 OPTIONS

=over

=item file

The path of a file to read or write.

=item fh

An open filehandle to read or write.

=item csv

The parser: a hash reference of options for Text::CSV's C<new>, such
as C<< {sep_char => "\t"} >> for TSV, or C<< {eol => "\r\n"} >>, given
over the defaults C<binary> on and C<auto_diag> off, as this module
reports errors itself; or an object of your own, such as a
L<Text::CSV_XS> you've set up, used as it is.

=item header

Reading, true, false or C<skip>. False, the default, reads every row
as data, as an array reference. True reads the first row as the
header, and each row after it as a hash reference keyed by its names:
a short row's missing fields are C<undef>, and a long row's extra
fields are dropped. A header naming a column twice croaks, as one
field's value would be lost. C<skip> reads the first row as the
header, and each row after it as an array reference.

Writing, true, false or an array reference of names. False, the
default, writes no header, and each row must be an array reference.
Names write them as the header, and order a hash's fields. True takes
the names from the run's context's C<columns>, as C<from_csv> gives
them, so

    Ekorn::Pipeline->new(@stages, to_csv(file => 'copy.csv', header => 1))
        ->iterator(from_csv(file => 'tracks.csv', header => 1));

writes the columns it read, in the order it read them, and croaks if
the run has no context naming its columns.

=item munge

Reading only, with a C<header>: how its names are changed before
they're used, as Text::CSV's C<munge_column_names> does. C<none>, the
default, uses them as they are; C<lc> or C<uc> makes them lower or
upper case; C<db> makes them names a database takes, lower case, with
each run of characters that aren't word characters an underscore, and
none leading, so C<Track Name> is C<track_name>. A hash reference maps
each name it has to a name of your own, leaving the rest as they are;
a code reference is called with each name, as its argument and in
C<$_>, and returns the name to use. The names are munged before
they're checked for a name given twice, and in the run's context too.

=item encoding

For a file only: the encoding its text is in, as L<Encode> names it,
such as C<latin1>; C<UTF-8> by default; or C<raw>, to read and write
its fields as bytes, as they are, with a byte order mark kept. Written
C<raw>, a field holding a character that isn't a byte croaks.

=back

=head1 DIAGNOSTICS

=over

=item Can't find Text::CSV, which %s needs; install it from CPAN

C<from_csv> or C<to_csv>, named in the message, was called, and
L<Text::CSV> isn't installed. Ekorn::Pipeline only recommends it.

=item Can't load Text::CSV, which %s needs: %s

Text::CSV is installed, but failed to load; the second part says why.

=item Expected options as name => value pairs

A function was given an odd number of arguments.

=item Expected the options %s, not %s

A function was given an option it doesn't know, named after "not";
the first part lists those it does.

=item Expected file to be a path

C<file> was undefined.

=item Expected a file or a filehandle, not both

A function was given both C<file> and C<fh>.

=item Expected an open filehandle

C<fh> was something other than an open filehandle.

=item Expected encoding only with a file

C<encoding> was given with a filehandle, or for a stage: neither opens
a file.

=item Expected an encoding Perl knows, not %s

C<encoding> wasn't C<raw>, or an encoding L<Encode> knows.

=item Expected header to be true, false or 'skip'

C<from_csv>'s C<header> was something else.

=item Expected header to be true, false or an array reference of names

C<to_csv>'s C<header> was something else, or an array holding
something other than names.

=item Expected munge only with a header

C<munge> was given, but C<header> was false: there are no names to
munge.

=item Expected munge to be lc, uc, db, none, a hash reference or a code reference

C<munge> was something else.

=item Expected csv to be a hash reference of options, or a parser object

C<csv> was something else.

=item Expected csv options the parser knows: %s

C<csv>'s options included one Text::CSV doesn't have; the rest of the
message is Text::CSV's.

=item Expected a header naming each column once, not "%s" twice

C<from_csv>, with C<header> true, read a header naming a column twice,
after munging, so one field's value would be lost. Read it with
C<header> C<skip>, or C<munge> the names apart.

=item Can't parse CSV from %s, record %d, field %d: %s

A row wasn't CSV, as the parser is set up to read it: the first part
is the file's path, "the filehandle", or "a value", for a stage; then
which record, counting the header as the first, and which field; and
Text::CSV's reason.

=item Can't read %s: %s

=item Can't write %s: %s

A file couldn't be opened, read, written or closed, or a filehandle
written; or its text wouldn't decode, or a character wouldn't encode,
as its encoding says. The second part says why.

=item Expected a row as an array or a hash reference

C<to_csv> was given something else as a row.

=item Expected a header naming the columns, to write a hash

C<to_csv> was given a hash reference as a row, without a C<header> to
order its fields.

=item Expected the run's context to name its columns, for to_csv's header

C<to_csv>'s C<header> was true, but the run had no context, or one
without C<columns>, such as a pushed run's.

=item Can't write a row as CSV: field %d is a reference

A row's field, counting from 1, was a reference, which CSV can't
hold.

=item Can't write a row as CSV: field %d holds a wide character, and the file is written raw

A row's field, counting from 1, held a character that isn't a byte,
in a file written with C<encoding> C<raw>.

=item Can't write a row as CSV: %s

The parser wouldn't combine a row's fields, saying why.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::JSON>, which reads and writes
JSON the same way, and L<Text::CSV>.

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
