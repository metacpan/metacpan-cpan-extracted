use strict;
use diagnostics;
use Test::More "no_plan";

my $PKG = 'HTTP::UserAgentString::Parser';

BEGIN {
	use_ok('HTTP::UserAgentString::Parser');
}

my $p = $PKG->new();
ok($p, "Created OK");

my $string = 'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.106 Safari/535.2';
for (1..3) {
	# Test 3 times to check that cache works ok
	my $browser = $p->parse($string);
	ok($browser, "String parsed OK");
	is(ref($browser), 'HTTP::UserAgentString::Browser', 'parse() return a Browser');
	is($browser->name, 'Chrome', 'Browser is Chrome');
	is($browser->version, '15.0.874.106');
	ok(defined($browser->os));
}

