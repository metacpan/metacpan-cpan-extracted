use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;

{
    note("--- set and define example");
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(
        xtics => 10,
        key   => undef
    );
    $builder->define(
        a      => 100,
        'f(x)' => 'sin(a * x)',
        b      => undef
    );
    is $builder->to_string(), <<'EXP', "mixed set() and define() ok";
set xtics 10
unset key
a = 100
f(x) = sin(a * x)
undefine b
EXP
}

{
    note("--- mixed add(), set() and define() with same keys");
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(key => "autotitle");
    $builder->add("set key");
    $builder->define(key => "10 + 20");
    is $builder->to_string, <<EXP, "options and definitions are in different namespaces";
set key autotitle
set key
key = 10 + 20
EXP
    $builder->set(foo => "bar");
    $builder->define(foo => "buzz");
    $builder->delete_option("foo");
    $builder->delete_definition("key");
    is $builder->to_string, <<EXP, "delete_*() works in its own namespace.";
set key autotitle
set key
foo = buzz
EXP

    $builder->add(1, 2 ,3);
    $builder->set(foo => "BAR", key => "auto columnhead");
    $builder->define(foo => "BUZZ", key => undef);
    is $builder->to_string, <<EXP, "change values in its own namespace.";
set key auto columnhead
set key
foo = BUZZ
1
2
3
set foo BAR
undefine key
EXP
}

done_testing;
