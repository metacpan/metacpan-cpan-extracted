use strict;
use warnings;
use Test::More;
use Math::BigInt;
use Math::Rand48::Cursor;

# Independent oracle: one drand48 step, computed straight from the definition.
my $A = Math::BigInt->new('25214903917');
my $C = Math::BigInt->new('11');
my $M = Math::BigInt->new('1')->blsft(48);
sub step { ( $A * $_[0] + $C ) % $M }

my $start = Math::BigInt->from_hex('0xec72189a6378');    # from the example

# forward one step matches the oracle
{
    my $rng = Math::Rand48::Cursor->new( state => $start );
    is $rng->forward->state->bstr, step($start)->bstr, 'forward == A*X+C mod M';
}

# seek(2) == two single forward steps (compose order)
{
    my $a = Math::Rand48::Cursor->new( state => $start )->seek(2)->state;
    my $b = Math::Rand48::Cursor->new( state => $start )->forward->forward->state;
    is $a->bstr, $b->bstr, 'seek(2) == forward x2';
}

# seek(-1) == backward, and backward undoes forward
{
    my $a = Math::Rand48::Cursor->new( state => $start )->seek(-1)->state;
    my $b = Math::Rand48::Cursor->new( state => $start )->backward->state;
    is $a->bstr, $b->bstr, 'seek(-1) == backward';

    my $rt = Math::Rand48::Cursor->new( state => $start )->forward->backward->state;
    is $rt->bstr, $start->bstr, 'backward undoes forward';
}

# seek(0) is a no-op (identity map)
{
    my $s = Math::Rand48::Cursor->new( state => $start )->seek(0)->state;
    is $s->bstr, $start->bstr, 'seek(0) is identity';
}

# seek(n) then seek(-n) round-trips, including a huge n
for my $n ( 1, 2, 7, 1000, 1_000_000, '123456789012345' ) {
    my $rng = Math::Rand48::Cursor->new( state => $start );
    $rng->seek($n)->seek("-$n");
    is $rng->state->bstr, $start->bstr, "seek($n) then seek(-$n) round-trips";
}

# seek(n) forward == n single forward steps (small n, brute-force check)
{
    my $jump  = Math::Rand48::Cursor->new( state => $start )->seek(50)->state;
    my $brute = Math::Rand48::Cursor->new( state => $start );
    $brute->forward for 1 .. 50;
    is $jump->bstr, $brute->state->bstr, 'seek(50) == 50 x forward';
}

# from_rand / rand round-trip pins the cursor on the observed value
{
    my $rng  = Math::Rand48::Cursor->new( state => $start );
    my $obs  = $rng->rand;
    my $back = Math::Rand48::Cursor->from_rand($obs);
    is $back->state->bstr, $start->bstr, 'from_rand(rand) recovers state';
}

done_testing;
