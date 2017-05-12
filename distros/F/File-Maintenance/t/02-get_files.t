#!perl

use strict;
use warnings;
use FindBin;
use Test::More tests => 6;
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

my %directory;

my @test_map = (
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

sub get_hash_ref {
	my %hash;
	foreach (@_) {
		$hash{$_}++;
	}
	return \%hash;
}

foreach my $file_spec (@test_map) {
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

my $fm = File::Maintenance->new(
	{
		age       => '31m',
		directory => $source_dir,
		recurse   => 1,
		pattern   => '*',
	}
);

is_deeply (
	get_hash_ref($fm->get_files),
	get_hash_ref(
		$source_dir . '/dummy.pm',
		$source_dir . '/mod/mymod.pm',
		$source_dir . '/mod/another/moremod.pm',
		$source_dir . '/mod/another/moremod.xml',
	), 
	'All 31 minutes'
);

$fm->age('0m') ;
$fm->pattern('*.xml');

is_deeply (
	get_hash_ref($fm->get_files),
	get_hash_ref(
		$source_dir . '/dummy.xml',
		$source_dir . '/mod/another/moremod.xml',
	), 
	'All XML FIles'
);

$fm->age('15m') ;
is_deeply (
	get_hash_ref($fm->get_files),
	get_hash_ref(
		$source_dir . '/mod/another/moremod.xml',
	), 
	'All XML FIles older than 15 minutes'
);

$fm->age('2d') ;
$fm->pattern('*');
is_deeply (
	get_hash_ref($fm->get_files),
	get_hash_ref(
		$source_dir . '/dummy.pm',
		$source_dir . '/mod/mymod.pm',
	), 
	'All files older than 2 days'
);

$fm->recurse(0);
is_deeply (
	get_hash_ref($fm->get_files),
	get_hash_ref(
		$source_dir . '/dummy.pm',
	), 
	'All files older than 2 days, non-recursive'
);

$fm->age('0m');
$fm->pattern(qr/^m\w+\.pm$/);
$fm->recurse(1);
is_deeply (
	get_hash_ref($fm->get_files),
	get_hash_ref(
		$source_dir . '/mod/mymod.pm',
		$source_dir . '/mod/another/moremod.pm',
	), 
	'Perl packaged modules starting with "m" using regex'
);

rmtree($source_dir);



