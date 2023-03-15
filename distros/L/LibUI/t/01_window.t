use strict;
use Test::More 0.98;
use lib './t/lib', './lib';
use t::Display;
use lib '../lib';
use LibUI ':all';
use LibUI::Window;
t::Display::needs_display();
Init() && die;
my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
isa_ok $window, 'LibUI::Window';
$window->onClosing(
    sub {
        diag 'Window cloased manually';
        Quit();
        return 1;
    },
    undef
);
ok !$window->show, '->show';
Timer(
    100,
    sub {
        pass 'Timer triggered! Quitting...';
        Quit;
    },
    undef
);
Main();
done_testing
