#!perl

use strict;
use warnings;
use FindBin;
use Test::More tests => 12;
use DateTime;
use File::Basename;
use File::Path;
use File::Maintenance;

my $source_dir = "$FindBin::Bin/source";
my $date       = DateTime->now(time_zone => 'local');
my %unit_map   = (
	s => 'seconds',
	m => 'minutes',
	h => 'hours',
	d => 'days'
);

sub test_map {
	return (
		{
			file => '/dummy.pm',
			age  => '3d'
		},
		{
			file => '/dummy.xml',
			age  => '3m'
		},
		{
			file => '/mod/mymod.pm',
			age  => '3d'
		},
		{
			file => '/mod/another/moremod.pm',
			age  => '1d'
		},
		{
			file => '/mod/another/moremod.xml',
			age  => '3h'
		},
		{
			file => '/image/one.jpg',
			age  => '30s'
		},
		{
			file => '/image/two.jpg',
			age  => '30m'
		},
		{
			file => '/image/sub/dir/two.jpg',
			age  => '30m'
		},
	);
}

my %extension = (
	'gzip'  => 'gz',
	'zip'   => 'zip',
	'bzip2' => 'bz2',
);


sub run_tests {
	my $name = shift;
	my $compress_type = shift;
	my @compressed_files = @_;

	foreach my $file (@compressed_files) {
		ok( -f $source_dir . $file . '.' . $extension{$compress_type},
		   "$name: File $file compressed");
	}
}

sub create_files {
	foreach my $file_spec (test_map()) {
		my $file = $source_dir . $file_spec->{file};
		if ($file_spec->{age} =~ /^(\d+)(s|m|h|d)$/) {
			my $unit      = $1;
			my $uom       = $2;
			my $base_date = $date->clone;
			$base_date->add($unit_map{$uom} => -$unit);

			unless (-d dirname($file)) {
				mkpath dirname($file);
			}

			open (my $fh, '>', $file);
			close $fh;
			utime $base_date->epoch, $base_date->epoch, $file;
		} else {
			die "Invalid age specifier: $file_spec->{age}"
		}
	}
}

my $fm = File::Maintenance->new(
	{
		age               => '31m',
		directory         => $source_dir,
		recurse           => 1,
		pattern           => '*',
	}
);


my @compressed_files = (
	'/dummy.pm',
	'/mod/mymod.pm',
	'/mod/another/moremod.pm',
	'/mod/another/moremod.xml'
);



create_files;

$fm->zip;
run_tests('Zip files', 'zip', @compressed_files);

create_files;
$fm->gzip;
run_tests('Gzip files', 'gzip', @compressed_files);

create_files;
$fm->bzip2;
run_tests('Bzip2 files', 'bzip2', @compressed_files);

rmtree($source_dir);
