use strict;
use warnings;
use Test::More;
use Test::Exception;

use t::Util;
use Imager::Heatmap;

subtest "Behavior of new" => sub {
    dies_ok sub { Imager::Heatmap->new( xsize => 100 ) }, "Die if ysize not specified";
    dies_ok sub { Imager::Heatmap->new( ysize => 100 ) }, "Die if xsize not specified";

    local %Imager::Heatmap::DEFAULTS = (
        xsigma           => 10.0,
        ysigma           => 5.0,
        correlation      => 1.0,
    );

    my $hmap;
    lives_ok sub { $hmap = Imager::Heatmap->new( xsize => 100, ysize => 100 ) };

    is $hmap->xsize,       100;
    is $hmap->ysize,       100;
    is $hmap->xsigma,      10.0;
    is $hmap->ysigma,      5.0;
    is $hmap->correlation, 1.0;

    throws_ok {
        Imager::Heatmap->new( xsize => 100, ysize => 100, foobar => 1 )
    } qr/unkown options.*foobar/, "Die if unkowon options ware specified";
};

subtest "Behavior of xsize" => sub {
    my $hmap = hmap;

    dies_ok { $hmap->xsize(-1) }   "Negative number is not allowed for xsize";

    my $matrix = $hmap->matrix;

    lives_ok { $hmap->xsize(100) } "xsize should be a positive number";

    is $hmap->xsize, 100,          "Accessor xsize worked";

    isnt $hmap->matrix, $matrix,   "Modifying xsize should invalidate existing matrix";
};

subtest "Behavior of ysize" => sub {
    my $hmap = hmap;

    dies_ok { $hmap->ysize(-1) }   "Negative number is not allowed for ysize";

    my $matrix = $hmap->matrix;

    lives_ok { $hmap->ysize(100) };

    is $hmap->ysize, 100,          "Accessor ysize worked";

    isnt $hmap->matrix, $matrix ,  "Modifying ysize should invalidate existing matrix";
};

subtest "Behavior of xsigma and ysigma" => sub {
    my $hmap = hmap;

    dies_ok { $hmap->xsigma(-1.0) } "Negative number is not allowed for xsigma";

    lives_ok { $hmap->xsigma(1.0) };
    is $hmap->xsigma, 1.0,          "Accessor xsigma worked";

    dies_ok { $hmap->ysigma(-1.0) } "Negative number is not allowed for ysigma";

    lives_ok { $hmap->ysigma(1.0) };
    is $hmap->ysigma, 1.0,          "Accessor ysigma worked";
};

subtest "Behavior of correlation" => sub {
    my $hmap = hmap;

    dies_ok { $hmap->correlation(-1.1) } "Number less    than -1 is not allowed for correlation";
    dies_ok { $hmap->correlation( 1.1) } "Number greater than  1 is not allowed for correlation";

    lives_ok { $hmap->correlation(-1) }  "correlation can be -1";
    lives_ok { $hmap->correlation( 1) }  "correlation can be  1";
    lives_ok { $hmap->correlation(0.0) };

    is $hmap->correlation, 0.0,          "Accessor correlation worked";
};

subtest "Behavior of matrix" => sub {
    my $hmap = hmap;

    my $matrix = $hmap->matrix;

    is_deeply $matrix, [ (0)x90000 ],        "Matrix should be zero-filled matrix before adding any datas.";
    $hmap->insert_datas([ 10, 10 ]);

    isnt $matrix->[10*$hmap->xsize+10], 0.0, "Matrix should be modified after adding datas.";
};

done_testing;
