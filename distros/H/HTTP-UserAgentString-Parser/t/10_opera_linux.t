use strict;
use diagnostics;
use Test::More "no_plan";

my $PKG = 'HTTP::UserAgentString::Parser';

BEGIN {
	use_ok('HTTP::UserAgentString::Parser');
}

my $p = $PKG->new();
ok($p, "Created OK");

my $browser = $p->parse('Opera/9.80 (X11; Linux x86_64; U; en) Presto/2.9.168 Version/11.50');
ok($browser, "String parsed OK");
is(ref($browser), 'HTTP::UserAgentString::Browser', 'parse() return a Browser');
is($browser->type, 0);
is($browser->name, 'Opera');
is($browser->version, '11.50');
my $os = $browser->os;
ok($os);
is($browser->os->family, 'Linux');
ok(! $browser->isRobot);
ok($browser->isBrowser);
ok(! $browser->isEmail);
ok(! $browser->isLibrary);
ok(! $browser->isWAP);
ok(! $browser->isMobile);
is($browser->typeDesc, 'Browser');
