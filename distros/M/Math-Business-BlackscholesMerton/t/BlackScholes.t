#!/usr/bin/perl

use lib qw{ lib t/lib };
use Test::More tests => 25;
use Test::NoWarnings;
use Math::Business::BlackScholesMerton::Binaries;
use Math::Business::BlackScholesMerton::NonBinaries;
use Roundnear;

my $S     = 1.35;
my $t     = 7 / 365;
my $sigma = 0.11;
my $r     = 0.002;
my $q     = 0.001;

# These are compared with Bloomberg standards...
# except EXPIRYMISS and UPORDOWN which are computed as opposing
# EXPIRYRANGE and RANGE respectively.

my @vanillas = ({
        type     => 'vanilla_call',
        barriers => [1.34],
        foreign  => 0.0140,
        domestic => 0.0141,
    },
    {
        type     => 'vanilla_put',
        barriers => [1.34],
        foreign  => 0.0040,
        domestic => 0.0040,
    },
);
my @binaries = ({
        type     => 'call',
        barriers => [1.36],
        foreign  => 0.3172,
        domestic => 0.3118,
    },
    {
        type     => 'put',
        barriers => [1.34],
        foreign  => 0.3096,
        domestic => 0.315,
    },
    {
        type     => 'onetouch',
        barriers => [1.36],
        foreign  => 0.6307,
        domestic => 0.6261,
    },
    {
        type     => 'notouch',
        barriers => [1.36],
        foreign  => 0.3692,
        domestic => 0.3739,
    },
    {
        type     => 'expiryrange',
        barriers => [1.36, 1.34],
        foreign  => 0.3732,
        domestic => 0.3732,
    },
    {
        type     => 'expirymiss',
        barriers => [1.36, 1.34],
        foreign  => 0.6268,
        domestic => 0.6268,
    },
    {
        type     => 'range',
        barriers => [1.36, 1.34],
        foreign  => 0.006902,
        domestic => 0.006902,
    },
    {
        type     => 'upordown',
        barriers => [1.36, 1.34],
        foreign  => 0.993093,
        domestic => 0.993088,
    },
    {
        type     => 'range',
        barriers => [1.35, 1.34],
        foreign  => 0,
        domestic => 0,
    },
    {
        type     => 'upordown',
        barriers => [1.36, 1.35],
        foreign  => 1,
        domestic => 1,
    },

);

foreach
    my $test_group (['Math::Business::BlackScholesMerton::Binaries::', \@binaries], ['Math::Business::BlackScholesMerton::NonBinaries::', \@vanillas])
{
    foreach my $test_case (@{$test_group->[1]}) {
        my $formula_name = $test_group->[0] . $test_case->{type};
        my %probs        = (
            domestic => &$formula_name($S, @{$test_case->{barriers}}, $t, $r, $r - $q,             $sigma),
            foreign  => &$formula_name($S, @{$test_case->{barriers}}, $t, $q, $r - $q + $sigma**2, $sigma),
        );

        foreach my $curr (sort keys %probs) {
            my $length = length($test_case->{$curr});
            my $precision = ($length < 2) ? 1 : 10**(-1 * ($length - 2));
            is(roundnear($precision, $probs{$curr}), $test_case->{$curr}, $test_case->{type} . ' ' . $curr);
        }
    }
}

