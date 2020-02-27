use strict;
use warnings;

use File::Find::Rule;
use File::Find::Rule::DMIDecode;
use File::Object;
use Test::NoWarnings;
use Test::More 'tests' => 2;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my @ret = File::Find::Rule->dmidecode_file->relative->in($data_dir->s);
is_deeply(
	\@ret,
	['thinkpad_x270'],
	'Get dmidecode files in data directory.',
);
