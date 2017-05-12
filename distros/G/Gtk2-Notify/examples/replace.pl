#!/usr/bin/perl

use strict;
use warnings;
use Glib qw( TRUE FALSE );
use Gtk2::Notify -init, 'Replace';

my $n = Gtk2::Notify->new('Summary', 'First message');
$n->set_timeout(0);

$n->show;

Glib::Timeout->add(3000, \&replace, $n);
Gtk2->main;

sub replace {
    my ($n) = @_;

    $n->update('Second Summary', 'First mesage was replaced');
    $n->set_timeout(-1);

    $n->show;

    Gtk2->main_quit;
}
