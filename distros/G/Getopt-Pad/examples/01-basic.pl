#!/usr/bin/env perl

# Basic Getopt::Pad usage: typed options with groups, defaults, a valid list,
# and one required positional argument.
#
# Try:
#   perl examples/01-basic.pl --owner dave --tag alpha --tag beta https://example.com/project.git
#   perl examples/01-basic.pl --help

use v5.26;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", $FindBin::Bin;

use Getopt::Pad;
use ResultDump;

my $opt = GetOptions(
	options => {
		'owner|o' => {
			type     => 's',
			required => 1,
			help     => 'Target owner (user or organization)',
			group    => 'Target',
		},
		'repo' => {
			type  => 's',
			help  => 'Target repository name (default: the source basename)',
			group => 'Target',
		},
		'private' => {
			type    => '!',
			default => 1,
			help    => 'Create the target repository as private; --no-private makes it public',
			group   => 'Target',
		},
		'log-level' => {
			type    => 's',
			default => 'info',
			valid   => [qw(trace debug info warn error fatal)],
			help    => 'Logging level to use',
		},
		'tag' => {
			type     => 's',
			multiple => 1,
			help     => 'May be given more than once; the reader returns an arrayref',
		},
	},
	args => [
		{ type => 'url', short => 'source-url', required => 1, help => 'The source address' },
	],
	description => 'Demonstrate basic Getopt::Pad usage.',
	examples    => [
		{ text => 'A typical invocation', args => '--owner dave https://example.com/project.git' },
	],
);

dumpResult($opt);
