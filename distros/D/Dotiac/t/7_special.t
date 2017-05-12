use Test::More tests=>13;
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
chdir "t";
unshift @INC,"."; #To load the local version, not the redist one...
require Dtest;
#require Dotiac::DTL::Addon::unparsed;
dtest("special_unparsed.html","A{{ X }}A{% unparsed %}{{ X }}{% endunparsed %}A{{ Z }}\n",{});
dtest("dir/subinc.html","ABACAB\nA\n",{});
