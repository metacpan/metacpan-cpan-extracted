#!./perl -w

use strict;
use Test; plan tests => 3;
use Event 0.53;

# $Event::DebugLevel = 3;

my $array = Event->timer(attach_to => [0,1,2], after => 1, cb => \&die);
ok $array->[2], 2;
ok $array->interval, 1;

eval { Event->timer(attach_to => bless([]), after => 1, cb => \&die); };
ok $@, '/blessed/';
