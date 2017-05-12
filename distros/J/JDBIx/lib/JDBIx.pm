=head1 NAME

JDBIx - Object-oriented higher-level DBI interface for select into arrays, placeholders, sequences, etc.

=head1 AUTHOR

	This module is Copyright (C) 2000-2016 by

		Jim Turner
		
		Email: turnerjw784@yahoo.com

	All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;
	use JDBIx;

	&jdbix_setlog('/tmp/dbixlogt.txt');   #OPTIONALLY, SET UP A LOG FILE.

	#CONNECT TO A DATABASE:

	my $dbh = new JDBIx('dbtype:dbname,dbuser,dbpswd',{}) 
			or die ("-no login: err=" . &jdbix_err() . ':' . &jdbix_errstr . "=\n");

	$dbh->package(__PACKAGE__);  #UNLESS PACKAGE IS "main::".

	#DO A SIMPLE SELECT, STORING THE RESULTS INTO @f1 AND @f2.

	our (@f1, @f2);  #MUST BE PACKAGE, NOT "MY" VARIABLES:
	my $res = $dbh->select('select field1, field2 into :f1, :f2 from test') 
			or warn ('Could not do select (' . $dbh->err() . '.' . $dbh->errstr() . ')!');

	for (my $i=0;$i<=$res;$i++) {
		print "-For record# $i: field1=$f1[$i], field2=$f2[$i]\n";
	}

	#ANOTHER SIMPLE SELECT, RETURNING THE RESULTS INTO @res:

	my @res = $dbh->select('select field1, field2 from test');
	for (my $i=0;$i<=$#res;$i++) {
		print "\n-For record# $i: ";
		for (my $j=0;$j<=$#{$res[$i]};$j++) {
			print "value =$res[$i]->[$j],\t";
		}
	}

	#DO A VECTORIZED SELECT, SELECTING A RECORD FOR EACH KEY VALUE IN @f1:

	our (@f3, @f4);  #MUST BE PACKAGE, NOT "MY" VARIABLES:
	my $sqlstr = 'select field3, field4 into :f3, :f4 from test2 where field1 = :f1';
	$res = $dbh->do($sqlstr, 1) or die $dbh->errstr();

	#INSERT A NEW RECORD:

	$res = $dbh->do1('insert into test values (?, ?, ?, ?)', 
			'value1', 'value2', 'value3', 'value4') 
		or die ('Could not insert record (' . $dbh->err() . '.' . $dbh->errstr() . ')!');

	#COMMIT THE TRANSACTION:

	$dbh->commit();

	#FETCH THE AUTONUMBER / SEQUENCE KEY VALUE OF THE LAST INSERT:

	my $newestkey = $dbh->fetchseq('keyfieldname');
	print "..Just inserted new record with key: $newestkey.\n";

	#CURSORS:

	$sqlstr = 'update test set field1 = ? where field2 = ?';
	my $csr = $dbh->opencsr($sqlstr) or die ("Could not open ($sqlstr) (".$dbh->errstr().")!");

	#AN OPTIONAL 2ND ARGUMENT TO opencsr CAUSES $dbh->execute() TO BE CALLED 
	#IN ADDITION TO $dbh->prepare().  IF THE RETURN VARIABLE IS A LIST, A 
	#SECOND VALUE IS RETURNED REPRESENTING THE RESULT RETURNED BY $dbh->execute. 
	#ALSO, IF USED FOR A SELECT STATEMENT, VARIABLES CAN BE BOUND JUST AS 
	#FOR select (see ":f1" and ":f2" in prev. examples). 

	for (my $i=0;$i<=$#f1;$i++) {
		$csr->bind($i, $f1[$i]);
	}
	$csr->closecsr();

	#AN EXAMPLE OF SELECT USING CURSORS:

	$sqlstr = 'select field3, field4 from test2 where field1 = ?';
	$csr = $dbh->opencsr($sqlstr) or die "Could not open ($sqlstr) (".$dbh->errstr().")!";
	for (my $i=0;$i<=$#f1;$i++) {
		$csr->bind($f1[$i]);
		while (my ($f3, $f4) = $csr->fetch()) {
			print "-For record# $i (key $f1[$i]): field3=$f3, field4=$f4\n";
		}
	}
	$csr->closecsr();

	#ANOTHER EXAMPLE OF VECTOR SELECT USING CURSORS (WITH INTO CLAUSE):
	#NOTE:  $csr->fetch() and $csr->fetchall() WILL NOT RETURN RESULTS HERE BECAUSE 
	#THE DATA HAS ALREADY BEEN FETCHED BY THE $csr->bind() CALL INTO THE VECTORS: @f1 and @f3!

	$sqlstr = 'select field3, field4 into :f3, :f4 from test2 where field1 = ?';
	$csr = $dbh->opencsr($sqlstr) or die "Could not open ($sqlstr) (".$dbh->errstr().")!";
	for (my $i=0;$i<=$#f1;$i++) {
		$res = $csr->bind($f1[$i]);
		for (my $j=0;$j<$res;$j++) {
			print "-For record# $i (key $f1[$i]): field3=$f3[$j], field4=$f4[$j]\n";
		}
	}
	$csr->closecsr();

	#DISCONNECT FROM THE DATABASE:

	$dbh->disconnect();

	exit(0);

=head1 DESCRIPTION

JDBIx provides a higher-level interface to L<DBI> by combining I<prepare>() and I<execute>() 
methods, but more than that, it also provides placeholders for databases that do not support 
them, provides instant loading of I<select>() results into arrays by column via a single command.  
Another feature is abstraction of sequence / autonumbering fields in a database-independent manner.

=head1 METHODS

=over 4

=item B<Class Methods>

=over 4

=item $dbh = B<new JDBIx>(I<connect-string>, [ I<attrs> ]);

Creates and returns a new database connection object. I<connect-string> normally contains the 
DBD::I<modulename>, the I<database-name>, the I<user-name>, and the I<password> in the format:  
'I<modulename>:I<database-name>,I<user-name>,I<password>'.  The I<user-name>, and I<password> 
are sometimes optional depending on the database and connection requirements.  I<attrs> is 
an optional hash-reference and DBD::I<modulename> -dependent.  Returns I<undef> on failure.

I<connect-string>:  Examples:

1) Simple 1:  'mysql:mydatabase,userid,password'

2) Simple 2:  'SQLite:mydatabase'

3) Proxy 1:   'dbi:host:port:mysql:mydatabase,userid,password'

3) Proxy 2:   'mysql:mydatabase,userid,password', { -proxy => 'host:port' }

4) Literal1:   '=dbi:Proxy:hostname=host;port=9090;dsn=DBI:dbi:host:port:mysql:userid,password'

5) Literal2:   'connect=dbi:Proxy:hostname=host;port=9090;dsn=DBI:dbi:host:port:mysql:userid,password'

6) Hash1: (-type => 'mysql', -name = >'mydatabase', -user=> 'userid' -pswd => 'password', -proxy => 'host:port')

7) Hash2: (-connect => 'mysql:mydatabase,userid,password', -proxy => 'host:port')

8) Hash3: (-connect => '=dbi:Proxy:hostname=host;port=9090;dsn=DBI:dbi:host:port:mysql:userid,password', -proxy => 'IGNORESME!:port')

NOTE:  If using the Hash format, any additional arguments ("I<attrs>") should be included in the hash, 
rather than as a separate hash-reference.

NOTE2:  If a literal DBI connect string ("=dbi...") is used, any conflicting attributes, namely "-name", 
"-user", "-pswd", and "-proxy" are IGNORED and the literal string is passed directly to DBI->connect()!

=item I<$scalar> = B<&jdbix_autocommit>([ I<1 | 0> ]);

I<attrs> - include any additional attributes in hash-reference format.  This includes any parameters to 
be passed to DBI, any database-specific parameters, any jdbix parameters (prefix with "-jdbix_I<parameter>"), 
and any environment variables that need to be set (prefix with "-jdbix_env_I<variable-name>").

If an argument is passed, then sets the default I<autocommit> status for any future database objects 
created within the program to on or off based on that argument, if no argument is passed, it returns 
the current default I<autocommit> status, which is zero (0) if this function has not been previously 
called with an argument.  NOTE:  It does not alter the I<autocommit> flag for any currently opened 
database objects, see $dbh->B<autocommit>() for changing the I<autocommit> flag for a currently opened 
database.

=item I<$scalar> = B<&jdbix_err>([ I<$database_object> ]);

Returns the last error code number encountered.  If I<$database_object> is specified, then it returns 
the last error code recorded for that database object, otherwise $DBI::err is returned.  NOTE:  this 
method can be used after an I<attempted> creation of a new database object to get the error code 
when the object fails to be created (and there's thus no database object).  After a database object 
is successfully created, it's preferred to use $dbh->B<err>().

=item I<$scalar> = B<&jdbix_errstr>([ I<$database_object> ]);

Returns the last error message text for the last error encountered.  If I<$database_object> is 
specified, then it returns the last error message recorded for that database object, otherwise 
$DBI::errstr is returned.  NOTE:  this method can be used after an I<attempted> creation of a new 
database object to get the error code when the object fails to be created (and there's thus no 
database object).  After a database object is successfully created, it's preferred to use 
$dbh->B<errstr>().

=item $dbh->B<setlog>(I<log-file>); -or- B<jdbix_setlog>(I<log-file>);

Sets up a log file to log queries to.  The first sets up a log file for a specific connection, 
the latter, a general log file for all connections.  The I<log-file> should be a string 
containing the full path of the log file.  Both functions may be called and set up two 
separate log files.  Return 1 if successfully opened the log file for writing, 0 if not.

=item I<$scalar> = B<&jdbix_package>([ I<package_name> ]);

Set or retrieve the current DEFAULT package name used for placeholder variables in "INTO" clauses in 
queries.  NOTE:  This function does NOT change the current package name used by currently opened 
database objects, but only the default package name used when subsequent database objects are created! 
See $dbh->B<package>() for changing the current package name used by an open database object. 
IF I<package_name> is specified, the default package name is set in the program in subsequently opened 
database objects (until B<&jdbix_package>() is called with a different package name).  
If not specified, it returns the current package name.  The default package name is "main".  
NOTE:  The current I<package_name> can also be set for a database when opened by 
passing the 'I<jdbix_package>' => 'I<package_name>' attribute when creating the database object.

=back

=item B<Object Methods>

=over 4

=item I<$scalar> = $dbh->B<autocommit>([ I<1 | 0> ]);

If an argument is passed, then sets the database's I<autocommit> status to on or off based on that 
argument, if no argument is passed, it returns the current state of the database's I<autocommit> status.

=item I<$scalar> = $dbh->B<commit>();

Causes any pending queries that changed the database to be committed (unless I<autocommit> is on for 
the database connection).  If I<autocommit> is on, it returns 1 (true).  Otherwise, it returns the 
result of the DBI->I<commit>() call.

=item $dbh->B<disconnect>();

Disconnect from the database;

=item I<$scalar> = $dbh->B<do>('I<query-string>' [, I<attrs> ]);

Provides vectorized selects and inserts, updates, etc.  I<query-string> can be any valid SQL 
query string.  Returns the number of records affected / selected.  I<attrs> is an optional 
hash-reference that can contain one or more of the following options:

=over 4

=item B<-interpolate> => 0..3 (default 0) - special attribute for handling the relationship between the 
key vector(s) and the vector array(s) containing the returned results.

If B<0>, then the query is just executed as-is and the 
number of rows affected / selected is returned.  For selects based on key vectors (arrays), the 
results are like as if 2 was specified. 

If B<1>, and the query is a select, then it is 
assumed that a 1:1 relationship exists between the vector array-references given in the WHERE clause 
and the results returned - the query is done once in a loop for each element in the set of "keys" 
specified by these array-references and only the first matching record for each keyset will be 
returned.  All the arrays given by the array-references in both the WHERE clause AND the INTO 
clause will be sorted WITHIN the sort order of the elements in the keys arrays.

If B<2> or B<3>, a 1:MANY relationship is assumed between the key arrays and the results returned in the 
INTO arrays, and all records that match the combination of the queries performed on each element 
in the set of "keys" specified by the array-references in the WHERE clause will be returned sorted, 
but the "key" arrays referenced will not be sorted, but remain in the order given.  The difference 
between 2 and 3 is that with 2, at least one record (with empty fields, if none match) is 
guarenteed to be returned for EACH element in the longest key array (all key arrays should be the 
same length).  With 3, if no records match a given element in the key arrays, then no records will 
be returned for that set of keys.

=item B<-commit> => true | false (default false) - If I<autocommit> is off for the database connection, 
a I<commit> will be done automatically after the query completes (if any records affected) (if TRUE), 
no commit is done if FALSE.

=back

=item [ I<$scalar> | I<@array> = ] $dbh->B<do1>('I<query-string>' [, I<bind-parameter-list> ]);

Performs a single query as-is.  

Similar to $dbh->B<do1>(), but simpler and a I<bind-parameter-list> is allowed.  This method is the 
preferred method of doing non-select queries, but can handle selects too.  The optional returned 
results are the same as $dbh->B<select>() for select queries, and $dbh->B<do>() for other queries.
The primary difference versus $dbh->B<do>() is that the query is not looped against vectors given 
in a WHERE clause, the WHERE clause must be a simple scalar set of key values, which can be bound 
with placeholders by the I<bind-parameter-list>.  Results are not committed unless I<autocommit> is 
turned on for the database connection.  Think of it as "do ONE query".

=item I<$scalar> = $dbh->B<err>();

Returns the last error code number encountered.

=item I<$scalar> = $dbh->B<errstr>();

Returns the last error message text for the last error encountered.  

=item I<$scalar> = $dbh->B<fetchnextseq>([ I<sequencename> ]);

This can be called anytime and returns the next value of sequence I<sequencename>.  For Sprite and Oracle, 
this is accomplished by doing a "SELECT <sequencename>.NEXTVAL from DUAL".  For mysql, it returns the 
I<mysql_insert_id>().  Currently only Oracle, Sprite, mysql, and SQLite are properly supported, but one can 
add code for their own database or send me a patch! Or, one can rely on the failsafe option 
(which works if either your database isn't supported, in which case, 
the first time this function is called, a file named "$ENV{HOME}/.dbixseq" is created with a sequence 
value of 1, which is returned. Subsequent calls return the next integer and save it to this file, 
emulating a "sequence".  For mysql and SQLite, the I<sequencename> can be omitted as mysql always returns 
I<mysql_insert_id>() which is the value of the most recent autonumber field updated.  SQLite always 
returns I<sqlite_last_insert_rowid>().

=item I<$scalar> = $dbh->B<fetchseq>('I<keyfieldname>', [ 'I<sequencename>', [ I<tablename>' ] ]);

This is called after an insert and should return the value of the last sequence specified in that 
insert (used to get the key of the last record inserted) when using sequences or the autonumbering 
feature of a database. Only the 1st argument is required. The other arguments are useful if one 
is not sure their database is supported or to act as a "catch-all" option if a value is not obtainable.  
This is done by doing a fetch from the table: "Table_Name" for a descending list of values for the 
field specified by "SEQ_FIELD_NAME" and returns the 1st value returned.  I<sequencename> defaults 
to the last sequence used in Oracle databases, but can be overridden here. This returns the 
sequence or auto-number assigned to the last key field inserted into a table in a database-independent 
way. You usually will call this function immediately after inserting a record with a sequence / 
autonumber field to get the generated key value, for example to create an index record referencing 
that key value. This currently supports Oracle, Sprite, and MySQL.  There is also a default method 
of fetching a descending list of values and returning the 1st one.  This should work with most other 
databases, but is less efficient. You can add code for your particular database, if it has a more 
efficient way of supporting it, grep the comments for "ADD CODE". 

The I<keyfieldname> is the sequence or autonumber field name.  The optional I<sequencename> is useful 
only for Oracle and Sprite databases and specifies the actual "sequence" name to fetch.  For others, 
the default is used, which is the last sequence or autonumber field used in the most recent 
insert or update query that involved a sequence or autonumber field.  The I<tablename> field is 
useful for other "non-supported" databases (those other than Oracle, Sprite, or mysql) to tell 
B<fetchseq>() which table to grab the most recent autonumber / sequence field specified by 
I<keyfieldname> from.  It is ignored for supported databases and defaults to the last table to which 
an insert or update involving a sequence or autonumber field was done.

=item I<$scalar> = $dbh->B<package>([ I<package_name> ]);

Set or retrieve the current package name used for placeholder variables in "INTO" clauses in queries.  
IF I<package_name> is specified, the default package for all such variables from that point on in 
the program (until B<&jdbix_package>() is called with a different package name) are assumed to be of 
that package.  If not specified, it returns the current package name.  The default package name 
is "main".  NOTE:  The current I<package_name> can also be set for a database when opened by 
passing the 'I<-jdbix_package>' => 'I<package_name>' attribute when creating the database object.

=item I<$scalar> = $dbh->B<rollback>();

Causes any pending queries that changed the database to be rolled back (unless I<autocommit> is on for 
the database connection).  If I<autocommit> is on, it returns 1 (true).  Otherwise, it returns the 
result of the DBI->I<rollback>() call.

=item $dbh->B<select>('I<query-string>' [, I<bind-parameter-list>]);

Perform a selection query on the database.  The I<query-string> can be a standard SQL query 
string, but may contain traditional SQL placeholders ("?") or special JDBIx placeholders 
in an "INTO" clause representing corresponding Perl variables to receive the respective field data.  
For example:

[ I<$scalar> | I<@array> = ] $dbh->B<select>('select field1, field2, field3 into :f1, :f2, :f3 where keyfield = ?', 'foo');

This would do a B<prepare>(), an B<execute>(), and B<fetch>() functions, and create / reset three 
scalars ($f1, $f2, and $f3) set to the first values returned for the respective fields, and 
three arrays (@f1, @f2, and @f3), each containing a list of all the values returned for their 
respective columns.  NOTE:  These are I<package> variables, NOT "my" variables.  The I<package> is 
the current package (or main) or the one specified by the B<dbix_package> attribute when the 
database object was created.

If <@array> is given, an array of references to arrays of field data is returned.  This is not 
necessary (and memory can be saved) if using the "INTO" clause and package variable placeholders 
as described above.  Each element of the array represents a single "row" or "record" of data as 
a reference to an array containing the field values returned for that record.  If no records are 
returned, then it is ().  If I<$scalar> is given, then it is the number of records (rows) fetched.

=back

=item B<Cursor Methods>

=over 4

=item I<$scalar> = $dbh->B<opencsr>(I<query-string> [, I<execute_flag> ]);

Opens a "cursor" (does a I<prepare>()) on the query specified by I<query-string> and returns a "cursor" 
object which can be used ...

If the optional I<execute_flag> is set to true, then an I<execute>() is also performed immediately after 
the I<prepare>().  One can then call B<opencsr>() in I<array> context, if so, the first element is the 
I<cursor> object returned and the second element is the result returned by the I<execute>() call.

Returns I<undef> if anything fails.

=item $csr->B<bind>(I<bind-parameter-list>);

Causes the values in the I<bind-parameter-list> to be bound to the placeholders and the query to be 
executed.  This is needed unless the I<execute_flag> is set to true when the cursor was opened.
Returns the number of rows affected or fetched, I<undef> on failure.  "0E0", the Perl "true" value 
for zero is returned if successful, but no rows are affected.  NOTE:  If a SELECT query with an INTO 
clause is used, the data is fetched into the vector arrays by bind() and the number of rows fetched 
will be returned.  In this case, calling fetch() or fetchall() will return empty since the data has 
already been fetched here.  If a SELECT query with no INTO clause is performed, then bind() returns 
"0E0" (success, but no rows affected or fetched) and then the data can then be fetched with either 
fetch() or fetchall().

=item I<@array> = $csr->B<fetch>();

Fetches and returns the next row of data by a call to I<fetchrow_array>().  If no records remained 
to be fetched, it returns an empty array () (false).

=item I<$scalar> | I<@array> = $csr->B<fetchall>();

Fetches and returns any and all remaining records by repeated calls to I<fetchrow_array>().  In 
scalar context, returns only the number of records fetched.  In array context, returns an array 
of array references, one for each record returned.  These each reference an array of field values 
returned.  If using array variable placeholders (an INTO clause), then one need not call B<fetchall>() 
in array context to get back the data.

=item $csr->B<closecsr>();

Closes the cursor.

=back

=back

=head1 KNOWN BUGS

-none (yet)-

=head1 SEE ALSO

L<DBI>, L<perl(1)>

=cut

package JDBIx;

#NOTE:  do commits due to multiple records, do1 does NOT!

use FileHandle;
use DBI;
use vars qw(@ISA @EXPORT $VERSION);
$VERSION = '1.02';

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(jdbix_autocommit jdbix_setlog jdbix_package jdbix_err jdbix_errstr);

my $calling_package = 'main';
my $autocommit = 0;
my $lastdb;
my $logfid = 0;
my $logfh = 0;

sub new
{
	my $class = shift;
	my $connectstr = shift;
	my $attrs;

	my $self = {};
	if ($connectstr =~ /^\s*\-/)
	{
		$attrs = {$connectstr, @_};
		foreach my $atb (qw(type name user pswd connect))
		{
			$self->{"db$atb"} = delete $attrs->{"-$atb"} || '';
		}
		$connectstr = (defined($self->{"dbconnect"}))
				? $self->{"dbconnect"}
				: "$self->{dbname},$self->{dbuser},$self->{dbpswd}";
	}
	else
	{
		$attrs = shift;
	}
	$self->{proxy} = delete $attrs->{"-proxy"} || '';

	my ($dbi_proxy, $j);
	foreach my $i (keys (%$attrs))
	{
		if ($i =~ /^\-jdbix_/o)
		{
			$j = $i;
			$j =~ s/^\-jdbix_//o;
			$self->{$j} = $attrs->{$i};
			$ENV{"\U$j\E"} = $attrs->{$i}  if ($j =~ s/^env_//o);
			delete $attrs->{$i};
		}
	}
	if ($self->{proxy})
	{
		$dbi_proxy = $self->{proxy};
		$dbi_proxy =~ s/\:/\;port\=/;
		$dbi_proxy = 'Proxy:hostname='.$dbi_proxy.';dsn=DBI:';
	}
	else
	{
		$dbi_proxy = '';
	}
	$self->{dbtype} = $1  if ($connectstr =~ s/^(\w+)\://);
	$self->{dbtype} = 'ODBC'  if ($self->{dbtype} =~ /odbc/i);

	if ($self->{dbtype} =~ /^Sybase/)
	{
		#SET IF DB DOES NOT ALLOW "?" PLACEHOLDERS IN SQL-COMMANDS!
		$self->{noplaceholders} = 1  unless(defined $self->{noplaceholders});
	}
	if ($connectstr =~ s/^\s*(?:connect\=|\=)//i)
	{
#		$self->{dbtype} = $1  if ($connectstr =~ /dbi\:${dbi_proxy}(\w+):/);
#x		if ($connectstr =~ /dbi\:${dbi_proxy}([^\:]+)\:(\w*)/)
		if ($connectstr =~ /dbi\:proxy\:([^\:]+)\:/i)
		{
			$dbi_proxy = $1;
			($self->{proxy} = $dbi_proxy) =~ s/\;dsn=DBI$//i;
			if ($connectstr =~ /dbi\:proxy\:${dbi_proxy}\:([^\:]+)\:(\w*)/i)
			{
				$self->{dbtype} = $1  if ($1);
				$self->{dbname} = $2  if ($2);
			}
		}
		else   #PROXY IS NOT IN THE LITERAL CONNECT STRING, SO REMOVE IT, IF SPECIFIED IN ATTRIBUTES!
		{
			$dbi_proxy = '';
			delete $self->{proxy}  if (defined $self->{proxy});
#			($self->{dbtype}, $self->{dbname}) = ($1, $2)  if ($connectstr =~ /dbi\:([^\:]+)\:(\w*)/);
			if ($connectstr =~ /dbi\:([^\:]+)\:(\w*)/i)
			{
				$self->{dbtype} = $1  if ($1);
				$self->{dbname} = $2  if ($2);
			}
		}
		$dbi_err = \$DBI::err;
		$dbi_errstr = \$DBI::errstr;
		($self->{dbuser}, $self->{dbpswd}) = ($1, $2)  if ($connectstr =~ /\,([^\,]*)\,(.*)$/);
		unless ($connectstr =~ /dbi\:proxy\:/i || $dbi_proxy)
		{
			$ENV{TWO_TASK} ||= $1  if ($connectstr =~ s/\:Oracle\:(\w+)/\:Oracle\:/);
		}
		my $dB = DBI->connect($connectstr,$self->{dbuser},$self->{dbpswd},$attrs);
#print "*** connect1($connectstr,".$self->{dbuser}.',',$self->{dbpswd},",<attrs>);\n";
		return undef  unless ($dB);
		return undef  if ($DBI::err);
		$self->{DBI} = $dB;
		$dB->{AutoCommit} = $attrs->{-AutoCommit} || $autocommit;
		$dB->{AutoCommit} = 1  if ($self->{dbtype} =~ /^mysql/ 
				|| ($connectstr =~ /dbi\:proxy\:/i && $DBI::VERSION < 1.21));
		$self->{connect} = $connectstr;
	}
	else
	{	
		if ($connectstr) {
			my @nup = split(/\,/,$connectstr);
			$self->{dbname} ||= $nup[0]  if ($nup[0]);
			$self->{dbuser} ||= $nup[1]  if ($nup[1]);
			$self->{dbpswd} ||= $nup[2]  if ($nup[2]);
		}
	
		$dbi_err = \$DBI::err;
		$dbi_errstr = \$DBI::errstr;
		my $dbid;
		if ($self->{dbtype} =~ /oracle/i)
		{
			@dbname = split(/:/,$self->{dbname});
			$self->{dbname} = 'T:' . $self->{dbname}  if ($#dbname == 1);
			$ENV{TWO_TASK} = $self->{dbname}  unless ($dbi_proxy);
			$dbid = "dbi:${dbi_proxy}Oracle:";
			$dbid .= $self->{dbname}  if ($dbi_proxy);
		}
		else
		{
			$dbid = "dbi:${dbi_proxy}$self->{dbtype}:$self->{dbname}";
		}
		my $dB = DBI->connect($dbid,$self->{dbuser},$self->{dbpswd},$attrs);
#print "*** connect($dbid,".$self->{dbuser}.',',$self->{dbpswd},",<attrs>);\n";
		return undef  unless ($dB);
		return undef  if ($DBI::err);
		$self->{DBI} = $dB;
		if ($self->{dbtype} =~ /^mysql/ || ($dbi_proxy && $DBI::VERSION < 1.21))
		{
			$dB->{AutoCommit} = 1;
		}
		else
		{
			$dB->{AutoCommit} = $attrs->{-AutoCommit} || $autocommit;
		}
		$self->{connect} = $dbid;
	}
	$self->{calling_package} = $self->{'package'} || $calling_package;
	($self->{dbi_proxy} = $dbi_proxy) =~ s/\;dsn\=DBI\:$/i/;
	$self->{autocommit} = $dB->{AutoCommit};
	$self->{lasterr} = undef;
	$self->{err} = \$DBI::err;
	$self->{errstr} = \$DBI::errstr;
	$self->{logfid} = 0;

	bless $self, $class;

	$lastdb = $self;
	return $self;
}

sub setlog
{
	my $self = shift;
	my ($mylogfid) = shift;

	$self->{addsemicolon} = shift || 0;  

	# 0=no change to logfile; 1=append ';'; 2=convert ampresands for SQL-PLUS and append ';'
	
	$self->{logfh}->close  if ($self->{logfid});
	$self->{logfid} = 0;
	if ($mylogfid)
	{
		$self->{logfh} ||= new FileHandle;
		if ($self->{logfh} && $self->{logfh}->open(">>$mylogfid"))
		{
			$self->{logfid} = $mylogfid;
			return (1);
		}
		else
		{
			return (0);
		}
	}
	return (1);
}

sub jdbix_setlog
{
	my ($mylogfid) = shift;

	$addsemicolon = shift || 0;  
	# 0=no change to logfile; 1=append ';'; 2=convert ampresands for SQL-PLUS and append ';'
	
	$logfh->close  if ($logfid);
	$logfid = 0;
	if ($mylogfid)
	{
		$logfh ||= new FileHandle;
		if ($logfh && $logfh->open(">>$mylogfid"))
		{
			$logfid = $mylogfid;
			return (1);
		}
		else
		{
			return (0);
		}
	}
	return (1);
}

sub package
{
	my $self = shift;
	my $pkg = shift;

	return $self->{calling_package}  unless (defined($pkg) && $pkg);
	$self->{calling_package} = $pkg;
	return 1;
}

sub jdbix_package
{
	my $pkg = shift;

	return $calling_package  unless (defined($pkg) && $pkg);

	$calling_package = $pkg;
	return 1;
}

sub disconnect
{
	return undef  unless ($_[0]->{DBI});
	my $res = $_[0]->{DBI}->disconnect;
	if ($self->{logfid})
	{
		$self->{logfh}->close;
		$self->{logfid} = 0;
		undef $self->{logfh};
	}
	$_[0]->{DBI} = undef;
	undef $_[0];
	return $res;
}

sub select
{
	my ($self, $sqlstr, @bindvals) = @_;   #bindvals ADDED 20000217!
	local ($_);
	my ($i, @res, $mycsr, $myexe, @reflistv, @refsclrv);
	my ($fetchcnt) = 0;
	my (@myline) = ();
	my ($cleansql) = $sqlstr;
	
	$lastdb = $self;
	#$nores = 1  if ($cleansql =~ s/\binto\b//i);
	$cleansql =~ s/\binto\b//io;
	#$nores = 1  unless (wantarray);  #20000425: CHANGED 2 NEXT LINE (FIX BUG)!
	$nores = (wantarray ? 0 : 1);
	$cleansql =~ s/\:[^\s\,\:]+\,?//go;
	if ($self->{noplaceholders})
	{
		$cleansql =~ s/([\'\"])([^\1]*?)\1/
				my ($quote) = $1;
				my ($str) = $2;
				$str =~ s|\?|\x02\^2jSpR1tE\x02|go;   #PROTECT ?'S IN QUOTES.
				"$quote$str$quote"
		/egs;
		my $t;
		while (@bindvals)
		{
			$t = shift(@bindvals);
			$t =~ s/\'/\'\'/gso;
			$t =~ s/\?/\x02\^2jSpR1tE\x02/gso;
			$cleansql =~ s/\?/\'$t\'/s;
		}
		$cleansql =~ s/\x02\^2jSpR1tE\x02/\?/gso;
	}
#print "<BR>-???- clean sql=$cleansql= DB=".$self->{dbtype}."=\n";
	if ($mycsr = $self->{DBI}->prepare($cleansql))
	{
		my (@types, @scales);
		if ($myexe = $mycsr->execute(@bindvals))
		{
			if ($self->{dbtype} eq 'SQLite')   #HACK TO MAKE SQLite SCALED "DECIMALS" ROUND TO PROPER #DECIMALS AND VALUES!
			{                                  #SINCE SQLite STORES DECIMALS AS FLOATING POINT (REAL)!
				@types = @{$mycsr->{TYPE}};
				for (my $i=0;$i<=$#types;$i++)
				{
					$scales[$i] = $1  if ($types[$i] =~ /(?:DECIMAL|REAL)\(\d+[\,\.](\d+)\)/io);
				}
			}
			if ($sqlstr =~ /\binto\b/io)
			{
				my (@varlistv) = ($sqlstr =~ /:\D\w*/go);
				foreach $i (@varlistv)
				{
					$i =~s/\:/$self->{calling_package}\:\:/;
					$i =~s/\,//o;
					@{$i} = ();     #INITIALIZE TO CLEAR ANY OLD VALUES!
					${$i} = '';
					push (@reflistv,\@{$i});
					push (@refsclrv,\${$i});
				}
				while ((@myline) = $mycsr->fetchrow_array())
				{
					last if (defined($self->{DBI}->err) && $self->{DBI}->err > 0);
					for ($i=0;$i<=$#varlistv;$i++)
					{
						$myline[$i] = sprintf("%.$scales[$i]f", $myline[$i])  if (defined $scales[$i]);  #FIX SQLite FLOAT->DECIMAL ROUNDING ERRORS
						${$refsclrv[$i]} = $myline[$i]  unless ($fetchcnt);
						push(@{$reflistv[$i]},$myline[$i]);

					}
					push (@res,[@myline])  unless ($nores);
					++$fetchcnt;
				};
			}
			else
			{
				if ($self->{dbtype} eq 'SQLite')   #HACK TO MAKE SQLite SCALED "DECIMALS" ROUND TO PROPER #DECIMALS AND VALUES!
				{
					while (@myline = $mycsr->fetchrow_array())
					{
						last if ($self->{DBI}->err > 0);
						for ($i=0;$i<=$#myline;$i++)
						{
							$myline[$i] = sprintf("%.$scales[$i]f", $myline[$i])  if (defined $scales[$i]);  #FIX SQLite FLOAT->DECIMAL ROUNDING ERRORS
						}
						push (@res,[@myline])  unless ($nores);
						++$fetchcnt;
					}
				}
				else
				{
					while (@myline = $mycsr->fetchrow_array())
					{
						last if ($self->{DBI}->err > 0);
						push (@res,[@myline])  unless ($nores);
						++$fetchcnt;
					}
				}
			}
		}
		else
		{
			return ();
		}
		$mycsr->finish();
		#$mycsr = undef;
		#return ( wantarray ? ('a','b','c') : $#res );
		return (@res)  unless ($nores);
		return $fetchcnt;
	}
	return ();
}

sub do
{
	my ($self, $sqlstr, $ophref) = @_;

#### WARNING:  DO *NOT* USE SINGLE-QUOTES AROUND ANY :PARAMETERS !!!!!!!!!
#### (IT DON'T WORK!)

	my ($interpolate) = $ophref->{-interpolate} || $ophref;
	local ($_);
	my ($i, $j, $mycsr, $myexe, $rowcnt, @myvals, 
			@varlistv, $logsql, $isaselect, $myline);
	my ($maxlistsize) = -1;
	my ($parmcnt) = 0;
	
	$lastdb = $self;
	$rowcnt = 0;
	unless ($interpolate)    #20001117: 3RD OPTION (=3): RETURN 0 OR MORE RECORDS FOR EACH KEY
	{                        #20001117: (=2) ALWAYS RETURNS 1 OR MORE RECORDS!
		$rowcnt = $self->{DBI}->do($sqlstr);
		if ($self->{logfid} || $logfid)
		{
			$sqlstr =~ s/\s+$//o;
			$sqlstr =~ s/^\s+//o;
			$sqlstr .= ';'  if ($self->{addsemicolon});
			$sqlstr =~ s/\&/\'\|\|\'\&\'\|\|\'/go
					if ($self->{addsemicolon} == 1);
			if ($self->{logfid})
			{
				my $logfh = $self->{logfh};   #NEEDED FOR PERL TO COMPILE.
				flock $logfh, 2;    #EXCLUSIVE LOCK.
				print $logfh "$sqlstr\n";
				flock $logfh, 8;    #UNLOCK.
			}
			if ($logfid)
			{
				flock $logfh, 2;    #EXCLUSIVE LOCK.
				print $logfh "$sqlstr\n";
				flock $logfh, 8;    #UNLOCK.
			}
		}
		$self->commit()  if ($ophref->{-commit});
		return (undef)  if ($self->{DBI}->err < 0);
		return ($rowcnt);
	}
	my $varliststart = 0;             #NEXT 15 ADDED 20011207 TO FIX INCORRECT MAXLISTSIZE ON SELECTS.
	if ($sqlstr =~ /^\s*select\s/io)  #("INTO" VBLES NEEDED BLANKING *BEFORE* MAXLISTSIZE CALCULATED!)
	{
		$isaselect = 1;
#CHGD. TO NEXT 20160122 TO ALLOW :vbles W/O LEADING "/":			while ($sqlstr =~  s#(into[\s\?\,]+)(\/\:[a-zA-Z_][^,\)\s\"]*)#$1\?#i)
		while ($sqlstr =~  s#(into[\s\?\,]+)(\/?\:[a-zA-Z_][\w\d\_]*)#$1\?#i)
		{
			push (@varlistv,$2);
			++$parmcnt;
		}
		for ($i=0;$i<=$#varlistv;$i++)
		{
#CHGD. TO NEXT 20160122 TO ALLOW :vbles W/O LEADING "/":				$varlistv[$i] =~ s#/\:#$self->{calling_package}\:\:#;
			$varlistv[$i] =~ s#\/?\:#$self->{calling_package}\:\:#;
		}
		$varliststart = scalar(@varlistv);
	}
#CHGD. TO NEXT 20160122 TO ALLOW :vbles W/O LEADING "/":	while ($sqlstr =~  s#\'?(\/\:[a-zA-Z_][^,\)\s\"]*)#\?#o)
	while ($sqlstr =~  s#\'?(\/?\:[a-zA-Z_][\w\d\_]*)#\?#o)
	{
		push (@varlistv,$1);
		++$parmcnt;
	}
	for ($i=$varliststart;$i<=$#varlistv;$i++)
	{
#CHGD. TO NEXT 20160122 TO ALLOW :vbles W/O LEADING "/":		$varlistv[$i] =~ s#/\:#$self->{calling_package}\:\:#;
		$varlistv[$i] =~ s#\/?\:#$self->{calling_package}\:\:#;
		if ($#{$varlistv[$i]} >= 0)
		{
			$maxlistsize = $#{$varlistv[$i]}  if ($#{$varlistv[$i]} > $maxlistsize);
		}
	}
	$sqlstr =~ s/'(\:\d+)'/$1/g;
	#$sqlstr =~ s/'\?'/\?/g;      #REMOVED 20010125 TO FIX ERROR WHEN USER ENTRY WAS JUST A SINGLE QUESTION-MARK!
	my ($cleansql) = $sqlstr;
	$selectargcnt = 0;
	if ($isaselect)
	{
		$cleansql =~ s/\binto\b([\s\?\,]*)//io;
		my ($t) = $1;
		++$selectargcnt  while ($t =~ /\?/go);
	}
	else
	{
		###########$sqlstr   =~ s/\n/ /gs;
		if ($self->{dbtype} =~ /^odbc/io && $sqlstr =~ /insert.*\w+\.NEXTVAL/so)
		{
			$sqlstr = &_fixNEXTVAL($self, $sqlstr);
		}
		elsif ($self->{dbtype} =~ /^mysql/o)
		{
			$sqlstr =~ s/([\,\(]\s*)\w+\.NEXTVAL(\s*[\,\)])/$1NULL$2/g;
			#MYSQL DOES SEQUENCES DIFFERENTLY (see AUTO_INCREMENT)!
		}
		#ADDED 20030904 TO MAKE SEQUENCE-RETRIEVAL DATABASE-INDEPENDENT.
		if ($sqlstr =~ /insert\s+into\s+(\w+).*?(\w+)\.NEXTVAL/sio)
		{
			$self->{lastsequencetable} = $1;
			$self->{lastsequencename} = $2;
		}
	}
	for ($i=0;$i<$selectargcnt;$i++)
	{
		@{$varlistv[$i]} = ();     #INITIALIZE TO CLEAR ANY OLD VALUES 
		${$varlistv[$i]} = '';     #FROM VBLES TO RECEIVE SELECT INPUTS.
	}
	my $cleantemplate;
	if ($self->{noplaceholders})
	{
		$cleansql =~ s/([\'\"])([^\1]*?)\1/
				my ($quote) = $1;
				my ($str) = $2;
				$str =~ s|\?|\x02\^2jSpR1tE\x02|go;   #PROTECT ?'S IN QUOTES.
				"$quote$str$quote"
		/egs;
		$cleansql =~ s/\?/\x02\^3jSpR1tE\x02/gso;     #PROTECT BINDING ?S.
		$cleansql =~ s/\x02\^2jSpR1tE\x02/\?/gso;     #UNPROTECT ?'S IN QUOTES.
		$cleantemplate = $cleansql;
	}
	elsif ($isaselect)
	{
		$mycsr = $self->{DBI}->prepare($cleansql) or return ();
	}

	$maxlistsize = 0 if ($maxlistsize < 0);
	my ($ii) = 0;
	my $bindok;

	#-------------------------------------------------------------

	local *select_noplaceholders = sub
	{
		my $t;
		for ($i=0;$i<=$maxlistsize;$i++)
		{
			$cleansql = $cleantemplate;
			for ($j=$selectargcnt;$j<=$parmcnt-1;$j++)
			{
				$t = defined($#{$varlistv[$j]}) ? ${$varlistv[$j]}[$i]
						: ${$varlistv[$j]};
				$t =~ s/\'/\'\'/gso;
				$t =~ s/\?/\x02\^3jSpR1tE\x02/gso;
				$cleansql =~ s/\x02\^3jSpR1tE\x02/\'$t\'/s;
			}
			@myline = ();
			$mycsr = $self->{DBI}->prepare($cleansql);
			return 0  if ($self->{DBI}->err);   #ADDED 20010517 TO CATCH ERRORS!
			$res = $mycsr->execute();
			return 0  if ($self->{DBI}->err);   #ADDED 20010517 TO CATCH ERRORS!
			#return 0  unless ($res > 0 || $mycsr);
			@myline = $mycsr->fetchrow_array();
			if ($#myline >= 0 || $interpolate < 3)     #IF ADDED 20001117
			{
				for ($j=0;$j<=$selectargcnt-1;$j++)
				{
					$myline[$j] = ''  if ($res eq 'OK');  #ADDED 19991011 JWT.
					if (defined($#{$varlistv[$j]}))
					{
						${$varlistv[$j]}[$ii] = $myline[$j];
					}
					else
					{
						${$varlistv[$j]} = $myline[$j];
					}
				}
				++$ii;
				++$rowcnt;
			}
			if ($interpolate >= 2)     #20001117
			{
II:
				while (@myline = $mycsr->fetchrow_array())
				{
					for ($j=0;$j<=$selectargcnt-1;$j++)
					{
						if (defined($#{$varlistv[$j]}))
						{
							${$varlistv[$j]}[$ii] = $myline[$j];
						}
						else
						{
							${$varlistv[$j]} = $myline[$j];
						}
					}
					++$ii;
					++$rowcnt;
				}
			}
			$mycsr->finish();
			if ($ophref->{-commit})
			{
				$self->commit()  unless ($rowcnt % 20);
			}
		}
		return 1;
	};

	local *select_placeholders = sub
	{
		for ($i=0;$i<=$maxlistsize;$i++)
		{
			@myvals = ();
			for ($j=$selectargcnt;$j<=$parmcnt-1;$j++)
			{
				if (defined($#{$varlistv[$j]}))
				{
					push(@myvals,${$varlistv[$j]}[$i]);
					###$mycsr->bind_param($j1, ${$varlistv[$j]}[$i])  if ($mycsr);
				}
				else
				{
					push(@myvals,${$varlistv[$j]});
				}
			}
			$res = $mycsr->execute(@myvals);
			return 0  if ($self->{DBI}->err);   #ADDED 20010517 TO CATCH ERRORS!
			@myline = $mycsr->fetchrow_array();
			if ($#myline >= 0 || $interpolate < 3)     #IF ADDED 20001117
			{
				for ($j=0;$j<=$selectargcnt-1;$j++)
				{
					$myline[$j] = ''  if ($res eq 'OK');  #ADDED 19991011 JWT.
					if (defined($#{$varlistv[$j]}))
					{
						${$varlistv[$j]}[$ii] = $myline[$j];
					}
					else
					{
						${$varlistv[$j]} = $myline[$j];
					}
				}
				++$ii;
				++$rowcnt;
			}
			if ($interpolate >= 2)     #20001117
			{
II:
				if (scalar(@myline))  #TEST ADDED 20040211 TO PREVENT RAISE-ERROR ERROR.
				{
					while (@myline = $mycsr->fetchrow_array())
					{
						for ($j=0;$j<=$selectargcnt-1;$j++)
						{
							if (defined($#{$varlistv[$j]}))
							{
								${$varlistv[$j]}[$ii] = $myline[$j];
							}
							else
							{
								${$varlistv[$j]} = $myline[$j];
							}
						}
						++$ii;
						++$rowcnt;
					}
				}
			}
			$mycsr->finish();
			if ($ophref->{-commit})
			{
				$self->commit()  unless ($rowcnt % 20);
			}
		}
		return 1;
	};

	local *nonselect_noplaceholders = sub
	{
		my $t;
		for ($i=0;$i<=$maxlistsize;$i++)
		{
			@myvals = ();
			$cleansql = $cleantemplate;
			for ($j=$selectargcnt;$j<=$parmcnt-1;$j++)
			{
				$t = defined($#{$varlistv[$j]}) ? ${$varlistv[$j]}[$i]
						: ${$varlistv[$j]};
				$t =~ s/\'/\'\'/gso;
				$t =~ s/\?/\x02\^3jSpR1tE\x02/gso;
				$cleansql =~ s/\x02\^3jSpR1tE\x02/\'$t\'/s;
			}
			@myline = ();
			$res = $self->{DBI}->do($cleansql);
			return 0  unless ($res eq '0E0' || $res > 0);
			++$rowcnt;
			if ($self->{logfid} || $logfid)
			{
				$logsql = $cleansql;
				$logsql =~ s/\s+$//o;
				$logsql =~ s/^\s+//o;
				$logsql .= ';'  if ($self->{addsemicolon});
				$sqlstr =~ s/\&/\'\|\|\'\&\'\|\|\'/go
						if ($self->{addsemicolon} == 1);
				if ($self->{logfid})
				{
					my $logfh = $self->{logfh};   #NEEDED FOR PERL TO COMPILE.
					flock $logfh, 2;    #EXCLUSIVE LOCK.
					print $logfh "$logsql\n";
					flock $logfh, 8;    #UNLOCK.
				}
				if ($logfid)
				{
					flock $logfh, 2;    #EXCLUSIVE LOCK.
					print $logfh "$logsql\n";
					flock $logfh, 8;    #UNLOCK.
				}
			}
			if ($ophref->{-commit})
			{
				$self->commit()  unless ($rowcnt % 20);
			}
		}
		return 1;
	};

	local *nonselect_placeholders = sub
	{
		for ($i=0;$i<=$maxlistsize;$i++)
		{
			@myvals = ();
			for ($j=$selectargcnt;$j<=$parmcnt-1;$j++)
			{
				if (defined($#{$varlistv[$j]}))
				{
					push(@myvals,${$varlistv[$j]}[$i]);
					###$mycsr->bind_param($j1, ${$varlistv[$j]}[$i])  if ($mycsr);
				}
				else
				{
					push(@myvals,${$varlistv[$j]});
				}
			}
			@myline = ();
			$res = $self->{DBI}->do($cleansql,{},@myvals);
			return 0  unless ($res eq '0E0' || $res > 0);
			++$rowcnt;
			if ($self->{logfid} || $logfid)
			{
				$logsql = $cleansql;
				for ($j=0;$j<=$#myvals;$j++)
				{
					#$j1 = $j + 1;
					#$logsql =~ s/\:$j1/\'$myvals[$j]\'/g;
					$logsql =~ s/\?/\'$myvals[$j]\'/;
				}
				$logsql =~ s/\s+$//o;
				$logsql =~ s/^\s+//o;
				$logsql .= ';'  if ($self->{addsemicolon});
				$sqlstr =~ s/\&/\'\|\|\'\&\'\|\|\'/go
						if ($self->{addsemicolon} == 1);
				if ($self->{logfid})
				{
					my $logfh = $self->{logfh};   #NEEDED FOR PERL TO COMPILE.
					flock $logfh, 2;    #EXCLUSIVE LOCK.
					print $logfh "$logsql\n";
					flock $logfh, 8;    #UNLOCK.
				}
				if ($logfid)
				{
					flock $logfh, 2;    #EXCLUSIVE LOCK.
					print $logfh "$logsql\n";
					flock $logfh, 8;    #UNLOCK.
				}
			}
			if ($ophref->{-commit})
			{
				$self->commit()  unless ($rowcnt % 20);
			}
		}
		return 1;
	};

	#-------------------------------------------------------------

	if ($isaselect)
	{
		$bindok = $self->{noplaceholders} ? &select_noplaceholders() : &select_placeholders();
	}
	else
	{
		$bindok = $self->{noplaceholders} ? &nonselect_noplaceholders() : &nonselect_placeholders();
	}
	if ($bindok)
	{
		$self->commit()  if ($ophref->{-commit});
		#NEXT IF ADDED 20040120 TO SORT VECTORIZED SELECTS (WHICH DON'T SORT
		#OTHERWISE) WHEN "ORDER-BY" CLAUSE PRESENT.  NOTE:  ONLY SELECT VECTORS 
		#ARE SORTED (NOT KEY VECTORS) UNLESS INTERPOLATE = 1 (INTERPOLATE = 1 
		#IMPLIES A PROMISE THAT *ALL* VECTORS WILL BE *SAME* LENGTH!!!!!!!!
		if ($isaselect && $selectargcnt > 0 && $rowcnt > 1)
		{
			if ($sqlstr =~ /\s*order\s+by\s+([\w\.\, ]+)$/iso)
			{
				my $ordbyclause = $1;
				my $sortavailable;
#s				eval {require 'sort_elements.pl' and $sortavailable = 1;};
#s				if ($sortavailable)
				unless (1)
				{
					my @sortfields = split(/\,/o, $ordbyclause);
					my @sortorders = ();
					for (my $i=0;$i<=$#sortfields;$i++)  #ASCENDING VS. DESCENDING.
					{
						$sortorders[$i] = ($sortfields[$i] =~ s/\s+desc//iso)
								? '-' : '';
						$sortfields[$i] =~ s/\s//go;
					}
					if ($sqlstr =~ /select\s+([a-z\.\,_\s]+)into/iso)
					{
						my $selfields = $1;
						my @selfields = split(/\,/o, $selfields);
						my @sortvec;
						for (my $i=0;$i<=$#selfields;$i++)
						{
							$selfields[$i] =~ s/\s//go;
						}
						#DETERMINE WHICH ARRAYS TO SORT BY (SORTVEC).
						for (my $j=0;$j<=$#sortfields;$j++)
						{
							for (my $i=0;$i<=$#selfields;$i++)
							{
								push (@sortvec, "$sortorders[$j]$i")  if ($selfields[$i] eq $sortfields[$j])
							}
						}
						my $sortcmd;
						if ($interpolate == 1)  #SORT *ALL* VECTORS INCL. KEYS!
						{
							$sortcmd = "&sort_elements_by_list(["
									.join(',',@sortvec).'], [], \@'
									.join(',\@', @varlistv).');';
						}
						else   #ONLY SORT NON-KEY VECTORS (KEY VECTORS NOT SAME LENGTH).
						{      #WARNING - KEY VECTORS WILL NOT LINE UP WITH SELECT VECTORS NOW!
							$sortcmd = "&sort_elements_by_list(["
									.join(',',@sortvec).'], []';
							for (my $i=0;$i<=$#selfields;$i++)
							{
								$sortcmd .= ',\@'.$varlistv[$i];
							}
							$sortcmd .= ');';
						}
						eval $sortcmd;
					}
				}
			}
		}
		return $rowcnt;
	}
	else
	{
NOBIND:
		return undef;
	}
}

sub commit
{
	my ($self) = shift;
	
	local ($_);
	$lastdb = $self;
	#return $self->{DBI}->commit;    #AUTOCOMMIT IS ON!

	return $self->{DBI}->commit  unless ($self->{DBI}->{AutoCommit});    #AUTOCOMMIT IS ON!
	return 0;
}

sub rollback
{
	my ($self) = shift;

	local ($_);
	return $self->{DBI}->rollback  unless ($self->{DBI}->{AutoCommit});    #AUTOCOMMIT IS ON!
	return 0;
}

sub autocommit  #CALL WITH 1 ARG UNLESS DB ALREADY OPEN!
{
	my ($self) = shift;
	my ($ac) = shift;

	return $self->{autocommit}  unless (defined($ac) && $ac);

	$lastdb = $self;
	$self->{DBI}->{AutoCommit} = $ac;
	$self->{autocommit} = $ac;
	return 1;
}

sub jdbix_autocommit  #CALL WITH 1 ARG UNLESS DB ALREADY OPEN!
{
	my ($ac) = shift;
	return $autocommit  unless (defined($ac) && $ac);

	$autocommit = $ac;
	return 1;
}

sub jdbix_err
{
	my ($self) = shift || $lastdb;

	return $self ? $self->err() : $DBI::err;
}

sub err
{
	my $self = shift;

	return $self->{DBI}->err  if ($self->{DBI} && $self->{DBI}->err);
	return ${$self->{err}}  if (ref $self->{err});
	return $DBI::err  if ($DBI::err);
	return undef;
}

sub jdbix_errstr
{
	my ($self) = shift || $lastdb;

#	return 'Not logged in, invalid database, id, password?'  unless ($self);
	return $self ? $self->errstr() : $DBI::errstr;
}

sub errstr
{
	my $self = shift;
	return $self->{DBI}->errstr  if ($self->{DBI} && $self->{DBI}->errstr);
#	return $$self->{errstr}  if (ref $self->{errstr});
	return $DBI::errstr  if ($DBI::errstr);
	return $self->err();
}

package JDBIx::csr;

use DBI;

sub new
{
	my $class = shift;

	my $self = {};
	
	bless $self, $class;

	return $self;
}
	
sub bind    #NOTE:  BIND ARGS MUST APPEAR IN ORDER (ie. :1, :2, :3)!
{
	my ($mycsr, @bindvals) = @_;
	my ($t);

	$lastdb = $mycsr->{dB};
	my $fetchcnt = 0;
	my $cleansql = $mycsr->{cleansql};
	my $sqlstr = $mycsr->{sql};
	if ($mycsr->{dB}->{noplaceholders})
	{
		$mycsr->{csr}->finish()  if ($mycsr->{csr});
		while (@bindvals)
		{
			$t = shift(@bindvals);
			$t =~ s/\'/\'\'/gs;
			$t =~ s/\?/\x02\^2jSpR1tE\x02/gso;
			$sqlstr =~ s/\x02\^3jSpR1tE\x02/\'$t\'/s;
		}
		$mycsr->{csr} = $mycsr->{dB}->{DBI}->prepare($sqlstr);
		return undef  unless ($mycsr->{csr});
	}
	my ($res) = $mycsr->{csr}->execute(@bindvals);
	return undef  if ($mycsr->{csr}->err);
	if ($mycsr->{select})
	{
		for (my $i=0;$i<=$mycsr->{varcnt};$i++)
		{
			${${$mycsr->{refsclrv}}[$i]} = '';
			@{${$mycsr->{reflistv}}[$i]} = ();
		}
		if ($mycsr->{varcnt} >= 0)
		{
			my (@myline);
			$fetchcnt = 0;
			while ((@myline) = $mycsr->{csr}->fetchrow_array())
			{
				last if ($mycsr->{dB}->{DBI}->err > 0);
				for (my $i=0;$i<=$mycsr->{varcnt};$i++)
				{
					${${$mycsr->{refsclrv}}[$i]} = $myline[$i]  unless ($fetchcnt);
					#CORRECTED ABOVE BUG 20001205 WHICHED RETURNED LAST RECORD (SHOULD BE 1ST)!
					push(@{${$mycsr->{reflistv}}[$i]},$myline[$i]);

				}
				++$fetchcnt;
			};
		}
	}
	else   #ADDED 20010228 TO LOG NON-SELECTS DONE W/BIND!
	{
		#NEXT 5 ADDED 20030922 TO MAKE SEQUENCE-RETRIEVAL DATABASE-INDEPENDENT.
		if ($sqlstr =~ /insert\s+into\s+(\w+).*?(\w+)\.NEXTVAL/sio)
		{
			$mycsr->{dB}->{lastsequencetable} = $1;
			$mycsr->{dB}->{lastsequencename} = $2;
		}
		if ($mycsr->{dB}->{logfid} || $logfid)
		{
			$sqlstr =~ s/\s+$//o;
			$sqlstr =~ s/^\s+//o;
			for (my $i=0;$i<=$#bindvals;$i++)
			{
				$t = $bindvals[$i];
				$t =~ s/\'/\'\'/go;
				$t =~ s/\?/\x02\^2jSpR1tE\x02/gso;
				$sqlstr =~ s/\x02\^3jSpR1tE\x02/\'$t\'/s;
			}
			$sqlstr .= ';'  if ($mycsr->{$dB}->{addsemicolon});
			$sqlstr =~ s/\&/\'\|\|\'\&\'\|\|\'/go
					if ($mycsr->{$dB}->{addsemicolon} == 1);
			if ($mycsr->{dB}->{logfid})
			{
				my $logfh = $mycsr->{dB}->{logfh};   #NEEDED FOR PERL TO COMPILE.
				flock $logfh, 2;    #EXCLUSIVE LOCK.
				print $logfh "$sqlstr\n";
				flock $logfh, 8;    #UNLOCK.
			}
			if ($logfid)
			{
				flock $logfh, 2;    #EXCLUSIVE LOCK.
				print $logfh "$sqlstr\n";
				flock $logfh, 8;    #UNLOCK.
			}
		}
	}
	if ($fetchcnt)   #ADDED 20001205 TO FIX ERRONIOUS RESULT FROM ORACLE DBI::PROXY OF 250.
	{
		return $fetchcnt;
	}
	elsif ($res)
	{
		return $mycsr->{csr}->rows ? $mycsr->{csr}->rows : $res;
	}
	else
	{
		return $res;
	}
}

sub fetch
{
	my $mycsr = shift;

	$lastdb = $mycsr->{dB};
	my @myline = $mycsr->{csr}->fetchrow_array();
	if ($mycsr->{select})
	{
		for (my $i=0;$i<=$mycsr->{varcnt};$i++)
		{
			${${$mycsr->{refsclrv}}[$i]} = $myline[$i];
		}
	}
	return @myline;
}

sub fetchall
{
	my $mycsr = shift;

	my ($myline, @res, $nores);
	
	$lastdb = $mycsr->{dB};
	$nores = 1  unless (wantarray);
	my ($fetchcnt) = 0;
	while ((@myline) = $mycsr->{csr}->fetchrow_array())
	{
		#THIS FOR-LOOP IS CURRENTLY DEPRECIATED BECAUSE FETCH WILL NOT RETURN VALUES IF VARCNT > 0 (THEY'VE ALREADY BEEN FETCHED BY BIND)!
		for (my $i=0;$i<=$mycsr->{varcnt};$i++)
		{
			${${$mycsr->{refsclrv}}[$i]} = $myline[$i]  unless ($fetchcnt);
			push (@{${$mycsr->{reflistv}}[$i]}, $myline[$i]);
		}
		push (@res, [@myline])  unless ($nores);
		++$fetchcnt;
	}
	return @res  unless ($nores);
	return $fetchcnt;
}

sub closecsr
{
	my $mycsr = shift;

	return undef  unless ($mycsr->{csr});
	my $res = $mycsr->{csr}->finish();
	$mycsr->{csr} = undef;
	return $res;
}

package JDBIx;

sub opencsr
{
	my ($self, $sqlstr, $xeqflag) = @_;

	$lastdb = $self;

	$sqlstr =~ s/\:\d+/\?/go  unless ($xeqflag);
	my ($myres, $cleansql);
	my ($mycsr) = new JDBIx::csr();
	
	$cleansql = $sqlstr;
	if ($sqlstr =~ /^\s*select\s/io)
	{
		$mycsr->{select} = 1;
		if ($sqlstr =~ /\binto\b/io)
		{
			my (@varlistv) = ($sqlstr =~ /:\D\w*/go);
			foreach $i (@varlistv)
			{
				$i =~s/\:/$self->{calling_package}\:\:/;
				$i =~s/,//o;
				@{$i} = ();     #INITIALIZE TO CLEAR ANY OLD VALUES!
				${$i} = '';
				push (@{$mycsr->{reflistv}},\@{$i});
				push (@{$mycsr->{refsclrv}},\${$i});
			}
			$mycsr->{varcnt} = $#varlistv;
			$cleansql =~ s/\binto\b//io;
			$nores = 1  unless (wantarray);
			$cleansql =~ s/\:[^\s\,\:]+\,?//go;
		}
		else
		{
			$mycsr->{varcnt} = -1;
		}
	}
	else
	{
		$mycsr->{select} = 0;
	}
	if ($self->{noplaceholders} && !$xeqflag)
	{
		$cleansql =~ s/([\'\"])([^\1]*?)\1/
				my ($quote) = $1;
				my ($str) = $2;
				$str =~ s|\?|\x02\^2jSpR1tE\x02|go;   #PROTECT ?'S IN QUOTES.
				"$quote$str$quote"
		/egs;
		$cleansql =~ s/\?/\x02\^3jSpR1tE\x02/gso;    #PROTECT OTHER(BIND) ?'S
		$cleansql =~ s/\x02\^2jSpR1tE\x02/\?/gso;    #UNPROTECT ?'S IN QUOTES.
		$mycsr->{sql} = $cleansql;    #ADDED 20010228 FOR USE IN BIND.
		$mycsr->{cleansql} = $cleansql;    #ADDED 20020715 FOR USE IN BIND.
		$mycsr->{cleansql} =~ s/\x02\^3jSpR1tE\x02/\?/gso;
		$mycsr->{dB} = $self;    #ADDED 20010228 FOR USE IN BIND.
	}
	else
	{
		$mycsr->{cleansql} = $cleansql;    #ADDED 20020715 FOR USE IN BIND.
		$mycsr->{dB} = $self;    #ADDED 20010228 FOR USE IN BIND.
		$mycsr->{csr} = $self->{DBI}->prepare($cleansql);
		return undef  unless (defined($mycsr->{csr}));
	
		if ($xeqflag && $mycsr->{csr})
		{
			$myres = $mycsr->{csr}->execute();
			if ($self->{logfid} || $logfid)
			{
				$cleansql =~ s/\s+$//o;
				$cleansql =~ s/^\s+//o;
				$cleansql .= ';'  if ($self->{addsemicolon});
				$cleansql =~ s/\&/\'\|\|\'\&\'\|\|\'/go  if ($self->{addsemicolon} == 1);
				if ($self->{logfid})
				{
					my $logfh = $self->{logfh};   #NEEDED FOR PERL TO COMPILE.
					flock $logfh, 2;    #EXCLUSIVE LOCK.
					print $logfh "$cleansql\n";
					flock $logfh, 8;    #UNLOCK.
				}
				if ($logfid)
				{
					flock $logfh, 2;    #EXCLUSIVE LOCK.
					print $logfh "$cleansql\n";
					flock $logfh, 8;    #UNLOCK.
				}
			}
		}
		$cleansql =~ s/\?/\x02\^3jSpR1tE\x02/gso;    #PROTECT OTHER(BIND) ?'S
		$mycsr->{sql} = $cleansql;    #ADDED 20010228 FOR USE IN BIND.
	}
	return wantarray ? ($mycsr, $myres) : $mycsr;
}

sub do1
{
	my ($self, $sqlstr, @bindvals) = @_;
	my ($res, $t);

	local ($_);
	$lastdb = $self;
	$sqlstr =~ s/\:\d+/\?/go  if ($#bindvals >= 0);  #CONVERT LEGACY PLACEHOLDERS, IE. :1, :2, ETC.

	if ($self->{dbtype} =~ /^odbc/io && $sqlstr =~ /insert.*\w+\.NEXTVAL/so)
	{
		$sqlstr = &_fixNEXTVAL($self, $sqlstr);
	}
	else
	{
		$sqlstr =~ s/([\,\(]\s*)\w+\.NEXTVAL(\s*[\,\)])/$1NULL$2/g 
				if ($self->{dbtype} =~ /^mysql/o);  #MYSQL DOES SEQUENCES DIFFERENTLY (see AUTO_INCREMENT)!
	}
	#ADDED 20030904 TO MAKE SEQUENCE-RETRIEVAL DATABASE-INDEPENDENT.
	if ($sqlstr =~ /insert\s+into\s+(\w+).*?(\w+)\.NEXTVAL/sio)
	{
		$self->{lastsequencetable} = $1;
		$self->{lastsequencename} = $2;
	}
	if ($self->{noplaceholders})
	{
		$sqlstr =~ s/([\'\"])([^\1]*?)\1/
				my ($quote) = $1;
				my ($str) = $2;
				$str =~ s|\?|\x02\^2jSpR1tE\x02|go;   #PROTECT ?'S IN QUOTES.
				"$quote$str$quote"
		/egs;
		while (@bindvals)
		{
			$t = shift(@bindvals);
			$t =~ s/\'/\'\'/so;
			$t =~ s/\?/\x02\^2jSpR1tE\x02/gso;
			$t =~ s/\?/\x02\^2jSpR1tE\x02/gso;
			$sqlstr =~ s/\?/\'$t\'/s;
		}
		$sqlstr =~ s/\x02\^2jSpR1tE\x02/\?/gso;       #UNPROTECT ?'S.
	}
	my ($mycsr) = $self->{DBI}->prepare($sqlstr);
	if ($mycsr)
	{
		#if ($sqlstr =~ /^\s+select/i)   #CHGD TO NEXT 20011121!
		if ($sqlstr =~ /^\s*select/io)
		{
			$res = $mycsr->execute(@bindvals);    #bindvals ADDED HERE 20000217.
			return undef  unless(defined($res));
			$res = $mycsr->rows  if ($res && $mycsr->rows);
			if ($res > 0 || $res eq '0E0')
			{
				@myline = $mycsr->fetchrow_array();
				$mycsr->finish();
				return wantarray ? ($res, @myline) : $res;
			}
		}
		else
		{
			$res = $mycsr->execute(@bindvals);
			return undef  unless(defined($res));
			if ($self->{logfid} || $logfid)
			{
				$sqlstr =~ s/\s+$//o;
				$sqlstr =~ s/^\s+//o;
				if ($#bindvals >= 0)
				{
					$sqlstr =~ s/([\'\"])([^\1]*?)\1/
							my ($quote) = $1;
							my ($str) = $2;
							$str =~ s|\?|\x02\^2jSpR1tE\x02|go;   #PROTECT ?'S IN QUOTES.
							"$quote$str$quote"
					/egs;

					for (my $i=0;$i<=$#bindvals;$i++)
					{
						$t = $bindvals[$i];
						$t =~ s/\'/\'\'/go;
						$t =~ s/\?/\x02\^2jSpR1tE\x02/gso;
						$sqlstr =~ s/\?/\'$t\'/;
					}
					$sqlstr =~ s/\x02\^2jSpR1tE\x02/\?/gso;       #UNPROTECT ?'S.
				}
				$sqlstr .= ';'  if ($self->{addsemicolon});
				$sqlstr =~ s/\&/\'\|\|\'\&\'\|\|\'/go  if ($self->{addsemicolon} == 1);
				if ($self->{logfid})
				{
					my $logfh = $self->{logfh};   #NEEDED FOR PERL TO COMPILE.
					flock $logfh, 2;    #EXCLUSIVE LOCK.
					print $logfh "$sqlstr\n";
					flock $logfh, 8;    #UNLOCK.
				}
				if ($logfid)
				{
					flock $logfh, 2;    #EXCLUSIVE LOCK.
					print $logfh "$sqlstr\n";
					flock $logfh, 8;    #UNLOCK.
				}
			}
			if ($res > 0 || $res eq '0E0')
			{
				$res = $mycsr->rows  if ($mycsr->rows);
				$mycsr->finish();
				return wantarray ? ($res) : $res;
			}
		}
		$mycsr->finish();
	}
	return undef;
}

sub fetchseq   #ADDED 20030904 TO MAKE SEQUENCE-RETRIEVAL DATABASE-INDEPENDENT.
{
	my $self = shift;
	my $seqfield = shift;
	my $seqname = shift || $self->{lastsequencename};
	my $tablename = shift || $self->{lastsequencetable};

	#ADD CODE FOR YOUR FAVORITE DATABASE HERE, OR TAKE THE DEFAULT (LAST OPTION)!

	return $self->{DBI}->{sprite_insertid}
			if ($self->{dbtype} eq 'Sprite' && defined($self->{DBI}->{sprite_insertid}) 
				&& $self->{DBI}->{sprite_insertid} =~ /\d/o);
	if ($self->{dbtype} =~ /^(?:Oracle|Sprite)/o)
	{
		my $mycsr;
		if ($mycsr = $self->{DBI}->prepare("select $seqname.CURRVAL from DUAL"))
		{
			my $myexe;
			if ($myexe = $mycsr->execute())
			{
				($lastseq) = $mycsr->fetchrow_array();
				$mycsr->finish();
				return $lastseq  if ($lastseq =~ /\d/o);
			}
		}
	}
	elsif ($self->{dbtype} =~ /^mysql/o)
	{
		return $self->{DBI}->{mysql_insert_id}  if (defined $self->{DBI}->{mysql_insert_id} && $self->{DBI}->{mysql_insert_id} =~ /\d/);
	}
	elsif ($self->{dbtype} =~ /^SQLite/o)
	{
		return $self->{DBI}->sqlite_last_insert_rowid();
	}
	if ($seqfield)    #IF ALL ELSE FAILS, FETCH A DESCENDING LIST OF VALUES FOR THE FIELD THE SEQUENCE WAS INSERTED INTO (USER MUST SPECIFY THE FIELD!)
	{
		my $sql = <<END_SQL;
			select $seqfield
			from $tablename
			order by $seqfield desc
END_SQL
		if ($mycsr = $self->{DBI}->prepare($sql))
		{
			my $myexe;
			if ($myexe = $mycsr->execute())
			{
				($lastseq) = $mycsr->fetchrow_array();
				$mycsr->finish();
				return $lastseq;
			}
		}
		return undef;
	}
	return undef;
}

sub fetchnextseq
{
	my $self = shift;
	my $seqname = shift || '.dbixseq';

	#ADD CODE FOR YOUR FAVORITE DATABASE HERE, OR TAKE THE DEFAULT (LAST OPTION)!

	if ($self->{dbtype} =~ /^(?:Oracle|Sprite)/o)
	{
		my $mycsr;
		if ($mycsr = $self->{DBI}->prepare("select $seqname.NEXTVAL from DUAL"))
		{
			my $myexe;
			if ($myexe = $mycsr->execute())
			{
				($lastseq) = $mycsr->fetchrow_array();
				$mycsr->finish();
				return $lastseq  if ($lastseq =~ /\d/o);
			}
		}
	}
	elsif ($self->{dbtype} =~ /^mysql/o)
	{
		return $self->{DBI}->{mysql_insert_id}  if (defined $self->{DBI}->{mysql_insert_id} && $self->{DBI}->{mysql_insert_id} =~ /\d/);
	}
	elsif ($self->{dbtype} =~ /^SQLite/o)
	{
		return $self->{DBI}->sqlite_last_insert_rowid();
	}

	#IF ALL ELSE FAILS, USE OUR OWN SPECIAL SEQUENCE FILE!

	my $seq_file = $ENV{HOME};
	$seq_file .= '/'  unless ($seq_file =~ m#\/$#o);
	$seq_file = ''  if ($seq_file eq '/');
	$seq_file .= $seqname;
	if (open(T, "<$seq_file"))
	{
		my $x = <T>;
		chomp($x);
		my ($seqval, $seqincby) = split(/\,/o, $x);
		close (T);
	}
	else
	{
		$seqval = 0;
		$seqincby = 1;
	}
	if (open (T, ">$seq_file"))
	{
		$seqval += ($seqincby || 1);
		print T "$seqval,$seqincby\n";
		close (T);
		return $seqval;
	}
	else
	{
		$lasterr = "$@/$? (file:$seq_file)";
	}
	return undef;
}

sub _fixNEXTVAL
{
	my ($self, $sqlstr) = @_;

	if ($sqlstr =~ /^\s*insert\s+into\s+        # Keyword
             (\S+)\s*                           # Table
             (?:\((.+?)\)\s*)?                  # Keys
             values\s*                          # 'values'
             \((.+)\)\s*$/isxo)
	{
		my ($table, $columns, $values) = ($1, $2, $3);
		my ($origvalues) = $values;
		
		$columns =~ s/\s//go;
		unless ($columns =~ /\S/o)
		{
			my $csr = $self->{DBI}->prepare("select * from $table");
			$csr->execute();
			$columns = join(',', @{$csr->{NAME}});
			$csr->finish();
		}
		my (@columns) = split(/,/o, $columns);
		$columns = '';
		$values =~ s/\\\\/\x02/go;         #PROTECT "\\"
		$values =~ s/\\\'/\x03/go;    #PROTECT "", \", '', AND \'.
		
		$values =~ s/\'(.*?)\'/
				my ($j)=$1; 
				$j =~ s|,|\x04|go;         #PROTECT "," IN QUOTES.
				"'$j'"
		/eg;
			
		@values = split(/,/,$values);
		for $i (0..$#values)
		{
			$values[$i] =~ s/^\s+//o;      #STRIP LEADING & TRAILING SPACES.
			$values[$i] =~ s/\s+$//o;
			$values[$i] =~ s/\x03/\'\'/go;   #RESTORE PROTECTED SINGLE QUOTES HERE.
			$values[$i] =~ s/\x02/\\/go;   #RESTORE PROTECTED SINGLE QUOTES HERE.
			$values[$i] =~ s/\x04/,/go;    #RESTORE PROTECTED SINGLE QUOTES HERE.
			if ($values[$i] =~ /\s*(\w+).NEXTVAL\s*$/o)
			{
				my ($t) = $1;
				$origvalues =~ s/\s*$t\.NEXTVAL\s*\,?\s*//;
			}
			else
			{
				$columns .= $columns[$i] . ',';
			}
		};
		chop ($columns);
		
		$sqlstr = "insert into $table ($columns) values ($origvalues) ";
	}
	return ($sqlstr);
}

1

__END__
