package FU::Pg 0.1;
use v5.36;
use FU::XS;

_load_libpq();

package FU::Pg::conn {
    sub lib_version { FU::Pg::lib_version() }

    sub Q {
        require FU::SQL;
        my $s = shift;
        my($sql, $params) = FU::SQL::SQL(@_)->compile(placeholder_style => 'pg', in_style => 'pg');
        $s->q($sql, @$params);
    }
};

*FU::Pg::txn::Q = \*FU::Pg::conn::Q;

package FU::Pg::error {
    use overload '""' => sub($e, @) { $e->{full_message} };
}

1;
__END__

=head1 NAME

FU::Pg - The Ultimate (synchronous) Interface to PostgreSQL

=head1 EXPERIMENTAL

This module is still in development and there will likely be a few breaking API
changes, see the main L<FU> module for details.

=head1 SYNOPSYS

  use FU::Pg;

  my $conn = FU::Pg->connect("dbname=test user=test password=nottest");

  $conn->exec('CREATE TABLE books (id SERIAL, title text, read bool)');

  $conn->q('INSERT INTO books (title) VALUES ($1)', 'Revelation Space')->exec;
  $conn->q('INSERT INTO books (title) VALUES ($1)', 'The Invincible')->exec;

  for my ($id, $title) ($conn->q('SELECT * FROM books')->flat->@*) {
      print "$id:  $title\n";
  }

=head1 DESCRIPTION

FU::Pg is a client module for PostgreSQL with a convenient high-level API and
support for flexible and complex type conversions. This module interfaces
directly with C<libpq>.

=head2 Connection setup

=over

=item FU::Pg->connect($string)

Connect to the PostgreSQL server and return a new C<FU::Pg::conn> object.
C<$string> can either be in key=value format or a URI, refer to L<the
PostgreSQL
documentation|https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING>
for the full list of supported formats and options. You may also pass an empty
string and leave the configuration up L<environment
variables|https://www.postgresql.org/docs/current/libpq-envars.html>.

=item $conn->server_version

Returns the version of the PostgreSQL server as an integer in the format of
C<$major * 10000 + $minor>. For example, returns 170002 for PostgreSQL 17.2.

=item $conn->lib_version

Returns the libpq version in the same format as the C<server_version> method.
Also available directly as C<FU::Pg::lib_version()>.

=item $conn->status

Returns a string indicating the status of the connection. Note that this method
does not verify that the connection is still alive, the status is updated after
each command. Possible return values:

=over

=item idle

Awaiting commands, not in a transaction.

=item txn_idle

Awaiting commands, inside a transaction.

=item txn_done

Idle, but a transaction object still exists. The connection is unusable until
that object goes out of scope.

=item txn_error

Inside a transaction that is in an error state. The transaction must be rolled
back in order to recover to a usable state. This happens automatically when the
transaction object goes out of scope.

=item bad

Connection is dead or otherwise unusable.

=back

=item $conn->cache($enable)

=item $conn->text_params($enable)

=item $conn->text_results($enable)

=item $conn->text($enable)

Set the default settings for new statements created with B<< $conn->q() >>.

=item $conn->cache_size($num)

Set the number of prepared statements to keep in the cache. Defaults to 256.

Setting this (temporarily) to 0 will immediately reclaim all cached statements.
Prepared statements that still have an active C<$st> object are not counted
towards this number. The cache works as an LRU: when it's full, the statement
that hasn't been used for the longest time is reclaimed.

=item $conn->query_trace($sub)

Set a subroutine to be called on every query executed on this connection. The
subroutine is given a statement object, refer to the C<$st> methods below for
the fields that can be inspected. C<$sub> can be set to C<undef> to disable
query tracing.

It is important to not hold on to the given C<$st> any longer than strictly
necessary, because the prepared statement is not closed or reclaimed while the
object remains alive. If you need information to remain around for longer than
the duration of the subroutine call, it's best to grab the relevant information
from the C<$st> methods and save that for later.

Also worth noting that the subroutine is called from the context of the code
executing the query, but I<before> the query results have been returned.

The subroutine is (currently) only called for queries executed through C<<
$conn->exec >>, C<< $conn->q >>, C<< $conn->Q >> and their C<$txn> variants;
internal queries performed by this module (such as for transaction management,
querying type information, etc) do not trigger the callback. Statements that
result in an error being thrown during or before execution are also not
traceable this way. This behavior might change in the future.

=item $conn->disconnect

Close the connection. Any active transactions are rolled back and further
attempts to use C<$conn> throw an error.

=back

=head2 Querying

=over

=item $conn->exec($sql)

Execute one or more SQL commands, separated by a semicolon. Returns the number
of rows affected by the last statement or I<undef> if that information is not
available for the given command (like with C<CREATE TABLE>).

=item $conn->q($sql, @params)

Create a new SQL statement with the given C<$sql> string and an optional list
of bind parameters. C<$sql> can only hold a single statement.

Parameters can be referenced from C<$sql> with numbered placeholders, where
C<$1> refers to the first parameter, C<$2> to the second, etc. Be careful to
not accidentally interpolate perl's C<$1> and C<$2>. Using a question mark for
placeholders, as is common with L<DBI>, is not supported. An error is thrown
when attempting to execute a query where the number of C<@params> does not
match the number of placeholders in C<$sql>.

Note that this method just creates a statement object, the query is not
prepared or executed until the appropriate statement methods (see below) are
used.

=item $conn->Q(@args)

Same as C<< $conn->q() >> but uses L<FU::SQL> to construct the query and bind
parameters.

=back

Statement objects returned by C<< $conn->q() >> support the following
configuration parameters, which can be set before the statement is executed:

=over

=item $st->cache($enable)

Enable or disable caching of the prepared statement for this particular query.

=item $st->text_params($enable)

Enable or disable sending bind parameters in the text format. See
L</"Formats and Types"> below for what this means.

=item $st->text_results($enable)

Enable or disable receiving query results in the text format. See
L</"Formats and Types"> below for what this means.

=item $st->text($enable)

Shorthand for setting C<text_params> and C<text_results> at the same time.

=back

To execute the statement, call one (and exactly one) of the following methods,
depending on how you'd like to obtain the results:

=over

=item $st->exec

Execute the query and return the number of rows affected. Similar to C<<
$conn->exec >>.

  my $v = $conn->q('UPDATE books SET read = true WHERE id = 1')->exec;
  # $v = 1

=item $st->val

Return the first column of the first row. Throws an error if the query does not
return exactly one column, or if multiple rows are returned. Returns I<undef>
if no rows are returned or if its value is I<NULL>.

  my $v = $conn->q('SELECT COUNT(*) FROM books')->val;
  # $v = 2

=item $st->rowl

Return the first row as a list, or an empty list if no rows are returned.
Throws an error if the query returned more than one row.

  my($id, $title) = $conn->q('SELECT id, title FROM books LIMIT 1')->rowl;
  # ($id, $title) = (1, 'Revelation Space');

=item $st->rowa

Return the first row as an arrayref, equivalent to C<< [$st->rowl] >> but might
be slightly more efficient. Returns C<undef> if the query did not generate any
rows.

  my $row = $conn->q('SELECT id, title FROM books LIMIT 1')->rowa;
  # $row = [1, 'Revelation Space'];

=item $st->rowh

Return the first row as a hashref. Returns C<undef> if the query did not
generate any rows. Throws an error if the query returns multiple columns with
the same name.

  my $row = $conn->q('SELECT id, title FROM books LIMIT 1')->rowh;
  # $row = { id => 1, title => 'Revelation Space' };

=item $st->alla

Return all rows as an arrayref of arrayrefs.

  my $data = $conn->q('SELECT id, title FROM books')->alla;
  # $data = [
  #   [ 1, 'Revelation Space' ],
  #   [ 2, 'The Invincible' ],
  # ];

=item $st->allh

Return all rows as an arrayref of hashrefs. Throws an error if the query
returns multiple columns with the same name.

  my $data = $conn->q('SELECT id, title FROM books')->allh;
  # $data = [
  #   { id => 1, title => 'Revelation Space' },
  #   { id => 2, title => 'The Invincible' },
  # ];

=item $st->flat

Return an arrayref with all rows flattened.

  my $data = $conn->q('SELECT id, title FROM books')->flat;
  # $data = [
  #   1, 'Revelation Space',
  #   2, 'The Invincible',
  # ];

=item $st->kvv

Return a hashref where the first result column is used as key and the second
column as value. If the query only returns a single column, C<true> is used as
value instead. An error is thrown if the query returns 3 or more columns.

  my $data = $conn->q('SELECT id, title FROM books')->kvv;
  # $data = {
  #   1 => 'Revelation Space',
  #   2 => 'The Invincible',
  # };

=item $st->kva

Return a hashref where the first result column is used as key and the remaining
columns are stored as arrayref.

  my $data = $conn->q('SELECT id, title, read FROM books')->kva;
  # $data = {
  #   1 => [ 'Revelation Space', true ],
  #   2 => [ 'The Invincible', false ],
  # };

=item $st->kvh

Return a hashref where the first result column is used as key and the remaining
columns are stored as hashref.

  my $data = $conn->q('SELECT id, title, read FROM books')->kvh;
  # $data = {
  #   1 => { title => 'Revelation Space', read => true },
  #   2 => { title => 'The Invincible', read => false },
  # };

=back

The only time you actually need to assign a statement object to a variable is
when you want to inspect the statement using one of the methods below, in all
other cases you can chain the methods for more concise code. For example:

  my $data = $conn->q('SELECT a, b FROM table')->cache(0)->text->alla;

Statement objects can be inspected with the following methods (many of which
only make sense after the query has been executed):

=over

=item $st->query

Returns the SQL query that the statement was created with.

=item $st->param_values

Returns the provided bind parameters as an arrayref.

=item $st->param_types

Returns an arrayref of integers indicating the type (as I<oid>) of each
parameter in the given C<$sql> string. Example:

  my $oids = $conn->q('SELECT id FROM books WHERE id = $1 AND title = $2')->param_types;
  # $oids = [23,25]

  my $oids = $conn->q('SELECT id FROM books')->params;
  # $oids = []

This method can be called before the query has been executed, but will then
trigger a prepare operation.

=item $st->columns

Returns an arrayref of hashrefs describing each column that the statement
returns.

  my $cols = $conn->q('SELECT id, title FROM books')->columns;
  # $cols = [
  #   { name => 'id', oid => 23 },
  #   { name => 'title', oid => 25 },
  # ]

=item $st->nrows

Number of rows returned by the query.

=item $st->exec_time

Observed query execution time, in seconds. Includes network round-trip and
fetching the full query results. Does not include conversion of the query
results into Perl values.

=item $st->prepare_time

Observed query preparation time, in seconds, including network round-trip.
Returns 0 if a cached prepared statement was used or C<undef> if the query was
executed without a separate preparation phase (currently only happens with C<<
$conn->exec() >>, but support for direct query execution may be added for other
queries in the future as well).

=item $st->get_cache

=item $st->get_text_params

=item $st->get_text_results

Returns the respective configuration parameters.

=back



=head2 Transactions

This module provides a convenient and safe API for I<scoped transactions> and
I<subtransactions>. A new transaction can be started with C<< $conn->txn >>,
which returns an object that can be used to run commands inside the transaction
and control its fate. When the object goes out of scope, the transaction is
automatically rolled back if no explicit C<< $txn->commit >> has been
performed. Any attempts to run queries on the parent C<< $conn >> object will
fail while a transaction object is alive.

  {
    # start a new transaction
    my $txn = $conn->txn;

    # run queries
    $txn->q('DELETE FROM books WHERE id = $1', 1)->exec;

    # run commands in a subtransaction
    {
      my $subtxn = $txn->txn;
      # ...
    }

    # commit
    $txn->commit;

    # If $txn->commit has not been called, the transaction will be rolled back
    # automatically when it goes out of scope.
  }

Transaction methods:

=over

=item $txn->exec(..)

=item $txn->q(..)

=item $txn->Q(..)

Run a query inside the transaction. These work the same as the respective
methods on the parent C<$conn> object.

=item $txn->commit

=item $txn->rollback

Commit or abort the transaction. Any attempts to run queries on this
transaction object after this call will throw an error.

Calling C<rollback> is optional, the transaction is automatically rolled back
when the object goes out of scope.

=item $txn->cache($enable)

=item $txn->text_params($enable)

=item $txn->text_results($enable)

=item $txn->text($enable)

Set the default settings for new statements created with B<< $txn->q() >>.

These settings are inherited from the main connection when the transaction is
created. Subtransactions inherit these settings from their parent transaction.
Changing these settings within a transaction does not affect the main
connection or any already existing subtransactions.

=item $txn->txn

Create a subtransaction within the current transaction. A subtransaction works
exactly the same as a top-level transaction, except any changes remain
invisible to other sessions until the top-level transaction has been committed.

=item $txn->status

Like C<< $conn->status >>, but with the following status codes:

=over

=item idle

Current transaction is active and awaiting commands.

=item done

Current transaction has either been committed or rolled back, further commands
will throw an error.

=item error

Current transaction is in error state and must be rolled back.

=item txn_idle

A subtransaction is active and awaiting commands. The current transaction is
not usable until the subtransaction goes out of scope.

(This status code is also returned when the subtransaction is 'done', the
current implementation does not track subtransactions that closely)

=item txn_error

A subtransaction is in error state and awaiting to be rolled back.

=item bad

Connection is dead or otherwise unusable.

=back

=back

Of course, if you prefer the old-fashioned manual approach to transaction
handling, that is still available:

  $conn->exec('BEGIN');
  # We're now inside a transaction
  $conn->exec('COMMIT') or $conn->exec('ROLLBACK');

Just don't try to use transaction objects and manual transaction commands at
the same time, that won't end well.


=head2 Formats and Types

The PostgreSQL wire protocol supports sending bind parameters and receiving
query results in two different formats: text and binary. While the exact wire
protocol is an implementation detail that you don't have to worry about, this
module does have a different approach to processing the two formats.

When you enable C<text> mode, your bind parameters are sent verbatim, as text,
to the PostgreSQL server, where they are then parsed, validated and
interpreted.  Likewise, when receiving query results in text mode, it is the
PostreSQL server that is formatting the data into textual strings. Text mode is
essentially a way to tell this module: "don't try to interpret my data, just
send and receive everything as text!"

Instead, in the (default) C<binary> mode, the responsibility of converting
Postgres data to and from Perl values lies with this module. This allows for a
lot of type-specific conveniences, but has the downside of requiring special
code for each supported PostgreSQL type. Most of the Postgres core types are
supported by this module and convert in an intuitive way, but here's a few
type-specific notes:

=over

=item bool

Boolean values are converted to C<builtin::true> and C<builtin::false>. As bind
parameters, Perl's idea of truthiness is used: C<0>, C<false> and C<""> are
false, everything else is true. Objects that overload I<bool> are also
supported. C<undef> always converts to SQL C<NULL>.

=item bytea

The C<bytea> type represents arbitrary binary data and this module will pass
that along as raw binary strings.

=item timestamp / timestamptz

These are converted to and from seconds since the Unix epoch as a floating
point value, similar to the C<time()> (or better: C<Time::HiRes::time()>)
functions.

The timestamp types in Postgres have microsecond accuracy. Floating point can
represent that without loss for dates that are near enough to the epoch (still
seems to be fine in 2025, at least), but this conversion may be lossy for dates
far beyond or before the epoch.

=item date

Converted between strings in C<YYYY-MM-DD> format. Postgres accepts a bunch of
alternative date formats, this module does not.

=item json / jsonb

These types are converted through C<json_parse()> and C<json_format()> from
L<FU::Util>.

While C<null> is a valid JSON value, there's currently no way to distinguish
that from SQL C<NULL>. When sending C<undef> as bind parameter, it is sent as
SQL C<NULL>.

=item arrays

PostgreSQL arrays automatically convert to and from Perl arrays as you'd
expect. Arrays in PostgreSQL have the rather unusual feature that the starting
index can be changed for each individual array, but this module doesn't support
that.  All arrays received from Postgres will use Perl's usual 0-based indexing
and all arrays sent to Postgres will use their default 1-based indexing.

=item records / row types

These are converted to and from hashrefs.

=item geometric types

=item numeric

=item macaddr

=item money

=item time / timetz

=item bit / varbit

=item tsvector / tsquery

=item Extension types

These are not supported at the moment. Not that they're hard to implement (I
think), I simply haven't looked into them yet. Open a bug report if you need
any of these.

=back

I<TODO:> Methods to convert between the various formats.

I<TODO:> Methods to query type info.

I<TODO:> Custom per-type configuration.

=head2 Errors

All methods can throw an exception on error. When possible, the error message
is constructed using L<Carp>'s C<confess()>, including a full stack trace.

SQL errors and other errors from I<libpq> are reported with a C<FU::Pg::error>
object, which has the following fields:

=over

=item action

The action that was attempted, "connect", "prepare" or "exec".

=item query

The query that was being prepared or executed, if any.

=item message

Human-readable error message.

=item verbose_message

More verbose message, usually consisting of multiple lines.

=item severity

=item detail

=item hint

=item statement_position

=item internal_position

=item internal_query

=item context

=item schema_name

=item table_name

=item column_name

=item datatype_name

=item constraint_name

=item source_file

=item source_line

=item source_function

These correspond to error fields from
L<PQresultErrorField()|https://www.postgresql.org/docs/current/libpq-exec.html#LIBPQ-PQRESULTERRORFIELD>.

=back


=head1 LIMITATIONS

=over

=item * Does not support older versions of libpq or PostgreSQL. Currently only
tested with version 17, but versions a bit older than that ought to work fine
as well.  Much older versions will certainly not work fine.

=item * (Probably) not thread-safe.

=item * Only supports the UTF-8 encoding for all text strings sent to and
received from the PostgreSQL server. The encoding is assumed to be UTF-8 by
default, but if this may not be the case in your situation, setting
C<client_encoding=utf8> as part of the connection string or manually switching
to it after C<connect()> is always safe:

  my $conn = FU::Pg->connect('');
  $conn->exec('SET client_encoding=utf8');

=item * Only works with blocking (synchronous) calls, not very suitable for use
in asynchronous frameworks unless you know your queries are fast and you have a
low-latency connection with the Postgres server.

=back

Missing features:

=over

=item COPY support

I hope to implement this someday.

=item LISTEN support

Would be nice to have, most likely doable without going full async.

=item Asynchronous calls

Probably won't happen. Perl's async story is slightly awkward in general, and
fully supporting async operation might require a fundamental redesign of how
this module works. It certainly won't I<simplify> the implementation.

=item Pipelining

I have some ideas for an API, but doubt I'll ever implement it. Suffers from
the same awkwardness and complexity as asynchronous calls.

=back


=head1 SEE ALSO

=over

=item L<DBD::Pg>

The venerable Postgres driver for DBI. More stable, portable and battle-tested
than this module, but type conversions may leave things to be desired.

=item L<Pg::PQ>

Thin wrapper around libpq. Lacks many higher-level conveniences and doesn't do
any type conversions for you.

=item L<DBIx::Simple>

Popular DBI wrapper with some API conveniences. I may have taken some
inspiration from it in the design of this module's API.

=back

=head1 COPYRIGHT

MIT.

=head1 AUTHOR

Yorhel <projects@yorhel.nl>
