#!/usr/bin/perl

use strict;
use warnings;
use Gtk2::Notify -init, 'Multi Actions';

my $n = Gtk2::Notify->new(
        'Low disk space',
        'You can free up some disk space by emptying the trash can.'
);

$n->set_urgency('critical');
$n->set_category('device');

$n->add_action('help', 'Help', \&action_cb);
$n->add_action('ignore', 'Ignore', \&action_cb);
$n->add_action('empty', 'Empty Trash', \&action_cb);

$n->show;

Gtk2->main;

sub action_cb {
    my ($n, $action) = @_;

    print "You clicked $action\n";
    $n->close;
    Gtk2->main_quit;
}
