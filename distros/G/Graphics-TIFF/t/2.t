use warnings;
use strict;
use Graphics::TIFF ':all';
use Test::More tests => 12;
use Test::Deep;
BEGIN { use_ok('Graphics::TIFF') }

#########################

like( Graphics::TIFF->GetVersion, qr/LIBTIFF, Version/, 'version string' );

my $version = Graphics::TIFF->get_version_scalar;
isnt $version, undef, 'version';

if ( $version < 4.000003 ) {
    plan skip_all => 'libtiff 4.0.3 or better required';
    exit;
}

ok( Graphics::TIFF->IsCODECConfigured(COMPRESSION_DEFLATE),
    'IsCODECConfigured' );

#########################

my $width        = 200;
my $height       = 200;
my $depth        = 1;
my $resolution   = 100;
my $bit_per_byte = 8;

# start with blank white image
my @buffer;
my $buffer_size = int( $width * $height / $bit_per_byte ) +
  ( $width * $height ) % $bit_per_byte;
for my $i ( 0 .. $buffer_size - 1 ) {
    $buffer[$i] = 0;
}
my $expected = pack "C*", @buffer;

# write TIFF
my $tif = Graphics::TIFF->Open( 'test.tif', 'w' );
$tif->SetField( TIFFTAG_IMAGEWIDTH,      $width );
$tif->SetField( TIFFTAG_IMAGELENGTH,     $height );
$tif->SetField( TIFFTAG_SAMPLESPERPIXEL, $depth );
$tif->SetField( TIFFTAG_BITSPERSAMPLE,   $depth );
$tif->SetField( TIFFTAG_XRESOLUTION,     $resolution );
$tif->SetField( TIFFTAG_YRESOLUTION,     $resolution );
$tif->SetField( TIFFTAG_PHOTOMETRIC,     PHOTOMETRIC_MINISWHITE );
$tif->WriteEncodedStrip( 0, $expected, length($expected) );
$tif->WriteDirectory;
$tif->Close;

# read TIFF
$tif = Graphics::TIFF->Open( 'test.tif', 'r' );
my $stripsize = $tif->StripSize;
my $example   = '';
for my $i ( 0 .. $tif->NumberOfStrips - 1 ) {
    $example .= $tif->ReadEncodedStrip( $i, $stripsize );
}

is( $example,                                $expected,   'buffer' );
is( $tif->GetField(TIFFTAG_IMAGEWIDTH),      $width,      'IMAGEWIDTH' );
is( $tif->GetField(TIFFTAG_IMAGELENGTH),     $height,     'IMAGELENGTH' );
is( $tif->GetField(TIFFTAG_SAMPLESPERPIXEL), $depth,      'SAMPLESPERPIXEL' );
is( $tif->GetField(TIFFTAG_BITSPERSAMPLE),   $depth,      'BITSPERSAMPLE' );
is( $tif->GetField(TIFFTAG_XRESOLUTION),     $resolution, 'XRESOLUTION' );
is( $tif->GetField(TIFFTAG_YRESOLUTION),     $resolution, 'YRESOLUTION' );
is( $tif->GetField(TIFFTAG_PHOTOMETRIC), PHOTOMETRIC_MINISWHITE,
    'PHOTOMETRIC' );
$tif->Close;

#########################

unlink 'test.tif';
