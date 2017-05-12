use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Fatal;
use Gnuplot::Builder::Template qw(gusing);
use Gnuplot::Builder::JoinDict;

foreach my $case (
    {label => "basic 2D", keys => [qw(x y)]},
    {label => "basic 3D", keys => [qw(x y z)]},
    {label => "basic polar", keys => [qw(t r)]},
    {label => "polar (radius)", keys => [qw(t radius)]},
    {label => "smooth acsplines", keys => [qw(x y weight)]},
    {label => "smooth kdensity (3 cols)", keys => [qw(x weight bandwidth)]},
    {label => "'value' should be used with kdensity", keys => [qw(value weight bandwidth)]},
    {label => "boxerrorbars (3 cols)", keys => [qw(x y ydelta)]},
    {label => "boxerrorbars (boxwidth != -2)", keys => [qw(x y ydelta x_width)]},
    {label => "boxerrorbars (boxwidth == -2)", keys => [qw(x y ylow yhigh)]},
    {label => "boxerrorbars (5 cols)", keys => [qw(x y ylow yhigh x_width)]},
    {label => "boxes (3 cols)", keys => [qw(x y x_width)]},

    ## boxplot is tricky
    {label => "boxplot (3 cols)", keys => [qw(x y x_width)]},
    {label => "boxplot (4 cols)", keys => [qw(x y x_width boxplot_factor)]},  ## maybe we can ignore this spec...

    {label => "(box)xyerrorbars (4 cols)", keys => [qw(x y xdelta ydelta)]},
    {label => "(box)xyerrorbars (6 cols)", keys => [qw(x y xlow xhigh ylow yhigh)]},
    {label => "candlesticks/financebars", keys => [qw(date open low high close)]},
    {label => "candlesticks (finace with width)", keys => [qw(date open low high close x_width)]},
    {label => "candlesticks", keys => [qw(x box_min whisker_min whisker_high box_high)]},
    {label => "candlesticks (with width)", keys => [qw(x box_min whisker_min whisker_high box_high x_width)]},
    {label => "circles", keys => [qw(x y radius)]},
    {label => "circles (partial)", keys => [qw(x y radius start_angle end_angle)]},
    {label => "ellipses (3 cols)", keys => [qw(x y major_diam)]},
    {label => "ellipses (4 cols)", keys => [qw(x y major_diam minor_diam)]},
    {label => "ellipses (5 cols)", keys => [qw(x y major_diam minor_diam angle)]},
    {label => "filledcurves", keys => [qw(x y1 y2)]},

    #### Ignore this style. "ydelta", "ylow", "yhigh" are enough.
    ## {label => "histograms (errorbars, 2 cols)", keys => [qw(y yerr)]},
    ## {label => "histograms (errorbars, 3 cols)", keys => [qw(y ymin ymax)]},

    {label => "image 2D", keys => [qw(x y value)]},
    {label => "image 3D", keys => [qw(x y z value)]},
    ## rgbimage is subset of rgbalpha
    {label => "rgbalpha 2D", keys => [qw(x y r g b a)]},
    {label => "rgbalpha 3D", keys => [qw(x y z r g b a)]},

    {label => "labels 2D (string)", keys => [qw(x y string)]},
    {label => "labels 2D (label)", keys => [qw(x y label)]},
    {label => "labels 3D (string)", keys => [qw(x y z string)]},
    {label => "labels 3D (label)", keys => [qw(x y z label)]},
    {label => "points 2D + varsize", keys => [qw(x y pointsize)]},
    {label => "points 3D + varsize", keys => [qw(x y z pointsize)]},
    {label => "vectors 2D", keys => [qw(x y xdelta ydelta)]},
    {label => "vectors 2D + vararrow", keys => [qw(x y xdelta ydelta arrowstyle)]},
    {label => "vectors 3D", keys => [qw(x y z xdelta ydelta zdelta)]},
    {label => "vectors 3D + vararrow", keys => [qw(x y z xdelta ydelta zdelta arrowstyle)]},
    {label => "xerrorbars (3 cols)", keys => [qw(x y xdelta)]},
    {label => "xerrorbars (4 cols)", keys => [qw(x y xlow xhigh)]},
    {label => "yerrorbars (3 cols)", keys => [qw(x y ydelta)]},
    {label => "yerrorbars (4 cols)", keys => [qw(x y ylow yhigh)]},
) {
    my @params = map { @$_ } reverse map { [ "-$case->{keys}[$_]" => $_ ] } 0 .. $#{$case->{keys}};
    die "$case->{label}: something is wrong" if !$case->{label} || !@params;
    my $using = gusing(@params);
    is "$using", join(":", 0 .. $#{$case->{keys}}), "$case->{label}: using string order OK";

    unshift @params, "-linecolor" => 9999;
    $using = gusing(@params);
    is "$using", join(":", (0 .. $#{$case->{keys}}), 9999), "$case->{label}: using -linecolor is always at the last (as of gnuplot 4.6.6)";
}

isa_ok $Gnuplot::Builder::Template::USING, "Gnuplot::Builder::JoinDict";

{
    note("--- key check");
    my @keys = $Gnuplot::Builder::Template::USING->get_all_keys();
    is(scalar(grep { $_ =~ /^-/ } @keys), scalar(@keys), "all predefined keys begin with -");
}

{
    note("--- custom keys");
    my $using = gusing(hoge => 1, foo => 2, -x => 3, -y => 4);
    is "$using", "3:4:1:2", "custom keys are always at the last";
}

{
    note("--- unknown hyphen keys");
    like(
        exception { gusing(-z => 10, -this_does_not_exist => 20) },
        qr/unknown key.*-this_does_not_exist/i,
        "it dies if unknown hyphen keys are given"
    );
    my $using = gusing(-x => 10);
    like(
        exception { $using->set(-this_does_not_exist => 200) },
        qr/unknown key.*-this_does_not_exist/i,
        "it dies if unknown hyphen keys are given, even after JoinDict is created"
    );
}

{
    note("--- template customize");
    local $Gnuplot::Builder::Template::USING = Gnuplot::Builder::JoinDict->new(
        separator => ","
    );
    my $using = gusing(-foo => 10, -bar => 20, -x => 30);
    is "$using", "10,20,30", "template is replaced";
}

{
    note("--- examples");
    {
        my $using = gusing(-y => 5, -x => 3);
        is "$using", "3:5";
    }
    {
        my $using = gusing(-x => 1,
                           -whisker_min => 2, -box_min => 3,
                           -box_high => 4, -whisker_high => 5);
        is "$using", "1:3:2:5:4";
    }
    {
        my $using = gusing(-x => 1, -y => 2, -x_width => "(0.7)", tics => "xticlabels(3)");
        is "$using", "1:2:(0.7):xticlabels(3)";
    }
}

done_testing;
