package IMDB::Local::DB::Base;

use 5.006;
use strict;
use warnings;
use Carp;

=head1 NAME

IMDB::Local::DB::Base - Object to manage database abstraction with handy entry points.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '1.00';


=head1 SYNOPSIS

This module presents one set of handy subroutines around a DBI connection. The interface is not well document, only as much as it is needed for the IMDB::Local::DB developer requires. It is meant to be extended.


=head1 SUBROUTINES/METHODS

=head2 new

=cut

use DBI;
use Time::HiRes;
use IMDB::Local::DB::RecordIterator;

use Class::MethodMaker
    [ 
      scalar => ['dbh', 'modCount'],
      scalar => ['driver'],
      scalar => [{-default => ''}, 'driverDetail'],
      scalar => ['server'],
      scalar => ['database'],
      scalar => ['user'],
      scalar => ['passwd'],
      scalar => [{-default => 1}, 'db_AutoCommit'],
      scalar => [{-default => 0}, 'db_RaiseError'],
      scalar => [{-default => 102400}, 'maxReadLen'],
      hash => ['connectAttrs'],
      array => ['tables'],
      hash => ['table_infos'],
      scalar => ['mutexName', 'mutex'],
      scalar => [{-default => sub { my ($self, $attempts, $gotit)=@_;
				    if ( !$gotit ) { 

					if ( $attempts % 100 == 0 ) {
					    warn("waiting on db lock.. ($attempts attempts)"); 
					    Time::HiRes::usleep(5*1000*1000);
					}
					elsif ( $attempts % 10 == 0 ) {
					    warn("waiting on db lock.. ($attempts attempts)"); 
					    Time::HiRes::usleep(1*1000*1000);
					}
					else {
					    Time::HiRes::usleep(100*1000);
					}
				    } 
				    return(0);
				}}, 'mutexWaitCallback'],
      new  => [qw/ -hash new /] ,
    ];


sub DESTROY($)
{
    my ($self)=@_;

    if ( $self->isConnected() ) {
	$self->disconnect();
    }
}

=head2 connect

=cut

sub connect($)
{
    my ($self)=@_;

    $self->disconnect();
    return $self if ( !defined($self->driver()) );

    my $dsn='dbi:'.$self->driver;

    if ( defined($self->driverDetail()) ) {
	$dsn.=":".$self->driverDetail();
    }
    if ( defined($self->server()) && length($self->server()) ) {
	if ( $self->driver eq 'ODBC' ) {
	    $dsn.=";Server=".$self->server();
	}
	elsif ( $self->driver eq 'SQLite' ) {
	    # remote server not supported
	}
	elsif ( $self->driver eq 'mysql' ) {
	    $dsn.=":host=".$self->server();
	}
    }
    if ( defined($self->database())  && length($self->database()) ) {
	if ( $self->driver eq 'ODBC' ) {
	    $dsn.=";Database=".$self->database();
	}
	elsif ( $self->driver eq 'SQLite' ) {
	    $dsn.=":dbname=".$self->database();
	}
	else {
	    $dsn.=":database=".$self->database();
	}
    }

    if ( defined($self->mutexName) && length($self->mutexName) ) {
	if ( $^O eq 'MSWin32' ) {
	    require Win32::Mutex;

	    my $attempts=0;
	    while ( 1 ) {
		my $name="Global\\".$self->mutexName;
		if ( defined($self->database())  && length($self->database()) ) {
		    $name="Global\\".$self->database()."-".$self->mutexName();
		}
		my $mutex=Win32::Mutex->new(1, $name);
		if ( $mutex ) {
		    if ( $^E == 183 ) {
			undef($mutex);
			my $sub=$self->mutexWaitCallback();
			my $stop=&$sub($self, ++$attempts, 0);
			if ( $stop ) {
			    return(undef);
			}
		    }
		    else {
			$self->mutex($mutex);
			if ( $attempts != 0 ) {
			    my $sub=$self->mutexWaitCallback();
			    &$sub($self, $attempts, 1);
			}
			last;
		    }
		}
	    }
	    #warn("mutex is MINE");
	}
	elsif ( $^O eq 'linux' ) {
	    use Fcntl ':flock';
	    my $attempts=0;
	    while ( 1 ) {
		my $name="/tmp/.".$self->mutexName();
		if ( defined($self->database())  && length($self->database()) ) {
		    $name=$self->database()."-".$self->mutexName().".lck";
		}

		my $fd;

		if ( !open($fd, "> $name") ) {
		    warn("$name:$!");

		    # die "Can't open $name for locking!\nError: $!\n";
		    my $sub=$self->mutexWaitCallback();
		    my $stop=&$sub($self, ++$attempts, 0);
		    if ( $stop ) {
			return(undef);
		    }
		}
		elsif ( !flock($fd, LOCK_EX|LOCK_NB) ) {
		    #warn("$name:$!");
		    my $sub=$self->mutexWaitCallback();
		    my $stop=&$sub($self, ++$attempts, 0);
		    close($fd);
		    if ( $stop ) {
			return(undef);
		    }
		    # spin and retry
		}
		else {
		    $self->mutex($fd);
		    if ( $attempts != 0 ) {
			my $sub=$self->mutexWaitCallback();
			&$sub($self, $attempts, 1);
		    }
		    last;
		}
	    }
	}
    }

    #warn("DB: $dsn\n");
    my %attrs=(RaiseError=>$self->db_RaiseError,
	       AutoCommit=>$self->db_AutoCommit);

    for my $k ($self->connectAttrs_keys()) {
	$attrs{$k}=$self->connectAttrs_index($k);
    }
    
    my $dbh=DBI->connect($dsn, $self->user, $self->passwd, \%attrs);
			  
    if ( !$dbh ) {
        print STDERR "connection failed:$DBI::errstr\n";
	if ( defined($self->mutex) ) {
	    if ( $^O eq 'MSWin32' ) {
		$self->mutex()->release();
	    }
	    elsif ( $^O eq 'linux' ) {
		close $self->mutex();
	    }
	}
	$self->mutex(undef);
	return(undef);
    }

    #print STDERR "autocommit: ".$dbh->{AutoCommit}."\n";

    # default for ODC is 80 bytes for LongReadLen, which causes
    # ODBC SQL Server Driver String data, right truncation (SQL-01004)
    # failures for things with lasrge enough strings
    #
    # note: setting arbitrarily high # causes memory allocation problems.
    $dbh->{LongReadLen}   = $self->maxReadLen();
    $dbh->{LongTruncOk}   = 0;

    if ($dbh->err()) {
        warn($dbh->errstr()."\n");
	$dbh->disconnect();
	if ( $^O eq 'MSWin32' ) {
	    $self->mutex()->release();
	}
	elsif ( $^O eq 'linux' ) {
	    close $self->mutex();
	}
	$self->mutex(undef);
	return(undef);
    }
    $self->dbh($dbh);

    if ( $self->driver eq 'SQLite' ) {
	#$self->runSQL("PRAGMA cache_size=200000");
    }
    $self->modCount(0);
    return($self);
}

=head2 disconnect

Disconnect from the database. Note that for those lazy programmers that fail to call disconnect, the disconnect will be called when the
object is destructed through perl's DESTROY.

=cut

sub disconnect()
{
    my ($self)=@_;

    if ( $self->dbh() ) {
	$self->dbh->disconnect();
	$self->dbh(undef);
    }

    if ( defined($self->mutex) ) {
	if ( $^O eq 'MSWin32' ) {
	    $self->mutex()->release();
	}
	elsif ( $^O eq 'linux' ) {
	    close $self->mutex();
	}
	#warn("mutex is NOT-MINE");
	$self->mutex(undef);
    }
    $self->tables_reset();
}

=head2 commit

Commit a DBI transaction (should only be used if db_AutoCommit was zero).

=cut

sub commit()
{
    my ($self)=@_;

    if ( ! defined($self->dbh) ) {
	carp("not connected");
    }
    $self->dbh->commit();
    $self->modCount(0);
}

=head2 isConnected

Check to see if there has been previous successful 'connect' call.

=cut

sub isConnected($)
{
    return(defined(shift->dbh));
}

=head2 quote

=cut

sub quote($)
{
    my ($self, @rest)=@_;

    if ( ! defined($self->dbh) ) {
	carp("not connected");
    }
    return($self->dbh->quote(@rest));
}

=head2 last_inserted_key

Retrieve the last inserted key for a given table and primaryKey.

=cut

sub last_inserted_key($$$)
{
    my ($self, $table, $primaryKey)=@_;

    if ( ! defined($self->dbh) ) {
	carp("not connected");
    }

    if ( $self->driver eq 'ODBC' ) {
	return $self->select2Scalar("select \@\@identity");
    }
    return $self->dbh->last_insert_id($self->database, undef, $table, $primaryKey);
}

=head2 runSQL

Execute a sql statement and return 1 upon success and 0 upon success. Upon failure, carp() is called with the sql statement.

=cut

sub runSQL($)
{
    my ($self, $stmt)=@_;

    if ( ! defined($self->dbh) ) {
	carp("not connected");
    }

    my $dbh=$self->dbh();

    #warn("$stmt");
    $dbh->do($stmt);
    if ( $dbh->err() ) {
	carp($stmt);
	return(0);
    }
    return(1);
}

=head2 runSQL_err

Return DBI->err() to retrieve error status of previous call to runSQL.

=cut

sub runSQL_err($)
{
    my ($self)=@_;

    if ( ! defined($self->dbh) ) {
	carp("not connected");
    }

    return $self->dbh()->err();
}

=head2 runSQL_srrstr

Return DBI->errstr() to retrieve error status of previous call to runSQL.

=cut

sub runSQL_errstr($)
{
    my ($self)=@_;

    if ( ! defined($self->dbh) ) {
	carp("not connected");
    }

    return $self->dbh()->errstr();
}

=head2 prepare

Return DBI->prepare() for a given statement.

=cut

sub prepare($$)
{
    my ($self, $query)=@_;

    if ( !defined($self->dbh) ) {
	carp("not connected");
    }
    #warn("STMT:$query");
    return $self->dbh->prepare($query);
}

=head2 execute

Wrapper for calling DBI->prepare() and DBI->exeute() fora given query. Upon success the DBI->prepare() handle is returned.
Upon failure, warn() is called with the query statement string and undef is returned.

=cut

sub execute($)
{
    my ($self, $query)=@_;

    if ( !defined($self->dbh) ) {
	carp("not connected");
    }

    #warn("STMT:$query");
    my $sth = $self->prepare($query);
    if ( !$sth ) {
	warn("STMT INVALID:$query");
	return(undef);
    }
    if ( !$sth->execute() ) {
	warn("FAILED STMT:$query");
	return(undef);
    }
    return($sth);
}

=head2 insert_row

Execute a table insertion and return the created primaryKey (if specified).
If primaryKey is not defined, 1 is returned upon success.

=cut

sub insert_row($$$%)
{
    my ($self, $table, $primaryKey, %args) = @_;

    my $dbh=$self->dbh();
    if ( !defined($dbh) ) {
	carp("not connected");
    }

    my ($k,$v)=('','');
    my @values;

    for my $key (sort keys %args) {
	if ( defined($args{$key}) ) {
	    $k.=$key.",";
	    #$k.=$self->dbh->quote($key).",";
	    push(@values, $args{$key});
	    #$v.=$self->dbh->quote($args{$key}).",";
	    $v.="?,";
	}
    }

    if ( !($k=~s/,$//) || !($v=~s/,$//) ) {
	warn "attempt to insert nothing into table $table";
	return(undef);
    }

    my $stmt="INSERT INTO $table ($k) VALUES ($v)";
    #print STDERR "STMT:$stmt\n";
    #print STDERR "VALUES:(".join(',', map($self->dbh->quote($_), @values)).")\n";
    
    my $sth=$dbh->prepare($stmt);
    $sth->execute(@values);

    if ($dbh->err()) {
	print STDERR "Error inserting into table: $table: ", $dbh->errstr()."\n";
	print STDERR "STMT:$stmt\n";
	#print STDERR "VALUES:$stmt\n";
	return undef;
    }
    $self->modCount($self->modCount()+1);

    # return primary key if its specified
    if ( !defined($primaryKey) ) {
	return(1);
    }
    return $self->last_inserted_key($table, $primaryKey);
}

sub _quoteField($$)
{
    my ($self, $word)=@_;

    if ( $self->driver eq 'ODBC' ) {
	# check for keywords used in column names we need to quote
	if ( $word eq 'File' ) {
	    return('['.$word.']');
	}

	# catch table.column in select
	if ( $word=~m/^([^\.]+)\.(File)$/o ) {
	    return($1.'['.$2.']');
	}
    }

    # no quote needed
    return($word);
}

=head2 query2SQLStatement

Construct an sql query using a hash containing:

  fields - required array of fields to select
  tables - required array of tables to select from
  wheres - optional array of where clauses to include (all and'd together)
  groupbys - optional array of group by clauses to include
  sortByField - optional field to sort by (if prefixed with -, then sort is reversed)
  orderbys - optional array of order by clauses to include
  offset - offset of returned rows
  limit - optional integer value to limit # of returned rows

=cut

sub query2SQLStatement($%)
{
    my ($self, %args)=@_;
	
    #print Dumper(\%args);
    my @columnHeaders=$args{fields};
    
    my $st="SELECT ";
    if ( $args{limit} && $self->driver eq 'ODBC' ) {
	# mssql
	$st.="TOP $args{limit} ";
    }
    my $cnt=0;
    for (@{$args{fields}}) {
	$st.=$self->_quoteField($_).",";
	$cnt++;
    }
    $st=~s/,$// || die "no fields in select";

    $st.=" FROM ";
    for (@{$args{tables}}) {
	$st.=$_.",";
    }
    $st=~s/,$// || die "no tables specified";

    if ( $args{wheres} ) {
	my $w=" WHERE ";
	for (@{$args{wheres}}) {
	    $w.="$_ AND ";
	}
	$st.=$w if ( $w=~s/ AND $// );
    }

    if ( $args{groupbys} ) {
	my $w=" GROUP BY ";
	for (@{$args{groupbys}}) {
	    $w.=$self->_quoteField($_).",";
	}
	$st.=$w if ( $w=~s/,$// );
    }

    my $sortedField='';
    my $sortedDescending=0;
    if ( defined($args{sortByField}) && length($args{sortByField})) {
	$sortedField=$args{sortByField};
	if ( $sortedField=~s/^\-// ) {
	    $st.=" ORDER BY ".$self->_quoteField($sortedField)." DESC";
	    $sortedDescending=1;
	}
	else {
	    $st.=" ORDER BY ".$self->_quoteField($sortedField)." ASC";
	    $sortedDescending=0;
	}
    }
    elsif ( defined($args{orderbys}) && @{$args{orderbys}} ) {
	$st.=" ORDER BY ";
	for (@{$args{orderbys}}) {
	    $st.=$self->_quoteField($_).",";
	}
	$st=~s/,$// || die "no orderbys specified";
    }

    if ( $args{limit} ) {
	if ( $self->driver eq 'ODBC' ) {
	    # covered at top of this sub
	}
	elsif ( $self->driver eq 'mysql' ) {
	    $st.=" LIMIT ".$args{limit};
	}
	elsif ( $self->driver eq 'SQLite' ) {
	    $st.=" LIMIT ".$args{limit};
	}

	if ( $args{offset} ) {
	    if ( $args{offset} < 0 ) {
		$args{offset}=0;
	    }
	    $st.=" OFFSET ".$args{offset};
	}
	else {
	    $args{offset}=0;
	}
    }
    return($st);
}

=head2 findRecords

Call query2SQLStatement with the given hash arguments and return a IMDB::Local::DB::RecordIterator handle.

In addition to the query2SQLStatement arguments the following are optional:
  cacheBy - set cacheBy value in returned IMDB::Local::DB::RecordIterator handle. If not specified, limit is used.

=cut

sub findRecords($%)
{
    my ($self, %args)=@_;

    my $cacheBy=1000;
    if ( $args{cacheBy} ) {
	$cacheBy=delete($args{cacheBy});
    }
    if ( $args{limit} && $cacheBy > $args{limit} ) {
	$cacheBy=$args{limit};
    }
    my $st=$self->query2SQLStatement(%args);

    #print STDERR "running '$st'\n";
    my $sth=$self->execute($st);
    if ( !defined($sth) ) {
	warn("sql '$st' failed:".$self->dbh->errstr()."\n");
	return(undef);
    }

    if ($self->dbh->err()) {
	print STDERR "Query error: ", $self->dbh->errstr()."\n";
	print STDERR "STMT:$st\n";
	#print STDERR "VALUES:$stmt\n";
	return undef;
    }

    my $int=new IMDB::Local::DB::RecordIterator($sth);
    $int->{cacheBy}=$cacheBy;
    return($int);
}

=head2 rowExists

Check to see at least one row exists with value in 'column' in the specified 'table'

=cut

sub rowExists($$$)
{
    my ($self, $table, $column, $value)=@_;
    my $sql;
    if ( $self->driver eq 'ODBC' ) {
	$sql="SELECT TOP 1 $column from $table where $column='$value'";
    }
    elsif ( $self->driver eq 'mysql' ) {
	$sql="SELECT $column from $table where $column='$value' LIMIT 1";
    }
    elsif ( $self->driver eq 'SQLite' ) {
	$sql="SELECT $column from $table where $column='$value' LIMIT 1";
    }

    my $v=$self->select2Scalar($sql);
    return(defined($v) && $v eq $value);
}

=head2 select2Scalar

Execute the given sql statement and return the value in a single scalar value

=cut

sub select2Scalar($$)
{
    my ($self, $sql)=@_;

    my $sth=$self->execute($sql);
    if ( !$sth ) {
	return(undef);
    }
    my @arr=$sth->fetchrow_array;
    return $arr[0];
}

=head2 select2Int

Execute the given sql statement and return the value cast as an integer (ie int(returnvalue))

=cut

sub select2Int($$)
{
    my ($self, $sql)=@_;

    my $r=$self->select2Scalar($sql);
    if ( defined($r) ) {
	$r=int($r);
    }
    return $r;
}

=head2 select2Array

Execute the given sql statement and return an array with all the results.

=cut

sub select2Array($$)
{
    my ($self, $sql)=@_;

    my $sth=$self->execute($sql);
    if ( !$sth ) {
	return(undef);
    }
    my @arr;
    my $all=$sth->fetchall_arrayref();
    for my $refer (@$all) {
	push(@arr, @$refer);
    }
    return \@arr;
}

=head2 select2Matrix

Execute the given sql statement and return an array of arrays, each containing a row of values

=cut

sub select2Matrix($$)
{
    my ($self, $sql)=@_;

    my $sth=$self->execute($sql);
    if ( !$sth ) {
	return(undef);
    }
    my $int=new IMDB::Local::DB::RecordIterator($sth);
    my @arr;
    while (my $refer=$int->nextRow()) {
	push(@arr, $refer);
    }
    return(\@arr);
}

=head2 select2HashRef

Execute the given sql statement and return a reference to a hash with the result

=cut

sub select2HashRef($$)
{
    my ($self, $sql)=@_;

    my $sth=$self->execute($sql);
    if ( !$sth ) {
	return(undef);
    }
    return($sth->fetchrow_hashref());
}

=head2 select2Hash

Execute the given sql statement and return a reference ot a hash containing the given row.

=cut

sub select2Hash($$)
{
    my ($self, $sql)=@_;

    my $sth=$self->execute($sql);
    if ( !$sth ) {
	return(undef);
    }
    my $int=new IMDB::Local::DB::RecordIterator($sth);
    my %arr;
    while (my $refer=$int->nextRow()) {
	my $key=$refer->[0];
	my @r=splice(@$refer, 1);
	if ( scalar(@r) == 1 ) {
	    $arr{$key}=$r[0];
	}
	else {
	    $arr{$key}=\@r;
	}
    }
    return(\%arr);
}

sub _NOT_USED_database_list($)
{
    my $self=shift;

    if ( $self->driver eq 'ODBC' ) {
	my @list;
	for my $t (@{$self->select2Array("select Name from master..sysdatabases")} ) {
	    push(@list, $t);
	}
	return(@list);
    }
    elsif ( $self->driver eq 'SQLite' ) {
	warn "database_list of sqlite db: unsupported";
	return(undef);
    }
    else {
	# mysql
	my @list;
	for my $t (@{$self->select2Array("show databases")} ) {
	    push(@list, $t);
	}
	return(@list);
    }
}

=head2 table_list

Retrieve a list of tables available. Created Tables or Views created after connect() may not be included.

=cut

sub table_list($)
{
    my $self=shift;

    # already got an answer ?
    if ( $self->tables_index(0) ) {
	return($self->tables);
    }

    if ( $self->driver eq 'ODBC' ) {
        my $sth=$self->dbh()->table_info($self->database, '', '', 'TABLE');
	if ( !defined($sth) ) {
	    warn("lookup of table_info failed:".$self->dbh->errstr()."\n");
	    return($self->tables);
	}
	my $int=new IMDB::Local::DB::RecordIterator($sth);
	while (my $refer=$int->nextRow()) {
	    my ($table_cat, $table_schem, $table_name, $table_type, $remarks)=@$refer;
	    $self->tables_push($table_name);
	}
	#warn "tables:".join(',', $self->tables)."\n";
	return($self->tables);
    }
    elsif ( $self->driver eq 'SQLite' ) {
	#$sth=$self->dbh()->table_info('%', '%', '%', 'TABLE');
	for my $t (@{$self->select2Array("select Name from sqlite_master where type='table'")} ) {
	    $self->tables_push($t);
	}
	return($self->tables);
    }
    else {
	# mysql
	for my $t (@{$self->select2Array("show tables")} ) {
	    $self->tables_push($t);
	}
	return($self->tables);
    }
   
}

=head2 table_exists

Check to see if a given table exists. Uses table_list.

=cut

sub table_exists($$)
{
    my ($dbh, $table)=@_;

    if ( !grep(/^$table$/, $dbh->table_list()) ) {
	return(0);
    }
    return(1);
}

=head2 table_exists

Check to see if a given table exists. Uses table_list.

=cut

sub table_clear($$)
{
    my ($db, $table)=@_;

    if ( !$db->isConnected() ) {
	carp("not connected");
    }
    if ( $db->table_exists($table) ) {
	if ( $db->runSQL("DELETE from $table") ) {
	    if ( $db->driver eq 'SQLite' &&
		 # reset state related to table (ie automatic id counters)
		 $db->runSQL("DELETE from sqlite_sequence where name='$table'") ) {
	    }
	    $db->commit();
	    return(1);
	}
    }
    return(0);
}

=head2 column_info

Retrieve information about a given column in a table. Changes to columns made after connect() may not be included.

Returns a list of columns in a database/driver specific order containing:
 COLUMN_NAME - name of the column
 TYPE_NAME - data type (if available)
 COLUMN_SIZE - size of column data (if available)
 IS_NULL - true/false if column is nullable
 IS_PRIMARY_KEY - 1 or 0 if column is a primary key

=cut

sub column_info($$)
{
    my ($self, $table)=@_;

    if ( $self->table_infos_exists($table) ) {
	return $self->table_infos_index($table);
    }

    my @key_column_names;
    if ( $self->driver eq 'ODBC' ) {
	@key_column_names = $self->dbh()->primary_key($self->database, '', $table);
    }
    elsif ( $self->driver eq 'SQLite' ) {
	# untested
	@key_column_names = $self->dbh()->primary_key(undef, undef, $table);
    }
    elsif ( $self->driver eq 'mysql' ) {
	my @list;
	my $res=$self->select2Matrix("describe $table");
	if ( $res ) {
	    for my $h (@$res) {
		my ($field, $type,$null, $key,$default,$extra)=@$h;
		$default='' if (!defined($default));
		my $t;
		$t->{COLUMN_NAME}=$field;
		$t->{TYPE_NAME}=$type;
		$t->{COLUMN_SIZE}=0;
		if ( $t->{TYPE_NAME}=~s/\((\d+)\)$// ) {
		    $t->{COLUMN_SIZE}=$1;
		}
		$t->{IS_NULLABLE}=uc($null);
		$t->{IS_PRIMARY_KEY}=(uc($key) eq 'PRI')?1:0;
		push(@list, $t);
	    }
	}
	if ( !@list ) {
	    warn("no table information for table '$table'");
	    return(undef);
	}
	@list=sort {$a->{COLUMN_NAME} cmp $b->{COLUMN_NAME}} @list;
	$self->table_infos($table, \@list);
	return $self->table_infos_index($table);
    }
    else {
	die "unsupported";
    }
    
    my $sth;
    if ( $self->driver eq 'ODBC' ) {
	$sth=$self->dbh()->column_info($self->database, '', $table, '%');
    }
    elsif ( $self->driver eq 'SQLite' ) {
	# untested
	$sth=$self->dbh()->column_info(undef, '%', $table, '%');
    }
    else {
	$sth=$self->dbh()->column_info(undef, '%', $table, '%');
    }
    if ( !defined($sth) ) {
	warn("no table information for table '$table'");
	return(undef);
    }
    
    my @list;
    while (my $hash=$sth->fetchrow_hashref()) {
	if ( @key_column_names ) {
	    my $col=$hash->{COLUMN_NAME};
	    if ( grep/^$col$/, @key_column_names ) {
		$hash->{IS_PRIMARY_KEY}=1;
	    }
	    else {
		$hash->{IS_PRIMARY_KEY}=0;
	    }
	}
	push(@list, $hash);
    }

    if ( !@list ) {
	warn("no table information for table '$table'");
	return(undef);
    }

    $self->table_infos($table, \@list);
    return $self->table_infos_index($table);
}

=head2 column_list

Retrieve a list of column names in column_list order.

=cut

sub column_list($$)
{
    my ($self, $table)=@_;

    my @columns;
    for my $t (@{$self->column_info($table)}) {
	push(@columns, $t->{COLUMN_NAME});
    }
    return(@columns);
}

=head2 writeQuery2CSV

Run an sql query and output the result to the specified file in Text::CSV format

=cut

sub writeQuery2CSV($$$)
{
    my ($self, $file, $hash)=@_;
    require Text::CSV;

    my $csv=new Text::CSV({binary=>1, always_quote=>1});

    my $int=$self->findRecords(%$hash);
    if ($int) {
	if ( open(my $fd, "> $file") ) {
	    $csv->combine(@{$hash->{fields}});
	    print $fd $csv->string()."\n";
	    
	    while (my $refer=$int->nextRow()) {
		$csv->combine(@$refer);
		print $fd $csv->string()."\n";
	    }
	    close($fd);
	    return(1);
	}
    }
    return(0);
}

=head2 appendCSV2Table

Parse the given CVS file (which must have column names that match a the given table) and insert each row
as a new row into the specified table.

Upon success, returns > 0, number of rows successfully inserted.
Returns 0 if open() on the given file fails.

=cut

sub appendCSV2Table($$$)
{
    my ($self, $file, $table)=@_;
    require Text::CSV;

    my $csv=new Text::CSV({binary=>1, always_quote=>1});

    if ( open(my $fd, "<:encoding(utf8)", $file) ) {
	my $lineNum=1;
        my @titleRow=@{$csv->getline($fd)};
	my $rowsInserted=0;
	
        while ( my $row = $csv->getline($fd) ) {
	    $lineNum++;
	    if ( scalar(@titleRow) != scalar(@$row) ) {
		warn("$file: invalid row: $lineNum\n");
	    }
	    else {
		my %args;
		my $c=0;
		for my $t (@titleRow) {
		    $args{$t}=$row->[$c];
		    $c++;
		}
		if ( $self->insert_row($table, undef, %args) ) {
		    $rowsInserted++;
		}
	    }
        }
	
        $csv->eof or $csv->error_diag();
        close($fd);
	$self->commit();
	return($rowsInserted);
    }
    return(0);
}

=head2 table_row_count

Retrieve the # of rows in a given table.

=cut

sub table_row_count($$)
{
    my ($self, $table)=@_;

    if ( $self->driver eq 'mysql' ) {
	return $self->select2Int("select count(*) from $table");
    }
    elsif ( $self->driver eq 'SQLite' ) {
	return $self->select2Int("select count(1) from $table");
    }
    else {
	# mssql magic
	my $sql="sp_Msforeachtable 'sp_spaceused ''$table'''";
	my $sth=$self->execute($sql);
	if ( !defined($sth) ) {
	    carp("table_row_count: called with non-existing table $table");
	    return(0);
	}
	
	my $int=new IMDB::Local::DB::RecordIterator($sth);
	my @infos;
	while (my $r=$int->nextRow()) {
	    my ($table, $rows, $reserved_kb, $data_kb, $index_kb, $unused_kb)=@$r;
	    return (int($rows));
	}
	#return $self->select2Scalar("select count(1) from $table");
    }
}

=head2 table_report

Retrieve a reference to an array of arrays, each sub-array containing [table, #ofRows, data-size-in-KBs, index-size-in-KBs]

=cut

sub table_report($@)
{
    my ($self, @tables)=@_;

    if ( $self->driver eq 'mysql' ) {
	if ( !@tables ) {
	    @tables=$self->table_list();
	}
	my @infos;
	for my $table (@tables) {
	    my $rows=$self->select2Array("select count(*) from $table");
	    push(@infos, [$table, $rows->[0], 0, 0]);
	}
	return(\@infos);
    }
    elsif ( $self->driver eq 'SQLite' ) {
	if ( !@tables ) {
	    @tables=$self->table_list();
	}
	my @infos;
	for my $table (@tables) {
	    my $rows=$self->select2Array("select count(*) from $table");
	    push(@infos, [$table, $rows->[0], 0, 0]);
	}
	return(\@infos);
    }
    else {
	# fall-through
    }

    # mssql magic
    my $sql="sp_Msforeachtable 'sp_spaceused ''?'''";
    my $sth=$self->execute($sql);
    
    my $int=new IMDB::Local::DB::RecordIterator($sth);
    my @infos;
    while (my $r=$int->nextRow()) {
	my ($table, $rows, $reserved_kb, $data_kb, $index_kb, $unused_kb)=@$r;
	if ( !@tables || grep(/^$table$/, @tables) ) {

	    # knock off units
	    $data_kb=~s/\s*KB$//o;
	    $index_kb=~s/\s*KB$//o;
	    $unused_kb=~s/\s*KB$//o;

	    $rows=~s/^\s*//o;
	    $rows=~s/\s*$//o;
	    push(@infos, [$table, $rows, $data_kb, $index_kb]);
	}
    }
    return(\@infos);
}
    
=head1 AUTHOR

jerryv, C<< <jerry.veldhuis at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-imdb-local at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IMDB-Local>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IMDB::Local::DB::Base


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IMDB-Local>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IMDB-Local>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IMDB-Local>

=item * Search CPAN

L<http://search.cpan.org/dist/IMDB-Local/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 jerryv.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of IMDB::Local::DB::Base
