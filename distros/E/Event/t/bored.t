# -*- perl -*-
use Test; plan test => 5;
use Event;

# $Event::DebugLevel = 3;

my $really_bored;
my $w;
$w = Event->timer(after => .5, parked => 1);
ok !defined $w->cb;
eval { $w->now() };
ok $@ =~ /callback unset/;
$w->cb(sub {
	   if (!$really_bored) {
	       $w->again;
	       $really_bored='yes';
	   } else {
	       ok 1;
	   }
       });
ok ref $w->cb, 'CODE';
$w->start;

ok !defined Event::loop();
