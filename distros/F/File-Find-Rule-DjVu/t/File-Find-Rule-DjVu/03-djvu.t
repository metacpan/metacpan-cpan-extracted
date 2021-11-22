use strict;
use warnings;

use File::Find::Rule::DjVu;
use File::Object;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my @ret = File::Find::Rule->djvu->relative->in($data_dir->s);
is_deeply(
	\@ret,
	[
		'11a7ffc0-c61e-11e6-ac1c-001018b5eb5c.djvu',
	],
	'Get DjVu files in data directory.',
);
