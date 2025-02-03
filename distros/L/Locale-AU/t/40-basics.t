#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 15;
use Locale::AU;
use Test::NoWarnings;

# Module loads
BEGIN { use_ok('Locale::AU') }

# Object creation
my $locale = new_ok('Locale::AU');

# Test state codes
my @expected_codes = qw(ACT NSW NT QLD SA TAS VIC WA);
my @actual_codes = $locale->all_state_codes();
is_deeply(\@actual_codes, \@expected_codes, 'State codes match expected values');

# Test state names
my @expected_names = (
	'AUSTRALIAN CAPITAL TERRITORY', 'NEW SOUTH WALES',
	'NORTHERN TERRITORY', 'QUEENSLAND', 'SOUTH AUSTRALIA',
	'TASMANIA', 'VICTORIA', 'WESTERN AUSTRALIA'
);
my @actual_names = $locale->all_state_names();
is_deeply(\@actual_names, \@expected_names, 'State names match expected values');

# Code-to-state mapping
is($locale->{code2state}{'NSW'}, 'NEW SOUTH WALES', "Code 'NSW' maps to 'NEW SOUTH WALES'");

# State-to-code mapping
is($locale->{state2code}{'NEW SOUTH WALES'}, 'NSW', "State 'NEW SOUTH WALES' maps to 'NSW'");

# Bi-directional consistency check
foreach my $code (@actual_codes) {
	my $state = $locale->{code2state}{$code};

	is($locale->{state2code}{$state}, $code, "Consistency check for $code and $state");
}
