package LEOCHARRE::Database;
use DBI;
use strict;
use warnings;
use Carp;
use LEOCHARRE::DEBUG;
use base 'LEOCHARRE::Database::Base';
use vars qw($VERSION);
$VERSION = sprintf "%d.%02d", q$Revision: 1.16 $ =~ /(\d+)/g;


sub dbh {
   my $self = shift;
   unless( $self->{DBH} ){
      
      $self->{AUTOCOMMIT} ||=0; 

      if( ! defined $self->{DBABSPATH} ){
         debug('will open mysql connection..'); 
   	   my $dbname		= $self->{DBNAME} or confess('missing DBNAME argument to constructor');
		   my $user			= $self->{DBUSER} or confess('missing DBUSER argument to constructor');
		   my $password	= $self->{DBPASSWORD} or confess('missing DBPASSWORD argument to constructor');

	   	$self->{DBH} = DBI::connect_mysql($self->{DBNAME}, $self->{DBUSER}, $self->{DBPASSWORD}, $self->{DBHOST})
            or die('connect_mysql failed');   
         debug("ok");
      }

      
      else {
         $self->{DBABSPATH} or confess('DBABSPATH argument to constructor bad');    
         debug("will open sqlite connection..$$self{DBABSPATH} ");         
         
         $self->{DBH} = DBI::connect_sqlite($self->{DBABSPATH}) or die('conect_sqlite failed');         
      }
      $self->{__DBH_IS_LOCAL_} = 1;
      
      $self->{DBH}->{RaiseError} = 1; # freak out when things go bad
      #$self->{DBH}->{PrintError} = 1; # print error or not
      
      $self->{DBH}->{AutoCommit} = $self->{AUTOCOMMIT};

      if ($DEBUG){
         $LEOCHARRE::Database::Base::DEBUG=1;
      }
         
      
   }
   return $self->{DBH};
}


# did the connection happen here?
sub _dbh_is_local {
   my $self = shift;
   $self->{__DBH_IS_LOCAL_} ||=0;
   return $self->{__DBH_IS_LOCAL_};
}


sub dbh_selectcol {
   my ($self, $statement) = @_; 
   return $self->dbh->selectcol($statement); 
}


sub dbh_do {
   my($self, $arg) = @_;
   defined $arg or confess('missing arg');
   ref $arg eq 'HASH' or confess('arg must be hashref');
   defined $arg->{sqlite} or confess('missing sqlite key');
   defined $arg->{mysql} or confess('missing mysql key');

   my $q = $self->dbh->is_mysql ? $arg->{mysql} : $arg->{sqlite};

   $self->dbh->do($q) ; # TODO or .. ????

   return 1;   
}
sub dbh_count {
   my ($self,$statement) = @_;
   return $self->dbh->rows_count($statement);   
}

sub dbh_sth {   
   my ($self, $statement) = @_;
   $statement or confess("missing statement argument");
   
   unless ($self->{_handles}->{$statement}){
      $self->{_handles} ||={};
      debug("preparing [$statement]..");
      
      local $self->dbh->{RaiseError};
      my $sth = $self->dbh->prepare($statement);
      defined $sth or confess("statment [$statement] failed to prepare, ". $self->dbh->errstr );      
      $self->{_handles}->{$statement} = $sth; 
   }

   return $self->{_handles}->{$statement};  
}

sub dbh_is_sqlite {
	my $self = shift;
   return $self->dbh->is_sqlite;
}

sub dbh_is_mysql {
	my $self = shift;
   return $self->dbh->is_mysql;
}

sub dbh_driver {
	my $self = shift;
   return $self->dbh->driver;
}



sub dbh_droptable {
   my ($self,$tablename) = @_;
   return $self->dbh->drop_table($tablename);
}

sub dbh_table_exists {
   my ($self,$tablename) = @_;
   return $self->dbh->table_exists($tablename);
}

sub dbh_table_dump {
   my ($self,$tablename) = @_;
   return $self->dbh->table_dump($tablename);
}



sub dbh_lid {
   my ($self,$tablename) = @_;
   return $self->dbh->lid($tablename);
}


# for retro
sub dbh_close_active_handles {
   my $self = shift;
   defined $self->dbh or return 1;
   return $self->dbh->close_active_handles;   
}



sub DESTROY {
   my $self = shift;  

   defined $self->dbh or return 1;
   
   $self->_dbh_is_local or debug("dbh is not local\n") and return 1;
#   unless( $self->dbh->{AutoCommit} or return 1;
   debug("dbh is local..");
   

   $self->dbh->close_active_handles;

   
     
   unless ( $self->dbh->{AutoCommit} ){
      debug("committing.."); 
      local $self->dbh->{RaiseError};      
      $self->dbh->commit or confess("cannot commit.. ".$self->dbh->errstr);
      debug("done.\n");
   }

   {      
      # sqlite reports errors here.. a bug
      # "closing dbh with active statement handles at.."
      # this is a brute force approach to get rid of that warning
      no warnings;
      (local $SIG{'__WARN__'} = sub {} ) if $self->dbh->is_sqlite;      
      
      $self->dbh->disconnect;
      debug("disconnected.\n");
   };   
  
   return 1;
}






1;

__END__

=pod

=head1 NAME

LEOCHARRE::Database - common database methods for oo

=head1 SYNOPSIS

Mymod.pm:

   package Mymod;
   use base 'LEOCHARRE::Database';

   1;

script.pl:

   use Mymod;

   my $m = new Mymod({ 
      DBHOST => 'localhost' , 
      DBUSER => 'username',
      DBPASSWORD => 'passwerd',
      DBNAME => 'superdb',
   });

   $m->dbh;

   my $a = $m->dbh_sth('select * from avocado where provider = ?');
   $a->execute(3);

   $m->dbh_sth('INSERT INTO fruit (name,provider) values(?,?)')->execute('grape','joe'); # gets prepared and cached
   
   $m->dbh_sth('INSERT INTO fruit (name,provider) values(?,?)')->execute('orange','joe'); # uses the previous cached prepared handle


=head1 DESCRIPTION

This is meant to be used as base by another oo module.

This can be passed an open database handle via DBH or it will attempt to open a new connection.
By default it attempts to open a mysql connection.
It can also open a sqlite connection.

Basically, if you provide the argument DBABSPATH, will attempt to open a mysql connection instead.

PLEASE NOTE autocommit is off. DESTROY calls commit and finishes and closes handles.

These and any other modules under my name as namespace base (LEOCHARRE) are parts of code that I use 
for doing repetitive tasks. They are not bringing anything really new to the table, and I wouldn't assume
that 'my way' is the way to attack these problems by any stretch of the imagination. 
This is why I place them under my namespace, as a gesture of deference.


=head2 To open a mysql connection

   new ({ 
      DBHOST => $host,
      DBNAME => $dbname,
      DBUSER => $dbuser,
      DBPASSWORD => $pw,
   });

=head2 To open a sqlite connection

   new ({ 
      DBABSPATH => '/home/myself/great.db',
   });

=head2 To use existing connection

   new ({ 
      DBH => $dbh,
   });


=head1 METHODS

These are meant to be inherited by your module with 

   use base 'LEOCHARRE::Database';



=head3 dbh()

returns database handle




=head2 dbh_selectcol()

argument is statement
will select and return array ref

   my $users = $self->dbh_selectcol("SELECT user FROM users WHERE type = 'm'");

Now users has ['joe','rita','carl']

This is useful sometimes.



=head2 dbh_do()

argis hash ref with mysql and sqlite keys

will select one or the other with dbh_is_mysql etc

   $self->dbh_do({
      sqlite => 'CREATE TABLE bla( name varchar(25) )',
      mysql  => 'CREATE TABLE bla( name varchar(25) )',  
   });




=head3 dbh_count()

argument is statement
returns count number
you MUST have a COUNT(*) in the select statement

   my $matches = $self->dbh_count('select count(*) from files');





=head2 dbh_sth()

argument is a statment, returns handle
it will cache in the object, subsequent calls are not re-prepared

   my $delete = $self->dbh_sth('DELETE FROM files WHERE id = ?');
   $delete->execute(4);
   
   # or..
   for (@ids){
      $self->dbh_sth('DELETE FROM files WHERE id = ?')->execute($_);
   } 

If the prepare fails, confess is called.



=head3 dbh_is_mysql()

returns boolean

=head3 dbh_is_sqlite()

returns boolean

=head3 dbh_driver()

returns name of DBI Driver, sqlite, mysql, etc.
Currently mysql is used, sqlite is used for testing. For testing the package, you don't need to have
mysqld running.



=head2 dbh_table_exists()

argument is table name, returns boolean

=head2 dbh_table_dump()

argument is table name
returns string of dump of table suitable for print to STDERR

=head2 dbh_droptable()

arg is table name, drops the table.
returns boolean
will drop IF EXISTS



=head2 dbh_lid()

arg is table name, returns last insert id. 
returns undef if not there



=head2 dbh_close_active_handles()

closes ChildHandles that are active, finishes and undefines them.
returns true + number of active handles were finished and undefined here

=head2 DESTROY()

If the database handle was created in this object and not passed via constructor, then we
close all handles, commit, and disconnect.

finishes active database handles etc, makes a commit to the database.
Note, this method is called automatically.



=head1 CAVEATS

=head2 IMPORTANT NOTE AUTOCOMMIT

Autocommit is set to 0 by default.
That means you should commit after indexing_lock(), indexing_lock_release(), delete_record()

DESTROY will finish and commit if there are open handles created by the object

=head1 DEBUG

To turn on debug, 

   $LEOCHARRE::Database::DEBUG = 1;

=head1 SEE ALSO

L<LEOCHARRE::CLI>
L<LEOCHARRE::Dev>
L<DBI>

=head1 AUTHOR

Leo Charre leocharre at cpan dot org
http://leocharre.com

=head1 COPYRIGHT

Copyright (c) 2008 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.


=cut

