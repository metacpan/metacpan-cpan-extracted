use strict;
use diagnostics;
use Test::More "no_plan";

my $PKG = 'HTTP::UserAgentString::Parser';

BEGIN {
	use_ok('HTTP::UserAgentString::Parser');
}

my $p = $PKG->new();
ok($p, "Created OK");
is('ARRAY', ref($p->browser_reg));
isnt(0, scalar(@{$p->browser_reg}));
is('ARRAY', ref($p->os_reg));
isnt(0, scalar(@{$p->os_reg}));
is('ARRAY', ref($p->robots));
isnt(0, scalar(@{$p->robots}));
