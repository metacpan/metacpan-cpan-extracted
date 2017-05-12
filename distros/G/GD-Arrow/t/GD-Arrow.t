
use Test::More tests => 12;
BEGIN { use_ok('GD::Arrow') };

use GD;

my $width = 6;
my ($x1, $y1) = (100, 10);
my ($x2, $y2) = (100, 190);
my ($x3, $y3) = (10, 30);
my ($x4, $y4) = (190, 75);
my ($x5, $y5) = (10, 80);
my ($x6, $y6) = (190, 155);

my $arrow = GD::Arrow::Full->new( 
                -X1    => $x1, 
                -Y1    => $y1, 
                -X2    => $x2, 
                -Y2    => $y2, 
                -WIDTH => $width,
            );

isa_ok( $arrow, 'GD::Arrow::Full' );

my $image = GD::Image->new(200, 200);
my $white = $image->colorAllocate(255, 255, 255);
my $black = $image->colorAllocate(0, 0, 0);
my $blue = $image->colorAllocate(0, 0, 255);
my $yellow = $image->colorAllocate(255, 255, 0);
my $red = $image->colorAllocate(255, 0, 0);
my $green = $image->colorAllocate(0, 255, 0);
$image->transparent($white);

$image->filledPolygon($arrow,$blue);
$image->polygon($arrow,$black);

my $half_arrow_1 = GD::Arrow::RightHalf->new( 
                       -X1    => $x3, 
                       -Y1    => $y3, 
                       -X2    => $x4, 
                       -Y2    => $y4, 
                       -WIDTH => $width,
                   );

my $half_arrow_2 = GD::Arrow::RightHalf->new( 
                       -X1 => $x4, 
                       -Y1 => $y4, 
                       -X2 => $x3, 
                       -Y2 => $y3, 
                       -WIDTH => $width
                   );

isa_ok( $half_arrow_1, 'GD::Arrow' );
isa_ok( $half_arrow_2, 'GD::Arrow' );

$image->filledPolygon($half_arrow_1,$blue);
$image->polygon($half_arrow_1,$black);

$image->filledPolygon($half_arrow_2,$yellow);
$image->polygon($half_arrow_2,$black);

my $half_arrow_3 = GD::Arrow::LeftHalf->new( 
                       -X1    => $x5, 
                       -Y1    => $y5, 
                       -X2    => $x6, 
                       -Y2    => $y6, 
                       -WIDTH => $width,
                   );

my $half_arrow_4 = GD::Arrow::LeftHalf->new( 
                       -X1 => $x6, 
                       -Y1 => $y6, 
                       -X2 => $x5, 
                       -Y2 => $y5, 
                       -WIDTH => $width
                   );

isa_ok( $half_arrow_3, 'GD::Arrow' );
isa_ok( $half_arrow_4, 'GD::Arrow' );

$image->filledPolygon($half_arrow_3,$red);
$image->polygon($half_arrow_3,$black);

$image->filledPolygon($half_arrow_4,$green);
$image->polygon($half_arrow_4,$black);

open IMAGE, "> image.png" or die $!;
binmode(IMAGE, ":raw");
print IMAGE $image->png;
close IMAGE;

ok( -e "image.png", "image.png was created" );

is( $arrow->width, $width, "Arrow width is $width." );
is( $arrow->x1, $x1, "X1 is $x1" );
is( $arrow->y1, $y1, "Y1 is $y1" );
is( $arrow->x2, $x2, "X2 is $x2" );
is( $arrow->y2, $y2, "Y2 is $y2" );

unlink("image.png");

exit(0);

