#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Memphis;
use FindBin;
use File::Spec;

exit main() unless caller;


sub main {
	my $map = Memphis::Map->new();
	isa_ok($map, 'Memphis::Map');

	my @box = $map->get_bounding_box();
	is_deeply(
		\@box,
		[0, 0, 0, 0],
		"get_bounding_box"
	);


	my $file = File::Spec->catfile($FindBin::Bin, 'map.osm');
	$map->load_from_file($file);
	pass("load_from_file");

	@box = $map->get_bounding_box();
	my @expected_box = (47.10, 9.14, 47.16, 9.23);
	foreach my $expected (@expected_box) {
		my $got = shift @box;
		is_float($got, $expected, 0.1, "get_bounding_box from load_from_file");
	}


	$map = Memphis::Map->new();
	$map->load_from_data(slurp($file));
	pass("load_from_data");

	@box = $map->get_bounding_box();
	foreach my $expected (@expected_box) {
		my $got = shift @box;
		is_float($got, $expected, 0.1, "get_bounding_box from load_from_data");
	}

	return 0;
}


sub is_float {
	my ($got, $expected, $delta, $message) = @_;
	$delta = 1.0 unless defined $delta;
	$message = "$message; " if defined $message;

	my $diff = $got - $expected;
	my $tester = Test::Builder->new();
	$tester->ok($diff >= -$delta && $diff <= $delta, $message . "$got == $expected (delta: $delta)");
}


sub slurp {
	my ($file) = @_;
	local $/;
	open my $handle, $file or die "Can't read file $file because $!";
	my $content = <$handle>;
	close $handle;
	return $content;
}
