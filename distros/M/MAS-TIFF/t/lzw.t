use strict;
use warnings;

use MAS::TIFF::Compression::LZW;

BEGIN {
  print "1..3\n";
}

#my @codes9 = (256, 7, 258, 8, 8, 258, 6, 6, 257);
#my @binary9 = qw(100000000 000000111 100000010 000001000 000001000 100000010 000000110 000000110 100000001);
#my @binary8 = qw(10000000 00000001 11100000 01000000 10000000 01000100 00001000 00001100 00000110 10000000 10000000);
#my $bytes = "\x80\x01\xe0\x40\x80\x44\x08\x0c\x06\x80\x80";
#
#my $decoded = MAS::TIFF::Compression::LZW::decode($bytes);
#
#print "not " unless $decoded eq "\x07\x07\x07\x08\x08\x07\x07\x06\x06";
#print "ok 1\n";

{
  my $bytes = "\x07\x07\x07\x08\x08\x07\x07\x06\x06";
#  printf "Bytes: %s\n", unpack('H*', $bytes);

  my $encoded = MAS::TIFF::Compression::LZW::encode($bytes);
#  print "\n";
#  printf "Encoded: %s\n", unpack('H*', $encoded);

  my $decoded = MAS::TIFF::Compression::LZW::decode($encoded);
#  print "\n";
#  printf "Decoded: %s\n", unpack('H*', $decoded);

  print 'not ' unless $decoded eq $bytes;
  print "ok 1\n";
#  print "\n";
}

#####################################

{
  my $bytes = '';
  for (my $i = 0; $i < 256; ++$i) {
    $bytes .= chr($i) # x 3
  }
#  printf "Bytes: %s\n", unpack('H*', $bytes);

  my $encoded = MAS::TIFF::Compression::LZW::encode($bytes);
#  print "\n";
#  printf "Encoded: %s\n", unpack('H*', $encoded);

  my $decoded = MAS::TIFF::Compression::LZW::decode($encoded);
#  print "\n";
#  printf "Decoded: %s\n", unpack('H*', $decoded);

  print 'not ' unless $decoded eq $bytes;
  print "ok 2\n";
#  print "\n";
}

#####################################

{
  my $hex ="803fe0502780020d0784426150b864361d0f003fdfd038a4562d178c466351b8e4763d1f90451e11582c424d27944a6123d7e4865d2f984c6651b91c8a55379c4e61a02080fe673fa0506653581c967547a452004002fd0a9d4fa75120949aa556a8267ed42b55b9a492ad5fb05500e1f6fd72cd42a93fe8d61b65b6740c3f4facf738f5a6d76ebc5e672c7ba5f6455ebd607054724b3ee57ea8e03078bc64e802f7c44c6ed8dca656904dc8c732796ce6767442ccd162af8cf6974d4718dcf37a7d66b6700607da315aeda6d654030ccbf57b6de6f65407aecdb7dc3e24a40426a6c1367c5e67361fcbe7747a5118a383a7d7e9457add8ee7162ac0eef877ddff17976be4f37a74fe8f57b739ecf77c719f0f97d6f5f4fb7e6d9f8fd7f6aafe3fd00a750040502a528a901034149cc1105c1d03a2904c1f09b9f08c290ba1906c310da0f0d4390dc3d0fc2e8080";
  my $bytes = pack('H*', $hex);
#  print "\n";
#  printf "Bytes: %s\n", unpack('H*', $bytes);

  my $decoded = MAS::TIFF::Compression::LZW::decode($bytes);
#  print "\n";
#  printf "Decoded: %s\n", unpack('H*', $decoded);

  my $encoded = MAS::TIFF::Compression::LZW::encode($decoded);
#  print "\n";
#  printf "Encoded: %s\n", unpack('H*', $encoded);

  print 'not ' unless $encoded eq $bytes;
  print "ok 3\n";
#  print "\n";
}

exit 0;
