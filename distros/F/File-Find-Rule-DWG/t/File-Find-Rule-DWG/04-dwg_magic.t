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
my @ret = sort { $a cmp $b } File::Find::Rule->dwg_magic('AC1003')->relative->in($data_dir->s);
is_deeply(
	\@ret,
	[
		'ex3.dwg',
	],
	"Get DWG files with 'AC1003' magic string in data directory.",
);
