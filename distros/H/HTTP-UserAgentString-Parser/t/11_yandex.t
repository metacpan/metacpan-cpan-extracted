use strict;
use diagnostics;
use Test::More "no_plan";

my $PKG = 'HTTP::UserAgentString::Parser';

BEGIN {
	use_ok('HTTP::UserAgentString::Parser');
}

my $p = $PKG->new();
ok($p, "Created OK");

my $string = 'Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)';
for (1..3) {
	# Test 3 times to check that cache works ok
	my $robot = $p->parse($string);
	ok($robot, "String parsed OK");
	is(ref($robot), 'HTTP::UserAgentString::Robot');
	is($robot->name, 'YandexBot/3.0');
	is($robot->family, 'YandexBot');
	ok(not defined($robot->os));
	is($robot->ico, 'bot_Yandex.png');
	ok($robot->isRobot());
}
