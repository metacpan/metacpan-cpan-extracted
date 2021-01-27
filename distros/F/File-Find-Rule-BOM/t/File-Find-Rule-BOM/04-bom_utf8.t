use strict;
use warnings;

use File::Find::Rule;
use File::Find::Rule::BOM;
use File::Object;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my @ret = File::Find::Rule->bom_utf8->relative->in($data_dir->s);
is_deeply(
	\@ret,
	[
		'UTF_8_bom',
	],
	'Get files with UTF-8 BOM in data directory.',
);
