package FU::Pg 1.2;
use v5.36;
use FU::XS;

_load_libpq();

package FU::Pg::conn {
    sub lib_version { FU::Pg::lib_version() }

    sub Q {
        require FU::SQL;
        my $s = shift;
        my($sql, $params) = FU::SQL::SQL(@_)->compile(
            placeholder_style => 'pg',
            in_style          => 'pg',
            quote_identifier  => sub { $s->conn->escape_identifier(@_) },
        );
        $s->q($sql, @$params);
    }

    sub set_type($s, $n, @arg) {
        Carp::confess("Invalid number of arguments") if @arg == 0 || (@arg > 1 && @arg % 2);
        return $s->_set_type($n, $arg[0], $arg[0]) if @arg == 1;
        my %arg = @arg;
        $s->_set_type($n, $arg{send}, $arg{recv});
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

=head1 Connection setup

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

=item active

Currently executing a query. This state can only be observed during a L<COPY
operation|/"COPY support">.

=item bad

Connection is dead or otherwise unusable.

=back

=item $conn->escape_literal($str)

Return an escaped version of C<$str> suitable for use as a string literal in an
SQL statement. You'll rarely need this, it's often better to pass data as bind
parameters instead.

=item $conn->escape_identifier($str)

Return an escaped version of C<$str> suitable for use as an identifier (name of
a table, column, function, etc) in an SQL statement.

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
C<< $conn->copy >> statements and internal queries performed by this module
(such as for transaction management, querying type information, etc) do not
trigger the callback. Statements that result in an error being thrown during or
before execution are also not traceable this way. This behavior might change in
the future.

=item $conn->disconnect

Close the connection. Any active transactions are rolled back and further
attempts to use C<$conn> throw an error.

=back

=head1 Querying

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
parameters. Uses the 'pg' C<in_style> and C<< $conn->escape_identifier() >> for
identifier quoting.

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
trigger a prepare operation. An empty array is also returned if the query has
already been executed without a separate preparation step; this happens if
prepared statement caching is disabled and C<text_params> is enabled.

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
executed without a separate preparation phase.

=item $st->get_cache

=item $st->get_text_params

=item $st->get_text_results

Returns the respective configuration parameters.

=back



=head1 Transactions

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

=item active

Currently executing a query. This state can only be observed during a L<COPY
operation|/"COPY support">.

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


=head1 Formats and Types

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
code for every PostgreSQL type. Most of the core types are supported by this
module and convert in an intuitive way, but you can also configure each type
manually:

=over

=item $conn->set_type($target_type, $type)

=item $conn->set_type($target_type, send => $type, recv => $type)

Change how C<$target_type> is being converted when used as a bind parameter
(I<send>) or when received from query results (I<recv>). The two-argument
version is equivalent to setting I<send> and I<recv> to the same C<$type>.

Types can be specified either by their numeric I<Oid> or by name. In the latter
case, the name must exactly match the internal type name used by PostgreSQL.
Note that this "internal type name" does not always match the names used in
documentation. For example, I<smallint>, I<integer> and I<bigint> should be
specified as I<int2>, I<int4> and I<int8>, respectively, and the I<char> type
is internally called I<bpchar>. The full list of recognized types in your
database can be queried with:

  SELECT oid, typname FROM pg_type;

The C<$target_type> does not have to exist in the database when this method is
called. This method only stores the type in its internal configuration, which
is consulted when executing a query that takes the type as bind parameter or
returns a column of that type.

The following arguments are supported for C<$type>:

=over

=item * I<undef>, to reset the conversion functions to their default.

=item * The numeric I<Oid> or name of a built-in type supported by this module,
to use those conversion functions.

=item * A subroutine reference that is called to perform the conversion.  For
I<send>, the subroutine is given a Perl value as argument and expected to
return a binary string to be sent to Postgres. For I<recv>, the subroutine is
given a binary string received from Postgres and expected to return a Perl
value.

=back

=back

Some built-in types deserve a few additional notes:

=over

=item bool

Boolean values are converted to C<builtin::true> and C<builtin::false>.

As bind parameters, values recognized by C<to_bool()> in L<FU::Util> are
accepted, in addition to C<0>, C<"f"> and C<""> for false and C<1>, and C<"t">
for true.  C<undef> always converts to SQL C<NULL>. Everything else throws an
error.

=item bytea

The C<bytea> type represents arbitrary binary data and this module will pass
that along as raw binary strings. If you prefer to work with hex strings
instead, use:

  $conn->set_type(bytea => '$hex');

The I<bytea> and the I<$hex> (pseudo-)types can be applied to any other type to
convert between the PostgreSQL binary wire format and Perl strings. For
example, if you prefer to receive integers as big-endian hex strings, you can
do that:

  $conn->set_type(int4 => recv => '$hex');

Or to treat UUIDs as 16-byte strings:

  $conn->set_type(uuid => 'bytea');

=item timestamp / timestamptz

These are converted to and from seconds since the Unix epoch as a floating
point value, for easy comparison against C<time()> and related functions.

The timestamp types in Postgres have microsecond accuracy. Floating point can
represent that without loss for dates that are near enough to the epoch (still
seems to be fine in 2025, at least), but this conversion may be lossy for dates
far beyond or before the epoch.

Postgres internally represents timestamps as microseconds since 2000-01-01
stored in a 64-bit integer. If you prefer that, use:

  $conn->set_type(timestamptz => 'int8');

=item date

Converted between seconds since Unix epoch as an integer, with the time fixed
at C<00:00:00 UTC>. When used as bind parameter, the time part is truncated.
This format makes for easy comparison with other timestamps, but if you prefer
to work with strings in the C<YYYY-MM-DD> format instead, use:

  $conn->set_type(date => '$date_str');

Postgres accepts a bunch of alternative date formats for bind paramaters, this
module does not.

=item time

Converted between floating point seconds since C<00:00:00>, supporting
microsecond precision. This format allows for easy comparison against Unix
timestamps (time of day in UTC = C<$timestamp % 86400>) and can be added to an
integer date value to form a complete timestamp.

(There's no support for the string format yet)

=item json / jsonb

These types are converted through C<json_parse()> and C<json_format()> from
L<FU::Util>.

While C<null> is a valid JSON value, there's currently no way to distinguish
that from SQL C<NULL>. When sending C<undef> as bind parameter, it is sent as
SQL C<NULL>.

If you prefer to work with JSON are raw text values instead, use:

  $conn->set_type(json => 'text');

That doesn't I<quite> work for the C<jsonb> type. I mean, it works, but then
there's a single C<"\1"> byte prefixed to the string.

=item arrays

PostgreSQL arrays automatically convert to and from Perl arrays as you'd
expect. Arrays in PostgreSQL have the rather unusual feature that the starting
index can be changed for each individual array, but this module doesn't support
that.  All arrays received from Postgres will use Perl's usual 0-based indexing
and all arrays sent to Postgres will use their default 1-based indexing.

=item records / row types

Typed records are converted to and from hashrefs. Untyped records (i.e. values
of the C<record> pseudo-type) are not supported.

=item domain types

These are recognized and automatically converted to and from their underlying
type. It may be tempting to use C<set_type()> to configure special type
conversions for domain types, but beware that PostgreSQL reports columns in the
C<SELECT> clause of a query as being of the I<underlying> type rather than the
domain type, so the conversions will not apply in that case. They do seem to
apply when the domain type is used as bind parameter, array element or record
field. This is an (intentional) limitation of PostgreSQL, sadly not something I
can work around.

=item geometric types

=item numeric

=item macaddr

=item money

=item timetz

=item bit / varbit

=item tsvector / tsquery

=item range / multirange

=item Extension types

These are not supported at the moment. Not that they're hard to implement (I
think), I simply haven't looked into them yet. Open a bug report if you need
any of these.

As a workaround, you can always switch back to the text format or use
C<set_type()> to configure appropriate conversions for these types.

=back

Utility functions:

=over

=item $conn->perl2bin($oid, $val)

=item $conn->bin2perl($oid, $bin)

Convert the value for a specific type between the Perl representation and the
PostgreSQL binary format, using the current type configuration of the
connection. This is the same conversion used internally by this module to send
bind parameters and receive query results, and map to the C<send> and C<recv>
functions of C<< $conn->set_type() >>.

These methods throw an error if C<$oid> is not a known type or if the given
data is not valid for the type. However, these methods should not be used for
strict validation: the conversion routines are usually written under the
assumption that the data has been received directly from Postgres or is about
to be sent to (and further validated by) Postgres.  For some types,
C<perl2bin()> may return invalid data on invalid input and C<bin2perl()> may
accept invalid binary data.

=item $conn->bin2text($oid, $bin, ...)

=item $conn->text2bin($oid, $text, ...)

Convert between the binary format and the PostgreSQL text format. This
conversion requires a round-trip to the server and throws an error if the
connection state is not I<idle> or I<txn_idle>. Since it is Postgres doing the
conversion, the input is properly validated and, in the case of C<bin2text()>,
the result is guaranteed to be suitable for use as a textual bind parameter or
for inclusion in an SQL query (but don't forget to use C<escape_literal()> in
that case).

Calling these methods many times can be pretty slow. If you have several values
to convert, you can do that in a single call to speed things up:

  my($text1, $text2, ..) = $conn->bin2text($oid1, $bin1, $oid2, $bin2, ..);

=back

I<TODO:> Methods to query type info.


=head1 COPY support

You can use L<COPY
statements|https://www.postgresql.org/docs/current/sql-copy.html> for efficient
bulk data transfers between your application and the PostgreSQL server:

=over

=item $copy = $conn->copy($statement)

=item $copy = $txn->copy($statement)

Execute C<$statement> and return a C<FU::Pg::copy> object that lets you
transfer data to or from Postgres.

It is not possible to execute any other queries on the same connection while a
copy operation is in progress. When used on a transaction object, C<$txn> must
be kept alive long enough to finish the copy operation.

=back

A C<$copy> object supports the following methods:

=over

=item $copy->is_binary

Returns true if the transfer is performed in the binary format, false for text.

=item $copy->write($data)

Send C<$data> to the server. An error is thrown if this is not a C<COPY FROM
STDIN> operation. An error may be thrown if C<$data> is not a valid format
understood by Postgres, but such errors can also be deferred to C<close()>.

C<$data> is interpreted as a Perl Unicode string for textual transfers and as a
binary string for binary transfers.

=item $copy->read

Return the next row read from the Postgres server, or C<undef> if no more data
is coming. In the text format, a single line - including trailing newline - is
returned as a Perl Unicode string. In the binary format, a single row is
returned as a byte string. An error is thrown if this is not a C<COPY TO
STDOUT> operation.

=item $copy->close

Marks the end of the copy operation. Does not return anything but throws an
error if something went wrong.

It is possible to close a read-copy operation before all data has been
consumed, but that causes all data to still be read and discarded during
C<close()>. If you really want to interrupt a large read operation, a more
efficient approach is to call C<< $conn->disconnect >> and discard the entire
connection.

It is not I<necessary> to call this method, simply letting the C<$copy> object
run out of scope will do the trick as well, but in that case errors are
silently discarded. An explicit C<close()> is recommended to catch errors.

=back


=head1 Errors

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
low-latency connection with the Postgres server. This is unlikely to improve in
future versions, Perl's async story is somewhat awkward in general, and fully
supporting async operation might require a fundamental redesign of how this
module works.

=item * LISTEN support is still missing. May be added in a future version, as
this seems doable without supporting full async.

=item * Pipelining support is also missing. I have some ideas for an API, but
doubt I'll ever implement it. Suffers from the same awkwardness and complexity
as asynchronous calls.

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
