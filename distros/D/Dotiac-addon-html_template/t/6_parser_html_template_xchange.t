use Test::More;

eval "use Dotiac::DTL 0.8 qw//;1" or plan skip_all => "Dotiac::DTL 0.8 or higher required for parser-hotswapping: $@";
plan tests=>31;

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
use strict;
use warnings;
dtest("parser_htp_hotswap.html","AXACDAXA\n",{text=>"X",title=>"X",loop=>[{text=>"C"},{title=>"D"}]},"Pure hotswapping");
dtest("parser_htp_hotswap2.html","AXACDAXA\n",{text=>"X",title=>"X",loop=>[{text=>"C"},{title=>"D"}]},"Pure hotswapping with CI");
dtest("parser_ht_hotswap.html","AYACDAXA\n",{text=>"X",loop=>[{text=>"C"},{title=>"D"}]},"combined hotswapping");
dtest("parser_ht_hotswap.html","AYACDAXA\n",{text=>"X",loop=>[{text=>"C"},{title=>"D"}]},"combined hotswapping with CI");
dtest("parser_htp_hotswap.html","AXACDAXA\n",{text=>"X",title=>"X",loop=>[{text=>"C"},{title=>"D"}]},"Pure hotswapping again");


