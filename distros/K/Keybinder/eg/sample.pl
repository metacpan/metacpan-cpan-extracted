#!/usr/bin/env perl

use strict;
use warnings;

use Gtk2 -init;
use Keybinder;

my $key = '<Ctrl>A';
my $window = Gtk2::Window->new('toplevel');
my $button = Gtk2::Button->new("press $key to quit app globally");
my $exit; $exit = sub {
    print "Exiting..\n";
    unbind_key($key, $exit);
    Gtk2->main_quit;
};
$button->signal_connect (clicked => $exit);
$window->add ($button);
$window->show_all;

sub d{
 print "d!\n";
}

#my @p = Gtk2::Accelerator->parse('<Shift><Control>N');
#print "@p\n";

bind_key($key => $exit) or die("can't bind $key");
bind_key('<Ctrl>B' => $exit) or die("can't bind...");
bind_key('<Shift>F1' => sub { "Ctrl+C has been pressed"}) or die("can't bind...");
bind_key('<Ctrl><Alt>V' => \&d) or die("can't bind...");

# not works ?
#bind_key('<Shift><Control>A' => \&d ) or die("can't bind...");


Gtk2->main;
