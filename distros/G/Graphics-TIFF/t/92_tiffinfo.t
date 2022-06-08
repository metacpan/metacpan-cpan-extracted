use warnings;
use strict;
use English;
use IPC::Cmd qw(can_run);
use Test::More;
use Test::Requires qw( v5.10 Image::Magick );
use File::Temp;
use File::Spec;

#########################

if ( can_run('tiffinfo') ) {
    plan tests => 15;
}
else {
    plan skip_all => 'tiffinfo not installed';
    exit;
}

my $directory = File::Temp->newdir;
my $file = File::Spec->catfile( $directory, 'test.tif' );
my $image = Image::Magick->new;
$image->Read( 'rose:', 'rose:' );
$image->Set( density => '72x72' );
$image->Write($file);
my $cmd = 'PERL5LIB="blib:blib/arch:lib:$PERL5LIB" '
  . "$EXECUTABLE_NAME examples/tiffinfo.pl";

is( `$cmd $file`, `tiffinfo $file`, 'basic multi-directory' );

is( `$cmd -2 $file`, `tiffinfo -2 $file`, 'dirnum' );

$image = Image::Magick->new;
$image->Read('rose:');
$image->Set( density => '72x72' );
$image->Write($file);

is( `$cmd -d $file`, `tiffinfo -d $file`, '-d' );

is( `$cmd -D $file`, `tiffinfo -D $file`, '-D' );

is(
    `$cmd -d -f lsb2msb $file`,
    `tiffinfo -d -f lsb2msb $file`,
    '-f lsb2msb'
);

is(
    `$cmd -d -f msb2lsb $file`,
    `tiffinfo -d -f msb2lsb $file`,
    '-f msb2lsb'
);

is( `$cmd -c $file`, `tiffinfo -c $file`, '-c' );

is( `$cmd -i $file`, `tiffinfo -i $file`, '-i' );

is( `$cmd -o 2 $file 2>&1`, `tiffinfo -o 2 $file 2>&1`, '-o' );

is( `$cmd -j $file`, `tiffinfo -j $file`, '-j' );

is( `$cmd -r -d $file`, `tiffinfo -r -d $file`, '-r -d' );

is( `$cmd -s -d $file`, `tiffinfo -s -d $file`, '-s -d' );

is( `$cmd -w -d $file`, `tiffinfo -w -d $file`, '-w -d' );

is( `$cmd -z -d $file`, `tiffinfo -z -d $file`, '-z -d' );

# strip '' from around ?, which newer glibc libraries seem to have added
my $expected = `tiffinfo -? $file 2>&1`;
$expected =~ s/'\?'/?/xsm;
# strip a description line added in libtiff 4.3.0
$expected =~ s/^Display information about TIFF files\R\R//sm;
# strip unsupported -M option added in libtiff 4.4.0
$expected =~ s/^ -M size\tset the memory allocation limit in MiB\. 0 to disable limit\R//sm;
is( `$cmd -? $file 2>&1`, $expected, '-?' );

#########################

