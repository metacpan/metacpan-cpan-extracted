use warnings;
use strict;
use English;
use IPC::Cmd qw(can_run);
use Test::More;
use Test::Requires qw( v5.10 Image::Magick );

#########################

if ( can_run('tiff2pdf') ) {
    plan tests => 4;
}
else {
    plan skip_all => 'tiff2pdf not installed';
    exit;
}

my $cmd = 'PERL5LIB="blib:blib/arch:lib:$PERL5LIB" '
  . "$EXECUTABLE_NAME examples/tiff2pdf.pl";
my $tif            = 'test.tif';
my $pdf            = 'C.pdf';
my $compressed_tif = 'comp.tif';
my $make_reproducible =
'grep --binary-files=text -v "/ID" | grep --binary-files=text -v "/CreationDate" | grep --binary-files=text -v "/ModDate" | grep --binary-files=text -v "/Producer"';

# strip '' from around ?, which newer glibc libraries seem to have added
my $expected = `tiff2pdf -? $tif 2>&1`;
$expected =~ s/'\?'/?/xsm;
# strip '-m' option added in tiff-4.2.0
$expected =~ s/^ -m: .*?\R//ms;
is( `$cmd -? $tif 2>&1`, $expected, '-?' );

#########################

my $image = Image::Magick->new;
$image->Read('rose:');
$image->Set( density => '72x72' );
$image->Write('test.tif');
system("tiff2pdf -d -o $pdf $tif");

$expected = `cat $pdf | $make_reproducible | hexdump`;
my @expected = split "\n", $expected;
my @output   = split "\n", `$cmd -d $tif | $make_reproducible | hexdump`;

is_deeply( \@output, \@expected, 'basic functionality' );

#########################

system("tiffcp -c lzw $tif $compressed_tif");
system("tiff2pdf -d -o $pdf $compressed_tif");

$expected = `cat $pdf | $make_reproducible | hexdump`;
@expected = split "\n", $expected;
@output = split "\n", `$cmd -d $compressed_tif | $make_reproducible | hexdump`;

is_deeply( \@output, \@expected, 'decompress lzw' );

#########################

SKIP: {
    skip "tiff2pdf doesn't decompress in this case", 1;
    system(
        sprintf
"convert -depth 1 -gravity center -pointsize 78 -size 500x500 caption:'Lorem ipsum etc etc' -background white -alpha off %s",
        $tif
    );
    system("tiffcp -c g3 $tif $compressed_tif");
    system("tiff2pdf -d -o $pdf $compressed_tif");

    $expected = `cat $pdf | $make_reproducible | hexdump`;
    @expected = split "\n", $expected;
    @output   = split "\n",
      `$cmd -d $compressed_tif | $make_reproducible | hexdump`;

    is_deeply( \@output, \@expected, 'decompress g3' );
}

#########################

unlink $tif, $compressed_tif, $pdf;
