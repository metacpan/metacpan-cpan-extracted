use strict;
use Test::More tests => 17;
use File::Spec;

use_ok('File::BaseDir', qw/:lookup xdg_data_files xdg_config_files/);

# Initalize test data:

# t/
# `-- data/		$dir[1]
#     |-- dir/		$dir[2]
#     |   `-- test	$file[1]
#     `-- test		$file[0]

my @dir = ('t', map File::Spec->catdir(@$_),
	[qw/t data/], [qw/t data dir/] );
my @file = (map File::Spec->catfile(@$_),
	[qw/t data test/], [qw/t data dir test/] );
mkdir $dir[1] or die $! unless -d $dir[1];
mkdir $dir[2] or die $! unless -d $dir[2];
open TEST, ">$file[0]" or die $!;
print TEST "test 1 2 3\n";
close TEST;
eval { chmod 0644, $file[0] }; # reset previous run
open TEST, ">$file[1]" or die $!;
print TEST "test 1 2 3\n";
close TEST;

$ENV{XDG_CONFIG_HOME} = 'foo';
$ENV{XDG_CONFIG_DIRS} = 'bar';
$ENV{XDG_DATA_HOME} = '.';
$ENV{XDG_DATA_DIRS} = join ':', @dir;

is(data_home(qw/t data test/), $file[0], 'data_home');
is(data_files(qw/data test/), $file[0], 'data_files');
is_deeply([data_files(qw/test/)], \@file, 'data_files - list');
is(data_dirs(qw/data dir/), $dir[2], 'data_dirs');
is_deeply([data_dirs(qw/data dir/)], [$dir[2]], 'data_dirs - list');

ok(!data_files(qw/data dir/), 'data_files does not match dir');
ok(!data_dirs(qw/data test/), 'data_dirs does not match file');

is_deeply([xdg_data_files(qw/test/)], \@file,
	'xdg_data_files - for backward compatibility');

$ENV{XDG_CONFIG_HOME} = '.';
$ENV{XDG_CONFIG_DIRS} = join ':', @dir;
$ENV{XDG_DATA_HOME} = 'foo';
$ENV{XDG_DATA_DIRS} = 'bar';

is(config_home(qw/t data test/), $file[0], 'config_home');
is(config_files(qw/data test/), $file[0], 'config_files');
is_deeply([config_files(qw/test/)], \@file, 'config_files - list');
is(config_dirs(qw/data dir/), $dir[2], 'config_dirs');
is_deeply([config_dirs(qw/data dir/)], [$dir[2]], 'config_dirs - list');

is_deeply([xdg_config_files(qw/test/)], \@file,
	'xdg_config_files - for backward compatibility');

SKIP: {
	eval { chmod 0200, $file[0] }; # make non-readable
	skip "chmod not supported", 1 if -r $file[0];
	is(config_files(qw/test/), $file[1], 'config_files checks for read');
}

$ENV{XDG_CACHE_HOME} = 't/data';
ok(cache_home('test') eq $file[0], 'data_cache');

