use strict;
use warnings;

use File::Find::Rule;
use File::Find::Rule::BOM;
use File::Object;
use Test::NoWarnings;
use Test::More 'tests' => 2;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my @ret = File::Find::Rule->bom_utf16->relative->in($data_dir->s);
is_deeply(
	\@ret,
	[
		'UTF_16_bom',
	],
	'Get files with UTF-16 BOM in data directory.',
);
