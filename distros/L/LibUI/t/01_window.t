use strict;
use Test::More 0.98;
use lib './t/lib', './lib', '../lib';
use t::Display;
use LibUI ':all';
#
t::Display::needs_display();
uiInit( { Size => 0 } ) && die;
#
pass 'post Init()';
ok my $window = uiNewWindow( 'Hi', 320, 100, 0 ), q[uiNewWindow( 'Hi', 320, 100, 0 )];
ok !uiControlShow($window),                       'uiControlShow($window)';
uiTimer( 100, sub { uiQuit(); }, undef );
uiMain();
pass 'uiMain() returned cleanly';
#
done_testing;
