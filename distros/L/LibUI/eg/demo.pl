use strict;
use warnings;
use lib '../lib';
use LibUI ':all';
use LibUI::Window;
use LibUI::Label;
Init() && die;
my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
$window->setMargined(1);
$window->setChild( LibUI::Label->new('Hello, World!') );
$window->onClosing(
    sub {
        Quit();
        return 1;
    },
    undef
);
$window->setMargined(1);
$window->show;
Main();
