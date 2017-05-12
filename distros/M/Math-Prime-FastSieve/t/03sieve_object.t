## no critic(RCS,VERSION,explicit,Module,ProhibitMagicNumbers)
use strict;
use warnings;

use Test::More;
use Math::Prime::FastSieve;

ok( 1, 'ok(1) should never fail.' );

# Test a small sieve.
my $obj_param = 20;
my $sieve = new_ok( 'Math::Prime::FastSieve::Sieve', [$obj_param] );

# Test $sieve->primes():

note 'Testing $sieve->primes():';

{
    my %test_data = (
        20 => [ 2, 3, 5, 7, 11, 13, 17, 19 ],
        19 => [ 2, 3, 5, 7, 11, 13, 17, 19 ],
        5  => [ 2, 3, 5 ],
        3  => [ 2, 3 ],
        2  => [2],
        1  => [],
        0  => [],
        -1 => [],
        21 => [],
    );
    foreach my $param ( sort { $a <=> $b } keys %test_data ) {
        local $" = ', ';
        my $expect = $test_data{$param};
        is_deeply( $sieve->primes($param),
            $expect,
            "\$sieve->primes( $param ) returns listref of [ @{$expect} ]." );
    }
}

note 'Testing $sieve->is_deeply()';
{
    my @test_data = (
        [ [ 2, 7 ], [ 2, 3, 5, 7 ] ],
        [ [ 3, 9 ], [ 3, 5, 7 ] ],
        [ [ 1, 9 ], [ 2, 3, 5, 7 ] ],
        [ [ 0, 9 ], [ 2, 3, 5, 7 ] ],
        [ [ -1, 9 ],  [] ],               # Out of range returns [ ].
        [ [ 12, 20 ], [ 13, 17, 19 ] ],
        [ [ 17, 21 ], [] ],               # Out of range returns [ ].
        [ [ -1, 21 ], [] ],               # Out of range returns [ ].
        [ [ 14, 16 ], [] ],               # No primes in this range.
    );
    foreach my $test (@test_data) {
        local $" = ', ';
        is_deeply(
            $sieve->ranged_primes( @{ $test->[0] } ),
            $test->[1],
            "\$sieve->ranged_primes( @{$test->[0]} ) "
              . "returns [ @{$test->[1]} ]."
              . (
                @{ $test->[1] }
                ? q{}
                : ' (Out of range or none found within range.)'
              )
        );
    }
}

note 'Testing $sieve->isprime()';
{
    my %test_data = (
        -1 => 0,    # Out of range.
        0  => 0,
        1  => 0,
        2  => 1,
        3  => 1,
        5  => 1,
        19 => 1,
        20 => 0,
        21 => 0,    # Out of range.
    );
    foreach my $param ( sort { $a <=> $b } keys %test_data ) {
        my $expect = $test_data{$param};
        if ($expect) {
            ok( $sieve->isprime($param),
                "\$sieve->isprime( $param ): $param is prime." );
            ok( $sieve->is_prime($param),
                "\$sieve->is_prime( $param ) : $param is prime." );
        }
        else {
            ok( !$sieve->isprime($param),
                    "\$sieve->isprime( $param ): $param isn't prime"
                  . ' or is out of range.' );
            ok( !$sieve->is_prime($param),
                    "\$sieve->is_prime( $param ): $param isn't prime"
                  . ' or is out of range.' );
        }
    }
}

note 'testing $sieve->nearest_le().';
{
    my %test_data = (
        -1 => 0,
        1  => 0,
        2  => 2,
        3  => 3,
        4  => 3,
        5  => 5,
        6  => 5,
        19 => 19,
        20 => 19,
        21 => 0,
    );
    foreach my $param ( sort { $a <=> $b } keys %test_data ) {
        my $expect = $test_data{$param};
        is(
            $sieve->nearest_le($param),
            $expect,
            "\$sieve->nearest_le( $param ): "
              . (
                $expect == 0
                ? "0: $param is out of range."
                : "$expect is nearest prime <= $param."
              )
        );
    }
}

note 'testing $sieve->nearest_ge().';
{
    my %test_data = (
        -1 => 2,    # Out of range, but we can ignore that.
        0  => 2,
        1  => 2,
        2  => 2,
        3  => 3,
        4  => 5,
        5  => 5,
        6  => 7,
        19 => 19,
        20 => 0,    # No primes >= 20 within sieve range.
        21 => 0,    # Out of range.
    );
    foreach my $param ( sort { $a <=> $b } keys %test_data ) {
        my $expect = $test_data{$param};
        is(
            $sieve->nearest_ge($param),
            $expect,
            "\$sieve->nearest_ge( $param ): "
              . (
                $expect == 0
                ? "0: No primes in sieve >= $param. "
                : "$expect is nearest prime >= $param."
              )
        );
    }
}

note 'Testing $sieve->count_sieve()';
{
    my %test_data = (
        -3        => 0,
        -1        => 0,
        0         => 0,
        1         => 0,
        2         => 1,
        3         => 2,
        4         => 2,
        5         => 3,
        6         => 3,
        7         => 4,
        11        => 5,
        18        => 7,
        19        => 8,
        20        => 8,
        1000      => 168,
        5_000_000 => 348_513,
    );
    foreach my $param ( sort { $a <=> $b } keys %test_data ) {
        my $expect = $test_data{$param};
        is( Math::Prime::FastSieve::Sieve->new($param)->count_sieve(), $expect,
                "\$sieve->count_sieve(): Accurate count of $expect "
              . "for a sieve of 1 .. $param." );
    }
}

note 'Testing $sieve->count_le()';
{
    my %test_data = (
        -3 => 0,
        -1 => 0,
        0  => 0,
        1  => 0,
        2  => 1,
        3  => 2,
        4  => 2,
        5  => 3,
        18 => 7,
        19 => 8,
        20 => 8,
    );
    foreach my $param ( sort { $a <=> $b } keys %test_data ) {
        my $expect = $test_data{$param};
        is( $sieve->count_le($param),
            $expect,
            "\$sieve->count_le( $param ): Accurate count of $expect " );
    }
}

note 'Testing $sieve->nth_prime().';
{
    my %test_data = (
        -1 => 0,    # Out of range.
        0  => 0,    # Out of range.
        1  => 2,
        2  => 3,
        3  => 5,
        8  => 19,
        9  => 0,    # Out of range.
    );
    foreach my $param ( sort { $a <=> $b } keys %test_data ) {
        my $expect = $test_data{$param};
        is( $sieve->nth_prime($param), $expect,
                "\$sieve->nth_prime( $param ): The prime in the cardinal "
              . "position ${param} is $expect. "
              . ( !$expect ? '(Out of range.)' : q{} ) );
    }
    my $sieve2 = Math::Prime::FastSieve::Sieve->new(150000);
    is( $sieve2->nth_prime(10001), 104743,
        'nth_prime passes Project Euler #7 test: 10001th prime is 104743.' );
}

done_testing();
