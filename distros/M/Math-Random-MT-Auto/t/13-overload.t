# Tests for overloading

use strict;
use warnings;

$| = 1;

use Test::More 'tests' => 16;
use Config;

my @WARN;
BEGIN {
    # Warning signal handler
    $SIG{__WARN__} = sub { push(@WARN, @_); };
}
use_ok('Math::Random::MT::Auto', ':!auto');
use_ok('Math::Random::MT::Auto::Range');

# Set predetermined seed for verification test
my @seed = ($Config{'uvsize'} == 8)
                    ? (0x12345, 0x23456, 0x34567, 0x45678)
                    : (0x123, 0x234, 0x345, 0x456);

my @rand = ($Config{'uvsize'} == 8) ?
  (  # 64-bit randoms
     7266447313870364031,  4946485549665804864, 16945909448695747420, 16394063075524226720,
     4873882236456199058, 14877448043947020171,  6740343660852211943, 13857871200353263164
  ) :
  (  # 32-bit randoms
    1067595299,  955945823,  477289528, 4107218783,
    4228976476, 3344332714, 3355579695,  227628506
  );

# Create PRNG object
my $prng;
eval { $prng = Math::Random::MT::Auto->new('SEED' => \@seed); };
if (my $e = OIO->caught()) {
    fail('MRMA->new(): ' . $e->error());
} elsif ($@) {
    fail('MRMA->new(): ' . $@);
} else {
    pass('MRMA->new()');
}

is("$prng", $rand[0]                    => ':Stringify');
SKIP: {
    my $rnd = 0+$prng;
    skip('64-bit overload bug', 1)
        if (($] < 5.010) && ($Config{'uvsize'} == 8));
    is($rnd, $rand[1]                   => ':Numerify');
}
is(($prng) ? 'odd' : 'even', 
   ($rand[2] & 1) ? 'odd' : 'even',     => ':Boolify');

my $x = \&{$prng};
is($x->(), $rand[3]                     => ':Codify');

my @x = @{$prng};
is($x[0], $rand[4]                      => ':Arrayify');

@x = @{$prng->array(3)};
my @results = @rand[5..7];
is_deeply(\@x, \@results                => '->array()');

### MRMA::Range

my ($LO, $HI) = (1000, 9999);
sub range
{
    return (($_[0] % (($HI + 1) - $LO)) + $LO);
}

my $rand;
eval { $rand = Math::Random::MT::Auto::Range->new('SEED' => \@seed,
                                                  'LOW'  => $LO,
                                                  'HIGH' => $HI,
                                                  'TYPE' => 'INTEGER'); };
if (my $e = OIO->caught()) {
    fail('MRMAR->new(): ' . $e->error());
} elsif ($@) {
    fail('MRMAR->new(): ' . $@);
} else {
    pass('MRMAR->new()');
}

is("$rand", range($rand[0])                     => ':Stringify');
is(0+$rand, range($rand[1])                     => ':Numerify');
is(($rand) ? 'odd' : 'even', 
   (range($rand[2]) & 1) ? 'odd' : 'even',      => ':Boolify');

my $x = \&{$rand};
is($x->(), range($rand[3])                      => ':Codify');

my @x = @{$rand};
is($x[0], range($rand[4])                       => ':Arrayify');

@x = @{$rand->array(3)};
my @results = map { range($_) } @rand[5..7];
is_deeply(\@x, \@results                        => '->array()');

exit(0);

# EOF
