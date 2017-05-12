use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

my $builder = Gnuplot::Builder::Script->new;
my $called = 0;
my $value = "bar";
$builder->set("foo", sub {
    my ($inner_builder, $opt_name) = @_;
    $called++;
    identical $inner_builder, $builder, "first arg should be the builder";
    is $opt_name, "foo", "second arg should be the opt name";
    ok wantarray, "code-ref is in list context";
    return $value;
});

is $called, 0, "not called yet";
is $builder->to_string, "set foo bar\n", "result ok";
is $called, 1, "called once";
$called = 0;

$value = "buzz";
is $builder->to_string, "set foo buzz\n", "the code-ref is evaled lazily";
is $called, 1, "called once";
$called = 0;

done_testing;
