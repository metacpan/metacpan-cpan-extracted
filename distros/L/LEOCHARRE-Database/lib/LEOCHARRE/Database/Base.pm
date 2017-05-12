package LEOCHARRE::Database::Base;
use strict;
use LEOCHARRE::DEBUG;
use warnings;
use Carp;
use Exporter;


use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
@ISA = qw/Exporter/;

@EXPORT_OK = qw(
rows_count 
is_sqlite 
is_mysql 
drop_table 
lid 
close_active_handles
table_exists 
table_dump 
driver
selectcol
connect_sqlite
connect_mysql
);

%EXPORT_TAGS = ( all => \@EXPORT_OK );

$VERSION = sprintf "%d.%02d", q$Revision: 1.7 $ =~ /(\d+)/g;



sub DBI::db::rows_count  { return rows_count(@_); }
sub DBI::db::is_sqlite  { return is_sqlite(@_); }
sub DBI::db::is_mysql  { return is_mysql(@_); }
sub DBI::db::drop_table  { return drop_table(@_); }
sub DBI::db::lid  { return lid(@_); }
sub DBI::db::close_active_handles { return close_active_handles(@_); }
sub DBI::db::table_exists  { return table_exists(@_); }
sub DBI::db::table_dump  { return table_dump(@_); }
sub DBI::db::driver { return driver(@_); }

sub DBI::db::selectcol { return selectcol(@_); } 

sub DBI::connect_sqlite { return connect_sqlite(@_); }
sub DBI::connect_mysql { return connect_mysql(@_); }



# FUNCTIONAL ORIENTED

sub rows_count {
   my ($dbh,$statement,$key,$val) = @_;
   defined $statement or confess('missing statement argument');
   $statement=~s/^\s+|\s+$//g;

   
   # is first arg a table name?
   if ($statement=~/^(\w+)$/){
      my $tname = $1;
      debug("arg 1 is table name");

      $statement = "SELECT COUNT(*) FROM $tname";

      if (defined $key and defined $val){
         debug("key and val arguments are defined also [$key:$val]");

         $statement.=" WHERE $key='$val'"; 
         debug("stmnt: [$statement]\n");
      }    
   
   }

   # if not, we expect no more arguments 
   else {
      debug("arg 1 is statement");
      if (defined $key or defined $val){
         carp('first argument was a statement, no more arguments should be provided.');
      }
      
      $statement=~/count\s*\(/i or confess("statement to dbh_count() must contain COUNT()");

   }

   return _rows_count($dbh,$statement);
}

sub _rows_count {
   my ($dbh,$statement) = @_;
   defined $statement or confess('missing statement argument');
   my $c = $dbh->prepare($statement) or confess($dbh->errstr);
   $c->execute;
   my $r = $c->fetchrow_arrayref;
   my $count = $r->[0];
   $count ||= 0;
   return $count;
}

sub is_sqlite {
	my $dbh = shift;
   my $d = driver($dbh) or return 0;
	$d=~/sqlite/i or return 0;
	return 1;
}

sub is_mysql {
	my $dbh = shift;
   my $d = driver($dbh) or return 0;   
	$d=~/mysql/i or return 0;
	return 1;
}

sub driver {
   my $dbh = shift;
   defined $dbh or confess('missing dbh object as arg');
   defined $dbh->{Driver} or debug("attribute 'Driver' not present in dbh obj passed") and return;
   my $n = $dbh->{Driver}->{Name} or return;
	return $n;
}

sub drop_table {
   my ($dbh,$tablename)= @_;
   defined $dbh and defined $tablename or die('missing args');
   local $dbh->{PrintError};
   local $dbh->{RaiseError};
   $dbh->do("DROP TABLE IF EXISTS $tablename");
   return 1;   
}

sub lid {
   my($dbh,$tablename) = @_;
   defined $dbh and defined $tablename or die('missing args');
   
   my $id = $dbh->last_insert_id(undef,undef,$tablename,undef);
   
   defined $id 
      or warn("last insert id on table $tablename returns undef, does table exists?") 
      and return;
   return $id;
}

sub close_active_handles {
   my $dbh = shift;
   defined $dbh or die('missing arg'); 
   my $x = 1;
   
   debug("closing active handles:");

   if ( defined $dbh->{ChildHandles} ){
   
      HANDLE: for (@{$dbh->{ChildHandles}}){
         my $handle = $_;
         defined $handle or next HANDLE;
         $handle or next HANDLE;
         

         if ($handle->{Active}){
            $handle->finish;
            $x++;
         }   
         
         undef $handle; # was $_
      }   
      
   }   
   debug("$x, done.\n");
   
   return $x;
}

sub table_exists {
   my($dbh,$tablename) = @_;
   defined $dbh or confess('missing dbh');
   defined $tablename or confess('missing tablename arg');

   local $dbh->{RaiseError};
   local $dbh->{PrintError};

   my $t = $dbh->prepare("select * from $tablename") or return 0;
   $t->execute or return 0;
   return 1;
}

sub table_dump {
   my ($dbh,$tablename) = @_;
   defined $dbh and defined $tablename or die('missing args');
   
   $dbh->table_exists($tablename) 
      or warn("table $tablename does not exist") 
      and return;
      
   my $dump = " # dump table '$tablename':\n";
   
   my $d = $dbh->selectall_arrayref("SELECT * FROM $tablename");

   defined $d and scalar @$d or carp("table $tablename had no entries") and return '';


   

   no warnings;
   for (@$d){
      $dump.= '   ['.join(':',@$_)."]\n";
   }
   
   #require Data::Dumper;
   #my $dump = " # dump table '$tablename':\n".Data::Dumper::Dumper($d);

   return $dump; 
   
}






sub selectcol {
   my ($dbh, $statement) = @_; 
   defined $statement or confess('missing statement arg');
   
   my $return = [];
   
   my $q = $dbh->prepare($statement) or confess("prepare [$statement] fails.. ".$dbh->errstr);
   $q->execute;

   while(my $row = $q->fetchrow_arrayref ){
      push @$return, $row->[0];
   }

   return $return;
}








sub connect_mysql {
   my($dbname,$user,$pass,$host)= @_;
   defined $dbname or confess('missing dbname');
   defined $user or confess('missing user');
   defined $pass or confess('missing pass');
   $host||='localhost';
   
   debug("[host:$host,dbname:$dbname,user:$user,pass:$pass]\n");
   require DBI;   
   my $dbh = DBI->connect( "DBI:mysql:database=$dbname;host=$host",$user, $pass )
		         or carp("  -ERROR=[$DBI::errstr]\n  -make sure mysqld is running\n  -wrong credentials?[$dbname,$user,$host]")
               and return;
   return $dbh;   
}

sub connect_sqlite {
   my $abs_db = shift;
   defined $abs_db or die;
   debug("abs db [$abs_db]");

   require DBI;   
   my $dbh = DBI->connect( "dbi:SQLite:$abs_db", '', '', )
	   or carp("$DBI::errstr, cant open sqlite connect. []")
      and return;
   return $dbh;  
}


1;

__END__

=pod

=head1 NAME

LEOCHARRE::Database::Base - added methods to DBI:db 

=head1 SYNOPSIS

   use DBI;
   use base 'LEOCHARRE::Database::Base';

   my $dbh = connect_sqlite('/abs/path/to.db');


=head1 DESCRIPTION

When used, this module adds methods to dbh handles, (DBI::db objects).

If instead you import, it just imports these subs..

=head1 SUBS


=head2 sth()

argument is dbh handle and statment, returns statement handle, cached prepared in dbh object
it will cache in the object, subsequent calls are not re-prepared

   my $delete = sth( $dbh, 'DELETE FROM files WHERE id = ?');
   $delete->execute(4);
   
   # or..
   for (@ids){
      sth( $dbh, 'DELETE FROM files WHERE id = ?')->execute($_);
   } 

If the prepare fails, confess is called.


=head2 selectcol()

argument is statement
will select and return array ref

   my $users = $dbh->selectcol("SELECT user FROM users WHERE type = 'm'");

Now users has ['joe','rita','carl']

This is useful sometimes.


=head2 table_exists()

argument is tablename
returns boolean

=head2 table_dump()

argument istablename
returns string of table dump suitable for print to STDERR
requires Data::Dumper

=head2 rows_count()

argument is statement or table name
returns count number
you MUST have a COUNT(*) if the first argument is a statement

takes 3 arguments or 1 argument, else throws an exception

   my $matches = $dbh->rows_count( 'select count(*) from files' );

   my $matches = $dbh->rows_count( 'files' ); #counts all entries in files table
   
   my $matches = $dbh->rows_count( 'files', size => 34 ); # all rows in files table with col 'size' == 34

   
   

=head2 close_active_handles()

closes ChildHandles that are active, finishes and undefines them.
returns true + number of active handles were finished and undefined here

=head2 lid()

argument is dbh and table name
returns last insert id for that table
returns undef if not there

this is often only available right after an insert,
if you make an insert into a table, and then into another, you cant get last insert id on the
first entry.

=head2 is_mysql()

returns boolean

=head2 is_sqlite()

returns boolean

=head2 driver()


returns name of DBI Driver, sqlite, mysql, etc.
Currently mysql is used, sqlite is used for testing. For testing the package, you don't need to have
mysqld running.

=head2 drop_table()

arument is dbh and table name
returns boolean


=head1 CONSTRUCTORS

=head2 connect_sqlite()

argument is abs path to db
returns db handle
returns undef on failure

   my $dbh = connect_sqlite('/home/myself/stuff.db');
   

=head2 connect_mysql()

args are dbname, dbuser, dbpass, hostname, if no hostname is provided, uses 'localhost'
returns database handle
returns undef on failure

   my $dbh = connect_mysql('stuff_data','joe','joepass');

=cut

=head1 DEBUG

   $LEOCHARRE::Database::Base::DEBUG = 1;


=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut




