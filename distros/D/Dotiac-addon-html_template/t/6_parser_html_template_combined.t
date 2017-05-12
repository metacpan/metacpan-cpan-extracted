use Test::More tests => 14;
eval {
	require Test::NoWarnings;
	Test::NoWarnings->import();
	#pass "Yo";
	1;
} or do {
	SKIP: {
		skip "Test::NoWarnings is not installed", 1;
		fail "This shouldn't really happen at all";
	};
};

chdir "t";
require Dtest;
use strict;
use warnings;


use_ok('Dotiac::DTL::Addon::html_template');
use Dotiac::DTL::Addon::html_template;

dtest("parser_combined.html","AYACDAXA\n",{text=>"X",loop=>[{text=>"C"},{title=>"D"}]},"nicely combined");
dtest("parser_combined_evil.html","AYACDAXAD\n",{text=>"X",loop=>[{text=>"C"},{title=>"D"}]},"evilly combined");
