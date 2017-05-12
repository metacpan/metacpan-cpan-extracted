use strict;
use warnings;
use Test::More;

sub Foo::foo {  }

my Foo $x = bless {}, "Foo";

{
    use Methods::CheckNames;

    my $ran = 0;
    eval '$ran++; $x->foo()';
    ok(!$@, "no error for acutal method");
    is($ran, 1, "ran");

    $ran = 0;
    eval '$ran++; $x->bar()';
    ok($@, "error for non existent method");
    is($ran, 0, "compile time error");
}

my $ran = 0;
eval '$ran++; $x->bar()';
like($@, qr/Can't locate object method/, 'normal runtime error message');
is($ran, 1, "ran");

done_testing;
