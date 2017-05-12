use strict;
use warnings;

use MarpaX::Grammar::GraphViz2;

use Path::Tiny; # For path().

use Test::More;

# ------------------------------------------------

sub process
{
	my($file_name) = @_;

	my($marpa_file_name) = path('share', 'metag.bnf');
	my($user_file_name)  = path('share', "$file_name.bnf");

	my($parser) = MarpaX::Grammar::GraphViz2 -> new
	(
		legend         => 1,
		marpa_bnf_file => "$marpa_file_name",
		user_bnf_file  => "$user_file_name",
	);

	isa_ok($parser, 'MarpaX::Grammar::GraphViz2', "File: $file_name. new() returned correct object type");

} # End of process.

# ------------------------------------------------

BEGIN {use_ok('MarpaX::Grammar::Parser'); }

my($count) = 1;

for (qw/c.ast json.1 json.2 stringparser termcap.info/)
{
	process($_);
	$count++;
}

print "# Internal test count: $count. \n";

done_testing;
