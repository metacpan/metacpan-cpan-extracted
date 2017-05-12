use strict;
use warnings;
use Test::More;

use Imager;
use Imager::Filter::Bakumatsu;

use File::Compare;
use File::Temp 'tempfile';

if (grep { /png/ } keys %Imager::formats) {
    plan tests => 1;
} else {
    plan skip_all => "test needs Imager that supports png format.";
}

my ($fh, $filename) = tempfile(UNLINK => 1, SUFFIX => '.png');

my $img = Imager->new;
$img->read(file => 't/sample.png') or die $img->errstr;
$img->filter(type => 'bakumatsu');
$img->write(file => $filename) or die $img->errstr;

ok( File::Compare::compare('t/sample-filterd.png', $filename) == 0 , 'same output');
