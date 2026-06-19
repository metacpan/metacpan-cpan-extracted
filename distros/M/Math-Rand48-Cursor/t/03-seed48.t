use strict;
use warnings;
use Config;
use Test::More;
use Math::BigInt;
use Math::Rand48::Cursor;

# from_seed48 lands on the POSIX srand48 seeded state: X0 = (seed<<16)|0x330E.
for my $s ( 0, 1, 12345, 424242 ) {
    my $want = ( Math::BigInt->new($s)->blsft(16) ) + 0x330e;
    my $got  = Math::Rand48::Cursor->from_seed48($s)->state;
    is $got->bstr, $want->bstr, "from_seed48($s) == (s<<16)|0x330E";
}

# The seeded cursor sits before the first output; ->forward is the first rand().
SKIP: {
    skip "rand() is not Perl_drand48 ($Config{randfunc})", 1
      unless $Config{randfunc} eq 'Perl_drand48';
    my $s = 987654321;
    srand($s);
    my $via_seek = Math::Rand48::Cursor->from_seed48($s)->forward->state;
    my $via_rand = Math::Rand48::Cursor->from_rand( rand() )->state;
    is $via_seek->bstr, $via_rand->bstr, 'from_seed48($s)->forward == first rand() after srand($s)';
}

done_testing;
