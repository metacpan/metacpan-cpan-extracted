#!/usr/bin/env perl

use strict;
use warnings;

use File::Slurper 'read_text';
use File::Temp;

use MarpaX::Grammar::Parser;

use Path::Tiny; # For path().

use Test2::Bundle::Extended;

# ------------------------------------------------

sub process
{
	my($file_name) = @_;

	# The EXLOCK option is for BSD-based systems.

	my($temp_dir)			= File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
	my($temp_dir_name)		= $temp_dir -> dirname;
	my($tree_file_name)		= path($temp_dir_name, "$file_name.test.tree");
	my($marpa_file_name)	= path('share', 'metag.bnf');
	my($user_file_name)		= path('share', "$file_name.bnf");
	my($orig_file_name)		= path('share', "$file_name.raw.tree");
	my($parser)				= MarpaX::Grammar::Parser -> new
	(
		bind_attributes => 0,
		logger          => '',
		marpa_bnf_file  => "$marpa_file_name",
		raw_tree_file   => "$tree_file_name",
		user_bnf_file   => "$user_file_name",
	);

	is($parser -> logger, '', 'logger() returns correct string');
	is($parser -> user_bnf_file, "$user_file_name", 'input_file() returns correct string');
	is($parser -> raw_tree_file, "$tree_file_name", 'tree_file() returns correct string');

	$parser -> run;

	is(read_text("$orig_file_name"), read_text("$tree_file_name"), "$file_name: Output tree matches shipped tree");

} # End of process.

# ------------------------------------------------

my($count) = 1;

for (qw/c.ast json.1 json.2 json.3 stringparser termcap.info/)
{
	diag("Input: $_");
	diag('Note! Testing c.ast can take 7 seconds') if (/c.ast/);

	process($_);

	$count += 4;
}

print "# Internal test count: $count. \n";

done_testing;
