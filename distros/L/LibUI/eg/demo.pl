use strict;
use warnings;
use lib '../lib';
use LibUI ':all';
use LibUI::Window;
use LibUI::Label;
Init( { Size => 1024 } ) && die;
my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
$window->setChild( LibUI::Label->new('Hello, World!') );
$window->onClosing(
    sub {
        Quit();
        return 1;
    },
    undef
);
$window->show;
Main();
