use strict;
use Devel::Cover;
use Test::More qw(no_plan);
use lib "lib";

#{
#	#no warnings 'redefine';
#	local $^W = 0;
#	*Test::More::plan = sub {};
#	*Test::More::import = sub {};
#}
# does not seem to work anymore
# so now we use a global variable

$::NO_PLAN = 1;

for my $file (glob 't/*.t') {
	next if $file =~ /warn\d+\.t$/;
	require $file;
}