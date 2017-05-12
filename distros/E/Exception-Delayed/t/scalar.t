#!perl -w

use Test::More tests => 2;

use Exception::Delayed;

my $ok = 0;

my $x = Exception::Delayed->wantscalar(
    sub {
        $ok = 1;
        my $sum = 0;
        map { $sum += $_ } @_;
        return $sum;
    },
    10,
    20,
    30
);

is( $ok, 1, "execute code" );

my $scalar = $x->result;

is( $scalar, 10 + 20 + 30, "pass arguments and return scalar" );

done_testing;
