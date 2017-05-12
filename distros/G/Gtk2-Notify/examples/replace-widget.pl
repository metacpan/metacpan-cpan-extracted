#!/usr/bin/perl

use strict;
use warnings;
use Gtk2::Notify -init, 'Replace Widgets';

my $win = Gtk2::Window->new;
$win->show;
$win->signal_connect(destroy => sub { Gtk2->main_quit });

my $button = Gtk2::Button->new('Click here to change notification');
$button->show;
$win->add($button);

my $n = Gtk2::Notify->new(
        'Widget Attachment Test',
        'Button has not been clicked yet',
        '',
        $button,
);

$n->set_category('presence.online');
$n->set_timeout(0);

$button->signal_connect(clicked => \&clicked_cb, $n);
my $exposed_signal_id = $button->signal_connect(expose_event => \&exposed_cb, $n);

Gtk2->main;

sub exposed_cb {
    my ($button, $event, $n) = @_;

    $button->signal_handler_disconnect($exposed_signal_id);
    $n->show;
}

my $count = 0;
sub clicked_cb {
    my ($button, $n) = @_;

    $count++;
    $n->update(
            'Widget Attachment Test',
            "You clicked the button $count times"
    );

    $n->show;
}
