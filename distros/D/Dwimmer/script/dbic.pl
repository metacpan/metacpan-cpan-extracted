#!/usr/bin/perl
use strict;
use warnings;

use Cwd qw(abs_path);
use DBIx::Class::Schema::Loader qw(make_schema_at);
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);

my $lib;
BEGIN {
	$lib = File::Spec->catdir( dirname(dirname abs_path($0)), 'lib');
}
use lib $lib;

#use Dwimmer::Tools;

my $temp = tempdir( CLEANUP => 0 );
my $root = File::Spec->catdir($temp, 'root');

system "$^X -I$lib script/dwimmer_admin.pl --setup --email dev\@dwimmer.org --password dwimmer --root $root";

my $dbfile = File::Spec->catfile($root, 'db', 'dwimmer.db');

make_schema_at(
	'Dwimmer::DB',
	{
		debug => 0,
		dump_directory => './lib',
	},
	[
		"dbi:SQLite:dbname=$dbfile", "", "",
	],
);
