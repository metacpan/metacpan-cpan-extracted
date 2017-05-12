use Test::More;

use Devel::Kit::TAP;

plan tests => 1;
is( \&Devel::Kit::o, \&Test::More::diag, 'Devel::Kit::o() is replaced' );
