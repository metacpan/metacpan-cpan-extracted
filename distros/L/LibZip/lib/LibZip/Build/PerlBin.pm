#############################################################################
## Name:        PerlBin.pm
## Purpose:     LibZip::Build::PerlBin
## Author:      Graciliano M. P.
## Modified by:
## Created:     2004-06-06
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package LibZip::Build::PerlBin ;
use 5.006 ;

use strict ;
use vars qw($VERSION) ;

$VERSION = '0.02' ;

use Config ;

use LibZip::CORE ;
use LibZip::Build::UPX ;
  
########
# VARS #
########

  my %opts = (
  type => 'def' ,
  ) ;
  
  my $size_mark       = '##[LBZZ]##' ;
  my $size_mark2      = '##[LBZS]##' ;
  my $allow_opts_mark = '##[LBZOPTS]###################' ;
  
  my $script_begin_mark = "\n##__LIBZIP-SCRIPT__##\n" ;
  
  my $LibZipBin_file = 'LibZipBin' . $Config{_exe} ;
  
#################
# FIND PERL BIN #
#################

my ($perlbin_dir , $LibZipBin) ;
{  
  my $perl_x = $^X ;
  $perl_x =~ s/\\/\//g ;
  ($perlbin_dir) = ( $perl_x =~ /^(.*?)\/*[^\/]+\/*$/g );
  
  if ( !-d $perlbin_dir) {
    my $inc_dir ;
    foreach my $INC_i ( @INC ) {
      if ($INC_i =~ /perl\/lib\/*$/i) { $inc_dir = $INC_i ; last ;}
    }
    ($perlbin_dir) = ( $inc_dir =~ /^(.*?\/*[^\/]+)\/+[^\/]+\/*$/g );
    $perlbin_dir .= '/bin'
  }

  my @dirs = ( "blib/arch" , $Config{installarchlib}, $Config{installsitearch} );

  foreach my $d ( @dirs ) {
    my $f = "$d/auto/LibZip/$LibZipBin_file" ;
    if( -s $f ) { $LibZipBin = $f ; last ;}
  }
  
}

  die "** Can't find LibZip binary!!!\n" if !-e $LibZipBin ;

############
# PERL2BIN #
############

sub perl2bin {
  my ( $script_file , $exe_name , %opts ) = @_ ;

  die "** Can't find script: $script_file\n" if !-e $script_file ;
  
  my ($script_dir , $filename) = ( $script_file =~ /^(.*?)[\\\/]*([^\\\/]+)$/s ) ;
  $script_dir ||= '.' ;
  
  if ( !$exe_name ) {
    $filename =~ s/\.\w+(?:\.pack)?$// ;
    $exe_name = $script_dir ? "$script_dir/$filename" : $filename ;
    $exe_name .= $Config{_exe} ;    
  }
  
  if (!$opts{overwrite} && -e $exe_name) {
    die "** New binary '$exe_name' already exists!\n" ;
  }
  
  my $binlog = cat($LibZipBin) ;
  die "** The Perl binary was not from LibZip: $LibZipBin\n" if $binlog !~ /\Q$size_mark\E/s ;
  
  if ( $opts{icon} ) {
    copy_file($LibZipBin,$exe_name) ;
    set_icon($exe_name , $opts{icon}) ;
    $binlog = cat($exe_name) ;
  }
  
  $binlog .= $script_begin_mark ;
  
  my $scriptlog = cat($script_file) ;  
  
  my $bin_lng = length($binlog) ;
  my $script_lng = length($scriptlog) ;
  
  my $size_var = $bin_lng ;
  while(length($size_var) < length($size_mark)) { $size_var = "0$size_var" ;}
  
  my $size_var2 = $script_lng ;
  while(length($size_var2) < length($size_mark2)) { $size_var2 = "0$size_var2" ;}

  $binlog =~ s/\Q$size_mark\E/$size_var/s ;
  $binlog =~ s/\Q$size_mark2\E/$size_var2/s ;
  
  if ( $opts{allowopts} ne '' ) {
    my $val = substr($opts{allowopts} , 0 , 30) ;
    while(length($val) < length($allow_opts_mark)) { $val .= '#' ;}
    $binlog =~ s/\Q$allow_opts_mark\E/$val/s ;
  }
  
  save($exe_name , $binlog . $scriptlog) ;
  
  if ($opts{gui}) {
    print "Converting to GUI...\n" ;
    exe_type($exe_name,'windows') ;
  }

  LibZip::Build::UPX::upx($exe_name) if $opts{upx} ;

  chmod(0755 , $exe_name) if !-x $exe_name ;

  check_perllib_copy($script_dir , $opts{upx}) ;
  
  my ($exe_dir) = ( $exe_name =~ /^(.*?)[\\\/]*[^\\\/]+$/s ) ;
  $exe_dir ||= '.' ;
  
  return( $exe_name , $exe_dir ) if wantarray ;
  return $exe_name ;
}

############
# SET_ICON #
############

sub set_icon {
  my ( $exe , $icon ) = @_ ;
  return if $^O ne 'MSWin32' ;
  
  eval {
    require Win32::Exe ;
    require Win32::Exe::IconFile ;
  };
  if ( $@ ) {
    warn "** Error loading Win32::Exe: $@\n" ;
  }
  
  my $win32exe = Win32::Exe->new($exe) ;
  if ( !$win32exe ) {
    warn "** Error using Win32::Exe: $@\n" ;
    return ;
  }
  eval {
    $win32exe->update(
    icon => $icon ,
    info => undef ,
    ) if -s $icon ;
  };
  if ( $@ ) {
    warn "** Error setting icon: $icon\n" ;
  }
  else {
    print "Icon set: $icon\n" ;
  }
}

############
# EXE_TYPE #
############

sub exe_type {
  my @ARGV = @_ ;

  my %subsys = (
  NATIVE => 1,
  WINDOWS => 2,
  CONSOLE => 3,
  POSIX => 7,
  WINDOWSCE => 9,
  );
  
  unless (0 < @ARGV && @ARGV < 3) {
    printf "Usage: $0 exefile [%s]\n", join '|', sort keys %subsys;
    exit;
  }
  
  $ARGV[1] = uc $ARGV[1] if $ARGV[1];
  unless (@ARGV == 1 || defined $subsys{$ARGV[1]}) {
    (my $subsys = join(', ', sort keys %subsys)) =~ s/, (\w+)$/ or $1/;
    print "Invalid subsystem $ARGV[1], please use $subsys\n";
    exit;
  }
  
  my ($record,$magic,$signature,$offset,$size);
  open EXE, "+< $ARGV[0]" or die "Cannot open $ARGV[0]: $!\n";
  binmode EXE;

  read EXE, $record, 64;
  ($magic,$offset) = unpack "Sx58L", $record;
  
  die "$ARGV[0] is not an MSDOS executable file.\n" unless $magic == 0x5a4d ;

  seek EXE, $offset, 0;
  read EXE, $record, 4+20+2;
  ($signature,$size,$magic) = unpack "Lx16Sx2S", $record;
  
  die "PE header not found" unless $signature == 0x4550;
  
  die "Optional header is neither in NT32 nor in NT64 format" unless ($size == 224 && $magic == 0x10b) || ($size == 240 && $magic == 0x20b) ;

  seek EXE, $offset+4+20+68, 0;
  if (@ARGV == 1) {
    read EXE, $record, 2;
    my ($subsys) = unpack "S", $record;
    $subsys = {reverse %subsys}->{$subsys} || "UNKNOWN($subsys)";
    print "$ARGV[0] uses the $subsys subsystem.\n";
  }
  else {
    print EXE pack "S", $subsys{$ARGV[1]};
  }
  close EXE;
}


######################
# CHECK_PERLLIB_COPY #
######################

sub check_perllib_copy {
  my ( $script_dir , $to_upx ) = @_ ;
  
  my $perllib_cp ;
  
  opendir (DIRLOG, $script_dir);
  while (my $filename = readdir DIRLOG) {
    if ($filename =~ /^perl\d+\.(?:dll|so)$/i) { $perllib_cp = 1 ;}
  }
  closedir (DIRLOG);
  
  if (! $perllib_cp) {
    opendir (DIRLOG, $perlbin_dir);
    while (my $filename = readdir DIRLOG) {
      if ($filename =~ /^perl\d+\.(?:dll|so)$/i) {
        my $new_file = "$script_dir/$filename" ;
        warn "PERLLIB saved at $new_file\n" ;
        copy_file("$perlbin_dir/$filename",$new_file) ;
        LibZip::Build::UPX::upx($new_file) if $to_upx ;
      }
    }
    closedir (DIRLOG);
  }
  
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
  

