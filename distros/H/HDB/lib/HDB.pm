#############################################################################
## Name:        HDB.pm
## Purpose:     HDB - Hybrid database
## Author:      Graciliano M. P.
## Modified by:
## Created:     06/01/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package HDB ;
use 5.006 ;

use strict qw(vars) ;

use vars qw(@ISA $AUTOLOAD) ;
no warnings ;

our ($VERSION) ;
$VERSION = '1.05' ;

my $REQUIRED ;

###########
# REQUIRE #
###########

sub REQUIRE {
  return if $REQUIRED ;
  require HDB::CORE ;
  require HDB::CMDS ;
  require HDB::Encode ;
  require HDB::MOD ;
  require HDB::Object ;
  $REQUIRED = 1 ;
}

##########
# SCOPES #
##########

  use vars qw($HPL_Run_MAIN $HPL_Run_NOW) ;

  *HPL_Run_MAIN = \$HPL::Run::MAIN ;
  *HPL_Run_NOW = \$HPL::Run::NOW ;

############
# HPL_MAIN #
############

sub HPL_MAIN {
  return $HPL_Run_MAIN if UNIVERSAL::isa($HPL_Run_MAIN,'UNIVERSAL') ;
  return $main::HPL if UNIVERSAL::isa($main::HPL,'UNIVERSAL') ;
  return ${"main::HPL"} ;
}

########
# VARS #
########

  my %args_types = (
  file     =>  [qw(file dbfile databasefile db database)] ,
  db       =>  [qw(db database)] ,
  host     => [[qw(host hostname)],localhost] ,
  user     =>  [qw(user username)] ,
  pass     =>  [qw(pass password)] ,
  type     => [[qw(type dbtype databasetype dbd)],auto] ,
  cache    => [[qw(cache)],1] ,
  id       =>  [qw(id ident)] ,
  warning  => [[qw(warning warnings error errors alert alerts carp)],1] ,
  dynamic  => [[qw(dynamic dyn)],1] ,
  conf_hpl =>  [qw(confhpl hplconf)] ,
  );
  
  my (%PASS , %DB , $WITH_HPL , %MOD_LOADED , $RESET_X) ;
  
##########
# IMPORT #
##########

sub import {
  my $class = shift ;
  if ($_[0] =~ /HPL/i) {
    $WITH_HPL = 1 ;
    &REQUIRE() ;
  }
}

############
# AUTOLOAD #
############

sub AUTOLOAD {

  if ( $#_ == 0 && ref($_[0]) && UNIVERSAL::isa($_[0],'HDB') ) {
    if ( ref($_[0]) eq 'HDB' ) {
      my $this = shift ;
      my $type = $this->{MOD}{type} ;
      bless($this , "HDB::MOD::$type") ;
      $this->connect ;
      my ($method) = ( $AUTOLOAD =~ /(\w+)$/s );
      $this->$method(@_) ;
    }
  
    my ($table) = ( $AUTOLOAD =~ /(\w+)$/s ) ;
    my $TABLE_OBJ = HDB::TABLE->new($_[0] , $table) ;
    return $TABLE_OBJ ;
  }

  if (ref($_[0])) {
    my @caller = caller ;
    &HDB::Error(undef,qq`Can't find $AUTOLOAD at $caller[1] line $caller[2]!`) ;
    return undef ;
  }
  
  my ($id0) = ( $AUTOLOAD =~ /(\w+)$/ ) ;
  my $id = lc($id0) ;
  
  if ( $WITH_HPL && $id ne '' ) {
    my $hpl = &HPL_MAIN() ;
    
    if ( $hpl ) {
      my $hpl_root = $hpl->pack_root ;
      
      if ( $id eq 'hploo' && !${"$hpl_root\::MYHDB::DB"}{$id} ) {
        $id = (sort keys %{"$hpl_root\::MYHDB::DB"})[0] ;
        if ( $id ) {
          $hpl->warn(qq`HDB id HPLOO not defined, using 1st defined DB for HDB::Object persistence.` , 1) ;
          ${"$hpl_root\::MYHDB::DB"}{hploo} = ${"$hpl_root\::MYHDB::DB"}{$id} ;
        }
      }
      
      my $obj = ${"$hpl_root\::MYHDB::DB"}{$id} ;
      if (!$obj) { $hpl->warn(qq`Can't find HDB id "$id" for dynamic access $_[0]\->$id0 !`) ;}
      return $obj ;
    }
  }
  else {
    if (! $DB{$id}) { &HDB::Error(undef,qq`Can't find HDB id "$id" for dynamic access $_[0]\->$id0 !`) ;}
    return $DB{$id} ;
  }
  
  return undef ;
}

###########
# ALIASES #
###########

sub WITH_HPL { $WITH_HPL ;}

sub open {
  if ( ref $_[0] && UNIVERSAL::isa($_[0],'HDB') ) {
    $_[0]->connect ;
    return $_[0] ;
  }
  else { return &new(@_) ;}
}

sub close { $_[0]->disconnect ;}

#######
# NEW #
#######

sub new {
  &REQUIRE() ;
  
  my $class = shift ;
  my $this = {} ;
  
  &HDB::CORE::parse_args($this , \%args_types , @_) ;
  $this->{file} = &HDB::CORE::path($this->{file}) if defined $this->{file} ;
  
  $this->{id} =~ s/\W//s ;
  $this->{id} = lc( $this->{id} ) ;
  
  if ( $this->{type} eq 'auto' ) {
    if ( defined $this->{file} ) { $this->{type} = 'sqlite' ;}
    else { $this->{type} = 'mysql' ;}
  }
  else {
    my $type = $this->{type} ;
    $this->{type} =~ s/\W//gs ;
    $this->{type} = lc( $this->{type} ) ;
  }

  return Error($this,"Invalid type!") if $this->{type} eq '' ;
  
  my $type = $this->{type} ;
  
  if ( !&_require_module($type) ) { return Error($this,"Can't find HDB module for $type (HDB::MOD::$type)!") ;}

  &{"HDB::MOD::$type\::new"}($this) ;
  
  return $this->Error("Error on loanding HDB module $type (HDB::MOD::$type)!") if !$this ;

  if ( ($this->{conf_hpl} || $WITH_HPL ) && $this->{file} ) {
    my $hpl = &HPL_MAIN() ;
    if ( defined $hpl->env->{DOCUMENT_ROOT} ) {
      $this->{file} =~ s/^[\/\\][\/\\]/$hpl->env->{DOCUMENT_ROOT}/se ;
    }
  }

  ## "HIDDE" PASS:
  $PASS{$this} = $this->{pass} ;
  delete $this->{pass} ;

  eval { $this->connect };
  
  if ( !$this || !$this->connected || !$this->dbh ) { $this->Error("Can't connect to DB. Load error!") ; return ;}
  
  if ($this->{dynamic} && $this->{id} ne '') {
    if ( $WITH_HPL ) {
      $this->{WITH_HPL} = 1 ;
      my $hpl = &HPL_MAIN() ;
      if ( $hpl ) {
        my $hpl_root = $hpl->pack_root ;
        ${"$hpl_root\::MYHDB::DB"}{ $this->{id} } = $this ;
      }
    }
    else { $DB{ $this->{id} } = $this ;}
  }

  
  if ( $WITH_HPL ) {
    $this->dbh->{HandleError} = \&HPL_show_error ;
  }

  return $this ;
}

##################
# HPL_SHOW_ERROR #
##################

sub HPL_show_error {
  my $hpl = &HPL_MAIN() ;
  $hpl->warn($_[0]) if $hpl ;
  return $_[2] ;
}

###########
# CONNECT #
###########

sub connect {
  if ( $_[0]->{dbh} ) { return $_[0]->{dbh} ;}
  $_[0]->MOD_connect( $PASS{$_[0]} ) ;
  return $_[0]->{dbh} ;
}

#############
# RECONNECT #
#############

sub reconnect {
  $_[0]->disconnect ;
  $_[0]->connect ;
}

#########
# ERROR #
#########

sub Error {

  if ( $_[0]->{sth} ) {
    $_[0]->{sth}->finish ;
    $_[0]->{sth} = undef ;
  }

  if ($_[0] && !$_[0]->{warning}) { return ;}
  if ($_[0] && ref $_[0]->{warning} eq 'CODE') { &{$_[0]->{warning}}($_[1]) }
  else {
    if ($WITH_HPL) {
      my $hpl = &HPL_MAIN() ;
      $hpl->warn($_[1] , $_[2]) if $hpl ;
    }
    else {
      eval {
        require Carp ;
        Carp::carp($_[1]) ;    
      };
    }
  }
  
  return ;
}

###################
# _REQUIRE_MODULE #
###################

sub _require_module {
  my ( $module ) = @_ ;
  return 1 if $MOD_LOADED{$module} ;
  eval("require HDB::MOD::$module ;") ;
  return undef if $@ ;
  return $MOD_LOADED{$module} = 1 ;
}

###########
# DESTROY #
###########

sub DESTROY {
  delete $PASS{$_[0]} ;
  $_[0]->disconnect ;
}

#########
# RESET #
#########

sub RESET {
  ++$RESET_X ;
  
  HDB::Object::RESET() if defined &HDB::Object::RESET && (!$WITH_HPL || $RESET_X > 10) ;

  if ( $WITH_HPL ) {
    my $hpl = &HPL_MAIN() ;
    if ( $hpl ) {
      my $HDB_LINKED = \%{ $hpl->pack_root ."::MYHDB::DB"} ;
      %$HDB_LINKED = () ;
      undef %$HDB_LINKED ;
      eval {
        foreach my $Key ( keys %$HDB_LINKED ) { $$HDB_LINKED{$Key}->UNLINK ;}
      };
    }
  }

  %DB = () ;
  
  HDB::Parser::RESET() if defined &HDB::Parser::RESET && (!$WITH_HPL || $RESET_X > 10) ;
  
  $RESET_X = 0 if $RESET_X > 10 ;
  
  return 1 ;
}

sub END { &RESET }

#########
# TABLE #
#########

sub TABLE { HDB::TABLE->new(@_) ;}

##############
# HDB::TABLE #
##############

package HDB::TABLE ;

use vars qw($AUTOLOAD) ;

#######
# NEW #
#######

sub new {
  bless({
  hdb => $_[1] ,
  table => $_[2] ,
  },$_[0]) ;
}

sub DESTROY {
  ##print main::STDOUT "DESTROY>> @_\n" ;
}

sub AUTOLOAD {
  my $obj = shift ;
  my ($method) = ( $AUTOLOAD =~ /(\w+)$/s ) ;
  my $class = ref $obj->{hdb} ;
  return ($obj->{hdb})->$method($obj->{table} , @_) ;
}

#############
# HDB::CMDS #
#############

package HDB::CMDS ;

sub default_types { require HDB::CMDS ; &default_types ;}
sub predefined_columns { require HDB::CMDS ; &predefined_columns ;}
sub default_mod { require HDB::CMDS ; &default_mod ;}

#######
# END #
#######

1;

__END__

=head1 NAME

HDB - Hybrid Database - Handles multiple databases with the same interface.

=head1 DESCRIPTION

B<HDB is an easy, fast and powerfull way to access any type of database>. With it you B<don't need to know SQL, DBI, or the type of the database> that you are using.
HDB will make all the work around between the differences of any database. From HDB you still can use DBI and SQL commands if needed, but this won't be portable between database types.
If you use only HDB querys (not DBI) B<you can change the database that you are using, Server and OS without change your code!> For example, you can test/develope your code in your desktop (let's say Win32) with SQLite, and send your code to the Server (Linux), where you use MySQL.

HDB borns like a module to access in a easy way MySQL databases from HPL Documents.
From HPL6, when it was fully rewrited, the module MYSQL was rewrited too and called HDB, where the resources were expanded for other DB types, like SQLite.
Also HDB was turned into a Perl module, that can run independent of HPL when not called from it.

=head1 USAGE

  use HDB ;
  
  my $HDB = HDB->new(
  type => 'sqlite' ,
  file => 'test.db' ,
  ) ;
  
  ... or ...
  
  my $HDB = HDB->new(
  type => 'mysql' ,
  host => 'some.domain.com' ,
  user => 'foo' ,
  pass => 'bar' ,
  ) ;
  
  $HDB->create('users',[
  'user' => 100 ,
  'name' => 100 ,
  'age' => 'int(200)' ,
  'more' => 1024*4 ,
  ]);
  
  $HDB->insert( 'users' , {
  user => 'joe' ,
  name => 'joe tribianny' ,
  age  => '30' ,
  } ) ;
  
  ... or ...
  
  $HDB->users->insert( {
  user => 'joe' ,
  name => 'joe tribianny' ,
  age  => '30' ,
  } ) ;

  
  ...
  
  my @sel = $HDB->select('users' , 'name =~ joe' , '@%' ) ;
  
  foreach my $sel_i ( @sel ) {
    my %cols = %$sel_i ;
    ...
  }
  
  ...
  
  my $hdbhandle = $HDB->select('users' , '<%>');
  
  while( my %cols = <$hdbhandle> ) {
    foreach my $Key ( keys %cols ) { print "$Key = $cols{$Key}\n" ;}
    ...
  }
  
  ...
  
  $HDB->update('users' , 'user eq joe' , { user => 'JoeT' } )
  
  ...
  
  $HDB->disconnect ;


=head1 METHODS

=head2 new

Create the HDB object connected to the DB.

B<Arguments:>

=over 10

=item FILE

File for flat databases, like SQLite.

=item DB

The database name.

=item HOST

The host of the database server. If omited and needed will use "localhost".

=item USER

The user for connection.

=item PASS

The password for connection.

=item TYPE

The database type. See modules inside HDB/MOD for installed names.

=item CACHE (boolean)

Turn on/off the cache of sth and col names.

=item ID

Set a global ID for dynamic access.

=item DYNAMIC (boolean)

Enable/disable the dynamic acess. 

=item WARNING (boolean)

Turn on/off errors/warnings.

=back

=head2 open

Alias for new.

=head2 connect

Connect to the database. Note, no arguments are needed, they will be get from the object.

** Password will be hidden inside the class, not int the object.

=head2 disconnect

Disconnect the database and free any sth or cache.

=head2 reconnect

Disconnect, if needed, and reconnect the database.

=head2 dbh

Use to access in the DBI way:

  $HDB->dbh->do("select * from users") ;
  
  ...
  
  my $sth = $HDB->dbh->prepare("INSERT INTO users VALUES (?, ?, ?)") ;
  $sth->execute("joe", "Joe Tribiany", "joe\friends.com") ;

You can use I<dbi> too:

  $HDB->dbi->do("select * from users") ;

B<** Try to avoid this way to keep your code portable between database types and OS>.

=head1 COMMANDS METHODS

** See L<HDB::CMDS> for usage.

B<Commands:> select, insert, update, delete, create, drop, cmd, names, tables, table_columns...

=head1 DYNAMIC ACCESS

You can access the database connection without have the object variable. With this you have a global access to any connection with the ID set.

The Dynamic Access allow the use of a table as a method too:

  $HDB->users->select('name == joe');

Since the table is always the first argument, HDB will paste the fake method (table name) to the CMD (select) as the fisrt argument.

** Note that the name of the table can't be a HDB method.

=head2 USAGE

  my $HDB = HDB->new(
  type => 'mysql' ,
  db   => 'test' ,
  user => 'joe' ,
  pass => '12345' ,
  id   => 'TEST' ;
  ) ;
  
  ...
  
  HDB->TEST->select(users , 'user == joe');
  
  ...

  my $HDB = HDB->TEST ;

  $HDB->users->update('name == joe',{name => 'Jeff'}) ;
  
  ... or ...
  
  my $table_users = $HDB->TABLE(users) ;
  $table_users->update('name == joe',{name => 'Jeff'}) ;
  
  ... or ...
  
  HDB->TEST->users->update('name == joe',{name => 'Jeff'}) ;
  
  ...

B<** Dynamic access is used for global connections in HPL (connections set in the config file: .conf.hpl).>

=head1 HDB::Object - Persistent Objects

An automatic persistence framework was built over HDB, where is possible to
create persistent classes in a easy and fast way. HDB was designed to handle any
type of DB behind it, what extends the persistence framework to any DB that DBI
can handle with standart SQL.

Take a look at L<HDB::Object>.

=head1 SEE ALSO

L<HDB::CMDS>, L<HDB::Encode>, L<HDB::sqlite>, L<HDB::mysql>.

L<HDB::Object>, L<HPL>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

