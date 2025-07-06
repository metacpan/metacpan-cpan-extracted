package FU::SQL 1.2;
use v5.36;
use Exporter 'import';
use Carp 'confess';
use experimental 'builtin', 'for_list';

our @EXPORT = qw/
    P RAW IDENT SQL
    PARENS INTERSPERSE COMMA
    AND OR WHERE
    SET VALUES IN
/;


sub _obj { bless [@_], 'FU::SQL::val' }

sub P :prototype($) ($p) { bless \(my $x = $p), 'FU::SQL::p' }
sub RAW :prototype($) ($s) { _obj "$s" }
sub IDENT :prototype($) ($s) { bless \(my $x = "$s"), 'FU::SQL::i' }

# These operate on $_ and must be called with &func syntax.
# The readonly check can be finicky.
sub _israw { builtin::created_as_string($_) && Internals::SvREADONLY($_) }
sub _tosql { &_israw ? "$_" : ref($_) =~ /^FU::SQL::/ ? $_ : P $_ }

sub SQL { _obj map &_tosql, @_ }
sub PARENS { SQL '(', @_, ')' }
sub INTERSPERSE { my @a = map &_tosql, @_; _obj map $_ > 1 ? ($a[0],$a[$_]) : $a[$_], 1..$#a }
sub COMMA { INTERSPERSE ',', @_ }

sub _conditions {
    @_ == 1 && ref $_[0] eq 'HASH'
    ? map PARENS(IDENT $_,
        !defined $_[0]{$_}              ? ('IS NULL') :
        ref($_[0]{$_}) eq 'FU::SQL::in' ? ($_[0]{$_})
                                        : ('=', $_[0]{$_})
      ), sort keys $_[0]->%*
    : map PARENS($_), @_
}

sub AND { !@_ || (@_ == 1 && ref $_[0] eq 'HASH' && keys $_[0]->%* == 0) ? RAW '1=1' : INTERSPERSE 'AND', _conditions @_ }
sub OR  { !@_ || (@_ == 1 && ref $_[0] eq 'HASH' && keys $_[0]->%* == 0) ? RAW '1=0' : INTERSPERSE 'OR',  _conditions @_ }
sub WHERE { SQL 'WHERE', AND @_ }

sub SET($h) { SQL 'SET', COMMA map SQL(IDENT $_, '=', $h->{$_}), sort keys %$h }

sub VALUES {
    @_ == 1 && ref $_[0] eq 'HASH'
    ? SQL '(', COMMA(map IDENT $_, sort keys $_[0]->%*), ') VALUES (', COMMA(map $_[0]{$_}, sort keys $_[0]->%*), ')'
    : @_ == 1 && ref $_[0] eq 'ARRAY'
    ? SQL 'VALUES (', COMMA($_[0]->@*), ')'
    : SQL 'VALUES (', COMMA(@_), ')';
}

sub IN :prototype($) ($a) {
    confess "Expected arrayref" if ref $a ne 'ARRAY';
    bless \$a, 'FU::SQL::in'
}



sub FU::SQL::val::_compile($self, $opt, $sql, $params) {
    for (@$self) {
        $$sql .= ' ' if length $$sql && $$sql !~ /\s$/;
        if (ref $_) { $_->_compile($opt, $sql, $params); }
        else { $$sql .= $_; }
    }
}

sub FU::SQL::p::_compile($self, $opt, $sql, $params) {
    push @$params, $$self;
    $$sql .= $opt->{placeholder_style} eq 'pg' ? '$'.@$params : '?';
}

sub FU::SQL::i::_compile($self, $opt, $sql, $params) {
    $$sql .= $opt->{quote_identifier} ? $opt->{quote_identifier}->($$self) : $$self;
}

sub FU::SQL::in::_compile($self, $opt, $sql, $params) {
    if ($opt->{in_style} eq 'pg') {
        $$sql .= '= ANY(';
        FU::SQL::p::_compile($self, $opt, $sql, $params);
        $$sql .= ')';
    } else {
        $$sql .= 'IN(';
        for my($i,$v) (builtin::indexed @$$self) {
            $$sql .= ',' if $i;
            FU::SQL::p::_compile(\$v, $opt, $sql, $params);
        }
        $$sql .= ')';
    }
}

sub FU::SQL::val::compile($self, %opt) {
    !/^(placeholder_style|in_style|quote_identifier)$/ && confess "Unknown flag: $_" for keys %opt;
    $opt{placeholder_style} ||= 'dbi';
    $opt{in_style} ||= 'dbi';
    my($sql, @params) = ('');
    $self->_compile(\%opt, \$sql, \@params);
    ($sql, \@params)
}

*FU::SQL::p::compile = *FU::SQL::i::compile = *FU::SQL::in::compile = \*FU::SQL::val::compile;

1;
__END__

=head1 NAME

FU::SQL - Small and Safe SQL Query Builder

=head1 SYNOPSIS

  use FU::SQL;

  my $data = { name => 'John', last_updated => RAW 'NOW()' };

  my $upd = SQL 'UPDATE table', SET $data;

  my $ins = SQL 'INSERT INTO table', VALUES $data;

  my $sel = SQL 'SELECT id, name FROM table', WHERE { id => IN([1,2,3]) };

  my($sql, @params) = $sel->compile;

=head1 DESCRIPTION

=head1 Compiling SQL

All functions listed under L</"Constructing SQL"> return an object that can be
passed to other construction functions or compiled into SQL and bind
parameters. These objects support one method call:

=over

=item ($sql, $params) = $obj->compile(%options)

Compile an object into a SQL string and a (possibly empty) arrayref of bind
parameters. The following options are supported:

=over

=item placeholder_style => 'dbi' or 'pg'

Set the style to use for placeholders in the SQL string. When set to C<'dbi'>
(default), placeholders are indicated with a single question mark. When set to
C<'pg'>, placeholders use PostgreSQL-style numbered variables instead. For
example:

  my $obj = SQL 'SELECT', 1, ',', 2;
  my ($sql) = $obj->compile(placeholder_style => 'dbi');
  # $sql = 'SELECT ?, ?'

  ($sql) = $obj->compile(placeholder_style => 'pg');
  # $sql = 'SELECT $1, $2'

All L<DBI> drivers support the C<'dbi'> method just fine, but you need to use
C<'pg'> when your SQL is going to L<FU::Pg> or L<Pg::PQ>.

=item in_style => 'dbi' or 'pg'

Set the style to use for C<IN> expressions, refer to the C<IN()> function below
for details.

=item quote_identifier => $func

Set a function to perform quoting of SQL identifiers. When using DBI, you can
do:

  my($sql) = $obj->compile(quote_identifier => sub { $dbh->quote_identifier(@_) });

If this option is not set, identifiers are included into the raw SQL string
without any escaping.

=back

=back

=head1 Constructing SQL

All of the functions below return an object with a C<compile()> method. All
functions are exported by default.

=over

=item SQL(@args)

Construct an SQL object by concatenating the given arguments. There are three
types of supported arguments:

=over

=item 1.

I<String literals> are interpreted as raw SQL fragments.

=item 2.

Objects returned by other functions listed below are included as SQL fragments.

=item 3.

I<Everything else> is considered a bind parameter.

=back

These rules allow for flexible SQL construction:

  SQL 'SELECT 1';       # Raw SQL statement
  SQL 'WHERE id =', 1;  # SQL with a bind parameter

  my $fifteen = SQL('5 + ', 10);
  SQL 'WHERE number =', $fifteen; # Composing SQL objects

There is some magic going on in order to differentiate between a I<string
literal> and other arguments. The rule is that anything that is
C<builtin::created_as_string()> and read-only (as per
C<Internals::SvREADONLY()>) is considered raw SQL. Regular variables, array
elements and hash values are always writable:

  my $x = 'SELECT 1';
  SQL $x;  # BAD: $x is used as bind parameter instead

  # Better:
  my $x = SQL 'SELECT 1';
  SQL $x;

Constants created with C<use constant> are considered string literals, and
there are probably plenty of other creative ways to end up with variables that
may be considered a "string literal" by this module. L<Hash::Util>,
L<Scalar::Readonly>, other modules and tied hashes or arrays all have the
potential to create read-only strings, but I don't expect that these are
commonly applied on untrusted user input.

In most cases, this heuristic should work out well. In the few cases where it
doesn't, or when you're not entirely sure what kind of value you're dealing
with, you can always use C<P()> or C<RAW()> to force an argument as bind
parameter or SQL string.

=item P($val)

Return an object where C<$val> is forced into a bind parameter, for example:

  SQL 'WHERE name =', 'John';  # BAD, 'John' is a string literal

  SQL 'WHERE name =', P 'John'; # Good, 'John' is now a parameter

=item RAW($sql)

Force the given C<$sql> string to be included as SQL. For example:

  # BAD:
  my $tables = ['a', 'b', 'c'];
  SQL 'SELECT * FROM', $tables[1];
  # 'SELECT * FROM ?', that's a syntax error.

  # Better:
  SQL 'WHERE * FROM', RAW $tables[1];
  # 'SELECT * FROM b'

Never use this function with untrusted input.

=item IDENT($string)

Mark the given string as an SQL identifier. This function is only useful if you
use potentially untrusted input to determine which column to select or which
table to select from, for example:

  SQL 'SELECT id,', IDENT $ENV{column}, 'FROM table';

B<WARNING:> By default this function is equivalent to C<RAW()> and hence
provides no safety whatsoever. Be sure to set the C<quote_identifier> option on
C<compile()> to get more useful behavior.

=item PARENS(@args)

Like C<SQL()> but surrounds the expression by parens:

  SQL 'WHERE x AND', PARENS('y', 'OR', 'z');
  # 'WHERE x AND ( y OR z )'

=item INTERSPERSE($value, @args)

Concatenate C<@args> with C<$value> as separator. Same way as C<join()> works
for strings, but I had to come up with a different name because "join" tends to
have a completely different meaning in the SQL world.

  INTERSPERSE 'OR', 'true', 'false';
  # 'true OR false'

=item COMMA(@args)

Short-hand for C<INTERSPERSE(',', @args)>.

=item AND(@conditions)

Construct an SQL expression to test that all given conditions are true. Returns
C<'1=1'> (i.e. true) if C<@conditions> is an empty list.

  AND 'x IS NOT NULL',
      SQL('id <>', $not_this_id);
  # '( x IS NOT NULL ) AND ( id <> ? )'

  AND;
  # '1=1'

=item AND($hashref)

A special form of C<AND()> that tests the given columns for equality instead.
The keys of the hashref are interpreted as per C<IDENT()> and the values as
bind parameters.

  AND { id => 1, number => RAW 'random()', x => undef }
  # '( id = ? ) AND ( number = random() ) AND ( x IS NULL )'

=item OR(@conditions)

=item OR($hashref)

Like C<AND()> except OR. These return C<'1=0'> (i.e. false) on an empty list.

=item WHERE(@conditions)

=item WHERE($hashref)

Like C<AND()> but prefixed with C<'WHERE'>.

=item SET($hashref)

Construct a SET clause:

  SQL 'UPDATE table', SET {
    name => 'John',
    last_updated => RAW('NOW()'),
  };
  # 'UPDATE table SET name = ? , last_updated = NOW()'

=item VALUES(@args)

Construct a VALUES clause, C<@args> is interpreted as in C<SQL()>:

  SQL 'INSERT INTO table (name, last_updated)', VALUES(P('John'), 'NOW()');
  # 'INSERT INTO table (name, last_updated) VALUES ( ? , NOW() )'

=item VALUES($arrayref)

Same as C<VALUES(@args)> but arguments are interpreted as bind parameters:

  SQL 'INSERT INTO table (name, last_updated)', VALUES(['John', RAW 'NOW()']);
  # 'INSERT INTO table (name, last_updated) VALUES ( ? , NOW() )'

=item VALUES($hashref)

Like C<VALUES($arrayref)> but also constructs a list of column names from the
hash keys:

  SQL 'INSERT INTO table', VALUES {
    name => 'John',
    last_updated => RAW('NOW()'),
  };
  # Same as above examples

Note how this allows for re-using the same hashref with C<SET()>, allowing for
convenient insert-or-update:

  my $data = {
    name => 'John',
    last_updated => RAW('NOW()'),
  };
  SQL 'INSERT INTO table', VALUES($data),
      'ON CONFLICT (name) DO UPDATE', SET($data);

(The bind parameters are duplicated though)

=item IN($arrayref)

Construct an C<IN()> clause for matching an SQL expression against multiple
values. This function results in different SQL depending on the C<in_style>
option given to C<compile()>. The default C<'dbi'> style passes each value as a
bind parameter:

  SQL 'WHERE id', IN [1, 2, 3, 4];
  # 'WHERE id IN(?, ?, ?, ?)', parameters: 1, 2, 3, 4

The C<'pg'> style passes the entire array as a single bind parameter instead:

  SQL 'WHERE id', IN [1, 2, 3, 4];
  # 'WHERE id = ANY(?)', parameter: [1, 2, 3, 4]

The C<'pg'> style allows for more efficient re-use of cached prepared
statements, since the generated query does not depend on the number of values.
Unfortunately, the only Postgres module that supports arrays as bind parameters
that I am aware of is L<FU::Pg>. This approach does not, as of writing, work
with L<DBD::Pg> or L<Pg::PQ>.

Can be used in the C<$hashref> versions of C<AND>, C<OR> and C<WHERE> as well:

  WHERE { id => IN [1, 2] }
  # 'WHERE id IN(?, ?)'

=back

=head1 SEE ALSO

L<SQL::Interp> and the many other related modules on CPAN. This module was
heavily inspired by SQL::Interp, but differs in a few key areas:

=over

=item * SQL::Interp expects bind parameters to be passed as a scalar reference
(e.g. C<\$x>), but this is easy to forget and the result of forgetting to do so
is an SQL injection vulnerability - the worst possible outcome.
C<sql_interp_strict()> was introduced in an attempt to provide a safer
alternative, but that limits the flexibility of the query builder.  This module
instead attempts to identify string literals through some trickery and
considers everything else a bind parameter, which is much less prone to
accidental SQL injection.

=item * SQL::Interp parses your input query in an attempt to guess the context
for interpolation. While this has (to my surprise) always worked out well for
anything I've written, it does feel a tad too magical for my taste. This module
instead requires you to more explicitly state your intentions, while hopefully
remaining as concise and readable.

=item * SQL::Interp assigns various semantics to hashrefs and arrayrefs, which
means those can't easily be used as bind parameters. Not at all a problem if
you're using DBI - which doesn't support that anyway, but it can cause trouble
with L<FU::Pg>.

=back

=head1 COPYRIGHT

MIT.

=head1 AUTHOR

Yorhel <projects@yorhel.nl>
