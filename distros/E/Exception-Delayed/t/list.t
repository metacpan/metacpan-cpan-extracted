#!perl -w

use Test::More tests => 2;

use Exception::Delayed;

my $ok = 0;

my $x = Exception::Delayed->wantlist(
    sub {
        $ok = 1;
        return map { $_ * 2 } @_;
    },
    10,
    20,
    30
);

is( $ok, 1, "execute code" );

my @list = $x->result;

is_deeply( \@list, [ 20, 40, 60 ], "pass arguments and return list" );

done_testing;
