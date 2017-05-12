use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;
use lib "t";
use testlib::LensUtil qw(test_lens_options);
use Data::Focus qw(focus);

test_lens_options("Script", sub { Gnuplot::Builder::Script->new });

{
    note("-- example");
    my %params = (
        xrange => '[*:*]',
        style => ["data linespoints", "fill solid 1.0"]
    );
    my $builder = Gnuplot::Builder::Script->new(%params);
    my $exp_builder = Gnuplot::Builder::Script->new(%params);

    ## 

    my $scalar = focus($builder)->get("xrange");
    my $exp_scalar = scalar($exp_builder->get_option("xrange"));
        
    my @list = focus($builder)->list("style");
    my @exp_list = scalar($exp_builder->get_option("style"));
        
    focus($builder)->set(xrange => '[10:100]');
    $exp_builder->set_option(xrange => '[10:100]');

    ##
    is $scalar, $exp_scalar;
    is_deeply \@list, \@exp_list;
    is_deeply [$builder->get_option("xrange")], [$exp_builder->get_option("xrange")];
}


done_testing;
