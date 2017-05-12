#!./perl -w

use Test; plan tests => 8;
use Event;

my $w = Event->idle(parked => 1, data => 'data');

ok $w->data, 'data';
ok !$w->private;
ok $w->private(1);
ok $w->private;

package Grapes;
use Test;

ok $w->data, 'data';
ok !$w->private;
ok $w->private(2), 2;

package main;

ok $w->private, 1;
