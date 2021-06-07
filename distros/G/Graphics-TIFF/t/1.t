use warnings;
use strict;
use Graphics::TIFF ':all';
use Test::More tests => 50;
use Test::Deep;
use IPC::Cmd qw(can_run);
use Test::Requires qw( Image::Magick );
use File::Temp;
use File::Spec;
use English;
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
my $directory = File::Temp->newdir;

my $image = Image::Magick->new;
my $file = File::Spec->catfile( $directory, 'test.tif' );
$image->Read('rose:');
$image->Set( density => '72x72' );
$image->Write($file);

my $tif = Graphics::TIFF->Open( $file, 'r' );
is( $tif->FileName, $file, 'FileName' );
isa_ok $tif, 'Graphics::TIFF';
can_ok $tif, qw(Close ReadDirectory ReadEXIFDirectory GetField);

is( $tif->ReadDirectory, 0, 'ReadDirectory' );

SKIP: {
    skip "Don't know how to create TIFF with EXIF on the fly, "
      . 'and reading an empty one crashes some implementations', 1;
    is( $tif->ReadEXIFDirectory(0), 0, 'ReadEXIFDirectory' );
}

is( $tif->NumberOfDirectories, 1, 'NumberOfDirectories' );

is( $tif->SetDirectory(0), 1, 'SetDirectory' );

is( $tif->SetSubDirectory(0), 0, 'SetSubDirectory' );

is( $tif->GetField(TIFFTAG_FILLORDER),   FILLORDER_MSB2LSB, 'GetField uint16' );
is( $tif->GetField(TIFFTAG_XRESOLUTION), 72,                'GetField float' );
my @counts = $tif->GetField(TIFFTAG_PAGENUMBER);
is_deeply( \@counts, [ 0, 1 ], 'GetField 2 uint16' );
@counts = $tif->GetField(TIFFTAG_STRIPBYTECOUNTS);
is_deeply( \@counts, [ 8190, 1470 ], 'GetField array of uint64' );
is( $tif->GetField(TIFFTAG_IMAGEWIDTH), 70, 'GetField uint32' );

@counts = $tif->GetField(TIFFTAG_PRIMARYCHROMATICITIES);
my @expected = (
    0.639999985694885, 0.330000013113022,
    0.300000011920929, 0.600000023841858,
    0.150000005960464, 0.0599999986588955
);
for my $i ( 0 .. $#expected ) {
    cmp_deeply(
        $counts[$i],
        num( $expected[$i], 0.0001 ),
        'GetField TIFFTAG_PRIMARYCHROMATICITIES (array of float)'
    );
}

@counts   = $tif->GetField(TIFFTAG_WHITEPOINT);
@expected = ( 0.312700003385544, 0.328999996185303 );
for my $i ( 0 .. $#expected ) {
    cmp_deeply(
        $counts[$i],
        num( $expected[$i], 0.0001 ),
        'GetField TIFFTAG_WHITEPOINT (array of float)'
    );
}

is( $tif->GetFieldDefaulted(TIFFTAG_FILLORDER),
    FILLORDER_MSB2LSB, 'GetFieldDefaulted uint16' );

is( $tif->SetField( TIFFTAG_FILLORDER, FILLORDER_LSB2MSB ),
    1, 'SetField status' );
is( $tif->GetField(TIFFTAG_FILLORDER), FILLORDER_LSB2MSB, 'SetField result' );
$tif->SetField( TIFFTAG_FILLORDER, FILLORDER_MSB2LSB );    # reset

is( $tif->IsTiled, 0, 'IsTiled' );

is( $tif->ScanlineSize, 210, 'ScanlineSize' );

is( $tif->StripSize, 8190, 'StripSize' );

is( $tif->NumberOfStrips, 2, 'NumberOfStrips' );

is( $tif->TileSize, 8190, 'TileSize' );

is( $tif->TileRowSize, 210, 'TileRowSize' );

is( $tif->ComputeStrip( 16, 0 ), 0, 'ComputeStrip' );

is( length( $tif->ReadEncodedStrip( 0, 8190 ) ),
    8190, 'ReadEncodedStrip full strip' );

is( length( $tif->ReadEncodedStrip( 1, 8190 ) ),
    1470, 'ReadEncodedStrip part strip' );

is( length( $tif->ReadRawStrip( 1, 20 ) ), 20, 'ReadRawStrip' );

my $filename = File::Spec->catfile( $directory, 'out.txt' );
open my $fh, '>', $filename;
$tif->PrintDirectory( $fh, 0 );
$tif->Close;
close $fh;
is( -s $filename, 449, 'PrintDirectory' );
unlink $filename;

#########################

SKIP: {
    skip 'tiffcmp not installed', 1 if ( not can_run('tiffcmp') );

    my $tif = Graphics::TIFF->Open( $file,  'r' );
    my $file2 = File::Spec->catfile($directory, 'test2.tif');
    my $out = Graphics::TIFF->Open( $file2, 'w' );
    for my $tag (
        ( TIFFTAG_IMAGEWIDTH, TIFFTAG_IMAGELENGTH,
            TIFFTAG_SAMPLESPERPIXEL, TIFFTAG_BITSPERSAMPLE,
            TIFFTAG_ORIENTATION,     TIFFTAG_PLANARCONFIG,
            TIFFTAG_PAGENUMBER,      TIFFTAG_PHOTOMETRIC,
            TIFFTAG_ROWSPERSTRIP,    TIFFTAG_FILLORDER,
            TIFFTAG_RESOLUTIONUNIT,  TIFFTAG_XRESOLUTION,
            TIFFTAG_YRESOLUTION
        )
      )
    {
        my @values = $tif->GetField($tag);
        $out->SetField( $tag, @values );
    }

    my $stripsize = $tif->StripSize;
    for my $stripnum ( 0 .. $tif->NumberOfStrips - 1 ) {
        my $buffer = $tif->ReadEncodedStrip( $stripnum, $stripsize );
        $out->WriteEncodedStrip( $stripnum, $buffer, length($buffer) );
    }
    $out->WriteDirectory;
    $tif->Close;
    $out->Close;

    is( `tiffcmp $file $file2`, '', 'tiffcmp' );
}

#########################

$image = Image::Magick->new;
$image->Read('rose:');
$image->Set( density => '72x72', alpha => 'Set' );
$image->Write($file);
$tif = Graphics::TIFF->Open( $file, 'r' );

my @values = $tif->GetField(TIFFTAG_EXTRASAMPLES);
is_deeply( \@values, [EXTRASAMPLE_UNASSALPHA],
    'GetField TIFFTAG_EXTRASAMPLES' );

@values = $tif->GetFieldDefaulted(TIFFTAG_EXTRASAMPLES);
is_deeply( \@values, [EXTRASAMPLE_UNASSALPHA],
    'GetFieldDefaulted TIFFTAG_EXTRASAMPLES' );

$tif->Close;

#########################

$image = Image::Magick->new;
$image->Read('rose:');
$image->Set( density => '72x72', type => 'palette', depth => 2 );
$image->Write($file);
$tif = Graphics::TIFF->Open( $file, 'r' );

@values = $tif->GetField(TIFFTAG_COLORMAP);
is $#{ $values[0] }, 255, 'GetField TIFFTAG_COLORMAP r';
is $#{ $values[1] }, 255, 'GetField TIFFTAG_COLORMAP g';
is $#{ $values[2] }, 255, 'GetField TIFFTAG_COLORMAP b';

@values = $tif->GetFieldDefaulted(TIFFTAG_COLORMAP);
is $#{ $values[0] }, 255, 'GetFieldDefaulted TIFFTAG_COLORMAP r';
is $#{ $values[1] }, 255, 'GetFieldDefaulted TIFFTAG_COLORMAP g';
is $#{ $values[2] }, 255, 'GetFieldDefaulted TIFFTAG_COLORMAP b';

$tif->Close;

#########################

my $convert;
if ( can_run('magick') ) {
    $convert = 'magick convert';
}
elsif ( $OSNAME ne 'MSWin32' and can_run('convert') ) {
    $convert = 'convert';
}
SKIP: {
    skip 'convert not installed', 2 if ( not $convert );
    system "$convert rose: -define tiff:predictor=2 -compress lzw $file";
    $tif = Graphics::TIFF->Open( $file, 'r' );
    is $tif->GetField(TIFFTAG_PREDICTOR), PREDICTOR_HORIZONTAL,
      'GetField TIFFTAG_PREDICTOR';
    $tif->Close;

#########################

    system "$convert rose: -define tiff:tile-geometry=256x256 $file";
    $tif = Graphics::TIFF->Open( $file, 'r' );
    is( length( $tif->ReadTile( 0, 0, 0, 0 ) ), 196608, 'ReadTile' );
    $tif->Close;
}
