#############################################################################
## Name:        CreateLib.pm
## Purpose:     LibZip::Build::CreateLib
## Author:      Graciliano M. P.
## Modified by:
## Created:     2004-06-06
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package LibZip::Build::CreateLib ;
use 5.006 ;

use Archive::Zip () ;

use strict qw(vars) ;
use vars qw($VERSION) ;

$VERSION = '0.01' ;

use LibZip::CORE ;
use LibZip::Build::UPX ;
use LibZip::Build::PodStripper ;

########
# VARS #
########

my ($TO_UPX , $STRIP_LIB) ;

sub TO_UPX { $TO_UPX = shift } ;
sub STRIP_LIB { $STRIP_LIB = shift } ;

my $POD_Stripper = new LibZip::Build::PodStripper() ;

my @DEFAULT_MODULES = qw(
AutoLoader
Carp
Config
Cwd
DynaLoader
Exporter
File::Basename
File::Spec
File::Spec::Unix
File::Spec::Win32
FindBin
XSLoader
re
strict
vars
warnings
warnings::register
) ;

##############
# CREATE_LIB #
##############

sub create_lib {
  my $zip_file = shift ;
  
  my ( @modules , %modules_skip , @skip_re ) ;

  if ( $#_ == 1 || @_ % 2 ) {
    my ( $mod , $ext ) = cat_modules( pop(@_) , 1 ) ;
    my @modules_skip = @$mod ;
    
    foreach my $ext_i ( @$ext ) {
      next if $ext_i !~ /^qr\W/ ;
      push(@skip_re , eval($ext_i) ) ;
    }

    @modules_skip{@modules_skip} = ((1) x @modules_skip) ;
  }
  
  if ( $#_ == 0 && -s $_[0] ) {
    @modules = cat_modules($_[0]) ;
  }
  else { @modules = @_ ;}
  
  push(@modules , @DEFAULT_MODULES) ;
  
  my %files ;
  
  my $incs = join "|" , map { "\Q$_\E" } @INC ;
  my $rm_inc = qr/^(?:$incs)[\\\/]*/s ;
  
  foreach my $modules_i ( @modules ) {
    $modules_i =~ s/[\\\/]+/::/g if $modules_i !~ /\.pl$/i ;
    $modules_i =~ s/\.pm$// ;
    $modules_i =~ s/[^\w:\.\/\\]+//g ;
    
    next if $modules_skip{$modules_i} ;
    next if chk_skip_re($modules_i , @skip_re) ;
    
    my $pm = $modules_i ;
    $pm .= '.pm' if $pm !~ /\.pl$/i ;
    $pm =~ s/::/\//g if $pm !~ /\.pl$/i ;
    
    my $dir = $modules_i ;
    if ( $pm =~ /\.pl$/i ) {
      ($dir) = ( $dir =~ /(.*?)(?:[\\\/]+)?[^\\\/]+$/gi );
    }
    else { $dir =~ s/::/\//g ;}
    
    my $pm_file = find_file($pm) ;
    my @pm_dirs = $dir ? find_file($dir) : () ;
    my @pm_auto = $dir ? find_file("auto/$dir") : () ;
    
    my @pm_sub_files = scan_dir(@pm_dirs , @pm_auto) ;
    
    foreach my $pm_sub_files_i ( $pm_file , @pm_sub_files ) {
      next if chk_skip_re($pm_sub_files_i , @skip_re) ;
      my $file_in_zip = $pm_sub_files_i ;
      $file_in_zip =~ s/$rm_inc// ;
      $file_in_zip = "lib/$file_in_zip" ;
      $files{$file_in_zip} = $pm_sub_files_i ;
      ##print "$file_in_zip = $pm_sub_files_i\n" ;
    }    
  }

  return zip( $zip_file , %files ) ;
}

###############
# CHK_SKIP_RE #
###############

sub chk_skip_re {
  my $str = shift ;
  my $skip ;
  foreach my $skip_re_i ( @_ ) {
    if ( $str =~ /$skip_re_i/ ) { $skip = 1 ; last ;}
  }
  return $skip ;
}

###############
# CAT_MODULES #
###############

sub cat_modules {
  my ( $file , $get_extra ) = @_ ;
  
  my (@modules , @extra) ;
  
  open (LOG,$file) ;
  my @log = <LOG> ;
  close (LOG) ;
  chomp(@log) ;
  
  foreach my $log_i ( @log ) {
    $log_i =~ s/^\s+// ;
    $log_i =~ s/\s+$// ;
    next if $log_i !~ /\S/ ;
    
    if ( $log_i =~ /^(?:\w+[\\\/]+)*?[\w:]+(?:\.pl)?$/i ) { push(@modules , $log_i) ;}
    else { push(@extra , $log_i) ;}
  }
    
  if ( $get_extra ) { return( \@modules , \@extra ) ;}
  
  return( @modules ) ;
}

#######
# ZIP #
#######

sub zip {
  my ( $zip_file , %files ) = @_ ;
  
  $zip_file .= '.zip' if $zip_file !~ /\.zip$/i ;
  
  my $zip = Archive::Zip->new() ;
  
  my @FLTMP ;
  
  foreach my $file_i (sort keys %files) {
    if (-d $files{$file_i} ) {
      print "ZIP_TREE: $file_i\n" ;
      warn "Can't add tree $files{$file_i}\n" if $zip->addTree( $files{$file_i} , $file_i ) != AZ_OK ;
    }
    else {
      if ( $STRIP_LIB && $file_i =~ /\.(?:pod|c|cpp|h|o|obj|xs|lib|exp|dsp|dsw|html?|epod|hploo|tmp)$/i ) {
        print "SKIP: $file_i\n" ;
        next ;
      }
    
      print "ZIP_FILE: $files{$file_i}\n" ;
      if ( $TO_UPX && LibZip::Build::UPX::can_upx($file_i) ) {
        my ($name) = ( $files{$file_i} =~ /([^\\\/]+)$/ );
        my $cp_file = "UPX-TMP-$name" ;
        while( -e $cp_file ) { $cp_file = "x$cp_file" ;}
        copy_file( $files{$file_i} , $cp_file ) if !-e $cp_file ;
        LibZip::Build::UPX::upx( $cp_file ) ;
        $zip->addFile( $cp_file , $file_i ) or warn "Can't add file $file_i\n" ;
        push(@FLTMP , $cp_file) ;
      }
      elsif ( $STRIP_LIB && $file_i =~ /\.(?:pm|pl)$/i ) {
        print "STRIP: $file_i\n" ;
        my ($name) = ( $files{$file_i} =~ /([^\\\/]+)$/ );
        my $cp_file = "STRIPLIB-TMP-$name" ;
        while( -e $cp_file ) { $cp_file = "x$cp_file" ;}
        save($cp_file , cat_stripped( $files{$file_i} ) ) ;
        $zip->addFile( $cp_file , $file_i ) or warn "Can't add file $file_i\n" ;
        push(@FLTMP , $cp_file) ;
      }
      else {
        $zip->addFile( $files{$file_i} , $file_i ) or warn "Can't add file $file_i\n" ;
      }
    }
  }
  
  my $status = $zip->writeToFileNamed($zip_file) ;
  
  foreach my $FLTMP_i ( @FLTMP ) { unlink($FLTMP_i) ;}

  return $status ;
}

################
# CAT_STRIPPED #
################

sub cat_stripped {
  my $src = $POD_Stripper->parse($_[0]) ;
  $src =~ s/\r\n?/\n/gs ;
  $src =~ s/^\s+//s ;
  $src =~ s/\s*$/\n/s ;
  return $src ;
}

############
# SCAN_DIR #
############

sub scan_dir {
  my ( @DIR ) = @_ ;

  my @files ;
  
  foreach my $DIR_i ( @DIR ) {
    opendir (DIRLOG, $DIR_i);
  
    while (my $filename = readdir DIRLOG) {
      if ($filename ne "\." && $filename ne "\.\." && $filename !~ /^(?:\.packlist|\.exists)$/) {
        my $file = "$DIR_i/$filename" ;
        if ( -d $file ) { push(@DIR , $file) ;}
        elsif ( -s $file ) { push(@files , $file) ;}
      }
    }
  
    closedir (DIRLOG);
  }
  
  return @files ;
}

#############
# COPY_FILE #
#############

sub copy_file {
  my ( $file1 , $file2 ) = @_ ;
  my $buffer ;
  
  open (FILELOG1,$file1) ; binmode(FILELOG1) ;
    open (FILELOG2,">$file2") ; binmode(FILELOG2) ;
    while( sysread(FILELOG1, $buffer , 1024*100) ) { print FILELOG2 $buffer ;}
    close (FILELOG2) ;
  close (FILELOG1) ;
}

#######
# END #
#######

1;


