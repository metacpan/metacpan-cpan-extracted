#############################################################################
## Name:        InitLib.pm
## Purpose:     LibZip::InitLib
## Author:      Graciliano M. P.
## Modified by:
## Created:     2004-06-06
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package LibZip::CORE ;

BEGIN { $INC{'LibZip/CORE.pm'} = 1 if !$INC{'LibZip/CORE.pm'} ;}

$VERSION = '0.01' ;

no warnings ;

##########
# IMPORT #
##########

sub import {
  shift ;
  my $caller = caller ;
  my @EXPORT = qw(find_file save cat);
  my @exp = @_ ;
  if ( !@_ ) { @exp = @EXPORT ;}
  foreach my $exp_i ( @exp ) { *{"$caller\::$exp_i"} = \&{$exp_i} ;}
}

#############
# FIND_FILE #
#############

sub find_file {
  my ( $pack , @LIB ) = @_ ;
  my @pack_fl ;
  
  foreach my $LIB_i ( @INC , @LIB ) {
    if ( ref($LIB_i) ) { next ;}
    my $fl = "$LIB_i/$pack" ;
    if (-e $fl) { push(@pack_fl , $fl) ;}
  }

  return( @pack_fl ) if wantarray ;
  return $pack_fl[0] ;
}

########
# SAVE #
########

sub save {
  my $fh ;
  open ($fh,">$_[0]") ; binmode($fh) ;
  print $fh $_[1] ;
  close ($fh) ;
}

#######
# CAT #
#######

sub cat {
  my ($fh , $buffer) ;
  open ($fh,$_[0]) ; binmode($fh) ;
  1 while( read($fh, $buffer , 1024*4 , length($buffer) ) ) ;
  close ($fh) ;
  return $buffer ;
}

#######
# END #
#######

1;


