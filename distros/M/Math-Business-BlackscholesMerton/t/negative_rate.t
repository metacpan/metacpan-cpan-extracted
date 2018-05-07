#!/usr/bin/perl

use strict;
use warnings;

use lib qw{ lib t/lib };
use Test::Most;
require Test::NoWarnings;
use Math::Business::BlackScholesMerton::Binaries;
use Roundnear;

my $S       = 1.35;
my $barrier = 1.36;
my $t       = 7 / 365;
my $sigma   = 0.11;
my $r       = -0.005;
my $q       = -0.002;

my $c;
lives_ok { $c = Math::Business::BlackScholesMerton::Binaries::onetouch($S, $barrier, $t, $r, $r - $q, $sigma, 0) }
'negative rates one touch does not die';
cmp_ok(roundnear(0.01, $c), '==', 0.62, 'negative rates onetouch');

my $barrier2 = 1;    # More or less still a onetouch.

lives_ok { $c = Math::Business::BlackScholesMerton::Binaries::upordown($S, $barrier, $barrier2, $t, $r, $r - $q, $sigma, 0) }
'negative rates upordown does not die';
cmp_ok(roundnear(0.01, $c), '==', 0.62, 'negative rates upordown');

Test::NoWarnings::had_no_warnings();
done_testing();

