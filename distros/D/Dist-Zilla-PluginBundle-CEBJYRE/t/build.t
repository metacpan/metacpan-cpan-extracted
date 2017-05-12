use strict;
use warnings;
use Test::More tests => 2;
use Test::DZil;

my $tzil = Builder->from_config(
	{dist_root => 'corpus'},
	{
		add_files => {
			'source/dist.ini' => simple_ini('@CEBJYRE'),
		}
	}
);

ok(1, "The builder didn't explode on the configuration");

my $build_dir = $tzil->build();

opendir my $dirh, $build_dir or die;
my @files = grep {/^[^.]/} readdir $dirh;
my @expected_files = qw(
	Changes
	dist.ini
	lib
	LICENSE
	Makefile.PL
	MANIFEST
	META.json
	README
	t
);

is_filelist(\@files, \@expected_files, 'The expected files were built');
