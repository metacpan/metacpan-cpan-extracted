# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 20;
use Path::Class qw{file};

BEGIN { use_ok( 'GD::Graph::Cartesian' ); }

my $rgb=file(file($0)->dir => "rgb.txt");
my $obj = GD::Graph::Cartesian->new(rgbfile => $rgb);

isa_ok($obj, "GD::Graph::Cartesian");
can_ok($obj, qw{new initialize});
can_ok($obj, qw{width height});

isa_ok($obj->color([0,0,0]), "ARRAY");
is_deeply($obj->color([0,0,0]), [0,0,0]);
is($obj->color("black"), "black");
ok(!ref($obj->color("black")), "black");

isa_ok($obj->color([255,255,255]), "ARRAY");
ok(!ref($obj->color("white")), "white");
is($obj->color("white"), "white");
is_deeply($obj->color([255,255,255]), [255,255,255]);

#these are pre-alocated on construction
my $white_index=$obj->_color_index([255,255,255]);
my $black_index=$obj->_color_index([0,0,0]);
my $red_index=$obj->_color_index([255,0,0]);
my $blue_index=$obj->_color_index([0,0,255]);

is($obj->_color_index("black"), $black_index, '$obj->_color_index black');
is($obj->_color_index("white"), $white_index, '$obj->_color_index white');

#these are new
is($obj->_color_index("blue"), $blue_index, '$obj->_color_index blue');
is($obj->_color_index("red"), $red_index, '$obj->_color_index red');

#these are cached
is($obj->_color_index([0,0,0]), $black_index, '$obj->_color_index black');
is($obj->_color_index([255,255,255]), $white_index, '$obj->_color_index white');
is($obj->_color_index([0,0,255]), $blue_index, '$obj->_color_index blue');
is($obj->_color_index([255,0,0]), $red_index, '$obj->_color_index red');

#use Data::Dumper qw{Dumper};
#diag Dumper $obj;
