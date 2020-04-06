use strict;
use warnings;

use File::Find::Rule;
use File::Find::Rule::DWG;
use File::Object;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my @ret = sort { $a cmp $b } File::Find::Rule->dwg->relative->in($data_dir->s);
is_deeply(
	\@ret,
	[
		'ex1.dwg',
		'ex2.dwg',
		'ex3.dwg',
	],
	'Get DWG files in data directory.',
);
