# This is a test for module Image::PNG::QRCode.

use warnings;
use strict;
use Test::More;
use Image::PNG::QRCode 'qrpng';
use FindBin;
use File::Compare;

my $pngfile = "$FindBin::Bin/test1.png";
qrpng (text => "this is my png", out => $pngfile);
ok (-f $pngfile);

my $pngfile2 = "$FindBin::Bin/test2.png";
# A scalar to write to
my $s;
qrpng (text => "this is my png", out => \$s);
ok ($s);
open my $o, ">:raw", $pngfile2 or die $!;
print $o $s;
close $o or die $!;
is (compare ($pngfile, $pngfile2), 0);

my $size3;
my $pngfile3 = "$FindBin::Bin/test3.png";
qrpng (text => "ballroom blitz", scale => 6, out => $pngfile3, size => \$size3);

ok (-f $pngfile3);
ok (-s $pngfile3 > 0);
ok (defined $size3, "got any size for image");
ok ($size3 > 0, "got a valid size for image");
note ($size3);
my $pngfile4 = "$FindBin::Bin/test4.png";
qrpng (text => "monster mash", scale => 6, quiet => 10, out => $pngfile4);

ok (-f $pngfile4);
ok (-s $pngfile4 > 0);

my $pngfile5 = "$FindBin::Bin/test5.png";
qrpng (text => "monster mash", level => 4, out => $pngfile5);

ok (-f $pngfile5);
ok (-s $pngfile5 > 0);

my $pngfile6 = "$FindBin::Bin/test6.png";
qrpng (text => "monster mash", version => 40, out => $pngfile6);

ok (-f $pngfile6);
ok (-s $pngfile6 > 0);

my $png = qrpng (text => 'buggles');
ok ($png, "Created a PNG using return value");
like ($png, qr/^.PNG/, "contains a PNG image");
my $warning;
{
    local $SIG{__WARN__} = sub {
	$warning = "@_";
    };
    $warning = '';
    my $pngout = qrpng (text => 'monkey', size => \my @notascalarref);
    like ($warning, qr/size option requires a scalar reference/);
    $warning = '';
    qrpng (text => 'ape');
    like ($warning, qr/Output discarded/);
    $warning = '';
    my $x = qrpng (text => 'ape', out => \my $y);
    like ($warning, qr/used twice/);
    # Check that the two outputs are OK anyway.
    is ($x, $y);
};

TODO: {
    local $TODO = 'not implemented yet';
};

# Remove the output files.

for my $file ($pngfile, $pngfile2, $pngfile3, $pngfile4, $pngfile5, $pngfile6) {
    if (-f $file) {
	unlink $file;
    }
}

done_testing ();

# Local variables:
# mode: perl
# End:
