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
chdir "t";

require Dtest;

dtest("undoc_cycle.html","ABACABA\n",{});
