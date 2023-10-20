#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

eval "use Digest::MD5 qw(md5_hex)";

plan skip_all => "Skipping tests: Digest::MD5 not available!" if $@;

plan tests => 18;

use Image::Square;

# Create horizontal image
my $horizontal = GD::Image->new(160, 90, 1);
my $red = $horizontal->colorAllocate(255,0,0);
$horizontal->rectangle(10, 10, 150, 80, $red);
$horizontal->fill(50, 50, $red);

# Create vertical image
my $vertical = GD::Image->new(200, 500, 1);
$vertical->rectangle(10, 10, 190, 490, $red);
$vertical->fill(50, 50, $red);

my $h_square = Image::Square->new($horizontal);
my $v_square = Image::Square->new($vertical);

ok ($h_square, 'Horizontal instantiation');
ok ($v_square, 'Vertical   instantiation');

my $square1 = $h_square->square();
my $square2 = $h_square->square(100);
my $square3 = $h_square->square(125, 0);
my $square4 = $h_square->square(150, 1);

diag ( 'Testing horizontal image' );

cmp_ok ( $square1->width, '==', $square1->height, 'Square 1 is square');
cmp_ok ( $square1->width, '==', 90, 'Square 1 is 90px');

cmp_ok ( $square2->width, '==', $square2->height, 'Square 2 is square');
cmp_ok ( $square2->width, '==', 100, 'Square 2 is 100px');

cmp_ok ( $square3->width, '==', $square3->height, 'Square 3 is square');
cmp_ok ( $square3->width, '==', 125, 'Square 3 is 125px');

cmp_ok ( $square4->width, '==', $square4->height, 'Square 4 is square');
cmp_ok ( $square4->width, '==', 150, 'Square 4 is 150px');

my $square5 = $v_square->square();
my $square6 = $v_square->square(80);
my $square7 = $v_square->square(110, 0);
my $square8 = $v_square->square(175, 1);

diag ( 'Testing vertical image' );

cmp_ok ( $square5->width, '==', $square5->height, 'Square 5 is square');
cmp_ok ( $square5->width, '==', 200, 'Square 5 is 200px');

cmp_ok ( $square6->width, '==', $square6->height, 'Square 6 is square');
cmp_ok ( $square6->width, '==', 80, 'Square 6 is 80px');

cmp_ok ( $square7->width, '==', $square7->height, 'Square 7 is square');
cmp_ok ( $square7->width, '==', 110, 'Square 7 is 1110px');

cmp_ok ( $square8->width, '==', $square8->height, 'Square 8 is square');
cmp_ok ( $square8->width, '==', 175, 'Square 8 is 175px');

done_testing;



