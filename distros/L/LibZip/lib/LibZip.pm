#############################################################################
## Name:        LibZip.pm
## Purpose:     Use lib.zip files as Perl librarys directorys.
## Author:      Graciliano M. P.
## Modified by:
## Created:     21/10/2002
## RCS-ID:      
## Copyright:   (c) 2002 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package LibZip ;

$VERSION = '0.06' ;

no warnings ;

BEGIN { $INC{'LibZip.pm'} = 1 if !$INC{'LibZip.pm'} ;}

use LibZip::CORE ;
use LibZip::InitLib ;
use LibZip::DynaLoader ;
use LibZip::MyArchZip ;

########
# VARS #
########

my (@LIBBASES,%LIBTREE,$ZIP,%DEP,@DATAPACK,@FIND_LIB) ;

BEGIN {
  *LIBZIP    = \$LibZip::InitLib::LIBZIP ;
  *LIBTMP    = \$LibZip::InitLib::LIBTMP ;
  *LIBTMPFIX = \$LibZip::InitLib::LIBTMPFIX ;
  *FILETMP   = \*LibZip::InitLib::FILETMP ;
  
  $DEBUG = 0 ;

  $LIBTMP = './lib/' if !defined $LIBTMP ;
  $CALL_BEGIN = 0 if !defined $CALL_BEGIN ;
  $HOOK_ADDED = 0 if !defined $HOOK_ADDED ;
}

begin() ;

##########
# IMPORT #
##########

sub import {
  my ($class , @args) = @_ ;

  if (-s $args[0]) { $LIBZIP = $args[0] ;}
  
  &LoadLibZip($LIBZIP) if $LIBZIP ;
}

#######
# INC #
#######

sub INC {
  my ( $ref , $pack ) = @_ ;
  
  print "HOOK>> $pack\n" if $DEBUG ;

  my $pack_fl = find_file_zip($pack) ;
  
  if ($pack_fl eq '') { return( undef ) ;}

  check_pack_dep($pack_fl) ;
  
  $INC{$pack} = "$LIBTMP/$pack_fl" ;
  
  return( get_file_zip_handle( $pack_fl , $pack ) ) ;
}

sub BEGIN {
  if ( !$HOOK_ADDED ) {
    $HOOK_ADDED = 1 ;
    unshift(@INC , \&INC ) ;
  }
}

##############
# LOADLIBZIP #
##############

sub LoadLibZip {
  my ( $libzip ) = @_ ;
  
  print "LOAD>> $libzip\n" if $DEBUG ;

  if (!-s $libzip) { warn("Can't find or load LibZip: $libzip") ; return ;}
  
  begin() ;

  $ZIP = LibZip::MyArchZip->new();
  $ZIP->read($libzip);

  %LIBTREE = map { $_ => 1 } ($ZIP->memberNames()) ;
  
  foreach my $Key ( keys %LIBTREE ) {
    my ($dir) = ( $Key =~ /^(.*?)[\\\/][^\\\/]+$/ );
    $LIBTREE{"$dir/"} = $LIBTREE{"$dir"} = 1 ;
  }
  
  my %libbases ;
  foreach my $libtree_i ( keys %LIBTREE ) {
    if ($libtree_i =~ /^(\/*(?:lib|site\/lib))\/[^\\\/]/i) {
      push(@LIBBASES , $1) if !$libbases{$1}++ ;
      #my $memb = $ZIP->memberNamed($libtree_i) ;
      #if ( $memb->isDirectory ) { push(@LIBBASES , $libtree_i) ;}
    }
  }
  
  push(@LIBBASES , "") ;
  
  foreach my $LIBBASES_i ( @LIBBASES ) { unshift(@INC , "$LIBTMP/$LIBBASES_i") ;}
  
  my $libzipdir ;
  
  foreach my $LIBBASES_i ( @LIBBASES ) {
    my $dir = zip_path($LIBBASES_i,'LibZip') ;
    if ($LIBTREE{$dir}) { $libzipdir = $dir ;}
  }
  
  my $LibZipInfo_pm ;
  
  if ($libzipdir eq '') { $LibZipInfo_pm = 'LibZipInfo.pm' ;}
  else { $LibZipInfo_pm = zip_path($libzipdir,'Info.pm') ;}
  
  if ($LIBTREE{$LibZipInfo_pm}) {
    my $pack = pm2pack($LibZipInfo_pm) ;
    eval("require $pack ;") ;
  }
  else { eval("require LibZip::Info ;") ;}
  
}

#################
# FIND_FILE_ZIP #
#################

sub find_file_zip {
  my ( $pack ) = @_ ;
  
  foreach my $LIB_i ( @LIBBASES ) {
    my $fl = zip_path($LIB_i,$pack) ;
    if ( $LIBTREE{$fl} ) { return( $fl ) ;}
  }

  return( undef ) ;
}

#######################
# GET_FILE_ZIP_HANDLE #
#######################

sub get_file_zip_handle {
  my ( $file , $pack ) = @_ ;
  
  my $filename = "$LIBTMP/$file" ;  
  
  my $memb = $ZIP->memberNamed($file) ;
  my $size = $memb->{'uncompressedSize'} ;

  if ($size > 0 && -s $filename != $size) {
    $ZIP->extractMember($file,$filename) ;
    print "ZIP>> $file >> $filename\n" if $DEBUG ;
  }
  
  $PMFILE = $filename ;

  my $fh ;
  open ($fh,$filename) ; binmode($fh) ;

  return( $fh ) ;
}

###########
# PM2PACK #
###########

sub pm2pack {
  my ( $pack ) = @_ ;
  $pack =~ s/^.*?\/lib\///i ;
  $pack =~ s/[\\\/]/::/gs ;
  $pack =~ s/\.pm$//i ;
  return( $pack ) ;
}

############
# ZIP_PATH #
############

sub zip_path {
  my ( $dir ) = @_ ;
  $dir .= '/' if ($dir ne '' && $dir !~ /\/$/) ;
  $dir .= $_[1] ;
  return( $dir ) ;
}

##################
# CHECK_PACK_DEP #
##################

sub check_pack_dep {
  my ( $pack ) = @_ ;

  $pack =~ s/\/*\.pm$/\//i ;
  
  print "LIBZIP DEP>> @_\n" if $DEBUG ;
  
  if ( $DEP{$pack} ) { return ;}
  
  if ( !$LIBTREE{$pack} && !$LIBTREE{$_[0]} ) {
    my $exists ;
    foreach my $LIBBASES_i ( @LIBBASES ) {
      my $path0 = zip_path($LIBBASES_i,$pack) ;
      my $path1 = zip_path($LIBBASES_i,$_[0]) ;
      if ( $LIBTREE{$path0} || $LIBTREE{$path1} ) {
        $pack = $path0 ;
        $exists = 1 ;
        last ;
      }
    }
    return if !$exists ;
  }
  
  $DEP{$pack} = 1 ;
  
  foreach my $path ( keys %LIBTREE ) {
    if ( $path !~ /\/$/ ) {
      if ( $path =~ /^\Q$pack\E[^\/]+$/ && $path !~ /\.pm$/i) {
        my $extract = "$LIBTMP/$path" ;
        my $memb = $ZIP->memberNamed($path) ;
        my $size = $memb->{'uncompressedSize'} ;
        
        if ($size > 0 && -s $extract != $size) {
          $ZIP->extractMember($path,$extract) ;
          print "DEP>> $path\n" if $DEBUG ;
        }
      }
    }
  }
  
  if ($pack =~ /^(?:lib|site\/lib)\/([^\/]+.*)$/ && !$_[1] ) {
    my $pack_path = $1 ;
    foreach my $LIBBASES_i ( @LIBBASES ) {
      my $auto = zip_path($LIBBASES_i,"auto/$pack_path") ;
      if ( $LIBTREE{$auto} ) { check_pack_dep("$auto.pm",1) ;}
    }
  }
  
  if ( %LibZip::Info::DEPENDENCIES ) {
    my $package = pm2pack($_[0]) ;
    $package =~ s/^(?:lib|site::lib)::// ;
    
    foreach my $Key ( keys %LibZip::Info::DEPENDENCIES ) {
      if ( $Key =~ /^$package$/i ) {
        my @dep ;
        if (ref($LibZip::Info::DEPENDENCIES{$Key}) eq 'ARRAY' ) { @dep = @{$LibZip::Info::DEPENDENCIES{$Key}} ;}
        else { @dep = $LibZip::Info::DEPENDENCIES{$Key} ;}
        foreach my $dep_i ( @dep ) {
          my $path = find_file_zip($dep_i) ;
          my $extract = "$LIBTMP/$path" ;
          if ($path =~ /\/$/) {
            $ZIP->extractTree($path,$extract) ;
            print "%DEP>> $path >> $extract\n" if $DEBUG ;
          }
          else {
            my $memb = $ZIP->memberNamed($path) ;
            my $size = $memb->{'uncompressedSize'} ;
            if ($size > 0 && -s $extract != $size) {
              $ZIP->extractMember($path,$extract) ;
              print "%DEP>> $path >> $extract\n" if $DEBUG ;
            }
          }
          check_pack_dep($path) ;
        }
      }
    }
  }

  return( undef ) ;
}

######################
# LIB_HAS_DYNALOADER #
######################

sub lib_has_dynaLoader {
  return 1 if $LIBTREE{"DynaLoader.pm"} || $LIBTREE{"lib/DynaLoader.pm"} ;
}

################
# CHK_DEAD_TMP # Check LIBTMP for dead files and rmtree(LIBTMP) if possible.
################

sub chk_dead_tmp {
  opendir (LIBTMPDIR, $LIBTMP) ;
  
  my ($has_files,@dirs) ;

  while (my $filename = readdir LIBTMPDIR) {
    if ($filename ne "\." && $filename ne "\.\.") {
      my $file = "$LIBTMP/$filename" ;
      if (-d $file) {
        push(@dirs , $file) if !$LIBTMPFIX || $filename ne 'auto' ;
      }
      else {
        my ($pid) = ( $filename =~ /^pm-(-?[\d]+)-/i );
        if ($_[0] ne '') {
          if ($pid != $_[0] && !kill(0,$pid)) { unlink ($file) ;}
          else { $has_files = 1 ;}
        }
        elsif (! kill(0,$pid)) { unlink ($file) ;}
        else { $has_files = 1 ;}
      }
    }
  }
  
  if (! $has_files) {
    foreach my $dirs_i ( @dirs ) { LibZip::File::Path::rmtree($dirs_i,0) ;}
  }
  
  closedir(LIBTMPDIR) ;
}

###################
# CHK_DEAD_TMPDIR # Check for libtmp dirs of ended PIDs.
###################

sub chk_dead_tmpdir {
  my $dir = '.' ;
  opendir (LIBTMPDIR, $dir) ;

  while (my $filename = readdir LIBTMPDIR) {
    if ($filename =~ /^libzip-(-?\d+)-\w+-tmp$/ ) {
      my $pid = $1 ;
      my $file = "$dir/$filename" ;
      if ( -d $file && !kill(0,$pid) ) {
        LibZip::File::Path::rmtree($file,0) ;
      }
    }
  }

  closedir(LIBTMPDIR) ;
}

#########
# BEGIN #
#########

sub begin {
  return if $CALL_BEGIN ;
  $CALL_BEGIN = 1 ;
  LibZip::InitLib::begin() ;
  chk_dead_tmp($$) ;
  chk_dead_tmpdir() ;
  return ;
}

sub BEGIN { &begin ;}

#######
# END #
#######

sub end {
  $END = 1 ;

  foreach my $DATAPACK_i ( @DATAPACK ) {
    eval(qq`close($DATAPACK_i\::DATA);`);
  }
  
  close(FILETMP) ;  
  unlink($FILETMP) ;

  &chk_dead_tmp ;
  &chk_dead_tmpdir ;
  
  LibZip::InitLib::end() ;
}

sub END { &end }

#######
# END #
#######

1;


