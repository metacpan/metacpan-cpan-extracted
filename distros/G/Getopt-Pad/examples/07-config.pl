#!/usr/bin/env perl

# Config files. Values come from the command line, then from config files,
# then from the spec default. Without --config, every existing file in
# 'paths' is loaded in order, and a later file overrides an earlier one
# option by option. --config FILE loads only that file; a bare --config
# loads 'defaultPath'. --create-default-config writes a starter file with
# the defaults. Config files are grouped like the help output: 'retries'
# and 'endpoint' are set under "Network".
#
# 07-config.json next to this script is the first file in 'paths'. The
# second one, ~/.example07.json, does not exist until you create it.
#
# Try:
#   perl examples/07-config.pl                     (endpoint and retries from 07-config.json)
#   perl examples/07-config.pl --retries 1         (the command line wins over the file)
#   perl examples/07-config.pl --create-default-config ~/.example07.json
#   (edit retries in ~/.example07.json, e.g. to 9, then:)
#   perl examples/07-config.pl                     (retries from ~/.example07.json, endpoint still from 07-config.json)
#   perl examples/07-config.pl --config            (only the defaultPath, ~/.example07.json)
#   perl examples/07-config.pl --config examples/07-config.json
#   perl examples/07-config.pl --help

use v5.26;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", $FindBin::Bin;

use Getopt::Pad;
use ResultDump;

my $opt = GetOptions(
	options => {
		'log-level' => {
			type    => 'string',
			default => 'info',
			valid   => [qw(debug info warn error)],
			help    => 'How much to log',
		},
		'retries' => {
			type    => 'int',
			default => 3,
			min     => 0,
			group   => 'Network',
			help    => 'How often to retry a failed request',
		},
		'endpoint' => {
			type  => 'url',
			group => 'Network',
			help  => 'The server to talk to',
		},
	},
	config => {
		format      => 'json',
		paths       => ["$FindBin::Bin/07-config.json", '~/.example07.json'],
		defaultPath => '~/.example07.json',
	},
	description => 'Demonstrate config files.',
);

dumpResult($opt);
