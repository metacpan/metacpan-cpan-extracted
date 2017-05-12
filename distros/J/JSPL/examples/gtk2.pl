#!/usr/bin/perl
use strict;
use warnings;

use JSPL;
use Gtk2 -init;

my $ctx = JSPL->stock_context;
my $ctl = $ctx->get_controller;
$ctl->install(
    'Gtk2' => 'Gtk2',
    'Gtk2.Window' => 'Gtk2::Window',
    'Gtk2.Button' => 'Gtk2::Button',
);

$ctx->eval(q|
    var window = new Gtk2.Window('toplevel');
    var button = new Gtk2.Button('Quit');
    button.signal_connect('clicked', function() { Gtk2.main_quit() });
    window.add(button);
    window.show_all();
    Gtk2.main();
    say('That all folk!');
|);
