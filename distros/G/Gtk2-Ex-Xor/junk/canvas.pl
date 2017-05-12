#!/usr/bin/perl
use strict;
use warnings;
use Gtk2 '-init';
use Gnome2::Canvas;
use Gtk2::Ex::CrossHair;

my $mw = Gtk2::Window->new('toplevel');
$mw->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new(0,0);
$mw->add ($vbox);

my $canvas = Gnome2::Canvas->new();
my $white = Gtk2::Gdk::Color->new (0xFFFF,0xFFFF,0xFFFF);
my $green = Gtk2::Gdk::Color->new (0x0000,0xFFFF,0x0000);
my $black = Gtk2::Gdk::Color->new (0x0000,0x0000,0x0000);

$canvas->modify_bg('normal',$white);
$canvas->modify_fg('active',$green);
$canvas->modify_base('active',$green);

$mw->set_default_size( 400, 300 );
$vbox->pack_start ($canvas, 1,1,1);

my $status = Gtk2::Label->new;
$vbox->pack_start ($status, 0,1,0);

my $cross = Gtk2::Ex::CrossHair->new (widget => $canvas,
                                      #foreground => '#00ff00',
                                      foreground => $green,
                                      #foreground => '#000000',
                                   );
$cross->signal_connect (moved => sub {
                          my ($cross, $widget, $x, $y) = @_;
                          if (defined $x) {
                            $status->set_text ("now at $x,$y");
                          } else {
                            $status->set_text ('');
                          }
                        });

$canvas->add_events ('button-press-mask');

$canvas->signal_connect (button_press_event => sub {
                         my ($canvas, $event) = @_;
                         $cross->start;
                         #($event);
                       return 0;
                       });

$mw->show_all;
print $mw->window,"\n";
print $canvas->window,"\n";
print $canvas->window->get_children,"\n";
print $canvas->flags,"\n";
printf "%#x\n", $canvas->window->XID;
Gtk2->main;


