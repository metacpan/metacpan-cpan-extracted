#############################################################################
## Name:        UPX.pm
## Purpose:     LibZip::Build::UPX
## Author:      Graciliano M. P.
## Modified by:
## Created:     2004-06-06
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package LibZip::Build::UPX ;
use 5.006 ;

use strict qw(vars) ;
use vars qw($VERSION) ;

$VERSION = '0.01' ;

use LibZip::CORE ;

########
# VARS #
########

my $upx_exe = 'upx' ;

#######
# UPX #
#######

sub upx {
  my ( $file ) = @_ ;
  return if !can_upx($file) || !-s $file || !-f $file ;
  
  if ( !-w ) {
   chmod(0777 , $file) ;
   print "CHMOD 0775 $file\n" ;
  }
  
  print "UPX: $file\n" ;
  
  open (CMDLOG,"| $upx_exe -q -9 $file") ; close (CMDLOG) ;
}

###########
# UPX_DIR #
###########

sub upx_dir {
  my ( $dir , $rec ) = @_ ;
  my @files = scan_dir($rec , $dir) ;
  foreach my $files_i ( @files ) {
    next if !can_upx($files_i) ;
    upx($files_i) ;
  }
}

###########
# CAN_UPX #
###########

sub can_upx {
  return 1 if $_[0] =~ /\.(?:dll|exe|so|a)$/i ;
  return ;
}

############
# SCAN_DIR #
############

sub scan_dir {
  my ( $rec , @DIR ) = @_ ;

  my @files ;
  
  foreach my $DIR_i ( @DIR ) {
    opendir (DIRLOG, $DIR_i);
  
    while (my $filename = readdir DIRLOG) {
      if ($filename ne "\." && $filename ne "\.\." && $filename !~ /^(?:\.packlist|\.exists)$/) {
        my $file = "$DIR_i/$filename" ;
        if ( -d $file ) { push(@DIR , $file) if $rec ;}
        elsif ( -s $file ) { push(@files , $file) ;}
      }
    }
  
    closedir (DIRLOG);
  }
  
  return @files ;
}

#######
# END #
#######

1;


