use lib "../lib";
use Image::Magick::Thumbnail;

my $src = new Image::Magick;
$src->Read('../t/source.jpg');

my ($thumb, $x, $y) = Image::Magick::Thumbnail::create($src,50);

$thumb->Write('source_thumb.jpg');

my ($thumb2, $x2, $y2) = Image::Magick::Thumbnail::create($src,'60x50');
