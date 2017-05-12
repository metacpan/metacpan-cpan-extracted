#!perl -w

use Test::More tests => 2;

use Exception::Delayed;

my $ok = 0;

my $x = Exception::Delayed->wantscalar(
    sub {
        $ok = 1;
        die "meh";
    },
    10,
    20,
    30
);

is( $ok, 1, "execute code" );

eval { $x->result };

like( $@, qr{meh}, "died" );

done_testing;
