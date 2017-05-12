use Test::More tests=>14;
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

# This tests for fixed bugs, so they don't reappear.

is_deeply([Dotiac::DTL::get_variables(undef)],[Dotiac::DTL::get_variables("")],"undef equals \"\" in get_variables()"); # Bugtracker #2514648 
is_deeply({Dotiac::DTL::get_variables(undef,"as","with")},{Dotiac::DTL::get_variables("","as","with")},"undef equals \"\" in get_variables(,'as')"); # Bugtracker #2514648 

dtest("tag_filter_bug.html","A<foo>A&lt;foo&gt;A\n",{}); # Bugtracker #2514617  

is_deeply({Dotiac::DTL::get_variables("loop foo bar","bar","foo")},{"" => ["loop"],"foo" => [],"bar" => []},"get_variables() with multiple keywords"); # Bugtracker #2569310 
is_deeply({Dotiac::DTL::get_variables("loop foo","bar","foo")},{"" => ["loop"],"foo" => []},"get_variables() with multiple keywords"); # Bugtracker #2569310 
is_deeply({Dotiac::DTL::get_variables("loop bar foo","bar","foo")},{"" => ["loop"],"foo" => [],"bar" => []},"get_variables() with multiple keywords"); # Bugtracker #2569310 
is_deeply({Dotiac::DTL::get_variables("loop bar","bar","foo")},{"" => ["loop"],"bar" => []},"get_variables() with multiple keywords"); # Bugtracker #2569310 
is_deeply({Dotiac::DTL::get_variables("loop foo bar","foo","bar")},{Dotiac::DTL::get_variables("loop foo bar","bar","foo")},"get_variables() with switched arguments"); # Addition to Bugtracker #2569310 
