#!/usr/bin/env perl

use strict;
use warnings;

use Devel::Cover::DB;
use Devel::Cover::Report::Phabricator;
use Cwd qw(abs_path);
use File::Basename qw(dirname basename);
use File::Copy qw(copy);
use File::Temp;
use File::Slurp qw(slurp);
use File::chdir;
use Test::More tests => 1;
use JSON qw(from_json);

my $test_cover_dbs = abs_path(dirname(__FILE__) . '/test_cover_dbs');

sub run_test_dir {
	my $test_dir = shift;

	my ($structure) = glob("$test_dir/structure/*");
	my $tmpdir = File::Temp->newdir();
	mkdir("$tmpdir/structure");
	copy("$test_dir/cover.13", $tmpdir);
	my @files;
	for my $lib (glob("$test_dir/lib/*")) {
		push @files, basename($lib);
		copy($lib, $tmpdir);
	}
	copy($structure, "$tmpdir/structure");
	my $expected = from_json(slurp("$test_dir/expected.json"));

	local $CWD=$tmpdir;
	my $db = Devel::Cover::DB->new(db => $tmpdir);
	Devel::Cover::Report::Phabricator->report(
	$db,
	{ outputdir => $tmpdir,
		file      => \@files,
		option    => { outputfile => 'phabricator.json' }
	});
	my $report = from_json(slurp("$tmpdir/phabricator.json"));
	is_deeply($report, $expected, q{Generated report matches expected output for directory '}.basename($test_dir).q{'});
}

for my $dir (glob("$test_cover_dbs/*")) {
	run_test_dir($dir);
}

