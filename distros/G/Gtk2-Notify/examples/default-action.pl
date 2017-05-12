#!/usr/bin/perl

use strict;
use warnings;
use Gtk2::Notify -init, 'Default Actions';

my $n = Gtk2::Notify->new('Matt is online');
$n->set_category('presence.online');

$n->add_action('default', 'Default Action', sub {
        print "You clicked the default action\n";
        $n->close;
        Gtk2->main_quit;
});

$n->show;

Gtk2->main;
