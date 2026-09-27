#!/usr/bin/env perl

# Value checks and help output details: a fixed 'valid' list, a 'valid'
# coderef that computes the allowed values at run time, a 'lazyValid'
# predicate, float bounds, a file that has to exist, a directory that is
# created when missing, a 'typehint' label, and a hidden option.
#
# Try:
#   perl examples/08-checks.pl --level high --example 01-basic.pl --name my-tool
#   perl examples/08-checks.pl --ratio 0.25 --input examples/08-checks.pl
#   perl examples/08-checks.pl --cache-dir /tmp/getopt-pad-example08/cache   (creates the directory)
#   perl examples/08-checks.pl --debug                  (accepted, but not listed in --help)
#   perl examples/08-checks.pl --level extreme          (fails: not one of the valid values)
#   perl examples/08-checks.pl --example nope.pl        (fails: not one of the scripts in examples/)
#   perl examples/08-checks.pl --name My_Tool           (fails: lazyValid returns false)
#   perl examples/08-checks.pl --ratio 1.5              (fails: above max)
#   perl examples/08-checks.pl --input missing.txt      (fails: the file has to exist)
#   perl examples/08-checks.pl --help

use v5.26;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", $FindBin::Bin;

use Getopt::Pad;
use ResultDump;

my $opt = GetOptions(
	options => {
		'level' => {
			type    => 'string',
			default => 'medium',
			valid   => [qw(low medium high)],
			help    => 'valid arrayref: listed in this help and offered by shell completion',
		},
		'example' => {
			type  => 'string',
			valid => \&exampleScripts,
			help  => 'valid coderef: one of the example scripts, looked up when needed',
		},
		'name' => {
			type      => 'string',
			lazyValid => sub { $_[0] =~ /\A[a-z][a-z0-9-]*\z/ },
			typehint  => 'lowercase-name',
			help      => 'lazyValid: lowercase letters, digits and dashes',
		},
		'ratio' => {
			type => 'float',
			min  => 0,
			max  => 1,
			help => 'float with min and max',
		},
		'input' => {
			type      => 'file',
			mustExist => 1,
			help      => 'mustExist: the file has to exist',
		},
		'cache-dir' => {
			type                => 'dir',
			createPathIfMissing => 1,
			help                => 'createPathIfMissing: the directory is created with its parents',
		},
		'debug' => {
			hidden => 1,
		},
	},
	description => 'Demonstrate value checks.',
);

dumpResult($opt);

# The allowed values of --example, computed each time they are needed:
# when a value is checked and when the shell asks for completions.
sub exampleScripts {
	opendir(my $handle, $FindBin::Bin) or return [];
	return [sort grep { /\.pl\z/ } readdir $handle];
}
