#############################################################################
## Name:        sqlite.pm
## Purpose:     HDB::MOD::sqlite -> for DBD::SQLite
## Author:      Graciliano M. P.
## Modified by:
## Created:     14/01/2003
## RCS-ID:      
## Copyright:   (c) 2002 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

# TESTED WITH DBD::SQLite 0.21 on Win32|Linux

package HDB::MOD::sqlite ;
use DBD::SQLite ;

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
  LIMIT => 1 ,
  TYPES => [qw(VARCHAR TEXT INTEGER FLOAT BOOLEAN CLOB BLOB TIMESTAMP NUMERIC)] ,
  ) ;
  
  my %HPL = (
  UNLINK_DISCONNECT => 1 ,
  ) ;

#######
# NEW #
#######

sub new {
  my $this = shift ;

  $this->{SQL} = \%SQL ;
  $this->{HPL} = \%HPL ;
  $this->{name} = 'HDB::SQLite' ;
  
  bless($this , __PACKAGE__) ;
  return( $this ) ;
}

###########
# CONNECT #
###########

sub MOD_connect {
  my $this = shift ;
  my ( $pass ) = @_ ;
  
  my $file = $this->{file} ;
  
  if ( $OPENED_DBH{$file}{db} ) {
    $this->{dbh} = $OPENED_DBH{$file}{db} ;
    $OPENED_DBH{$file}{x}++ ;
  }
  else {
    $this->{dbh} = DBI->connect("dbi:SQLite:dbname=$file", $this->{user} , $pass , { RaiseError => 0 , PrintError => 1 , AutoCommit => 1 }) ;
  
    if (! $this->{dbh} ) { return $this->Error("Can't connect to db $file!") ;}
    else {
      $OPENED_DBH{$file}{db} = $this->{dbh} ;
      $OPENED_DBH{$file}{x}++ ;
    }
  }
  
  return $this->{dbh} ;
}

##################
# MOD_DISCONNECT #
##################

sub MOD_disconnect {
  my $this = shift ;
  my $file = $this->{file} ;
  $this->{dbh}->disconnect if ( $OPENED_DBH{$file} && !$OPENED_DBH{$file}{x} ) ;
}

##############
# DISCONNECT #
##############

sub disconnect {
  my $this = shift ;

  my $file = $this->{file} ;
  $OPENED_DBH{$file}{x}-- ;
  
  if ( $OPENED_DBH{$file}{x} <= 0 ) {
    $OPENED_DBH{$file}{db} = undef ;
    delete $OPENED_DBH{$file} ;
  }
    
  $this->SUPER::disconnect(@_) ;
}

##########
# TABLES #
##########

sub tables {
  my $this = shift ;
  
  $this->{sql} = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name" ;
  
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

#################
# TABLE_COLUMNS #
#################

sub table_columns {
  my $this = shift ;
  my ( $table ) = @_ ;
  
  $table = HDB::CMDS::_format_table_name($table) ;
  
  if (! $table) { $this->Error('Invalid table!') ; return ;}
  
  my $sql = $this->select( "sqlite_master" , "name = $table" , cols => 'sql' , '$' ) ;
  
  my ($cols) = ( $sql =~ /^\s*CREATE\s+TABLE\s+\S+\s*.*?\(\s*(.*?)\s*\)/gs );
  $cols .= ' ,' ;
  my (%cols) = ( $cols =~ /(\w+)\s*(.*?)\s*,/gs );
  
  foreach my $Key (sort keys %cols ) {
    $cols{$Key} =~ s/\s+/ /gs ;
    $cols{$Key} = "\U$cols{$Key}\E" ;
  }

  return( %cols ) ;
}

#################
# AUTOINCREMENT #
#################

sub AUTOINCREMENT { return "INTEGER PRIMARY KEY" ;}

#########
# LIMIT #
#########

sub LIMIT {
  my $this = shift ;
  my ( $sz , $offset ) = @_ ;
  my $limit = $offset > 0 ? "$offset,$sz" : $sz ;
  return( "LIMIT $limit" ) ;
}

#######
# END #
#######

1;


