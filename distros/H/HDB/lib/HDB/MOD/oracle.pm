#############################################################################
## Name:        oracle.pm
## Purpose:     HDB::MOD::oracle -> for DBD::Oracle
## Author:      Graciliano M. P.
## Modified by:
## Created:     14/01/2003
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package HDB::MOD::oracle ;
use DBD::Oracle ;

use strict qw(vars) ;
no warnings ;

our $VERSION = '1.0' ;
our @ISA = qw(HDB::MOD) ;

  my (%OPENED_DBH) ;

  my %SQL = (
  LIKE => 1 ,
  REGEXP => 0 ,
  LOCK_TABLE => 0 ,
  SHOW => 0 ,
  LIMIT => 0 ,
  TYPES => [qw(NUMBER VARCHAR VARCHAR2 BOOLEAN)] ,
  TYPES_MASK => {
                'BOOLEAN' => 'NUMBER(1)' ,
                } ,
  ) ;

#######
# NEW #
#######

sub new {
  my $this = shift ;

  $this->{SQL} = \%SQL ;
  $this->{name} = 'HDB::Oracle' ;
  
  bless($this , __PACKAGE__) ;
  return( $this ) ;
}

###########
# CONNECT #
###########

sub MOD_connect {
  my $this = shift ;
  my ( $pass ) = @_ ;
  
  my $db = $this->{db} ;
  my $host = $this->{host} ;
  
  $this->{dbh} = DBI->connect("DBI:Oracle:host=$host;sid=$db", $this->{user} , $pass , { RaiseError => 0 , PrintError => 1 , AutoCommit => 1 }) ;
  
  if (! $this->{dbh} ) { return $this->Error("Can't connect to db $db\@$host!") ;}
  
  return( $this->{dbh} ) ;
}

##############
# PRIMARYKEY #
##############

sub PRIMARYKEY { return "PRIMARY KEY" ;}

#################
# AUTOINCREMENT #
#################

sub AUTOINCREMENT { return "NUMBER PRIMARY KEY" ;}

#########
# LIMIT #
#########

sub LIMIT {
  my $this = shift ;
  my ( $sz , $offset ) = @_ ;
  
  my $into_where = $offset ? "rownum >= $offset && $offset <= " . ($offset+$sz) : "rownum <= $sz" ;
  
  return( undef , $into_where) ;
}

#############
# TYPE_TEXT #
#############

sub Type_TEXT {
  my $this = shift ;
  my ( $sz ) = @_ ;
  
  if ( $sz eq '0' ) { return $this->Type_INTEGER() ;}
  
  $sz = 65535 if $sz <= 0 ;
  
  my $ret = $sz <= 250 ? "VARCHAR($sz)" :
           ($sz <= 4000 ? "VARCHAR2($sz)" : "LONG") ;
  
  return $ret ;
}

################
# TYPE_INTEGER #
################

sub Type_INTEGER {
  my $this = shift ;
  my ( $sz ) = @_ ;
  
  $sz =~ s/\D+//g ;
  $sz = 10 if $sz <= 0 ;
  $sz = 38 if $sz > 38 ;
  
  return "NUMBER($sz)" ;
}

##############
# TYPE_FLOAT #
##############

sub Type_FLOAT {
  my $this = shift ;
  my ( $type , $args ) = @_ ;
  
  if ( $args !~ /\d/ ) { return "NUMBER(38)" ;}
  
  my $tp_arg ;
  if    ( $args =~ /(\d+)\D+(\d+)/ ) { $tp_arg = "($1,$2)" ;}
  elsif ( $args =~ /(\d+)/ ) { $tp_arg = "($1)" ;}
  
  return "NUMBER$tp_arg" ;
}

##########
# TABLES #
##########

sub tables {
  my $this = shift ;
  
  $this->{sql} = "SELECT TABLE_NAME FROM user_tables ORDER BY TABLE_NAME" ;
  
  eval{
    $this->_undef_sth ;
    $this->{sth} = $this->dbh->prepare( $this->{sql} ) ;
    $this->{sth}->execute ;
  };
  if ( $@ ) { $this->Error("SQL error: $this->{sql}") ;}
  
  my @tables = $this->Return('$') ;
  
  $this->_undef_sth ;
 
  return( sort @tables ) ;
}

#########
# NAMES #
#########

sub names {
  my $this = shift ;
  my ( $table ) = @_ ;
  
  $table = HDB::CMDS::_format_table_name($table) ;
  
  if (! $table) { return $this->Error('Invalid table!') ;}
  elsif ( $this->{CACHE}{names}{$table} ) { return @{ $this->{CACHE}{names}{$table} } ;}
  
  $this->{sql} = "SELECT * FROM $table WHERE(rownum <= 1)" ;
  
  $this->_undef_sth ;
  eval{
    $this->{sth} = $this->dbh->prepare( $this->{sql} ) ;
    $this->{sth}->execute ;
  };

  return $this->Error("SQL error: $this->{sql}") if $@ ;

  my @names ;
  eval { @names = map { substr($_ , 0) } @{ $this->{sth}->{'NAME'} } };
  
  $this->_undef_sth ;

  return () if !@names ;
  
  if ( $this->{cache} ) { $this->{CACHE}{names}{$table} = \@names ;}
  
  return @names ;
}

#############
# ON_CREATE #
#############

sub ON_CREATE {
  my $this = shift ;
  my ( $table , $cols , $order ) = @_ ;
  
  $this->dbh->do(qq`
    create sequence HDBseq_$table
      start with 1 
      increment by 1 
      nomaxvalue
  `);
  
  $this->dbh->do(qq`
    create trigger HDBtrigger_$table
      before insert on $table
      for each row begin
        select HDBseq_$table.nextval into :new.ID from dual;
      end;
  `);
  
}

###########
# ON_DROP #
###########

sub ON_DROP {
  my $this = shift ;
  my ( $table ) = @_ ;

  $this->dbh->do(qq` drop sequence HDBseq_$table `);
}

##############
# LOCK_TABLE #
##############

sub lock_table { $_[0]->dbh->do("LOCK TABLE $_[1] IN EXCLUSIVE MODE") ;}

################
# UNLOCK_TABLE #
################

sub unlock_table { $_[0]->dbh->do("COMMIT") ;}

#######
# END #
#######

1;


