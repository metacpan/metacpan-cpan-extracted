#!/usr/bin/perl -w
# mv-simple.pl --- 
# Last modify Time-stamp: <Ye Wenbin 2007-09-28 15:33:43>
# Version: v 0.0 2007/09/26 13:31:45
# Author: Ye Wenbin <wenbinye@gmail.com>

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../blib/arch";
use lib "$Bin/../blib/lib";

use Gtk2 '-init';
use Glib qw(TRUE FALSE);
use Goo::Canvas;

my $window = Gtk2::Window->new('toplevel');
$window->signal_connect('delete_event' => sub { Gtk2->main_quit; });
$window->set_default_size(640, 600);

my $swin = Gtk2::ScrolledWindow->new;
$swin->set_shadow_type('in');
$window->add($swin);

my $canvas = Goo::Canvas->new();
$canvas->set_size_request(600, 450);
$canvas->set_bounds(0, 0, 1000, 1000);
$swin->add($canvas);

my $root = Goo::Canvas::GroupModel->new();
my $rect_model = Goo::Canvas::RectModel->new(
    $root, 100, 100, 400, 400,
    'line-width' => 10,
    'radius-x' => 20,
    'radius-y' => 10,
    'stroke-color' => 'yellow',
    'fill-color' => 'red'
);
my $text_model = Goo::Canvas::TextModel->new(
    $root, "Hello World", 300, 300, -1, 'center',
    'font' => 'Sans 24',
);
$text_model->rotate(45, 300, 300);
$canvas->set_root_item_model($root);

my $rect_item = $canvas->get_item($rect_model);
$rect_item->signal_connect('button-press-event',
                      \&on_rect_button_press);

$window->show_all();
Gtk2->main;

sub on_rect_button_press {
    print "Rect item pressed!\n";
    return TRUE;
}
