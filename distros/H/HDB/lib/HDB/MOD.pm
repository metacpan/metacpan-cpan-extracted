#############################################################################
## Name:        MOD.pm
## Purpose:     HDB::MOD - Common things for HDB modules.
## Author:      Graciliano M. P.
## Modified by:
## Created:     15/01/2003
## RCS-ID:      
## Copyright:   (c) 2002 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package HDB::MOD ;

use DBI ;

use strict qw(vars) ;
no warnings ;

our $VERSION = '1.0' ;
our @ISA = qw(HDB::CMDS HDB) ;

###############
# VAR ALIASES #
###############

sub dbi { $_[0]->{dbh} ;}
sub dbh { $_[0]->{dbh} ;}
sub sth { $_[0]->{sth} ;}
sub sql { $_[0]->{sql} ;}

#############
# CONNECTED #
#############

sub connected {
  if ( !$_[0]->dbh ) { return undef ;}
  if ( $_[0]->dbh->{Active} ) { return 1 ;}
  return undef ;
}

##############
# DISCONNECT #
##############

sub disconnect {
  my $this = shift ;

  $this->{sth}->finish if $this->{sth} ;
  $this->{sth} = undef ;
  
  $this->flush_cache ;
  
  if ( $this->{dbh} ) {
    $this->{dbh}->commit if !$this->{dbh}->{AutoCommit} ;
    $this->MOD_disconnect if !$this->{dbh}->{Kids} ;  
  }

  $this->{dbh} = undef ;

  return ;
}

##################
# MOD_DISCONNECT #
##################

sub MOD_disconnect {
  my $this = shift ;
  $this->{dbh}->disconnect ;
}

########
# LINK #
########

sub LINK {
  if ( $_[0]->{HPL}{UNLINK_DISCONNECT} ) { $_[0]->connect ;}
}

##########
# UNLINK #
##########

sub UNLINK {
  $_[0]->flush_cache ;
  if ( $_[0]->{sth} ) { $_[0]->{sth}->finish ; $_[0]->{sth} = undef ;}
  if ( $_[0]->{HPL}{UNLINK_DISCONNECT} ) { $_[0]->disconnect ;}
}

######
# DO #
######

sub do { $_[0]->{dbh}->do(@_[1..$#_]) ;}

###########
# PREPARE #
###########

sub prepare { $_[0]->{dbh}->prepare(@_[1..$#_]) ;}

###########
# EXECUTE #
###########

sub execute { $_[0]->{sth}->execute(@_[1..$#_]) ;}

#############
# TYPE_TEXT #
#############

sub Type_TEXT { return 'TEXT' ;}

################
# TYPE_INTEGER #
################

sub Type_INTEGER { return 'INTEGER' ;}

##############
# TYPE_FLOAT #
##############

sub Type_FLOAT { return 'FLOAT' ;}

##############
# PRIMARYKEY #
##############

sub PRIMARYKEY { return "PRIMARY KEY" ;}

#################
# AUTOINCREMENT #
#################

sub AUTOINCREMENT { return "INTEGER NOT NULL AUTO_INCREMENT" ;}

#########
# LIMIT #
#########

sub LIMIT {
  my $this = shift ;
  my ( $sz , $offset ) = @_ ;
  my $limit = $offset > 0 ? "$sz,$offset" : $sz ;
  return( "LIMIT $limit" ) ;
}

#######
# DBD #
#######

package DBI ;
package DBD ;
use vars qw(%HDB) ;

#######
# END #
#######

1;

