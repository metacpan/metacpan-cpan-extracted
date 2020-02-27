use strict;
use warnings;

use File::Find::Rule;
use File::Find::Rule::DMIDecode;
use File::Object;
use Test::NoWarnings;
use Test::More 'tests' => 3;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my @ret = File::Find::Rule->dmidecode_handle('0x0001')->relative->in($data_dir->s);
is_deeply(
	\@ret,
	['thinkpad_x270'],
	'Get dmidecode files with 0x0001 handle in data directory.',
);

# Test.
@ret = File::Find::Rule->dmidecode_handle('0x000G')->relative->in($data_dir->s);
is_deeply(
	\@ret,
	[],
	"Get dmidecode files with '0x000G' handle in data directory.",
);
