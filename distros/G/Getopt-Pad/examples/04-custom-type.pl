#!/usr/bin/env perl

# Extending Getopt::Pad with a custom option type: 'even' accepts only even
# integers. A type subclasses Getopt::Pad::Type, names itself via the NAMES
# constant, tells Getopt::Long how to parse it via glSuffix, and validates
# in check(). Registering it makes the name usable as any option's 'type'.
#
# Try:
#   perl examples/04-custom-type.pl --workers 8
#   perl examples/04-custom-type.pl --workers 7    (fails: not even)

use v5.26;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", $FindBin::Bin;

use Object::Pad;
use Getopt::Pad;
use Getopt::Pad::Type;

class My::Type::Even :isa(Getopt::Pad::Type) {
	use constant NAMES => ['even'];

	method glSuffix() { return '=s' }

	method coerce($value) {
		return $value + 0;
	}

	method check($value) {
		return "'$value' is not an integer" if $value !~ /^-?\d+$/;
		return "$value is not an even number" if $value % 2;
		return undef;
	}

	method label() { return 'Even' }
}

Getopt::Pad::Type::registerType('My::Type::Even');

use ResultDump;

my $opt = GetOptions(
	options => {
		'workers' => { type => 'even', help => 'Number of worker processes (must be even)' },
	},
	description => 'Demonstrate a custom option type.',
);

dumpResult($opt);
