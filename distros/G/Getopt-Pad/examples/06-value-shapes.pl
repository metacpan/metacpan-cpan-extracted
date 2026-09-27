#!/usr/bin/env perl

# Options that hold more than one value. 'multiple' collects a repeated
# option into a list, 'csv' also splits every value at commas, 'hash'
# collects KEY=VALUE words into a mapping, and 'objectlist' collects
# INDEX.FIELD=VALUE words into a list of records. Every single value still
# passes the type and 'valid' checks. Absent list options read as [], an
# absent hash option as {}.
#
# Try:
#   perl examples/06-value-shapes.pl --tag red --tag blue
#   perl examples/06-value-shapes.pl --color red,green --color blue
#   perl examples/06-value-shapes.pl --define os=linux --define arch=x86_64
#   perl examples/06-value-shapes.pl --limit cpu=2 --limit memory=512
#   perl examples/06-value-shapes.pl --server 0.host=alpha --server 0.port=8080 --server 1.host=beta
#   perl examples/06-value-shapes.pl --color red,,blue          (fails: empty item)
#   perl examples/06-value-shapes.pl --limit cpu=two            (fails: not an integer)
#   perl examples/06-value-shapes.pl --server 1.host=beta       (fails: missing index 0)
#   perl examples/06-value-shapes.pl --help

use v5.26;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", $FindBin::Bin;

use Getopt::Pad;
use ResultDump;

my $opt = GetOptions(
	options => {
		'tag' => {
			type     => 'string',
			multiple => 1,
			help     => 'multiple: may be given more than once',
		},
		'color' => {
			type     => 'string',
			multiple => 1,
			csv      => 1,
			valid    => [qw(red green blue)],
			help     => 'multiple + csv: repeatable, and every value is split at commas',
		},
		'define' => {
			type => 'string',
			hash => 1,
			help => 'hash: KEY=VALUE pairs',
		},
		'limit' => {
			type    => 'int',
			hash    => 1,
			default => { cpu => 1 },
			help    => 'hash with int values; the default is a hashref',
		},
		'server' => {
			type       => 'string',
			objectlist => 1,
			help       => 'objectlist: INDEX.FIELD=VALUE pairs, collected into a list of hashrefs',
		},
	},
	description => 'Demonstrate options with several values.',
);

dumpResult($opt);
