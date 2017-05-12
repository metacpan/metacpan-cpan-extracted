#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use File::Temp;

use Path::Tiny; # For path().

use Test::More;

# ------------------------------------------------

sub process
{
	my($file_name) = @_;
	my(@base_name) = File::Spec -> splitpath($file_name);
	substr($base_name[2], -4, 4) = '.txt';

	# The EXLOCK option is for BSD-based systems.

	my($temp_dir)           = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
	my($temp_dir_name)      = $temp_dir -> dirname;
	my($output_file_name)   = path("$temp_dir_name/$base_name[2]");
	my($expected_dir_name)  = 'lua.output';
	my($expected_file_name) = path("$expected_dir_name/$base_name[2]");
	my($parser)             = MarpaX::Languages::Lua::Parser -> new
	(
		input_file_name  => "$file_name",
		logger           => '',
		output_file_name => "$output_file_name",
	);

	$parser -> run;

	is_deeply([path($expected_file_name) -> lines_utf8], [path($output_file_name) -> lines_utf8], "$file_name: OK");

} # End of process.

# ---------------------------------

BEGIN {use_ok('MarpaX::Languages::Lua::Parser'); }

my($count) = 1;

for (<"lua.sources/*">)
{
	if ($_ eq 'lua.sources/keyword.as.identifier.lua')
	{
		diag "Skipping $_. \n";

		next;
	}

	$count += 1;

	process($_);
}

print "# Internal test count: $count. \n";

done_testing;
