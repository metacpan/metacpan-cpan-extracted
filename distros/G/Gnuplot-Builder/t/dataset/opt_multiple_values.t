use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;

{
    note("--- example: order unchanged");
    my $dataset = Gnuplot::Builder::Dataset->new;
    my $scale = 0.001;
    $dataset->set_file('dataset.csv');
    $dataset->set_option(
        every => undef,
        using => sub { qq{1:(\$2*$scale)} },
        title => '"data"',
        with  => 'lines lw 2'
    );
    is $dataset->to_string(), q{'dataset.csv' using 1:($2*0.001) title "data" with lines lw 2};
    
    $dataset->set_option(
        title => undef,
        every => '::1',
    );
    is $dataset->to_string(), q{'dataset.csv' every ::1 using 1:($2*0.001) with lines lw 2};
}

{
    note("--- example: gnuplot syntex is not checked.");
    my $bad_dataset = Gnuplot::Builder::Dataset->new_file('hoge');
    $bad_dataset->set_option(
        lw => 4,
        w  => "lp",
        ps => "variable",
        u  => "1:2:3"
    );
    is $bad_dataset->to_string(), q{'hoge' lw 4 w lp ps variable u 1:2:3};

    my $good_dataset = Gnuplot::Builder::Dataset->new_file('hoge');
    $good_dataset->set_option(
        u  => "1:2:3",
        w  => "lp",
        lw => 4,
        ps => "variable"
    );
    is $good_dataset->to_string(), q{'hoge' u 1:2:3 w lp lw 4 ps variable};
}

{
    note("--- example: options without arguments");
    my $dataset = Gnuplot::Builder::Dataset->new("sin(x)");
    $dataset->set_option(matrix => "", volatile => "");
    is $dataset->to_string, "sin(x) matrix volatile", "enable by empty string values";
    
    $dataset->set_option(volatile => undef);
    is $dataset->to_string, "sin(x) matrix", "disable by undef";
    
    $dataset->set_option(matrix => undef, "" => "volatile  matrix");
    is $dataset->to_string, "sin(x) volatile  matrix", "empty string as a key";
}

done_testing;
