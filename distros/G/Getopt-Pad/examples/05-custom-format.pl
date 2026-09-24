#!/usr/bin/env perl

# Extending Getopt::Pad with a custom config file format: TOML via
# TOML::Tiny. A format subclasses Getopt::Pad::Config::Format, names itself
# via the NAMES constant, and implements parse($text) returning the config
# structure (group names containing option-name mappings); die() on parse
# problems - the message surfaces as a regular config error. Getopt::Pad
# reads and writes the files itself as UTF-8, so a format only translates
# text. Registering it makes the name usable as the config block's 'format'.
#
# Try:
#   perl examples/05-custom-format.pl --create-default-config /tmp/demo.toml
#   perl examples/05-custom-format.pl --config /tmp/demo.toml
#   perl examples/05-custom-format.pl --config /tmp/demo.toml --owner cli-wins
#   perl examples/05-custom-format.pl --help

use v5.26;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", $FindBin::Bin;

use Object::Pad;
use Getopt::Pad;
use Getopt::Pad::Config::Format;

class My::Format::Toml :isa(Getopt::Pad::Config::Format) {
	use Carp qw(croak);
	use Feature::Compat::Try;

	use constant NAMES => ['toml'];

	method parse($text) {
		try { require TOML::Tiny }
		catch ($error) { croak "config format 'toml' requires the TOML::Tiny module" }

		return TOML::Tiny::from_toml($text);
	}

	# Optional: enables --create-default-config for this format.
	method dump($data) {
		try { require TOML::Tiny }
		catch ($error) { croak "config format 'toml' requires the TOML::Tiny module" }

		return TOML::Tiny::to_toml($data) . "\n";
	}
}

Getopt::Pad::Config::Format::registerFormat('My::Format::Toml');

use ResultDump;

my $opt = GetOptions(
	options => {
		'owner'     => { type => 's', help => 'Target owner' },
		'log-level' => { type => 's', default => 'info', valid => [qw(trace debug info warn error fatal)] },
	},
	config => {
		format => 'toml',
		paths  => ['~/.example05.toml'],
	},
	description => 'Demonstrate a custom config file format.',
);

dumpResult($opt);
