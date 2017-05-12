use strict;
use warnings;
use Test::More;
use Test::Warn;
use Imager::Test qw/ is_image /;
use Imager;
use File::Spec;

use t::Util;
use Imager::Heatmap;

@Imager::Heatmap::DEFAULTS{qw/ xsigma ysigma /} = (20.0, 20.0);

####### Non-test code for generating images used to compare test ###################

# Run following to re-generate test images.
# $ perl t/03_image.t generate
if (@ARGV && shift @ARGV eq 'generate') {
    my $hmap = hmap;

    $hmap->insert_datas(sample_data('sample.tsv'));
    my $img = $hmap->draw;
    $img->write(file => File::Spec->catfile($t::Util::RESOURCES_DIR, 'sample.png'));

    exit 0;
}


## Following are test code ##########################################################

subtest "Heatmap generation with linear matrix construction" => sub {
    my $hmap = hmap;

    $hmap->insert_datas(sample_data('sample.tsv'));
    is_image $hmap->draw, load_image('sample.png'), "Result image comparison";
};

subtest "Heatmap generation with no datas(result is blank image)" => sub {
    my $hmap = hmap;

    my $img;
    warning_like sub {
        $img = $hmap->draw;
    }, qr/Nothing to be rendered/, "Nothing to be rendered if no data specified";

    is_image $img, Imager->new(
        xsize    => $hmap->xsize, 
        ysize    => $hmap->ysize,
        channels => 4,
    ), "Returned image should be a blank image";
};

subtest "Heatmap generation with 0 x 0 matrix" => sub {
    my $hmap = hmap;

    $hmap->xsize(0);
    $hmap->ysize(0);

    $hmap->insert_datas(sample_data('sample.tsv'));

    my $img;
    warning_like sub {
        $img = $hmap->draw;
    }, qr/Nothing to be rendered/;

    is $img, undef;
};


done_testing;
