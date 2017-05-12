use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::JoinDict;

{
    my $joinval = Gnuplot::Builder::JoinDict->new(
        separator => ",", content => [real => "{10", imag => "20}"],
    );
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->define(a => 10), $builder, "define() should return the object";

    my $called = 0;
    $builder->define(b => [20, 30], c => undef, e => $joinval, "f(x)" => sub {
        my ($inner_builder, $key) = @_;
        $called++;
        identical $inner_builder, $builder, "first arg for code-ref OK";
        is $key, "f(x)", "second arg for code-ref OK";
        ok wantarray, "list context ok";
        return "sin(x)";
    });
    is $called, 0, "not yet called";
    is $builder->to_string, <<EXP, "script OK";
a = 10
b = 20
b = 30
undefine c
e = {10,20}
f(x) = sin(x)
EXP
    is $called, 1, "called";
    $called = 0;

    is_deeply [$builder->get_definition("a")], [10], "get single definition";
    is_deeply [$builder->get_definition("b")], [20, 30], "get multiple occurrences";
    is_deeply [$builder->get_definition("c")], [undef], "get undef";
    is_deeply [$builder->get_definition("f(x)")], ["sin(x)"], "get code-ref";
    is_deeply [$builder->get_definition("d")], [], "get non-existent";
    identical [$builder->get_definition("e")]->[0], $joinval, "get object";
    is $called, 1, "called once";
    is scalar($builder->get_definition("a")), 10, "get single definition (scalar)";
    is scalar($builder->get_definition("b")), 20, "get multiple occurrences (scalar)";
    is scalar($builder->get_definition("c")), undef, "get undef (scalar)";
    is scalar($builder->get_definition("f(x)")), "sin(x)", "get code-ref (scalar)";
    is scalar($builder->get_definition("d")), undef, "get non-existent (scalar)";
    identical scalar($builder->get_definition("e")), $joinval, "get object (scalar)";
    is $called, 2, "called again";

    identical $builder->delete_definition("b"), $builder, "delete_definition() should return the object";
    is_deeply [$builder->get_definition("b")], [], "b no longer exists";
    is $builder->to_string, <<EXP, "b is deleted";
a = 10
undefine c
e = {10,20}
f(x) = sin(x)
EXP
    $builder->delete_definition("a", "f(x)");
    is $builder->to_string, <<EXP, "delete multiple definitions";
undefine c
e = {10,20}
EXP
}

{
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->set_definition(<<EOT), $builder, "set_definition() should return the object";
a = 10
b

c = ""
f(x, y) = sin(x) * cos(y)

-d
EOT
    is $builder->to_string, <<EXP, "set_definition() with setting script OK";
a = 10
b =
c = ""
f(x, y) = sin(x) * cos(y)
undefine d
EXP
}

{
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->undefine(qw(a b c)), $builder, "undefine() should return the object";
    is $builder->to_string, <<EXP, "undefine() OK";
undefine a
undefine b
undefine c
EXP
}

done_testing;
