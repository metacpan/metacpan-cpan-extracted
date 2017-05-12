use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::JoinDict qw(joind);
use lib "t";
use testlib::RefUtil qw(is_different);
use testlib::LensUtil ();
use Data::Focus qw(focus);

{
    note("-- basics");
    my $dict = joind(",", x => 1, y => 2);
    is focus($dict)->get("x"), 1;
    is_deeply [focus($dict)->list("x")], [1];
    is focus($dict)->get("unknown"), undef;
    is_deeply [focus($dict)->list("unknown")], [undef], "single focal point";

    is focus($dict)->get("y"), 2;
    my $ydict = focus($dict)->set(y => 50);
    is_different $dict, $ydict;
    is $ydict->get("y"), 50, "set via Lens works";
    is "$dict", "1,2", "dict is intact";
    is "$ydict", "1,50", "ydict is the modified version of dict";

    my $zdict = focus($dict)->set(z => 3);
    is_different $dict, $zdict;
    is $zdict->get("z"), 3, "Lens allows setting to a new key";
    is "$dict", "1,2", "dict is intact";
    is "$zdict", "1,2,3", "zdict is the modified version of dict";

    my $odict = focus($dict)->over(y => sub { $_[0] * $_[0] });
    is $odict->get("y"), 4, "over() works";
}

{
    note("-- example");
    my $dict = joind(",", x => 100, y => 200);
    my $exp_dict = $dict->clone;

    ##
    
    my $scalar = focus($dict)->get("x");
    my $exp_scalar = $exp_dict->get("x");
        
    my $new_dict = focus($dict)->set(x => '($1 * 1000)');
    my $exp_new_dict = $exp_dict->set(x => '($1 * 1000)');

    ##

    is $scalar, $exp_scalar;
    is "$new_dict", "$exp_new_dict";
}

done_testing;
