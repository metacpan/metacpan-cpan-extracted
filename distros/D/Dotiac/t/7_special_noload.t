use Test::More tests=>7;
eval {
	require Test::NoWarnings;
	Test::NoWarnings->import();
	1;
} or do {
	SKIP: {
		skip "Test::NoWarnings is not installed", 1;
		fail "This shouldn't really happen at all";
	};
};
BEGIN {
chdir "t";
unshift @INC,"."; #To load the local version, not the redist one...
};
require Dtest;
use Dotiac::DTL::Addon::unparsed;
dtest("special_unparsed_noload.html","A{{ X }}A{% unparsed %}{{ X }}{% endunparsed %}A{{ Z }}\n",{});
