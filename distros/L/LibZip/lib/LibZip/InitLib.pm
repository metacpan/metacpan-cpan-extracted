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

package LibZip::InitLib ;

BEGIN { $INC{'LibZip/InitLib.pm'} = 1 if !$INC{'LibZip/InitLib.pm'} ;}

$VERSION = '0.01' ;

no warnings ;

use LibZip::CORE ;

########
# VARS #
########

my ( @INC_ORG , @DIRTMP ) ;

$CALL_BEGIN = 0 if !defined $CALL_BEGIN ;

## $LIBZIP , $LIBTMP , $LIBTMPFIX , $FILETMP , @LYB

###########
# ALIASES #
###########

sub LIBZIP { begin() ; "$LIBZIP" ;}
sub LIBTMP { begin() ; "$LIBTMP" ;}

#########
# BEGIN #
#########

sub begin {
  return if $CALL_BEGIN ;
  $CALL_BEGIN = 1 ;

  if (-d './lib') { splice(@INC,-1,0,'./lib') ;}
  
  @LYB = (0..9,'a'..'z','A'..'Z') ;
  
  define_lib() ;
}

####################
# DEFINE_REAL_PATH #
####################

sub define_real_path {
  eval{ require FindBin ;};

  if ( !$@ ) {
    if ( $LIBZIP !~ /^(?:\w+:\/|\/)/ ) {
      $LIBZIP =~ s/^\.?\/*// ;
      $LIBZIP = "$FindBin::RealBin/$LIBZIP" ;
    }
    
    if ( $LIBTMP !~ /^(?:\w+:\/|\/)/ ) {
      my $real_libtmp = $LIBTMP ;
      $real_libtmp =~ s/^\.?\/*// ;
      $real_libtmp = "$FindBin::RealBin/$real_libtmp" ;
      
      foreach my $INC_i ( @INC ) {
        next if ref $INC_i ;
        if ( $INC_i eq $LIBTMP ) { $INC_i = $real_libtmp ;}
        elsif ( $INC_i =~ /^\Q$LIBTMP\E[\\\/](.*)/ ) { $INC_i = "$real_libtmp/$1" ;}
      }
      
      $LIBTMP = $real_libtmp ;
    }
    
    if ( $FILETMP !~ /^(?:\w+:\/|\/)/ ) {
      $FILETMP =~ s/^\.?\/*// ;
      $FILETMP = "$FindBin::RealBin/$FILETMP" ;
    }
    
    if ( $^X !~ /^(?:\w+:\/|\/)/ ) {
      my ($name) = ( $^X =~ /([^\\\/]+)$/ );
      $^X = "$FindBin::RealBin/$name" ;
    }
    
    $0 = $FindBin::RealScript = $FindBin::Script = $^X ;
    
    my $fix_lib = "$FindBin::RealBin/lib" ;
    if ( -d $fix_lib ) { unshift (@INC, $fix_lib) ;}
  }

  if ($^O=~/(msw|win|dos)/i && $^X !~ /\.exe$/ && -e "$^X.exe") { $^X .= '.exe' ;}
  
  if ( LibZip::lib_has_dynaLoader() ) {
    delete $INC{'DynaLoader.pm'} ;
    require DynaLoader ;
    my $bootstrap = \&DynaLoader::bootstrap ;
    
    *DynaLoader::bootstrap = sub {
      LibZip::check_pack_dep("$_[0].pm") if defined &LibZip::check_pack_dep ;
      &$bootstrap(@_) ;
    }
  }
  
  $@ = undef ;
  
  my (@inc_ok , %inc_ok) ;
  foreach my $INC_i ( @INC ) {
    if ( ref $INC_i ) { push(@inc_ok , $INC_i) ;}
    else {
      $INC_i =~ s/[\\\/]+$// ;
      push(@inc_ok , $INC_i) if !$inc_ok{$INC_i}++ ;
    }
  }
  @INC = @inc_ok ;

  return ;
}

##############
# DEFINE_LIB #
##############

sub define_lib {
  my @find_lib = find_lib() ;
  
  $LIBZIP = find_file('lib.zip',@find_lib,'.') ;
  
  my $libtmp ;
  
  foreach my $find_lib_i ( @find_lib ) {
    if ($find_lib_i =~ /[\\\/]site$/i && $find_lib_i =~ /perl/) {
      my $tmp_lib = "$find_lib_i/libzip-tmp" ;
      if (! -d $tmp_lib) { mkdir($tmp_lib,0775) ;}
      if (-d $tmp_lib && -r $tmp_lib && -w $tmp_lib) { $libtmp = $tmp_lib ; last ;}
    }
  }
  
  if ($libtmp eq '') {
    foreach my $find_lib_i ( @find_lib ) {
      if ($find_lib_i =~ /[\\\/]lib$/i && $find_lib_i =~ /perl/) {
        my $tmp_lib = "$find_lib_i/libzip-tmp" ;
        if (! -d $tmp_lib) { mkdir($tmp_lib,0775) ;}
        if (-d $tmp_lib && -r $tmp_lib && -w $tmp_lib) { $libtmp = $tmp_lib ; last ;}
      }
    }
  }

  if ($libtmp eq '') {
    my $tmp = find_file('libzip-tmp',@find_lib,'.') ;
    if ( -d $tmp ) {
      $libtmp = $tmp ;
      $LIBTMPFIX = 1 ;
    }
  }

  if ($libtmp eq '') { $libtmp = new_tempdir('.') ;}
  
  $LIBTMP = $libtmp ;
  push(@INC , $LIBTMP) ;
  
  $FILETMP = "$LIBTMP/pm-$$-zip.tmp" ;
  open (FILETMP,">$FILETMP") ;
  
  ##print "DEFINED>> $LIBZIP >> $LIBTMP >>$^X\n" ;
  
}

###############
# NEW_TEMPDIR #
###############

sub new_tempdir {
  my ( $lib ) = @_ ;

  my $rand ;
  while(length($rand) < 4) { $rand .= $LYB[rand(@LYB)] ;}
  
  my $file = "$lib/libzip-$$-$rand-tmp" ;
  
  if (-e $file) { $file = &new_tempdir($_[0],1) ;}
  
  if (! $_[1]) {
    mkdir($file,0775) ;
    push(@DIRTMP , $file) ;
  }
  
  return( $file ) ;
}

############
# FIND_LIB #
############

sub find_lib {
  @INC_ORG = @INC if !@INC_ORG ;

  my @find_lib = @INC_ORG ;
  
  if ( $^X !~ /(?:^|[\\\/])perl(?:\.\w+)?$/i ) {
    my $exec_path = $^X ;  
    $exec_path =~ s/[\\\/]+[^\\\/]+$//gs ;
    $exec_path =~ s/[\\\/]+$// ;    
    $exec_path .= "/lib" ;
    push(@find_lib , $exec_path) if -d $exec_path ;
  }
  
  foreach my $find_lib_i ( @find_lib ) { $find_lib_i =~ s/[\\\/]+[^\\\/]+[\\\/]*$// ;}
  
  return @find_lib ;
}

#######
# END #
#######

sub end {
  foreach my $DIRTMP_i ( @DIRTMP ) { rmdir($DIRTMP_i) ;}
}

sub END { &end ;}

#######
# END #
#######

1;


