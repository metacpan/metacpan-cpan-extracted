use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;

{
    note("--- params_string()");
    my $builder = Gnuplot::Builder::Dataset->new;
    $builder->set_source("sin(x)");
    $builder->setq_option(title => 'hogehoge');
    $builder->set_option(with => "linespoints");
    is $builder->params_string, "sin(x) title 'hogehoge' with linespoints",
        "params_string() is an alias for to_string()";
}

{
    note("--- set_file()");
    my $builder = Gnuplot::Builder::Dataset->new;
    identical $builder->set_file("foobar.dat"), $builder, "set_file() returns the dataset";
    is $builder->get_source(), q{'foobar.dat'}, "set_file() is an alias for setq_source()";
}

{
    note("--- set(), setq()");
    foreach my $case (
        {method => "set",
         exp_named => q{hoge HOGE foo FOO}, exp_single => q{hoge huga foo FOO fizz buzz}},
        {method => "setq",
         exp_named => q{hoge 'HOGE' foo 'FOO'}, exp_single => q{hoge 'huga' foo 'FOO' fizz 'buzz'}}
    ) {
        my $builder = Gnuplot::Builder::Dataset->new;
        my $method = $case->{method};
        identical $builder->$method(hoge => "HOGE", foo => "FOO"), $builder, "$method() returns the builder";
        is $builder->to_string, $case->{exp_named}, "$method() is alias for ${method}_option(): named arg";
        identical $builder->$method(<<SET), $builder, "$method() returns the builder";
hoge = huga
fizz = buzz
SET
        is $builder->to_string, $case->{exp_single}, "$method() is alias for ${method}_option(): single arg";
    }
}

{
    note("--- unset()");
    my $builder = Gnuplot::Builder::Dataset->new('f(x)', a => 1, b => 2, c => 3, d => 4);
    identical $builder->unset(qw(a c)), $builder, "unset() returns the builder";
    is $builder->to_string, "f(x) b 2 d 4", "unset() disables options";
    my $child = $builder->new_child;
    $child->unset("b");
    is $child->to_string, "f(x) d 4", "unset() disables options. It overrides the parent.";
}

done_testing;
