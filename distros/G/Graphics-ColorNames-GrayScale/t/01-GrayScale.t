use Test;

BEGIN { plan tests => 4 + (8 * 256) + (1 * 101), todo => [ ] }

use strict;
use Carp;

use Graphics::ColorNames::GrayScale 2.00;
ok(1);


use Graphics::ColorNames 1.03, qw( hex2tuple tuple2hex );
ok(1);

tie my %colors, 'Graphics::ColorNames', 'GrayScale';
ok(1);

eval { keys %colors };
ok($!);

for my $i (0..255) {
  my $dec = sprintf('%03d',$i);
  my $hex = sprintf('%02x',$i);
  ok($colors{"gray$dec"} eq $colors{"gray$hex"});
  ok($colors{"grey$dec"} eq $colors{"gray$hex"});

  my $rgb = hex($colors{"gray$dec"});
  ok( ($rgb & 0xff0000 )== hex( $colors{"red$dec"} ) );
  ok( ($rgb & 0x00ff00 )== hex( $colors{"green$dec"} ) );
  ok( ($rgb & 0x0000ff )== hex( $colors{"blue$dec"} ) );
  ok( ($rgb & 0x00ffff )== hex( $colors{"cyan$dec"} ) );
  ok( ($rgb & 0xffff00 )== hex( $colors{"yellow$dec"} ) );
  ok( ($rgb & 0xff00ff )== hex( $colors{"purple$dec"} ) );
}

for my $i (0..100) {
  my $byte = sprintf('%03d', int($i / 100 * 255));
  ok($colors{"gray$byte"} eq $colors{"gray$i\%"});
}
