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
no warnings;


require Dtest;
use warnings;
use strict;
$Dotiac::DTL::ALLOWED_INCLUDE_ROOTS=1;
dtest("tag_ssi.html","AB\nACA\nB\nA\n",{var1=>B=>var2=>C=>inc_name=>"inc_more.html",inc_object=>"inc_var.html"});
dtest("tag_ssi_static.html","A{{ var1 }}\nA{{ var2 }}A\n{{ var1 }}\nA\n",{var1=>B=>var2=>C=>inc_name=>"inc_more.html",inc_object=>"inc_var.html"});
my $inc=Dotiac::DTL->new("inc_var.html");
$Dotiac::DTL::ALLOWED_INCLUDE_ROOTS=0;
