#!/usr/bin/perl -w
# table.pl --- 
# Last modify Time-stamp: <Ye Wenbin 2007-09-28 15:36:39>
# Version: v 0.0 2007/09/26 19:32:49
# Author: Ye Wenbin <wenbinye@gmail.com>

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../blib/arch";
use lib "$Bin/../blib/lib";
use Goo::Canvas;
use Gtk2 '-init';
use Glib qw(TRUE FALSE);
use constant {
 DEMO_RECT_ITEM => 0,
 DEMO_TEXT_ITEM  => 1,
 DEMO_WIDGET_ITEM  => 2,
};
use Data::Dumper qw(Dumper); 
my $window = Gtk2::Window->new('toplevel');
$window->signal_connect('delete_event' => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new(FALSE, 4);
$vbox->set_border_width(4);
$window->add($vbox);

my $hbox = Gtk2::HBox->new(FALSE, 4);
$vbox->pack_start($hbox, FALSE, FALSE, 0);

my $swin = Gtk2::ScrolledWindow->new;
$swin->set_shadow_type('in');
$vbox->pack_start($swin, TRUE, TRUE, 0);

my $canvas = Goo::Canvas->new;
$canvas->can_focus(TRUE);
$canvas->set_size_request(600, 450);
$canvas->set_bounds(0, 0, 1000, 1000);
$swin->add($canvas);

my $root = $canvas->get_root_item;

create_demo_table($root) if 1;
if ( 1 ) {
create_table($root, -1, -1, 0, 10, 10, 0, 1.0, DEMO_TEXT_ITEM);
create_table($root, -1, -1, 0, 180, 10, 30, 1.0, DEMO_TEXT_ITEM);
create_table($root, -1, -1, 0, 350, 10, 60, 1.0, DEMO_TEXT_ITEM);
create_table($root, -1, -1, 0, 500, 10, 90, 1.0, DEMO_TEXT_ITEM);
}

if ( 1 ) {
my $table = create_table($root, -1, -1, 0, 30, 150, 0, 1.0, DEMO_TEXT_ITEM);
$table->set(
    width => 300,
    height => 100
);
}

create_table($root, -1, -1, 1, 200, 200, 30, 0.8, DEMO_TEXT_ITEM) if 1;

if ( 1 ) {
my $table = create_table($root, -1, -1, 0, 10, 700, 0, 1.0, DEMO_WIDGET_ITEM);
$table->set(
    width => 300,
    height => 100
);
}

$window->show_all();
# FIXME: get warnings
Gtk2->main;

sub create_demo_table {
    my $root = shift;
    my $table = Goo::Canvas::Table->new(
        $root,
        'row-spacing' => 4,
        'column-spacing' => 4,
    );
    $table->translate(400, 200);

    my $square = Goo::Canvas::Rect->new(
        $table, 0, 0, 50, 50,
        'fill-color' => 'red',
    );
    $table->set_child_properties(
        $square,
        'row' => 0,
        'column' => 0,
    );
    my $circle = Goo::Canvas::Ellipse->new(
        $table, 0, 0, 25, 25,
        'fill-color' => 'blue',
    );
    $table->set_child_properties(
        $circle,
        'row' => 0,
        'column' => 1,
    );
    my $triangle = Goo::Canvas::Polyline->new(
        $table, TRUE, [25,0, 0,50, 50,50],
        'fill-color' => 'yellow',
    );
    $table->set_child_properties(
        $triangle,
        'row' => 0,
        'column' => 2,
    );
}

sub create_table {
    my ($parent, $row, $col, $embedding_level, $x, $y,
        $rotation, $scale, $demo_item_type) = @_;
    my $table = Goo::Canvas::Table->new(
        $parent,
        'row-spacing' => 4,
        'column-spacing' => 4,
    );
    $table->translate($x, $y);
    $table->rotate($rotation, 0, 0);
    $table->scale($scale, $scale);
    if ( $row != -1 ) {
        $parent->set_child_properties(
            $table,
            "row" => $row,
            "column" => $col,
            'x-expand' => TRUE,
            'y-fill' => FALSE,
        );
    }
    if ( $embedding_level ) {
        my $level = $embedding_level -1;
        create_table($table, 0, 0, $level, 50, 50, 0, 0.7,   $demo_item_type);
        create_table($table, 0, 1, $level, 50, 50, 45, 1.0,  $demo_item_type);
        create_table($table, 0, 2, $level, 50, 50, 90, 1.0,  $demo_item_type);
        create_table($table, 1, 0, $level, 50, 50, 135, 1.0, $demo_item_type);
        create_table($table, 1, 1, $level, 50, 50, 180, 1.5, $demo_item_type);
        create_table($table, 1, 2, $level, 50, 50, 225, 1.0, $demo_item_type);
        create_table($table, 2, 0, $level, 50, 50, 270, 1.0, $demo_item_type);
        create_table($table, 2, 1, $level, 50, 50, 315, 1.0, $demo_item_type);
        create_table($table, 2, 2, $level, 50, 50, 360, 2.0, $demo_item_type);
    } else {
        create_demo_item ($table, $demo_item_type, 0, 0, 1, 1, "(0,0)");
        create_demo_item ($table, $demo_item_type, 0, 1, 1, 1, "(1,0)");
        create_demo_item ($table, $demo_item_type, 0, 2, 1, 1, "(2,0)");
        create_demo_item ($table, $demo_item_type, 1, 0, 1, 1, "(0,1)");
        create_demo_item ($table, $demo_item_type, 1, 1, 1, 1, "(1,1)");
        create_demo_item ($table, $demo_item_type, 1, 2, 1, 1, "(2,1)");
        create_demo_item ($table, $demo_item_type, 2, 0, 1, 1, "(0,2)");
        create_demo_item ($table, $demo_item_type, 2, 1, 1, 1, "(1,2)");
        create_demo_item ($table, $demo_item_type, 2, 2, 1, 1, "(2,2)");
    }
    return $table;
}

sub create_demo_item {
    my ($table, $demo_item_type, $row, $column, $rows, $columns, $text) = @_;
    my ($widget, $item);
    
    if ( $demo_item_type == DEMO_RECT_ITEM ) {
        $item = Goo::Canvas::Rect->new(
            $table, 0, 0, 38, 19,
            'fill-color' => 'red',
        );
    }
    elsif ( $demo_item_type == DEMO_TEXT_ITEM ) {
        $item = Goo::Canvas::Text->new(
            $table, $text, 0, 0, -1, 'nw'
        );
    }
    elsif ( $demo_item_type == DEMO_WIDGET_ITEM ) {
        $widget = Gtk2::Button->new_with_label($text);
        $item = Goo::Canvas::Widget->new(
            $table, $widget, 0, 0, -1,-1
        );
    }
    $table->set_child_properties(
        $item,
        'row' => $row,
        'column' => $column,
        'rows' => $rows,
        'columns' => $columns,
        'x-expand' => TRUE,
        'x-fill' => TRUE,
        'y-expand' => TRUE,
        'y-fill' => TRUE,
    );
    $item->{id} = $text;
    $item->signal_connect("button-press-event",
                          \&on_button_press);
}

sub on_button_press {
    my $item = shift;
    print "$item->{id} is pressed\n";
    return FALSE;
}
