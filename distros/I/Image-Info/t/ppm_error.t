use strict;
use warnings;
use Test::More tests => 1;

use File::Temp qw(tempfile);
use Image::Info qw(image_info);

{
    my($tmpfh,$tmpfile) = tempfile(UNLINK => 1);
    $tmpfh->print("P1\n100 "); # test case from Imager (junk.ppm)
    $tmpfh->close;

    my @i = image_info($tmpfile);
    is_deeply \@i, [{ error => "Incomplete PBM/PGM/PPM header" }], 'junk ppm file detected';
}
