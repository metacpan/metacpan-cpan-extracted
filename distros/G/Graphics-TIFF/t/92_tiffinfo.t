use warnings;
use strict;
use English;
use Test::More;
use Test::Requires qw( v5.10 );
use Image::Magick;

#########################

if ( system("which tiffinfo > /dev/null 2> /dev/null") == 0 ) {
    plan tests => 15;
}
else {
    plan skip_all => 'tiffinfo not installed';
    exit;
}

my $image = Image::Magick->new;
$image->Read( 'rose:', 'rose:' );
$image->Set( density => '72x72' );
$image->Write('test.tif');
my $cmd = 'PERL5LIB="blib:blib/arch:lib:$PERL5LIB" '
  . "$EXECUTABLE_NAME examples/tiffinfo.pl";

is( `$cmd test.tif`, `tiffinfo test.tif`, 'basic multi-directory' );

is( `$cmd -2 test.tif`, `tiffinfo -2 test.tif`, 'dirnum' );

$image = Image::Magick->new;
$image->Read('rose:');
$image->Set( density => '72x72' );
$image->Write('test.tif');

is( `$cmd -d test.tif`, `tiffinfo -d test.tif`, '-d' );

is( `$cmd -D test.tif`, `tiffinfo -D test.tif`, '-D' );

is(
    `$cmd -d -f lsb2msb test.tif`,
    `tiffinfo -d -f lsb2msb test.tif`,
    '-f lsb2msb'
);

is(
    `$cmd -d -f msb2lsb test.tif`,
    `tiffinfo -d -f msb2lsb test.tif`,
    '-f msb2lsb'
);

is( `$cmd -c test.tif`, `tiffinfo -c test.tif`, '-c' );

is( `$cmd -i test.tif`, `tiffinfo -i test.tif`, '-i' );

is( `$cmd -o 2 test.tif 2>&1`, `tiffinfo -o 2 test.tif 2>&1`, '-o' );

is( `$cmd -j test.tif`, `tiffinfo -j test.tif`, '-j' );

is( `$cmd -r -d test.tif`, `tiffinfo -r -d test.tif`, '-r -d' );

is( `$cmd -s -d test.tif`, `tiffinfo -s -d test.tif`, '-s -d' );

is( `$cmd -w -d test.tif`, `tiffinfo -w -d test.tif`, '-w -d' );

is( `$cmd -z -d test.tif`, `tiffinfo -z -d test.tif`, '-z -d' );

# strip '' from around ?, which newer glibc libraries seem to have added
my $expected = `tiffinfo -? test.tif 2>&1`;
$expected =~ s/'\?'/?/xsm;
is( `$cmd -? test.tif 2>&1`, $expected, '-?' );

#########################

unlink 'test.tif';
