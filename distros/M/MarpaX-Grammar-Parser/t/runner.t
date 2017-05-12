use strict;
use warnings;

use File::Slurp; # For read_file().
use File::Temp;

use MarpaX::Grammar::Parser;

use Path::Tiny;   # For path().

use Test::More;

# ------------------------------------------------

sub process
{
	my($file_name) = @_;

	# The EXLOCK option is for BSD-based systems.

	my($temp_dir)        = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
	my($temp_dir_name)   = $temp_dir -> dirname;
	my($tree_file_name)  = path($temp_dir_name, "$file_name.test.tree");
	my($marpa_file_name) = path('share', 'metag.bnf');
	my($user_file_name)  = path('share', "$file_name.bnf");
	my($orig_file_name)  = path('share', "$file_name.raw.tree");

	my($parser) = MarpaX::Grammar::Parser -> new
	(
		bind_attributes => 0,
		logger          => '',
		marpa_bnf_file  => "$marpa_file_name",
		raw_tree_file   => "$tree_file_name",
		user_bnf_file   => "$user_file_name",
	);

	isa_ok($parser, 'MarpaX::Grammar::Parser', 'new() returned correct object type');
	is($parser -> user_bnf_file, $user_file_name, 'input_file() returns correct string');
	is($parser -> logger, '', 'logger() returns correct string');
	is($parser -> raw_tree_file, $tree_file_name, 'tree_file() returns correct string');

	$parser -> run;

	is(scalar read_file("$orig_file_name", binmode => ':utf8'), scalar read_file("$tree_file_name", binmode => ':utf8'), "$file_name: Output tree matches shipped tree");

} # End of process.

# ------------------------------------------------

BEGIN {use_ok('MarpaX::Grammar::Parser'); }

my($count) = 1;

# We omit c.ast only because it takes 7 seconds to process.

for (qw/json.1 json.2 stringparser termcap.info/)
{
	process($_);

	$count += 5;
}

print "# Internal test count: $count. \n";

done_testing;
