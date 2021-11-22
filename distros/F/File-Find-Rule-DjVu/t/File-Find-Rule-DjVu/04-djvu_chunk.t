use strict;
use warnings;

use File::Find::Rule::DjVu;
use File::Object;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my @ret = File::Find::Rule->djvu_chunk('INFO')->relative->in($data_dir->s);
is_deeply(
	\@ret,
	['11a7ffc0-c61e-11e6-ac1c-001018b5eb5c.djvu'],
	'Get DjVu files with INFO chunk in data directory.',
);

# Test.
@ret = File::Find::Rule->djvu_chunk('BG44')->relative->in($data_dir->s);
is_deeply(
	\@ret,
	['11a7ffc0-c61e-11e6-ac1c-001018b5eb5c.djvu'],
	'Get DjVu files with BG44 chunk in data directory.',
);

# Test.
@ret = File::Find::Rule->djvu_chunk('ANTz')->relative->in($data_dir->s);
is_deeply(
	\@ret,
	[],
	'Get DjVu files with ANTz chunk in data directory.',
);
