#!/usr/bin/perl

use Test::More tests => 7;

BEGIN { use_ok('Finance::Amortization') }

my $am = Finance::Amortization->new(principal => 10000, rate => 0.12,
	periods => 12 * 5);

isa_ok($am, 'Finance::Amortization');

is($am->periods(), 60, 'periods');
is($am->principal, '10000.00', 'principal');
is($am->rate, 0.01, 'rate');
is($am->balance(1), 9877.56, 'balance 1');
is($am->interest(1), '100.00', 'interest 1');

