#!perl

use strict;
use warnings;
use FindBin;
use Test::More tests => 24;
use DateTime;
use File::Basename;
use File::Path;
use File::Maintenance;

my $source_dir = "$FindBin::Bin/source";
my $target_dir = "$FindBin::Bin/target";
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

sub get_hash_ref {
	my %hash;
	foreach (@_) {
		$hash{$source_dir . $_}++;
	}
	return \%hash;
}

sub get_files {
	my @files;
	foreach my $file_spec(test_map()){
		push @files, $file_spec->{file};
	}
	return @files;
}

sub run_tests {
	my $name = shift;
	my @archived_files = @_;
	foreach my $file (get_files) {
		if (grep(/^$file/, @archived_files)) {
			ok( -f $target_dir . $file, "$name: File $file archived");
		} else {
			ok(-f $source_dir . $file, "$name: File $file not archived");
		}
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

	rmtree($target_dir) if -d $target_dir;
	mkpath($target_dir);
}

my $fm = File::Maintenance->new(
	{
		age               => '31m',
		directory         => $source_dir,
		recurse           => 1,
		pattern           => '*',
		archive_directory => $target_dir,
	}
);


my @archived_files = (
	'/dummy.pm',
	'/mod/mymod.pm',
	'/mod/another/moremod.pm',
	'/mod/another/moremod.xml'
);

create_files;
$fm->archive;

run_tests('Older than 31m', @archived_files);

@archived_files = (
	'/mod/another/moremod.xml'
);

create_files;
$fm->pattern('*.xml');
$fm->archive;
run_tests('XML files older than 31m', @archived_files);

@archived_files = (
	'/dummy.xml',
	'/mod/another/moremod.xml'
);

create_files;
$fm->age('0s');
$fm->pattern('*.xml');
$fm->archive;
run_tests('All XML Files', @archived_files);

rmtree($source_dir);
rmtree($target_dir);
