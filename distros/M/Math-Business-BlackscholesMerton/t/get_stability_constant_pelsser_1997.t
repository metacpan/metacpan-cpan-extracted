#!/usr/bin/perl

use lib qw{ lib t/lib };
use Test::Most;
use Test::Exception;
require Test::NoWarnings;
use Math::Business::BlackScholesMerton::Binaries;
use Roundnear;

my $S         = 1.35;
my $barrier_u = 1.36;
my $barrier_l = 1.34;
my $t         = 7 / 365;
my $sigma     = 0.11;
my $r         = 0.002;
my $q         = 0.001;

throws_ok {
    my $stability_constant =
        Math::Business::BlackScholesMerton::Binaries::get_stability_constant_pelsser_1997($S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma, 0);
}
qr/Eta not defined/, 'Missing $eta argument';

throws_ok {
    my $stability_constant =
        Math::Business::BlackScholesMerton::Binaries::get_stability_constant_pelsser_1997($S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma, 0, 1,
        4);
}
qr/Power of PI/, 'Wrong value for PI';

throws_ok {
    my $stability_constant =
        Math::Business::BlackScholesMerton::Binaries::common_function_pelsser_1997($S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma, 0);
}
qr/eta not defined/, 'Missing $eta argument';

Test::NoWarnings::had_no_warnings();
done_testing();

