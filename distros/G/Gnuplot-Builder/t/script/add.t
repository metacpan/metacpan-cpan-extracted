use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

{
    my $builder = Gnuplot::Builder::Script->new;
    is $builder->to_string, "", "at first, empty";

    identical $builder->add("set term png"), $builder, "add() should return the object";
    is $builder->to_string, "set term png\n", "add() should append newline if not exists";

    $builder->add("set key\n", "set grid\n");
    is $builder->to_string,
        "set term png\nset key\nset grid\n",
            "add() should not change the trailing newline.";

    my $unit = "m";
    my $called = 0;
    $builder->add(sub {
        my $inner_builder = shift;
        $called++;
        identical $inner_builder, $builder, "add() code-ref should receive the builder.";
        ok wantarray, "add() code-ref should be called in list context";
        return "set xlabel 'distance [$unit]'";
    });

    is $builder->to_string,
        "set term png\nset key\nset grid\nset xlabel 'distance [m]'\n",
            "add() code-ref should be evalulated lazily";
    is $called, 1, "code-ref should be called once";
    $called = 0;

    $unit = "km";
    is $builder->to_string,
        "set term png\nset key\nset grid\nset xlabel 'distance [km]'\n",
            "add() code-ref should be evalulated lazily, again";
    is $called, 1, "code-ref should be called once";
    $called = 0;
}

{
    note("--- return list from code-ref");
    my $builder = Gnuplot::Builder::Script->new;
    $builder->add(sub {
        return ("foo", "bar");
    });
    is $builder->to_string, "foo\nbar\n", "each element returned should be treated as a line.";
}

done_testing;

