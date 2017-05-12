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
no warnings;
BEGIN {
	*CORE::GLOBAL::time = sub { return 1294484984 };
	*CORE::GLOBAL::localtime = sub { return(gmtime($_[0])) };
}

require Dtest;
use warnings;
use strict;
my @t=gmtime(1294484984);
SKIP: {
	skip("Strange time handling detected, can't test for it then",6) unless $t[0] == "44" and $t[1] == 9 and $t[2] == 11;
	dtest("tag_now.html","p.m.PMjan08Sat11:09January1111 1111of098Saturday001Jan1Jan.+000011:09 p.m.Sat, 1 Jan 2011 11:09:44 +000044th30w011120117\n",{});
};
