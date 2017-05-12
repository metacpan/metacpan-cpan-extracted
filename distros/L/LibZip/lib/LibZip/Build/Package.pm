#############################################################################
## Name:        Package.pm
## Purpose:     LibZip::Build::Package
## Author:      Graciliano M. P.
## Modified by:
## Created:     2004-06-06
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package LibZip::Build::Package ;
use 5.006 ;

use strict qw(vars) ;
use vars qw($VERSION) ;

$VERSION = '0.01' ;

BEGIN { $LibZip::MyZlib::NO_BOOT = 1 ;}

require LibZip ;
use LibZip::Build::PodStripper ;
use LibZip::Build::MyZlibCompress ;
use LibZip::Build::LZW ;
use LibZip::Build::CreateLib ;
use LibZip::Build::UPX ;

########
# VARS #
########

my @INCLUDE_PACKS = qw(
strict.pm
warnings.pm
) ;

my @LIBZIP_ORDER = qw(
LibZip/CORE.pm
LibZip/InitLib.pm
LibZip/MyZlib.pm

LibZip/DynaLoader.pm
LibZip/MyFile.pm
LibZip/MyArchZip.pm
LibZip.pm
) ;

my $POD_Stripper = new LibZip::Build::PodStripper() ;

##########
# SOURCE #
##########

sub source {
  my ( $main_script , %opts ) = @_ ;
  
  my ($begin , $extra_begin , $extra , $libzip , $zlib) ;

  my $re_libzip = qr/^LibZip\W/ ;
  my $re_libzip_build = qr/^LibZip\/Build\W/ ;
  
  my $incs = join "|" , map { "\Q$_\E" } @INCLUDE_PACKS ;
  my $re_incs = qr/^(?:$incs)$/ ;
  
  my $re_inc = qr/(?:$re_incs|$re_libzip)/s ;

  my %included ;

  foreach my $Key ( @INCLUDE_PACKS , @LIBZIP_ORDER , sort keys %INC ) {
    next if $included{$Key} || $Key !~ /$re_inc/ || $Key =~ /$re_libzip_build/ ;
    $included{$Key} = 1 ;
    
    ##print ">> $Key\n" ;

    if ( $Key =~ /(?:CORE|InitLib|MyZlib)/ ) {
      my $mod = cat($INC{$Key}) ;
      clean_src($mod) ;
      $zlib .= "BEGIN {\n#line 1 $Key\n$mod}\n" ;
    }
    else {
      my $mod = cat($INC{$Key}) ;
      
      if ( $Key =~ /$re_libzip/ ) {
        clean_src($mod) ;
        $mod = "BEGIN {\n#line 1 $Key\n$mod}\n" ;
        $libzip .= $mod ;
        $begin .= "\$INC{'$Key'} = 1 ; " ;
      }
      else {
        $extra_begin .= "\$INC{'$Key'} = 1 ; " ;
        if ( $Key =~ /^(?:strict\.pm|warnings\.pm)$/ ) {
          clean_src($mod) ;
          $mod = "BEGIN {\n$mod}\n" ;
        }
        else {
          $mod = "\n#line 1 $Key\n" . $mod ;
        }
        $extra .= $mod ;
      }
    }
  }
  

  ##################################
  
  $libzip = "package main ; BEGIN { $begin }\n$libzip" ;

  $extra = "package main ; BEGIN { \$SIG{__WARN__}=sub{}; $extra_begin }\n". src_Carp() . $extra ;
  $extra .= "\npackage main ; no strict ; no warnings ;" ;

  my $src_zlib = "$extra\n$zlib" ;
  
  ##print "$libzip\n" ;

  my $src_init = src_INIT($libzip) ;
  
  ##################################

  my $src_main = cat($main_script , 1) ;
  
  my $src = "BEGIN{$src_zlib$src_init}\nreturn if \$LibZip::ONLY_INIT;\n#line 1 main\n$src_main" ;
  
  my $size_unpacked = get_size_unpacked($src_zlib , $libzip , $src_main) ;
  
  print "PACKAGE: size unpacked: $size_unpacked\n" ;
  
  if ( $opts{lzw} ) {
    print "Applying LZW... " ;
    $src = src_LZW($src) ;  
    print "OK\n" ;
  }
  
  print "PACKAGE: size packed:   ". length($src) ."\n" ;
  
  return $src ;  
}

#####################
# GET_SIZE_UNPACKED #
#####################

sub get_size_unpacked {
  my ($src_zlib , $libzip , $src_main) = @_ ;
  
  my $size += length(src_INIT()) +  length($src_zlib) + length($libzip) + length($src_main) ;
    
  return( $size ) ;
}

#############
# CLEAN_SRC #
#############

sub clean_src {
  $_[0] =~ s/(?:^|[\r\n])[ \t]*#[^\r\n]*//gs ;
  $_[0] =~ s/\n+/\n/gs ;
  $_[0] =~ s/\n[ \t]+/\n/gs ;
  $_[0] =~ s/[ \t]+\n/\n/gs ;
  $_[0] =~ s/\n+/\n/gs ;
  return $_[0] ;
}

#######
# CAT #
#######

sub cat {
  if ( !$_[1] ) {
    my $src = $POD_Stripper->parse($_[0]) ;
    $src =~ s/\r\n?/\n/gs ;
    $src =~ s/^\s+//s ;
    $src =~ s/\s*$/\n/s ;
    $src =~ s/\n__(?:END|DATA)__//gs ;
    return $src ;
  }
  else {
    my ($fh , $buffer) ;
    open ($fh,$_[0]) ; binmode($fh) ;
    1 while( read($fh, $buffer , 1024*4 , length($buffer) ) ) ;
    close ($fh) ;
    return $buffer ;
  }
}

############
# SRC_CARP #
############

sub src_Carp {

return q`{package Carp;
BEGIN { $INC{'Carp.pm'} = 1 if !$INC{'Carp.pm'} ;}
$CarpLevel = 0;
$MaxEvalLen = 0;
$MaxArgLen = 64;
$MaxArgNums = 8;
$Verbose = 0;
sub import {
shift ;
my $caller = caller ;
my @EXPORT = qw(confess croak carp);
my @EXPORT_OK = qw(cluck verbose);
my @exp = @_ ;
if ( !@_ ) { @exp = @EXPORT ;}
foreach my $exp_i ( @exp ) { *{"$caller\::$exp_i"} = \&{$exp_i} ;}
}
sub export_fail {
shift;
$Verbose = shift if $_[0] eq 'verbose';
return @_;
}
sub longmess {}
sub shortmess {}
sub croak   { die  shortmess @_ }
sub confess { die  longmess  @_ }
sub carp    { warn shortmess @_ }
sub cluck   { warn longmess  @_ }
1;
}
` ;

}

############
# SRC_INIT #
############

sub src_INIT {
  my ( $libzip ) = @_ ;

  if ( @_ ) {
    $libzip = LibZip::Build::MyZlibCompress::my_compress_base64($libzip) ;  
  }

return q`{package main ;
my $code = LibZip::MyZlib::tools::my_uncompress_base64(<<'__LIBZIP_MARK_DATA__');
`. $libzip .q`
__LIBZIP_MARK_DATA__
eval($code);
die "LibZip INIT ERROR: $@\n" if $@ ;
foreach my $Key ( keys %INC ) { delete $INC{$Key} if $INC{$Key} eq '1' && $Key !~ /^(?:LibZip\W[\w\/]*|DynaLoader|XSLoader)(?:\.pm)?$/ ;}
LibZip->import() ;
LibZip::InitLib::define_real_path() ;
$SIG{__WARN__}='';
}
` ;

}

###########
# SRC_LZW #
###########

sub src_LZW {
my $src = LibZip::Build::LZW::compress($_[0]) ;

return q`{package LibZip::LZW;
sub ul{my($s)=@_;my%d=(map{($_,chr$_)}0..255);my$n=256;my$r='';my($p,@c)=unpack('S*',$s);$r.=$d{$p};for(@c){if(exists $d{$_}){$r.=$d{$_};$d{$n++}=$d{$p}.substr($d{$_}, 0, 1);}else{my$dp=$d{$p};unless($_==$n++){warn"LZW ERROR!"};$r.=($d{$_}=$dp.substr($dp,0,1));}$p=$_;}$r;}
my$c=<<'__LZW__';
`. $src .q`
__LZW__
$c=~s/\n$//;
eval(ul($c));die($@)if$@;
}` ;

}

##############
# FIX_BINARY #
##############

sub fix_binary {
  $_[0] =~ s/([\x0a\x0d])/ my $n = unpack("C", $1) ; "\n" . tohex($n) /ges ;
  return $_[0] ;
}

################
# UNFIX_BINARY #
################

sub unfix_binary {
  $_[0] =~ s/\n(\w\w)/pack("C", hex($1))/ges ;
  return $_[0] ;
}

#########
# TOHEX #
#########

sub tohex {
  my ( $s ) = @_ ;
  my $hx = unpack("H", pack("C",$s) ) . unpack("h", pack("C",$s) ) ;
  return( $hx ) ;
}

#######
# END #
#######

1;


