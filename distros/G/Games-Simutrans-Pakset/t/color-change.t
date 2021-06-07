# -*- mode: cperl -*-
use strict;
use Test::More;
use Games::Simutrans::Image;

use Mojo::File;

my $f;

is_deeply([Games::Simutrans::Image::mapcolor(3)->rgba], [96, 132, 167, 255], 'mapcolors retrived correctly');

# Use an image file located relative to this test script.
$f = Games::Simutrans::Image->new(file => Mojo::File->new($0)->
                                  sibling('test_files/player_colors.png'));
is (ref $f, 'Games::Simutrans::Image', 'Create object of correct type');

$f->read({save => 1});
is ($f->image->errstr, undef, 'Imager loaded image');
is ($f->height, 42, 'Loaded image correctly');
ok ($f->is_transparent == 0, 'Original image does not use PNG transparency');

is_deeply([$f->image->getpixel(x=>0,y=>20)->rgba], [231,255,255,255], 'original color');

################

is($f->tilesize, undef, 'Tile size not yet known');
is($f->guess_tilesize, undef, 'Tile size cannot be computed without knowing maximum grid coordinates');
$f->record_grid_coordinate(2,0);
$f->guess_tilesize;
is($f->tilesize, 32, 'Took a good guess at the tile size.');

my $subi = $f->subimage(1,0);
is ($subi->getwidth, 32, 'Extracted a subimage');
is ($subi->getheight, 32, 'Extracted a subimage');

is_deeply ([$subi->getpixel(x=>0, y=>0)->rgba], [76, 113, 145, 255], 'Extracted correct subimage');
is_deeply ([$subi->getpixel(x=>31,y=>0)->rgba], [116, 151, 189, 255], 'Extracted correct subimage');

################

$f->make_transparent;
ok ($f->is_transparent, 'Added PNG transparency');
is_deeply([$f->image->getpixel(x=>0,y=>20)->rgba], [0,0,0,0], 'Transparent color');

is_deeply([$f->image->getpixel(x=>0,y=>0)->rgba], [36,75,103,255], 'Original player color');
$f->change_from_player_colors({type => 'std', mapcolor => 141});
is_deeply([$f->image->getpixel(x=>0,y=>0)->rgba], [0,128,0,255], 'Changed player color to mapcolor');

is_deeply([$f->image->getpixel(x=>0,y=>32)->rgba], [123,88,3,255], 'Original alternate-player color');
is_deeply([$f->image->getpixel(x=>64,y=>32)->rgba], [198,180,8,255], 'Original alternate-player color');
$f->change_from_player_colors({type => 'alt', mapcolor => 191, offset => 4, levels => 4});
is_deeply([$f->image->getpixel(x=>0,y=>32)->rgba], [123,88,3,255], 'Level and offset parameters should not change colors outside range');
is_deeply([$f->image->getpixel(x=>64,y=>32)->rgba], [138,64,16,255], 'Alternate-player colors modified correctly');

done_testing;

1;
