# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 14;
use Path::Class qw{file};

BEGIN { use_ok( 'GD::Graph::Cartesian' ); }


my $rgb=file(file($0)->dir => "rgb.txt");
my $obj = GD::Graph::Cartesian->new(width   => 106,
                                    height  => 108,
                                    borderx => 3,
                                    bordery => 4,
                                    rgbfile => $rgb);

isa_ok($obj, "GD::Graph::Cartesian");

can_ok($obj, qw{new initialize});
can_ok($obj, qw{width height});

foreach my $x (-33, 22, 11, -50, 50) {
  foreach my $y (55, -34, 56, 25, -44) {
    $obj->addPoint($x,$y);
  }
}
is($obj->width => 106);
is($obj->height => 108);
is($obj->_scaley(15), 15, "_scaley");
is($obj->_scalex(15), 15, "_scalex");
my($x,$y)=$obj->_imgxy_xy(5,7);
is($x,58, "_imgxy_xy -> x");
is($y,53, "_imgxy_xy -> y");
ok($obj->color([1,2,3]), "color");
is($obj->minx, -50, "minx");
is($obj->miny, -44, "miny");
SKIP: {
  eval q{use Graphics::ColorNames};
  skip "Graphics::ColorNames Not Installed", 1 if $@;
  ok($obj->color("blue"), "color");
}
