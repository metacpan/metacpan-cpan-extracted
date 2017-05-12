#!/usr/bin/perl -w
# scalablity.pl --- 
# Last modify Time-stamp: <Ye Wenbin 2007-09-29 09:15:37>
# Version: v 0.0 2007/09/26 15:32:25
# Author: Ye Wenbin <wenbinye@gmail.com>

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../blib/arch";
use lib "$Bin/../blib/lib";

use Goo::Canvas;
use Gtk2 '-init';
use Glib qw(TRUE FALSE);
use Time::HiRes qw/gettimeofday tv_interval/;
use constant {
    N_GROUP_COLS => 5,
    N_GROUP_ROWS => 5,
    # N_GROUP_COLS => 25,
    # N_GROUP_ROWS => 20,
    N_COLS       => 10,
    N_ROWS       => 10,
    PADDING      => 10,
};
use Data::Dumper qw(Dumper); 
my $use_pixmap = shift;
my $max = 1<<29;
my ($left_offset, $top_offset, $total_width, $total_height);
my @ids;

my $window = Gtk2::Window->new('toplevel');
$window->signal_connect('delete_event' => sub { Gtk2->main_quit; });
$window->set_default_size(640, 600);

my $swin = Gtk2::ScrolledWindow->new;
$window->add($swin);

my $canvas = create_canvas();
$swin->add($canvas);

$window->show_all();
Gtk2->main();

sub create_canvas {
    my $canvas = Goo::Canvas->new();
    $canvas->set_size_request(600, 450);
    my $start = [gettimeofday];
    setup_canvas ($canvas);
    print "Create Canvas Time Used: ", tv_interval($start), "\n";
    $canvas->set_bounds($left_offset, $top_offset,
                        $left_offset + $total_width, $top_offset + $total_height);
    return $canvas;
}

sub setup_canvas {
    my $canvas = shift;
    my ($root, $group, $item);
    my ($pattern, $pixbuf);
    my ($item_width, $item_height, $group_width, $group_height, $cell_width, $cell_height);
    my @styles;
    my ($total_items, $id_item_num) = (0, 0);
    $root = $canvas->get_root_item();
    if ( $use_pixmap ) {
        # my $surface = Cairo::ImageSurface->create_from_png("$Bin/toroid.png");
        # $item_width = $surface->get_width;
        # $item_height = $surface->get_height;
        # $pattern = Goo::Cairo::Pattern->new(
        #     Cairo::SurfacePattern->create($surface)
        #     );
        $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file("$Bin/toroid.png");
        $item_width = $pixbuf->get_width;
        $item_height = $pixbuf->get_height;
        $pattern = Goo::Cairo::Pattern->new_from_pixbuf($pixbuf);
    } else {
        $item_width = 400;
        $item_height = 19;
    }
    $cell_width = $item_width + PADDING * 2;
    $cell_height = $item_height + PADDING * 2;
    $group_width = N_COLS * $cell_width;
    $group_height = N_ROWS * $cell_height;
    $total_width = N_GROUP_COLS * $group_width;
    $total_height = N_GROUP_ROWS * $group_height;
    $left_offset = - $total_width / 2;
    $top_offset = - $total_height / 2;
    for ( 'mediumseagreen', 'steelblue' ) {
        my $style = Goo::Canvas::Style->new;
        my $color = Gtk2::Gdk::Color->parse($_);
        my $pattern = Goo::Cairo::Pattern->new(
            Cairo::SolidPattern->create_rgb(
                map { $_/65535 } $color->red, $color->green, $color->blue
            ));
        $style->set_property('fill-pattern', $pattern);
        push @styles, $style;
    }
 OUTER:
    foreach my $i ( 0..N_GROUP_COLS ) {
        foreach my $j ( 0..N_GROUP_ROWS ) {
            my $x = $left_offset + ($i * $group_width);
            my $y = $top_offset + ($j * $group_height);
            $group = Goo::Canvas::Group->new( $root );
            $total_items++;
            $group->translate($x, $y);
            for my $i ( 0..N_COLS ) {
                for my $j ( 0..N_ROWS ) {
                    my $ix = $i * $cell_width + PADDING;
                    my $iy = $j * $cell_height + PADDING;
                    my $rotation = $i % 10 * 2;
                    my $rx = $ix + $item_width / 2;
                    my $ry = $iy + $item_height / 2;
                    $ids[$id_item_num] = ($x+$ix) . " - " . ($y+$iy);
                    if ( $use_pixmap ) {
                        # use Data::Dumper qw(Dumper); 
                        # print Dumper($pattern, $item_width), "\n";
                        $item = Goo::Canvas::Image->new(
                            $group, undef, $ix, $iy,
                            'pattern' => $pattern,
                            'width' => $item_width,
                            'height' => $item_height
                        );
                        $item->rotate($rotation, $rx, $ry);
                    } else {
                        $item = Goo::Canvas::Rect->new($group, $ix, $iy, $item_width, $item_height);
                        $item->set_style($styles[($j+1)%2]);
                        $item->rotate($rotation, $rx, $ry);
                    }
                    $item->{"id"} = $ids[$id_item_num];
                    $item->signal_connect('motion-notify-event',
                                          \&on_motion_notify);
                    $item = Goo::Canvas::Text->new(
                        $group,
                        $ids[$id_item_num],
                        $ix+$item_width/2, $iy+$item_height/2,
                        -1, 'center',
                        "font" => 'Sans 8'
                    );
                    $item->rotate($rotation, $rx, $ry);
                    $id_item_num++;
                    $total_items+=2;
                    if ( $max < $total_items ) {
                        last OUTER;
                    }
                }
            }
        }
    }
    print("total items: ", $total_items, "\n");
}
                                               
sub on_motion_notify {
    my $item = shift;
    print( ($item->{id} || "Unknown"),
        " item received 'motion-notify' signal\n");
    return FALSE;
}

    
