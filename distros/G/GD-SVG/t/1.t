# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 49;
BEGIN { use_ok('GD::SVG') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $image = GD::SVG::Image->new(100,100);
my $black = $image->colorAllocate(0,0,0);
my $polygon = GD::SVG::Polygon->new();

# object creation
ok(defined($image) && ref $image eq 'GD::SVG::Image','GD::SVG::Image-new() ok');
ok(defined($polygon) && ref $polygon eq 'GD::SVG::Polygon','GD::SVG::Polygon->new() ok');

# Color manipulation
ok(defined($black),'colorAllocate ok');
# colorDeallocate
ok(defined($image->colorExact(0,0,0)),'colorClosest ok');
ok($image->colorsTotal > 0,'colorsTotal ok');
# rgb()

# drawing
ok($image->setThickness(2),'setThickness ok');
ok($image->setPixel(10,10,$black),'setPixel ok');
ok($image->line(10,20,20,40,$black),'line ok');
ok($image->rectangle(10,20,20,40,$black),'rectangle ok');
ok($image->filledRectangle(10,20,20,40,$black),'filledRectangle ok');
ok($image->ellipse(10,20,20,40,$black),'ellipse ok');
ok($image->filledEllipse(10,20,20,40,$black),'filledEllipse ok');
ok($image->arc(10,20,20,40,0,360,$black),'arc (closed) ok');
ok($image->arc(10,20,20,40,40,360,$black),'arc (open) ok');
ok($image->filledArc(10,20,20,40,0,360,$black),'filledArc (closed) ok');
ok($image->filledArc(10,20,20,40,100,360,$black),'filledArc (open) ok');

# fill
# fillToBorder

# setBrush
my $brush = GD::SVG::Image->new(10,10);
my $red = $brush->colorAllocate(255,255,255);
my $white = $brush->colorAllocate(0,0,0);
ok($image->setBrush($brush),'setBrush ok');

ok($image->line(10,20,50,100,gdBrushed()),'drawing with gdBrushed ok');

# polygons
my $index = $polygon->addPt(30,30);
$polygon->addPt(0,0);
$polygon->addPt(0,10);
$polygon->addPt(10,10);
$polygon->addPt(10,0);
ok(defined($index),'addPt ok');
my ($x,$y) = $polygon->getPt($index);
ok(defined($x),'getPt ok');

my $new_index = $polygon->setPt($index,30,50);
ok(defined($new_index),'setPt ok');
my ($x2,$y2) = $polygon->deletePt($index);
ok(defined($y2),'deletePt ok');
ok($polygon->length > 0,'polygon length ok');
ok($polygon->vertices > 0,'vertices ok');
ok($image->polygon($polygon,$black),'create polygon ok');
ok($image->filledPolygon($polygon,$black),'create filledPolygon ok');

# Fonts
ok(GD::SVG::Font->Tiny > 0,'GD::SVG::Font->Tiny ok');
ok(gdTinyFont->width > 0,'gdTinyFont->width ok');
ok(gdTinyFont->height > 0,'gdTinyFont->height ok');
ok(GD::SVG::Font->Small > 0,'GD::SVG::Font->Small ok');
ok(gdSmallFont->width > 0,'gdSmallFont->width ok');
ok(gdSmallFont->height > 0,'gdSmallFont->height ok');
ok(GD::SVG::Font->MediumBold > 0,'GD::SVG::Font->MediumBold ok');
ok(gdMediumBoldFont->width > 0,'gdMediumBoldFont->width ok');
ok(gdMediumBoldFont->height > 0,'gdMediumBoldFont->height ok');
ok(GD::SVG::Font->Large > 0,'GD::SVG::Font->Large ok');
ok(gdLargeFont->width > 0,'gdLargeFont->width ok');
ok(gdLargeFont->height > 0,'gdLargeFont->height ok');
ok(GD::SVG::Font->Giant > 0,'GD::SVG::Font->Giant ok');
ok(gdGiantFont->width > 0,'gdGiantFont->width ok');
ok(gdGiantFont->height > 0,'gdGiantFont->height ok');
ok($image->string(gdMediumBoldFont,10,30,'test',$black) > 0,'string creation ok');
ok($image->string(GD::SVG::Font->Large,10,30,'test',$black) > 0,'string creation with oo-approach ok');
ok($image->stringUp(gdMediumBoldFont,10,30,'test',$black) > 0,'stringUp creation ok');
ok($image->char(gdMediumBoldFont,10,30,'test',$black) > 0,'char creation ok');
ok($image->charUp(gdMediumBoldFont,10,30,'test',$black) > 0,'charUp creation ok');
my ($width,$height) = $image->getBounds;
ok(defined($width),'getBounds ok');

my $svg = $image->svg;
ok(defined($svg),'svg output ok');
