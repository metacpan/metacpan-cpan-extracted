#############################################################################
## Name:        mysql.pm
## Purpose:     HDB::MOD::mysql -> for DBD::MySQL
## Author:      Graciliano M. P.
## Modified by:
## Created:     15/01/2003
## RCS-ID:      
## Copyright:   (c) 2002 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package HDB::MOD::mysql ;

my $DRIVER = 'mysql' ;

BEGIN {
  eval { require DBD::mysql } ;
  
  if ( $@ ) {
    ## Try a pure Perl version of MySQL client.
    eval { require DBD::mysqlPP } ;
    if ( !$@ ) { $DRIVER = 'mysqlPP' ;}
    else {
      die("Can't load DBD::mysql or DBD::mysqlPP") ;
    }
  }
}

use strict qw(vars) ;
no warnings ;

our $VERSION = '1.0' ;
our @ISA = qw(HDB::MOD) ;

  my %SQL = (
  REGEXP => 1 ,
  LOCK_TABLE => 1 ,
  SHOW => 1 ,
  LIMIT => 1 ,
  TYPES => ['*'] ,
  TYPES_MASK => {
                'BOOLEAN' => 'BOOL' ,
                } ,
  ) ;

#######
# NEW #
#######

sub new {
  my $this = shift ;

  $this->{SQL} = \%SQL ;
  $this->{name} = 'HDB::MySQL' ;
  
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
  
  $this->{dbh} = DBI->connect("DBI:$DRIVER:database=$db;host=$host", $this->{user} , $pass , { RaiseError => 0 , PrintError => 1 , AutoCommit => 1 }) ;
  
  if (! $this->{dbh} ) { return $this->Error("Can't connect to db $db\@$host!") ;}
  
  return( $this->{dbh} ) ;
}

#################
# TABLE_COLUMNS #
#################

sub table_columns {
  my $this = shift ;
  my ( $table ) = @_ ;
  
  $table = HDB::CMDS::_format_table_name($table) ;
  
  if (! $table) { $this->Error('Invalid table!') ; return ;}
  
  my @cols = $this->cmd( "show columns from $table" , '@' ) ;
  
  my %cols ;
  
  foreach my $cols_i ( @cols ) {
    my ( $col , $type ) = @$cols_i ;
    $cols{$col} = $type ;
  }

  return %cols ;
}

##############
# TYPE_FLOAT #
##############

sub Type_FLOAT {
  my $this = shift ;
  my ( $type , $args ) = @_ ;
  
  my $plus_minus ;
  
  if ( $type =~ /^\s*([\+\-])\s*(\w+)/s) { $plus_minus = $1 ; $type = $2 ;}
  
  $type =~ s/\W//gs ;
  
  if    ($type =~ /^f/i) { $type = 'FLOAT' ;}
  elsif ($type =~ /^d/i) { $type = 'DOUBLE' ;}
  
  my $unsigned ;
  
  if ($plus_minus eq '+') { $unsigned = ' UNSIGNED' ;}
  
  if ( $args !~ /\d/ ) { return($type . $unsigned) ;}
  
  my $tp_arg ;
  
  if    ( $args =~ /(\d+)\D+(\d+)/ ) { $tp_arg = "($1,$2)" ;}
  elsif ( $args =~ /(\d+)/ ) { $tp_arg = "($1)" ;}
  
  return($type . $tp_arg . $unsigned) ;
}

#################
# AUTOINCREMENT #
#################

sub AUTOINCREMENT { return( "INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY" ) ;}

##############
# LOCK_TABLE #
##############

sub lock_table { $_[0]->dbh->do("LOCK TABLES $_[1] WRITE , $_[1] READ") ;}

################
# UNLOCK_TABLE #
################

sub unlock_table { $_[0]->dbh->do("UNLOCK TABLES") ;}

#######
# END #
#######

1;

