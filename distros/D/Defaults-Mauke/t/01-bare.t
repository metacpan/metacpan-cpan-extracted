use Defaults::Mauke;
use Test::More tests => 11;

fun foo($x, $y) {
    $x * 2 + $y
}

{
    package T;
    sub f { 1 }
}

ok !eval 'f T';
ok $@;
like $@, qr/indirect/i;

ok !eval 'open F, __FILE__';
ok $@;
like $@, qr/bareword/i;

ok !eval "\$x";
ok $@;
like $@, qr/^Global symbol "\$x" requires explicit package name/;

is foo(20, 2), 42;

is fc('.'), '.';
