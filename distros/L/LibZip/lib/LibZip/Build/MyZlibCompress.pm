#############################################################################
## Name:        MyZlibCompress.pm
## Purpose:     LibZip::Build::MyZlibCompress
## Author:      Graciliano M. P.
## Modified by:
## Created:     2004-06-06
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
##
## This module will compress unsing Compress::Zlib and will be able to
## decompress this data with Compress::Zlib::Perl (pure Perl).
##
#############################################################################

package LibZip::Build::MyZlibCompress ;
use 5.006 ;

use strict qw(vars) ;
use vars qw($VERSION) ;

$VERSION = '0.01' ;

use LibZip::CORE ;

use Compress::Zlib ;
use MIME::Base64 qw() ;
use LibZip::MyFile ;

########
# VARS #
########
  
  my $BLK_SIZE = 1024 * 250 ;

my $RE_FIXBIN_OK ;
{
  my $qr_ok ;
  my @ok = ( 9 , (32..91) , (93..95) , (97..126) , 128 , (130..137) , (139..140) , 142 , (145..156) , (158..159) , (161..172) , (174..255)) ;
  
  foreach my $ok_i ( @ok ) {
    my $s = pack("C", $ok_i ) ;
    my $re = qr/\Q$s\E/ ;
    if ( $re =~ /xism:\\/ ) { $s = "\\" . $s ;}
    $qr_ok .= $s ;
  }
  
  $RE_FIXBIN_OK = qr/[^$qr_ok]/s ;
}

##########
# MY_TAR #
##########

sub my_tar {
  my ( %files ) = @_ ;
  
  my $tar ;
  
  foreach my $file (sort keys %files ) {
    my $name = $files{$file} || $file ;
    $name =~ s/^[\\\/]+// ;
    my $comp = my_compress( cat($file) ) ;
    $tar .= pack("V", length($name) ) . $name ;
    $tar .= pack("V", length($comp) ) . $comp ;
  }
  
  return $tar ;
}

############
# MY_UNTAR #
############

sub my_untar {
  my ( $tar_file ) = @_ ;

  my $tar = (length($tar_file) < 1024*4 && -e $tar_file) ? cat($tar_file) : $tar_file ;
  my $lng = length($tar) ;

  my %files ;
  my ( $sz , $name ) ;
  for(my $i = 0 ; $i < $lng ;) {
    $sz = unpack("V", substr($tar , $i , 4) ) ; $i += 4 ;
    $name = substr($tar , $i , $sz) ; $i += $sz ;
    $sz = unpack("V", substr($tar , $i , 4) ) ; $i += 4 ;
    $files{$name} = my_uncompress( split_bloks( substr($tar , $i , $sz) ) ) ; $i += $sz ;
  }
  
  return \%files ;
}

################
# MY_SAVE_TREE #
################

sub my_save_tree {
  my $dir = shift ;
  my $tree = shift ;
  
  LibZip::File::Path::mkpath($dir) if ( !-d $dir );
  
  foreach my $Key (sort keys %$tree ) {
    my $name = "$dir/$Key" ;
    my ( $volumeName, $dirName, $fileName ) = LibZip::File::Spec->splitpath($name) ;
    $dirName = LibZip::File::Spec->catpath( $volumeName, $dirName, '' ) ;
    LibZip::File::Path::mkpath($dirName) if ( !-d $dirName ) ;
    save($name , $$tree{$Key}) ;
  }
}

###############
# MY_COMPRESS #
###############

sub my_compress {
  my ( $data ) = @_ ;
  my @compressed ;
  my $sizes ;
  
  my $lng = length($data)  ;
  
  for(my $i = 0 ; $i < $lng ; $i += $BLK_SIZE ) {
    my ($d, $status) = deflateInit( -WindowBits => MAX_WBITS ) ;
    my $blk = substr($data , $i , $BLK_SIZE) ; ## need to copy first.
    $d->deflate($blk) ;
    my ($out2, $status2) = $d->flush() ;
    push(@compressed , $out2) ;
    $sizes .= pack("V", length($out2) ) ;
  }
  
  my $size_blk ;
  {
    my ($d, $status) = deflateInit( -WindowBits => MAX_WBITS ) ;
    $d->deflate($sizes) ;
    my ($out2, $status2) = $d->flush() ;
    $size_blk = pack("V", length($out2) ) . $out2 ;
  }
  
  return (join('',$size_blk,@compressed) , @compressed ) if wantarray ;
  return join('',$size_blk,@compressed) ;
}

#################
# MY_UNCOMPRESS #
#################

sub my_uncompress {
  my ( @blks ) = @_ ;

  my $uncompressed ;
  
  foreach my $blks_i ( @blks ) {
    my ($d, $status) = inflateInit( -WindowBits => - MAX_WBITS ) ;
    my ($out, $status) = $d->inflate($blks_i) ;
    $uncompressed .= $out ;
  }
  
  return $uncompressed ;
}

###############
# SPLIT_BLOKS #
###############

sub split_bloks {
  my $sz_blk_size = unpack("V", substr($_[0] , 0 , 4) ) ;
  my $blk_size = substr($_[0] , 4 , $sz_blk_size) ;
  
  my $total = 4 + $sz_blk_size ;
  
  $blk_size = my_uncompress($blk_size) ;
  
  my (@sizes) = ( $blk_size =~ /(....)/gs );

  my $i = $sz_blk_size + 4 ;
  
  my @blks ;
  foreach my $sizes_i ( @sizes ) {
    $sizes_i = unpack("V", $sizes_i ) ;
    push(@blks , substr($_[0] , $i , $sizes_i) ) ;
    $i += $sizes_i ;
  }

  return @blks ;
}

##############
# FIX_BINARY #
##############

sub fix_binary {
  $_[0] =~ s/($RE_FIXBIN_OK)/ my $n = unpack("C", $1) ; "\n$n\n" /ges ;
  return $_[0] ;
}

################
# UNFIX_BINARY #
################

sub unfix_binary {
  $_[0] =~ s/\n(\d+)\n/ pack("C", $1) /ges ;
  return $_[0] ;
}

#######################
# MY_UNCOMPRESS_SPLIT #
#######################

sub my_uncompress_split { return my_uncompress( split_bloks(@_) ) ;}

#############
# FIXBINARY #
#############

sub my_compress_fixbin { return fix_binary( my_compress($_[0]) ) ;}
sub my_uncompress_fixbin { return my_uncompress( split_bloks( unfix_binary($_[0]) ) ) ;}

sub my_tar_fixbin { return fix_binary( my_tar(@_) ) ;}
sub my_untar_fixbin { return my_untar( unfix_binary($_[0]) ) ;}

##########
# BASE64 #
##########

sub my_compress_base64 { return MIME::Base64::encode_base64( my_compress($_[0]) ) ;}
sub my_uncompress_base64 { return my_uncompress( split_bloks( MIME::Base64::decode_base64($_[0]) ) ) ;}

sub my_tar_base64 { return MIME::Base64::encode_base64( my_tar(@_) ) ;}
sub my_untar_base64 { return my_untar( MIME::Base64::decode_base64($_[0]) ) ;}

#######
# END #
#######

1;


