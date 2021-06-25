use strict;
use warnings;
use Test::More tests => 11;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 11 unless $lib;

  require_ok 'Geo::H3::FFI';

  my $obj = Geo::H3::FFI->new;
  isa_ok($obj, 'Geo::H3::FFI');

  my $string = '8a2a1072b59ffff';
  my $index  = '622236750694711295';

  my $size   = 17;
  my $out    = "\000" x $size;
  is($index, '622236750694711295', 'index before');
  like($out, qr/\A\000{17}\Z/, 'out before');
  is($size, 17, 'size before');

  my $void1  = $obj->h3ToString($index, $out, $size);

  is($index, '622236750694711295', 'index after');
  {
    local $TODO = "I'm not sure why this is not being set to 15 by the API";
    is($size, 15, 'size after');
  }
  $out =~ s/\000+\Z//;
  is($out, '8a2a1072b59ffff', 'out after');
  is(length($out), 15, 'length($out)');
  is($out, sprintf("%x", $index), 'perl h3ToString');

  {
    my $output = $obj->h3ToStringWrapper($index);
    is($output, '8a2a1072b59ffff', 'h3ToStringWrapper');
  }
}
