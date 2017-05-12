# hook -*-perl-*-

use strict;
use Test; plan test => 4;
use Event qw(sweep sleep);

my ($p,$c,$ac,$cb) = (0)x4;

Event::add_hooks(prepare => sub { ++$p },
		 check => sub { ++$c },
		 asynccheck => sub { ++$ac },
		 callback => sub { ++$cb });
Event->timer(after => 0, cb => sub {});

sleep .5;
sweep();

ok $p,1;
ok $c,1;
ok $ac,1;
ok $cb,1;
