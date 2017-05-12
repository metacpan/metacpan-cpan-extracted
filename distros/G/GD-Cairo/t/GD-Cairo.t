# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GD-Cairo.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use GD;
use GD::Cairo qw();
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my( $w, $h ) = (400, 700 );

my $gd_cairo = GD::Cairo->new( $w, $h, 1 );
draw_stuff( $gd_cairo );

my $gd_image = GD::Image->new( $w, $h, 1 );
draw_stuff( $gd_image );

my $img = GD::Image->new( $w*2+1, $h, 1 );

my $white = $img->colorAllocate( 255, 255, 255 );
$img->fill(0,0,$white);

$img->setBrush( $gd_image );
$img->setPixel($w/2,$h/2,gdBrushed);

my $cairo_brush = GD::Image->newFromPngData($gd_cairo->png, 1);
$img->setBrush( $cairo_brush );
$img->setPixel($w/2*3+1,$h/2,gdBrushed);

open(my $fh, ">", "examples/rectangle.png") or die $!;
binmode($fh);
print $fh $img->png;
close($fh);

$gd_cairo->writePdf( "examples/test.pdf" );
$gd_cairo->writeSvg( "examples/test.svg" );

ok(1);

sub draw_stuff
{
	my( $img ) = @_;

	my $white = $img->colorAllocate( 255, 255, 255 );
	my $black = $img->colorAllocate( 0, 0, 0 );
	my $red = $img->colorAllocate( 255, 0, 0 );
	my $blue = $img->colorAllocate( 0, 0, 255 );

	$img->fill(0,0,$white);

	$img->rectangle( 0, 0, $w-1, $h-1, $black );

	$img->rectangle( 25, 25, 75, 75, $black );
	$img->arc( 50, 50, 50, 100, 0, 225, $black );
	$img->line( 10, 10, 30, 40, $red );

	$img->line( 4, 1, 4, 10, $black );
	$img->line( 1, 4, 10, 4, $black );
	$img->setPixel( 5, 5, $red );

	$img->rectangle( 25, 100, 75, 150, $black );
	$img->fill(26, 101, $red );

	$img->ellipse( 50, 175, 50, 50, $red );
	$img->fill( 50, 175, $black );

	$img->filledRectangle( 25, 200, 75, 250, $red );

	$img->filledArc( 150, 50, 50, 75, 90, 225, $black, gdArc );
	$img->filledArc( 150, 125, 50, 75, 90, 225, $black, gdChord );
	$img->filledArc( 150, 200, 50, 75, 90, 225, $black, gdEdged );
	$img->filledArc( 200, 250, 50, 75, 90, 225, $black, gdEdged|gdNoFill );

	$img->filledArc( 200, 50, 50, 75, 225, 360, $black, gdArc );
	$img->filledArc( 200, 125, 50, 75, 225, 360, $black, gdChord );
	$img->filledArc( 200, 200, 50, 75, 225, 360, $black, gdEdged );
	$img->filledArc( 200, 250, 50, 75, 225, 360, $black, gdEdged|gdNoFill );

	$img->setAntiAliased( $black );
	my $i = 0;
	for(qw(openPolygon unclosedPolygon filledPolygon))
	{
		my $poly = GD::Polygon->new;
		$poly->addPt( 275, 25 + $i * 100);
		$poly->addPt( 300, 50 + $i * 100);
		$poly->addPt( 280, 80 + $i * 100);
		$poly->addPt( 250, 80 + $i * 100);

		$img->$_( $poly, gdAntiAliased );
		
		$i++;
	}

	my @bounds = $img->stringFT( $black, 'examples/Vera.ttf', 12, 0, 50, 350, 'Foxy Doggy' );
	$img->line( 40, 350, 200, 350, $red );
	$img->line( 50, 300, 50, 400, $red );
	my $poly = GD::Polygon->new;
	$poly->addPt( splice(@bounds,0,2) ) while @bounds;
	$img->openPolygon( $poly, $blue );

	@bounds = $img->stringFT( $black, 'examples/Vera.ttf', 12, 3.14159265358979323846, 100, 400, 'Hello World' );
	$poly = GD::Polygon->new;
	$poly->addPt( splice(@bounds,0,2) ) while @bounds;
	$img->openPolygon( $poly, $blue );

	@bounds = $img->stringFT( $black, 'examples/Vera.ttf', 12, 3.14159265358979323846/4, 200, 400, 'Hello World' );
	$poly = GD::Polygon->new;
	$poly->addPt( splice(@bounds,0,2) ) while @bounds;
	$img->openPolygon( $poly, $blue );

	$i = 0;
	for(qw( gdSmallFont gdMediumBoldFont gdTinyFont gdLargeFont gdGiantFont ))
	{
		$img->string( &$_, 50, 450 + $i * 20, $_, $black );
		$img->line( 40, 450 + $i * 20, 200, 450 + $i * 20, $red );
		$img->line( 40, 450 + $i * 20 + &$_->height, 200, 450 + $i * 20 + &$_->height, $blue );
		$img->line( 50, 440 + $i * 20, 50, 480 + $i * 20, $red );
		$img->line( 50 + &$_->width * length($_), 440 + $i * 20, 50 + &$_->width * length($_), 480 + $i * 20, $red );
		$i++;
	}

	$img->stringUp( gdSmallFont, 230, 550, 'gdSmallFont', $black );
	$img->line( 230, 500, 230, 570, $red );
	$img->line( 230, 550, 250, 550, $red );

	$img->char( gdSmallFont, 220, 550, 'C', $black );

	my $brush = GD::Image->new( 20, 20 );
	my $bgrey = $brush->colorAllocate( 127,127,127 );
	my $bwhite = $brush->colorAllocate( 255,255,255 );
	my $bred = $brush->colorAllocate( 255,0,0 );
	$brush->fill(0,0,$bgrey);
	$brush->filledRectangle( 0,0,10,20,$bred );

	$img->setBrush( $brush );
	$img->line( 10, 600, 20, 610, gdBrushed );
	$img->line( 20, 610, 30, 600, gdBrushed );

	$img->filledRectangle( 40, 580, 100, 610, gdBrushed );

	$img->copy( $brush, 10, 620, 5, 5, 10, 10 );
	$img->rectangle( 10, 620, 20, 630, $black );

	$img->copyResized( $brush, 30, 620, 5, 5, 20, 15, 10, 10 );
	$img->rectangle( 30, 620, 50, 635, $black );

	$img->copyRotated( $brush, 75, 635, 5, 5, 10, 10, 45 );
	$img->rectangle( 60, 620, 80, 635, $black );

	$img->setPixel( 15, 645, gdBrushed );

	$img->string( gdSmallFont, 5, 570, 'Brush', $black );

	$img->setStyle( $black, $black, $black, gdTransparent, gdTransparent, $red, $red, $red, gdTransparent, gdTransparent );
	$img->setThickness( 20 );
	$img->line( 150, 620, 200, 620, gdStyled );
	$img->line( 210, 580, 210, 640, gdStyled );
	$img->setThickness( 1 );
	$img->line( 220, 620, 250, 620, gdStyled );
	$img->line( 251, 580, 251, 640, gdStyled );
	$img->string( gdSmallFont, 125, 590, 'Dashed Line', $black );

	my $blue_filter = $img->colorAllocateAlpha( 0,0,255,100 );
	for(0..5)
	{
		$img->filledRectangle( 50 + $_*50, 660, 75 + (5-$_)*50, 680, $blue_filter );
	}
	$img->string( gdSmallFont, 60, 662, 'Alpha', $black );
}
