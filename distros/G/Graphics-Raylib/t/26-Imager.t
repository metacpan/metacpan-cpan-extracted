use Test::Needs 'Imager';
use Test::More;
use strict;
use warnings;

use Graphics::Raylib '+family';
use Imager;

my $g = Graphics::Raylib->window(100, 100);
plan skip_all => 'No graphic device' if !$g or defined $ENV{NO_GRAPHICAL_TEST} or defined $ENV{NO_GRAPHICAL_TESTS};

$g->fps(30);
my $imager = Imager->new(xsize => 100, ysize => 100);

$imager->box(xmin => 0, ymin => 0, xmax => 99, ymax => 99,
    filled => 1, color => 'blue');
$imager->box(xmin => 20, ymin => 20, xmax => 79, ymax => 79,
    filled => 1, color => 'green');

my $img = Graphics::Raylib::Texture->new( imager => $imager, fullscreen => 1 );

my $i = 0;
while (!$g->exiting && $i++ < 30) {
    Graphics::Raylib::draws $img;
}
ok 1;
done_testing
