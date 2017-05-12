#!/usr/bin/perl -w
# demo.pl --- 
# Last modify Time-stamp: <Ye Wenbin 2007-11-02 03:25:30>
# Version: v 0.0 2007/09/26 13:31:45
# Author: Ye Wenbin <wenbinye@gmail.com>

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../blib/arch";
use lib "$FindBin::Bin/../blib/lib";

use Gtk2 '-init';
use Glib qw(TRUE FALSE);
use Goo::Canvas;

my $window = create_window();
Gtk2->main;

#{{{  Main window
sub create_window {
    my $window = Gtk2::Window->new('toplevel');
    $window->signal_connect('delete_event' => sub { Gtk2->main_quit; });
    $window->set_default_size(640, 600);
    $window->show;

    my $notebook = Gtk2::Notebook->new;
    $window->add($notebook);
    $notebook->show;

    foreach my $pkg (
        "Primitives",
        "Arrowhead",
        "Fifteen",
        "Reparent",
        "Scalability",
        "Grabs",
        "Events",
        "Paths",
        "Focus",
        "Animation",
        "Clipping",
      ) {
        $notebook->append_page( $pkg->create_canvas, Gtk2::Label->new($pkg) );
    }
    return $window;
}
#}}}

#{{{  Primitives
package Primitives;
use Gtk2;
use Glib qw(TRUE FALSE);
use constant {
    VERTICES => 10,
    RADIUS => 60,
    SCALE => 7,
};
use Math::Trig qw/pi/;

sub create_canvas {
    my $pkg = shift;
    my $vbox = Gtk2::VBox->new;
    my $group;
    my ($hbox, $w, $swin, $canvas, $adj);
    my $bg_color = Gtk2::Gdk::Color->new(50000, 50000, 65535);
    
    $vbox->set_border_width(4);
    $vbox->show;
    $w = Gtk2::Label->new("Drag an item with button 1.  Click button 2 on an item to lower it, or button 3 to raise it.");
    $vbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;

    $hbox = Gtk2::HBox->new(FALSE, 4);
    $vbox->pack_start($hbox, FALSE, FALSE, 0);
    $hbox->show;
    # Create the canvas
    $canvas = Goo::Canvas->new;
    $canvas->modify_base('normal', $bg_color);
    $canvas->set_bounds(0, 0, 604, 454);

    ###### Frist Row
    # Zoom
    $w = Gtk2::Label->new("Zoom:");
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;

    $adj = Gtk2::Adjustment->new(1, 0.05, 100, 0.05, 0.5, 0.5);
    $w = Gtk2::SpinButton->new($adj, 0, 2);
    $adj->signal_connect("value-changed", \&zoom_changed, $canvas);
    $w->set_size_request(50, -1);
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;
    # Center
    $w = Gtk2::CheckButton->new_with_label("Center scroll region");
    $hbox->pack_start($w, FALSE, FALSE, 0);
      # $w->show;
    $w->signal_connect("toggled", \&center_toggled, $canvas);
    # Move Ellipse
    $w = Gtk2::Button->new_with_label('Move Ellipse');
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;
    $w->signal_connect("clicked", \&move_ellipse_clicked, $canvas);
    # Animate Ellipse
    $w = Gtk2::Button->new_with_label('Animate Ellipse');
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;
    $w->signal_connect("clicked", \&animate_ellipse_clicked, $canvas);
    # Stop Animation
    $w = Gtk2::Button->new_with_label('Stop Animation');
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;
    $w->signal_connect("clicked", \&stop_animation_clicked, $canvas);
    # Create PDF
    $w = Gtk2::Button->new_with_label('Write PDF');
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;
    $w->signal_connect("clicked", \&write_pdf_clicked, $canvas);
    ##### Start anothor Row
    $hbox = Gtk2::HBox->new(FALSE, 4);
    $vbox->pack_start($hbox, FALSE, FALSE, 0);
    $hbox->show;
    # Scroll to
    $w = Gtk2::Label->new('Scroll to:');
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;

    $w = Gtk2::Button->new_with_label('50,50');
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;
    $w->signal_connect("clicked", \&scroll_to_50_50_clicked, $canvas);
    $w = Gtk2::Button->new_with_label('250,250');
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;
    $w->signal_connect("clicked", \&scroll_to_250_250_clicked, $canvas);
    $w = Gtk2::Button->new_with_label('500,500');
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;
    $w->signal_connect("clicked", \&scroll_to_500_500_clicked, $canvas);
    # Scroll anchor
    $w = Gtk2::Label->new('Anchor:');
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;
    
    foreach my $anchor( 'NW', 'N', 'NE', 'W', 'SW', 'S', 'SE' ) {
        $w = Gtk2::RadioButton->new_with_label($group, $anchor);
        $group = $w;
        $hbox->pack_start($w, FALSE, FALSE, 0);
        $w->show;
        $w->signal_connect('toggled', \&anchor_toggled, $canvas);
        $w->{anchor} = lc($anchor);
    }
    # Layout the stuff
    $swin = Gtk2::ScrolledWindow->new();
    $swin->show;
    $vbox->pack_start($swin, TRUE, TRUE, 0);
    $canvas->show;
    $swin->add($canvas);
    setup_canvas($canvas);
    if ( 0 ) {
        $canvas->signal_connect_after('key_press_event', \&key_press);
        $canvas->can_focus(TRUE);
        $canvas->grab_focus;
    }
    return $vbox;
}

sub setup_canvas {
    my $canvas = shift;
    my $root = $canvas->get_root_item;
    $root->signal_connect('button_press_event',
                          \&on_background_button_press);
    setup_divisions($root);
    setup_rectangles($root);
    setup_ellipses($root);
    setup_lines($root);
    setup_polygons($root);
    setup_texts($root);
    setup_images($root);
    setup_invisible_texts($root);
}

sub setup_divisions {
    my $root = shift;
    my ($group, $item);
    $group = Goo::Canvas::Group->new($root);
    $group->translate(2, 2);
    $item = Goo::Canvas::Rect->new(
        $group, 0, 0, 600, 450,
        'line-width' => 4
    );
    $item = Goo::Canvas::Polyline->new_line(
        $group, 0, 150, 600, 150,
        'line-width' => 4,
    );
    $item = Goo::Canvas::Polyline->new_line(
        $group, 0, 300, 600, 300,
        'line-width' => 4,
    );
    $item = Goo::Canvas::Polyline->new_line(
        $group, 200, 0, 200, 450,
        'line-width' => 4,
    );
    $item = Goo::Canvas::Polyline->new_line(
        $group, 400, 0, 400, 450,
        'line-width' => 4,
    );
    setup_heading ($group, "Rectangles", 0);
    setup_heading ($group, "Ellipses", 1);
    setup_heading ($group, "Texts", 2);
    setup_heading ($group, "Images", 3);
    setup_heading ($group, "Lines", 4);
    setup_heading ($group, "Polygons", 7);
}

sub setup_heading {
    my ($root, $text, $pos) = @_;
    my $x = ($pos%3)*200 + 100;
    my $y = (int($pos/3))*150 + 5;
    # print("$text $pos($x, $y)\n");
    my $item = Goo::Canvas::Text->new(
        $root, $text, $x, $y, -1, 'n',
        'font' => 'Sans 12'
    );
    $item->skew_y(30, $x, $y);
}

sub setup_rectangles {
    my $root = shift;
    my ($item, $pattern);
    my @stipple_data = (
    0, 0, 0, 255,   0, 0, 0, 0,   0, 0, 0, 0,     0, 0, 0, 255
    );
    $item = Goo::Canvas::Rect->new(
        $root, 20, 30, 50, 30,
        'stroke-color' => 'red',
        'line-width' => 8,
    );
    setup_item_signals($item);
    $pattern = create_stipple('mediumseagreen', \@stipple_data);
    $item = Goo::Canvas::Rect->new(
        $root, 90, 40, 90, 60,
        'fill-pattern' => $pattern,
        'stroke-color' => 'black',
        'line-width' => 4,
    );
   setup_item_signals($item);
    $item = Goo::Canvas::Rect->new(
        $root, 10, 80, 70, 60,
        'fill-color' => 'steelblue',
    );
    setup_item_signals($item);
    $item = Goo::Canvas::Rect->new(
        $root, 20, 90, 70, 60,
        'fill-color-rgba' => 0x3cb37180,
        'stroke-color' => 'blue',
        'line-width' => 2,
    );
    setup_item_signals($item);
    $item = Goo::Canvas::Rect->new(
        $root, 110, 80, 50, 30,
        'radius-x' => 20,
        'radius-y' => 10,
        'stroke-color' => 'yellow',
        'fill-color-rgba' => 0x3cb3f180,
    );
    setup_item_signals($item);
    $item = Goo::Canvas::Rect->new(
        $root, 30, 20, 50, 30,
        'fill-color' => 'yellow',
    );
    setup_item_signals($item);
}

sub create_stipple {
    our @stipples;
    my($color_name, $stipple_data) = @_;
    my $color = Gtk2::Gdk::Color->parse($color_name);
    $stipple_data->[2] = $stipple_data->[14] = $color->red >> 8;
    $stipple_data->[1] = $stipple_data->[13] = $color->green >> 8;
    $stipple_data->[0] = $stipple_data->[12] = $color->blue >> 8;
    my $stipple_str = join('', map {chr} @$stipple_data);
    push @stipples, \$stipple_str; # make $stipple_str refcnt increase
    my $surface = Cairo::ImageSurface->create_for_data(
        $stipple_str, 'argb32',
        2, 2, 8
    );
    my $pattern = Cairo::SurfacePattern->create($surface);
    $pattern->set_extend('repeat');
    return Goo::Cairo::Pattern->new($pattern);
}

sub setup_ellipses {
    my $root = shift;
    my @stipple_data = (
        0, 0, 0, 255,   0, 0, 0, 0,
        0, 0, 0, 0,     0, 0, 0, 255
    );
    my $ellipse1 = Goo::Canvas::Ellipse->new(
        $root, 245, 45, 25, 15,
        'stroke-color' => 'goldenrod',
        'line-width' => 8
    );
    setup_item_signals($ellipse1);
    my $ellipse2 = Goo::Canvas::Ellipse->new(
        $root, 335, 70, 45, 30,
        'fill-color' => 'wheat',
        'stroke-color' => 'midnightblue',
        'line-width' => 4,
        'title' => 'An ellipse'
    );
    setup_item_signals($ellipse2);
    $ellipse2->get_canvas->{ellipse} = $ellipse2;
    my $pattern = create_stipple('cadetblue', \@stipple_data);
    my $ellipse3 = Goo::Canvas::Ellipse->new(
        $root, 245, 110, 35, 30,
        'fill-pattern' => $pattern,
        'stroke-color' => 'black',
        'line-width' => 1,
    );
    setup_item_signals($ellipse3);
}

sub setup_lines {
    my $root = shift;
    my $line;
    
    polish_diamond($root);
    make_hilbert($root);
    $line = Goo::Canvas::Polyline->new(
        $root, FALSE,
        [ 340, 170,
          340, 230,
          390, 230,
          390, 170 ],
        'stroke-color' => 'midnightblue',
        'line-width' => 3,
        'start-arrow' => TRUE,
        'end-arrow' => TRUE,
        'arrow-tip-length' => 3,
        'arrow-length' => 4,
        'arrow-width' => 3.5
    );
    setup_item_signals($line);
    $line = Goo::Canvas::Polyline->new(
        $root, FALSE,
        [ 356, 180,
          374, 220, ],
        'stroke-color' => 'blue',
        'line-width' => 1,
        'start-arrow' => TRUE,
        'end-arrow' => TRUE,
        'arrow-tip-length' => 5,
        'arrow-length' => 6,
        'arrow-width' => 6,
    );
    setup_item_signals($line);
    $line = Goo::Canvas::Polyline->new(
        $root, FALSE,
        [356, 220,
         374, 180,],
         'stroke-color' => 'blue',
        'line-width' => 1,
        'start-arrow' => TRUE,
        'end-arrow' => TRUE,
        'arrow-tip-length' => 5,
        'arrow-length' => 6,
        'arrow-width' => 6,
    );
    setup_item_signals($line);
    $line = Goo::Canvas::Polyline->new($root, FALSE, undef);
    setup_item_signals($line);
    $line = Goo::Canvas::Polyline->new(
        $root, FALSE,
        [356, 220],
        'start-arrow' => TRUE,
        'end-arrow' => TRUE,
    );
    setup_item_signals($line);
}

sub polish_diamond {
    my $root = shift;
    my $item;
    my ($a, $x1, $y1, $x2, $y2);
    my $group = Goo::Canvas::Group->new(
        $root,
        'line-width' => 1,
        'line-cap' => 'round'
    );
    $group->translate(270, 230);
    setup_item_signals($group);
    for my $i ( 0..VERTICES ) {
        $a = 2*pi*$i/VERTICES;
        $x1 = RADIUS * cos($a);
        $y1 = RADIUS * sin($a);
        for my $j( $i+1..VERTICES ) {
            $a = 2*pi*$j/VERTICES;
            $x2 = RADIUS * cos($a);
            $y2 = RADIUS * sin($a);
            $item = Goo::Canvas::Polyline->new_line(
                $group, $x1, $y1, $x2, $y2
            );
        }
    }
}

sub make_hilbert {
    my $root = shift;
    my $hilbert = "urdrrulurulldluuruluurdrurddldrrruluurdrurddldrddlulldrdldrrurd";
    my @stipple_data = (
        0, 0, 0, 255,   0, 0, 0, 0,   0, 0, 0, 0,     0, 0, 0, 255
    );
    my $pattern = create_stipple('red', \@stipple_data);
    my @points = ( [340, 290] );
    my $pp = $points[0];
    foreach ( 0..length($hilbert)-1 ) {
        my @p;
        my $c = substr($hilbert, $_, 1);
        if ( $c eq 'u' ) {
            $p[0] = $pp->[0];
            $p[1] = $pp->[1] - SCALE;
        }
        elsif ( $c eq 'd' ) {
            $p[0] = $pp->[0];
            $p[1] = $pp->[1] + SCALE;
        }
        elsif ( $c eq 'l' ) {
            $p[0] = $pp->[0] - SCALE;
            $p[1] = $pp->[1];
        }
        elsif ( $c eq 'r' ) {
            $p[0] = $pp->[0] + SCALE;
            $p[1] = $pp->[1];
        }
        push @points, \@p;
        $pp = \@p;
    }
    my $item = Goo::Canvas::Polyline->new(
        $root, FALSE, [map {@{$_}} @points],
        'line-width' => 4,
        'stroke-pattern' => $pattern,
        'line-cap' => 'square',
        'line-join' => 'miter'
    );
    setup_item_signals($item);
}

sub setup_polygons {
    my $root = shift;
    my $line;
    my @stipple_data = (
        0, 0, 0, 255,   0, 0, 0, 0,   0, 0, 0, 0,     0, 0, 0, 255
    );
    my @points = (
        210, 320,
        210, 380,
        260, 350
    );
    my $pattern = create_stipple('blue', \@stipple_data);
    $line = Goo::Canvas::Polyline->new(
        $root, TRUE, \@points,
        'line-width' => 1,
        'fill-pattern' => $pattern,
        'stroke-color' => 'black'
    );
    setup_item_signals($line);
    @points = (
        270.0, 330.0,
        270.0, 430.0,
        390.0, 430.0,
        390.0, 330.0,
        310.0, 330.0,
        310.0, 390.0,
        350.0, 390.0,
        350.0, 370.0,
        330.0, 370.0,
        330.0, 350.0,
        370.0, 350.0,
        370.0, 410.0,
        290.0, 410.0,
        290.0, 330.0,
    );
    $line = Goo::Canvas::Polyline->new(
        $root, TRUE, \@points,
        'fill-color' => 'tan',
        'stroke-color' => 'black',
        'line-width' => 3,
    );
    setup_item_signals($line);
}

sub setup_texts {
    my $root = shift;
    my @stipple_data = (
        0, 0, 0, 255,   0, 0, 0, 0,   0, 0, 0, 0,     0, 0, 0, 255
    );
    my $pattern = create_stipple('blue', \@stipple_data);
    my $item;
    $item = Goo::Canvas::Text->new(
        make_anchor($root, 420, 20),
        'Anchor NW',
        0, 0, -1, 'nw',
        'font' => 'Sans Bold 24',
        'fill-pattern' => $pattern,
    );
    setup_item_signals($item);

    $item = Goo::Canvas::Text->new(
        make_anchor($root, 470, 75),
        "Anchor center\nJustify center\nMultiline text\nb8bit text ÅÄÖåäö",
        0, 0, -1, 'center',
        "font" => "monospace bold 14",
        "alignment" => 'center',
        "fill-color" => "firebrick",
    );
    setup_item_signals($item);

    $item = Goo::Canvas::Text->new(
        make_anchor($root, 590, 140),
"Clipped text\nClipped text\nClipped text\nClipped text\nClipped text\nClipped text",
        0, 0, -1, 'se',
        'font' =>'Sans 12',
        'fill-color' => 'darkgreen'
    );
    setup_item_signals($item);

    $item = Goo::Canvas::Text->new(
        make_anchor($root, 420, 240),
        "This is a very long paragraph that will need to be wrapped over several lines so we can see what happens to line-breaking as the view is zoomed in and out.",
        0, 0, 180, 'w',
        'font' => 'Sans 12',
        'fill-color' => 'goldenrod'
    );
    setup_item_signals($item);
}

sub make_anchor {
    my($root, $x, $y) = @_;
    my $group = Goo::Canvas::Group->new($root);
    my $transform = Goo::Cairo::Matrix->new(
        Cairo::Matrix->init(0.8, 0.2, -0.3, 0.5, $x, $y ),
    );
    my $item;
        
    $group->translate($x, $y);
    $group->set( 'transform' => $transform );
    $item = Goo::Canvas::Rect->new(
        $group, -2.5, -2.5, 4, 4,
        'line-width' => 1,
    );
    setup_item_signals($item);
    return $group;
}

sub setup_images {
    my $root = shift;
    my ($im, $image);
    use Data::Dumper qw(Dumper); 
    $im = Gtk2::Gdk::Pixbuf->new_from_file("$FindBin::Bin/toroid.png");
    if ( $im ) {
        my $w = $im->get_width;
        my $h = $im->get_height;
        $image = Goo::Canvas::Image->new(
            $root, $im, 100-$w/2, 225-$h/2,
            'width' => $w,
            'height' => $h
        );
        setup_item_signals($image);
    } else {
        warn "Could not foundhe toroid.png sample file\n";
    }
    plant_flower ($root,  20.0, 170.0, 'nw');
    plant_flower ($root, 180.0, 170.0, 'ne');
    plant_flower ($root,  20.0, 280.0, 'sw');
    plant_flower ($root, 180.0, 280.0, 'se');
}

sub plant_flower {
    my ($root, $x, $y, $anchor) = @_;
    my $surface = Cairo::ImageSurface->create_from_png("$FindBin::Bin/flower.png");
    my $w = $surface->get_width;
    my $h = $surface->get_height;
    my $pattern = Cairo::SurfacePattern->create($surface);
    my $image = Goo::Canvas::Image->new(
        $root, undef, $x, $y,
        'pattern' => Goo::Cairo::Pattern->new($pattern),
        'width' => $w,
        'height' => $h,
    );
    setup_item_signals($image);
}

sub setup_invisible_texts {
    my $root = shift;
    Goo::Canvas::Text->new(
        $root, "Visible above 0.8x", 500, 330, -1, 'center',
        "visibility"           => 'visible_above_threshold',
        "visibility-threshold" => 0.8,
    );
    Goo::Canvas::Rect->new(
        $root, 410.5, 322.5, 180, 15,
        "line-width"           => 1.0,
        "visibility"           => 'visible-above-threshold',
        "visibility-threshold" => 0.8,
    );

    Goo::Canvas::Text->new(
        $root, "Visible above 1.5x", 500, 350, -1, 'center',
        "visibility"           => 'visible-above-threshold',
        "visibility-threshold" => 1.5,
    );
    Goo::Canvas::Rect->new(
        $root, 410.5, 342.5, 180, 15,
        "line-width"           => 1.0,
        "visibility"           => 'visible-above-threshold',
        "visibility-threshold" => 1.5,
    );

    Goo::Canvas::Text->new(
        $root, "Visible above 3.0x", 500, 370, -1, 'center',
        "visibility"           => 'visible-above-threshold',
        "visibility-threshold" => 3.0,
    );
    Goo::Canvas::Rect->new(
        $root, 410.5, 362.5, 180, 15,
        "line-width"           => 1.0,
        "visibility"           => 'visible-above-threshold',
        "visibility-threshold" => 3.0,
    );

    # This should never be seen.
    Goo::Canvas::Text->new(
        $root, "Always Invisible", 500, 390, -1, 'center',
        "visibility" => 'invisible',
    );
    Goo::Canvas::Rect->new(
        $root, 410.5, 350.5, 180, 15,
        "line-width" => 1.0,
        "visibility" => 'invisible',
    );
}

#{{{  Signals
sub setup_item_signals {
    my $item = shift;
    $item->signal_connect('motion_notify_event', \&on_motion_notify);
    $item->signal_connect('button_press_event', \&on_button_press);
    $item->signal_connect('button_release_event', \&on_button_release);
}

sub on_motion_notify {
    my ($item, $target, $ev) = @_;
    # print "Ev state: ", $ev->state, "\n";
    if ( $item->{dragging} && $ev->state >= 'button1-mask' ) {
        $item->translate($ev->x - $item->{drag_x},
                         $ev->y - $item->{drag_y});
    }
    return TRUE;
}

sub on_button_press {
    my ($item, $target, $ev) = @_;
    if ( $ev->button == 1 ) {
        if ( $ev->state >= 'shift-mask' ) {
            my $parent = $item->get_parent;
            $parent->remove_child($parent->find_child($item));
        } else {
            $item->{drag_x} = $ev->x;
            $item->{drag_y} = $ev->y;
            my $fleur = Gtk2::Gdk::Cursor->new('fleur');
            my $canvas = $item->get_canvas;
            $canvas->pointer_grab($item, ['pointer-motion-mask', 'button-release-mask'],
                                  $fleur, $ev->time);
            $item->{dragging} = TRUE;
        }
    }
    elsif ( $ev->button == 2 ) {
        $item->lower;
    }
    elsif ( $ev->button == 3 ) {
        $item->raise;
    }
    return TRUE;
}

sub on_button_release {
    my ($item, $target, $ev) = @_;
    my $canvas = $item->get_canvas;
    $canvas->pointer_ungrab($item, $ev->time);
    $item->{dragging} = FALSE;
    return TRUE;
}

sub on_background_button_press {
    return TRUE;
}

sub zoom_changed {
    my ($adj, $canvas) = @_;
    $canvas->set_scale($adj->get_value);
}

sub center_toggled {
}

sub anchor_toggled {
    my ($but, $canvas) = @_;
    if ( $but->get_active ) {
        $canvas->set("anchor" => $but->{anchor});
    }
}

sub scroll_to_50_50_clicked {
    my ($but, $canvas) = @_;
    $canvas->scroll_to(50, 50);
}

sub scroll_to_250_250_clicked {
    my ($but, $canvas) = @_;
    $canvas->scroll_to(250, 250);
}

sub scroll_to_500_500_clicked {
    my ($but, $canvas) = @_;
    $canvas->scroll_to(500, 500);
}

sub animate_ellipse_clicked {
    my ($but, $canvas) = @_;
    $canvas->{ellipse}->animate(100, 100, 1, 90, TRUE, 1000, 40, 'bounce');
}

sub stop_animation_clicked {
    my ($but, $canvas) = @_;
    $canvas->{ellipse}->stop_animation();
}

sub move_ellipse_clicked {
    my ($but, $canvas) = @_;
    my $ellipse = $canvas->{ellipse};
    if ( !exists $ellipse->{last_state} ) {
        $ellipse->{last_state} = 0;
    }
    my $last_state = $ellipse->{last_state};
    if ( $last_state == 0 ) {
        $ellipse->set(
            'center-x' => 300,
            'center-y' => 70,
            'radius-x' => 45,
            'radius-y' => 30,
            'fill-color' => 'red',
            'stroke-color' => 'midnightblue',
            'line-width' => 4,
            'title' => 'A red ellipse'
        );
        $last_state = 1;
    }
    elsif ( $last_state == 1 ) {
        $ellipse->set(
            'center-x' => 390,
            'center-y' => 150,
            'radius-x' => 45,
            'radius-y' => 40,
            'fill-color' => 'brown',
            'stroke-color' => 'midnightblue',
            'line-width' => 4,
            'title' => 'A brown ellipse'
        );
        $last_state = 2;
    }
    elsif ( $last_state == 2 ) {
        $ellipse->set(
            'center-x' => 0,
            'center-y' => 0,
            'radius-y' => 30,
        );
        $ellipse->set_simple_transform(100, 100, 1, 0);
        $last_state = 3;
    }
    elsif ( $last_state == 3 ) {
        $ellipse->set_simple_transform(200, 200, 2, 0);
        $last_state = 4;
    }
    elsif ( $last_state == 4 ) {
        $ellipse->set_simple_transform(200, 200, 1, 45);
        $last_state = 5;
    }
    elsif ( $last_state == 5 ) {
        $ellipse->set_simple_transform(-50, -50, 0.2, 225);
        $last_state = 6;
    }
    else {
        $ellipse->set(
            'center-x' => 335,
            'center-y' => 70,
            'radius-x' => 45,
            'radius-y' => 30,
            'fill-color' => 'purple',
            'stroke-color' => 'midnightblue',
            'line-width' => 4,
            'title' => 'A purple ellipse'
        );
        $last_state = 0;
    }
    $ellipse->{last_state} = $last_state;
    return TRUE;
}
sub write_pdf_clicked {
    my ($but, $canvas) = @_;
    print "Write PDF...\n";
    my $surface = Cairo::PdfSurface->create("demo.pdf", 9*72, 10*72);
    my $cr = Cairo::Context->create($surface);
    $cr->translate(20, 130);
    $canvas->render($cr, undef, 1);
    $cr->show_page;
    return TRUE;
}

#}}}
#}}}

#{{{  Arrowhead
package Arrowhead;
use Gtk2;
use Glib qw(TRUE FALSE);
use constant {
 LEFT             => 50.0,
 RIGHT            => 350.0,
 MIDDLE           => 150.0,
 DEFAULT_WIDTH    => 2,
 DEFAULT_SHAPE_A  => 4,
 DEFAULT_SHAPE_B  => 5,
 DEFAULT_SHAPE_C  => 4,
};

sub create_canvas {
    my $pkg = shift;
    my ($w, $frame, $canvas, $root, $item);
    my $vbox = Gtk2::VBox->new;
    $vbox->show;
    $vbox->set_border_width(4);
    $w = Gtk2::Label->new( <<EOF );
This demo allows you to edit arrowhead shapes.  Drag the little boxes
to change the shape of the line and its arrowhead.  You can see the
arrows at their normal scale on the right hand side of the window.
EOF
    $vbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;
    $w = Gtk2::Alignment->new(0.5, 0.5, 0, 0);
    $vbox->pack_start($w, TRUE, TRUE, 0);
    $w->show;
    $frame = Gtk2::Frame->new;
    $frame->set_shadow_type('in');
    $w->add($frame);
    $frame->show;

    $canvas = Goo::Canvas->new;
    $canvas->set_size_request(500, 350);
    $canvas->set_bounds(0, 0, 500, 350);
    $frame->add($canvas);
    $canvas->show;
    $canvas->{width} = DEFAULT_WIDTH;
    $canvas->{shape_a} = DEFAULT_SHAPE_A;
    $canvas->{shape_b} = DEFAULT_SHAPE_B;
    $canvas->{shape_c} = DEFAULT_SHAPE_C;
    
    $root = $canvas->get_root_item;
    # Big arrow
    $item = Goo::Canvas::Polyline->new_line(
        $root, LEFT, MIDDLE, RIGHT, MIDDLE,
        'stroke-color' => 'mediumseagreen',
        'end_arrow' => TRUE,
    );
    $canvas->{big_arrow} = $item;
    # Arrow outline
    $item = Goo::Canvas::Polyline->new(
        $root, TRUE, undef,
        "stroke-color" => 'black',
        'line-width' => 2,
        'line-cap' => 'round',
        'line-join' => 'round'
    );
    $canvas->{outline} = $item;
    # Drag boxes
    create_drag_box($canvas, $root, 'width_drag_box');
    create_drag_box($canvas, $root, 'shape_a_drag_box');
    create_drag_box($canvas, $root, 'shape_b_c_drag_box');
    # Dimensions
	create_dimension ($canvas, $root, "width_arrow", "width_text", 'e');
	create_dimension ($canvas, $root, "shape_a_arrow", "shape_a_text", 'n');
	create_dimension ($canvas, $root, "shape_b_arrow", "shape_b_text", 'n');
	create_dimension ($canvas, $root, "shape_c_arrow", "shape_c_text", 'w');
    # Info
	create_info ($canvas, $root, "width_info", LEFT, 260);
	create_info ($canvas, $root, "shape_a_info", LEFT, 280);
	create_info ($canvas, $root, "shape_b_info", LEFT, 300);
	create_info ($canvas, $root, "shape_c_info", LEFT, 320);
    # Division line
    Goo::Canvas::Polyline->new_line(
        $root, RIGHT + 50, 0, RIGHT+ 50, 1000,
        'fill-color' => 'black',
        'line-width' => 2
    );
    # Sample arrows
	create_sample_arrow ($canvas, $root, "sample_1",
			     RIGHT + 100, 30, RIGHT + 100, MIDDLE - 30);
	create_sample_arrow ($canvas, $root, "sample_2",
			     RIGHT + 70, MIDDLE, RIGHT + 130, MIDDLE);
	create_sample_arrow ($canvas, $root, "sample_3",
			     RIGHT + 70, MIDDLE + 30, RIGHT + 130, MIDDLE + 120);
    # Done
    set_arrow_shape($canvas);
    return $vbox;
}

sub set_dimension {
    my ($canvas, $arrow_name, $text_name, $x1, $y1, $x2, $y2, $tx, $ty, $dim) = @_;
    my $points = Goo::Canvas::Points->new([$x1, $y1, $x2, $y2]);
    $canvas->{$arrow_name}->set(points => $points);
    $canvas->{$text_name}->set(text => sprintf("%.2f", $dim),
                               x => $tx,
                               y => $ty);
}

sub move_drag_box {
    my ($item, $x, $y) = @_;
    $item->set(x => $x-5,
               y => $y-5);
}

sub set_arrow_shape {
    my $canvas  = shift;
    my $width = $canvas->{width};
    my $shape_a = $canvas->{shape_a};
    my $shape_b = $canvas->{shape_b};
    my $shape_c = $canvas->{shape_c};
    # Big arrow
    $canvas->{big_arrow}->set(
        'line-width' => 10*$width,
        'arrow-tip-length' => $shape_a,
        'arrow-length' => $shape_b,
        'arrow-width' => $shape_c
    );
    # Outline
    my @points;
    $points[0] = RIGHT -int(10 *$shape_a*$width);
    $points[1] = MIDDLE-int(10*$width/2);
    $points[2] = RIGHT - 10 * $shape_b * $width;
    $points[3] = MIDDLE - 10 * ($shape_c * $width / 2.0);
    $points[4] = RIGHT;
    $points[5] = MIDDLE;
    $points[6] = RIGHT - 10 * $shape_b * $width;
    $points[7] = MIDDLE + 10 * ($shape_c * $width / 2.0);
    $points[8] = RIGHT -int(10 *$shape_a*$width);
    $points[9] = MIDDLE + 10 * $width / 2;
    $canvas->{outline}->set(
        points => Goo::Canvas::Points->new(\@points)
    );
    move_drag_box($canvas->{width_drag_box}, LEFT, MIDDLE-10*$width/2);
    move_drag_box($canvas->{shape_a_drag_box},
                  RIGHT-10*$shape_a*$width, MIDDLE);
    move_drag_box($canvas->{shape_b_c_drag_box},
                  RIGHT-10*$shape_b*$width, MIDDLE-10*($shape_c*$width/2));
    # Dimensions
    set_dimension($canvas, 'width_arrow', 'width_text',
		       LEFT - 10,
		       MIDDLE - 10 * $width / 2.0,
		       LEFT - 10,
		       MIDDLE + 10 * $width / 2.0,
		       LEFT - 15,
		       MIDDLE,
		       $width);
	set_dimension ($canvas, "shape_a_arrow", "shape_a_text",
		       RIGHT - 10 * $shape_a * $width,
		       MIDDLE + 10 * ($shape_c * $width / 2.0) + 10,
		       RIGHT,
		       MIDDLE + 10 * ($shape_c * $width / 2.0) + 10,
		       RIGHT - 10 * $shape_a * $width / 2.0,
		       MIDDLE + 10 * ($shape_c * $width / 2.0) + 15,
		       $shape_a);
	set_dimension ($canvas, "shape_b_arrow", "shape_b_text",
		       RIGHT - 10 * $shape_b * $width,
		       MIDDLE + 10 * ($shape_c * $width / 2.0) + 35,
		       RIGHT,
		       MIDDLE + 10 * ($shape_c * $width / 2.0) + 35,
		       RIGHT - 10 * $shape_b * $width / 2.0,
		       MIDDLE + 10 * ($shape_c * $width / 2.0) + 40,
		       $shape_b);

	set_dimension ($canvas, "shape_c_arrow", "shape_c_text",
		       RIGHT + 10,
		       MIDDLE - 10 * $shape_c * $width / 2.0,
		       RIGHT + 10,
		       MIDDLE + 10 * $shape_c * $width / 2.0,
		       RIGHT + 15,
		       MIDDLE,
		       $shape_c);
    # Info
    $canvas->{width_info}->set(
        text => sprintf("line-width: %.2f", $width)
    );
    $canvas->{shape_a_info}->set(
        text => sprintf("arrow-tip-length: %.2f (* line-width)",
                        $shape_a)
    );
    $canvas->{shape_b_info}->set(
        text => sprintf("arrow-length: %.2f (* line-width)",
                        $shape_b)
    );
    $canvas->{shape_c_info}->set(
        text => sprintf("arrow-width: %.2f (* line-width)",
                        $shape_c)
    );
    # Sample arrows
    for ( qw/ sample_1 sample_2 sample_3 / ) {
        $canvas->{$_}->set(
            "line-width"       => $width,
            "arrow-tip-length" => $shape_a,
            "arrow-length"     => $shape_b,
            "arrow-width"      => $shape_c,
        );
    }
}

sub create_dimension {
    my ($canvas, $root, $arrow_name, $text_name, $anchor) = @_;
    my $item;
    $item = Goo::Canvas::Polyline->new(
        $root, FALSE, undef,
        'fill-color' => 'black',
        'start-arrow' => TRUE,
        'end-arrow' => TRUE,
    );
    $canvas->{$arrow_name} = $item;
    $item = Goo::Canvas::Text->new(
        $root, "", 0, 0, -1, $anchor,
        'fill-color' => 'black',
        'font' => 'Sans 12',
    );
    $canvas->{$text_name} = $item;
}

sub create_info {
    my ($canvas, $root, $info_name, $x, $y) = @_;
    my $item = Goo::Canvas::Text->new(
        $root, "", $x, $y, -1, 'nw',
        'fill-color' => 'black',
        'font' => 'Sans 12',
    );
    $canvas->{$info_name} = $item;
}

sub create_sample_arrow {
    my ($canvas, $root, $sample_name, $x1, $y1, $x2, $y2) = @_;
    my $item = Goo::Canvas::Polyline->new_line(
        $root, $x1, $y1, $x2, $y2,
        'start-arrow' => TRUE,
        'end-arrow' => TRUE,
    );
    $canvas->{$sample_name} = $item;
}

sub on_enter_notify {
    my $item = shift;
    $item->set('fill-color' => 'red');
    return TRUE;
}

sub on_leave_notify {
    my $item = shift;
    $item->set('fill-color' => 'black');
    return TRUE;
}

sub on_button_press {
    my ($item, $target, $ev) = @_;
    my $fleur = Gtk2::Gdk::Cursor->new('fleur');
    $item->get_canvas->pointer_grab(
        $item, ['pointer-motion-mask', 'button-release-mask'],
        $fleur, $ev->time);
    return TRUE;
}

sub on_button_release {
    my ($item, $target, $ev) = @_;
    $item->get_canvas->pointer_ungrab(
        $item, $ev->time
    );
    return TRUE;
}

sub on_motion {
    my ($item, $target, $ev)= @_;
    my $canvas = $item->get_canvas;
    my ($x, $y, $width, $shape_a, $shape_b, $shape_c);
    my $change = FALSE;
    unless ( $ev->state >= 'button1-mask' ) {
        return FALSE;
    }
    if ( $item == $canvas->{width_drag_box} ) {
        $y = $ev->y;
        $width = (MIDDLE-$y)/5;
        if ( $width < 0) {
            return FALSE;
        }
        $canvas->{width} = $width;
        set_arrow_shape($canvas);
    }
    elsif ( $item == $canvas->{shape_a_drag_box} ) {
        $x = $ev->x;
        $width = $canvas->{width};
        $shape_a = (RIGHT-$x)/10/$width;
        if ( ($shape_a < 0) || ($shape_a>30) ) {
            return FALSE;
        }
        $canvas->{shape_a} =$shape_a;
        set_arrow_shape($canvas);
    }
    elsif ( $item == $canvas->{shape_b_c_drag_box} ) {
        $x = $ev->x;
        $width = $canvas->{width};
        $shape_b = (RIGHT-$x)/10/$width;
        if ( ($shape_b >= 0) && ($shape_b <=30) ) {
            $canvas->{shape_b} = $shape_b;
            $change = TRUE;
        }
        $y = $ev->y;
        $shape_c = (MIDDLE-$y) * 2/10/$width;
        if ( $shape_c >= 0 ) {
            $canvas->{shape_c} = $shape_c;
            $change = TRUE;
        }
        if ( $change ) {
            set_arrow_shape($canvas);
        }
    }
    return TRUE;
}

sub create_drag_box {
    my ($canvas, $root, $box_name) = @_;
    my $item = Goo::Canvas::Rect->new(
        $root, 0, 0, 10, 10,
        'fill-color' => 'black',
        'stroke-color' => 'black',
        'line-width' => 1,
    );
    $canvas->{$box_name} = $item;
    $item->signal_connect(
        'enter_notify_event' => \&on_enter_notify
    );
    $item->signal_connect(
        'leave_notify_event' => \&on_leave_notify,
    );
    $item->signal_connect(
        'button_press_event' => \&on_button_press
    );
    $item->signal_connect(
        'button_release_event' => \&on_button_release
    );
    $item->signal_connect(
        'motion_notify_event' => \&on_motion
    );
}

#}}}

#{{{  Fifteen
package Fifteen;
use Gtk2;
use Glib qw(TRUE FALSE);

use constant {
    PIECE_SIZE => 50,
    SCRAMBLE_MOVES => 256,
};

sub create_canvas {
    my $pkg = shift;
    my $vbox = Gtk2::VBox->new;
    my ($alignment, $frame, $canvas, $root, $button);
    my ($x, $y, @board);
    
    $vbox->set_border_width(4);
    $vbox->show;

    $alignment = Gtk2::Alignment->new(0.5, 0.5, 0, 0);
    $vbox->pack_start($alignment, TRUE, TRUE, 0);
    $alignment->show;

    $frame = Gtk2::Frame->new();
    $frame->set_shadow_type('in');
    $alignment->add($frame);
    $frame->show;

    # Create the canvas and board
    $canvas = Goo::Canvas->new;
    $root = $canvas->get_root_item;
    $canvas->set_size_request( PIECE_SIZE * 4 + 1,
                               PIECE_SIZE * 4 + 1);
    $canvas->set_bounds(0, 0, PIECE_SIZE * 4+1, PIECE_SIZE * 4 + 1);
    $frame->add($canvas);
    $canvas->show;

    foreach my $i( 0..14 ) {
        $x = $i % 4;
        $y = int($i / 4);
        my $item = Goo::Canvas::Group->new($root);
        $item->translate($x * PIECE_SIZE, $y * PIECE_SIZE);
        setup_item_signals($item);
        my $rect = Goo::Canvas::Rect->new(
            $item, 0, 0, PIECE_SIZE, PIECE_SIZE,
            'fill-color' => get_piece_color($i),
            'stroke-color' => 'black',
            'line-width' => 1
        );
        my $text = Goo::Canvas::Text->new(
            $item, $i+1, PIECE_SIZE/2, PIECE_SIZE/2, -1, 'center',
            'font' => 'Sans bold 24',
            'fill-color' => 'black'
        );
        $item->{text} = $text;
        $item->{piece_num} = $i;
        $item->{piece_pos} = $i;
        push @board, $item;
    }
    push @board, undef;
    $canvas->{board} = \@board;
    $button = Gtk2::Button->new("Scramble");
    $vbox->pack_start($button, FALSE, FALSE, 0);
    $button->signal_connect('clicked', \&scramble, $canvas);
    $button->show;
    return $vbox;
}

sub get_piece_color {
    use integer;
    my $i = shift;
    my $x = $i % 4;
    my $y = $i / 4;
    my $r = (( 4- $x) * 255) /4;
    my $g = (( 4- $y) * 255) /4;
    my $b = 128;
    return sprintf("#%02x%02x%02x", $r, $g, $b);
}

sub piece_enter_notify {
    my $item = shift;
    $item->{text}->set(
        'fill-color' => 'white'
    );
    return FALSE;
}

sub piece_leave_notify {
    my $item = shift;
    $item->{text}->set(
        'fill-color' => 'black'
    );
    return FALSE;
}

sub piece_button_press {
    my ($item, $target, $event, $data) = @_;
    my ($num, $pos, $text, $x, $y, $move, $dx, $dy, $newpos);
    
    my $canvas = $item->get_canvas;
    my $board = $canvas->{board};
    $num = $item->{piece_num};
    $pos = $item->{piece_pos};
    $text = $item->{text};
    $x = $pos % 4;
    $y = int($pos / 4);
    $move = TRUE;
    if ( $y>0 && !$board->[($y-1)*4+$x] ) {
        $dx = 0;
        $dy = -1;
        $y--;
    }
    elsif ( $y<3 && !$board->[($y+1)*4+$x] ) {
        $dx = 0;
        $dy = 1;
        $y++;
    }
    elsif ( $x>0 && !$board->[$y*4+$x-1] ) {
        $dx = -1;
        $dy = 0;
        $x--;
    }
    elsif ( $x<3 && !$board->[$y*4+$x+1] ) {
        $dx = 1;
        $dy = 0;
        $x++;
    }
    else {
        $move = FALSE;
    }
    if ( $move ) {
        $newpos = $y*4+$x;
        $board->[$pos] = undef;
        $board->[$newpos] = $item;
        $item->{piece_pos} = $newpos;
        $item->translate($dx*PIECE_SIZE, $dy*PIECE_SIZE);
        test_win($board);
    }
    return FALSE;
}

sub test_win {
    my $board = shift;
    foreach ( 0..14 ) {
        if ( !$board->[$_] || $board->[$_]{piece_num} != $_ ) {
            return;
        }
    }
    if ( 1 ) {
        my $item = ($board->[0] || $board->[1]);
        my $dia = Gtk2::MessageDialog->new(
            $item->get_canvas->get_toplevel, 'destroy-with-parent',
            'info', 'ok',
            'You stud, you win!',
        );
        $dia->show;
        $dia->signal_connect( 'response' => sub { $dia->destroy; } );
    }
    return TRUE;
}

sub setup_item_signals {
    my $item = shift;
    $item->signal_connect(
        'enter_notify_event' => \&piece_enter_notify
    );
    $item->signal_connect(
        'leave_notify_event' => \&piece_leave_notify,
    );
    $item->signal_connect(
        'button-press-event' => \&piece_button_press,
    );
}

sub scramble {
    my ($but, $canvas) = @_;
    my $board = $canvas->{board};
    my ($x, $y, $dir, $oldpos);
    my $pos = 0;
    foreach ( @$board ) {
        last unless $_;
        $pos++;
    }
    for ( 0..SCRAMBLE_MOVES ) {
        my $done = 0;
        $x = $y = 0;
        while ( !$done ) {
            $dir = int(rand(4));
            $done = 1;
            if ( $dir == 0 && $pos > 3 ) {
                $y = -1;
            } elsif ( $dir==1 && $pos < 12 ) {
                $y = 1;
            } elsif ( $dir == 2 && ($pos%4) != 0 ) {
                $x = -1;
            }
            elsif ( $dir == 3 && ($pos %4) != 3  ) {
                $x = 1;
            }
            else {
                $done = 0;
            }
        }
        $oldpos = $pos + $y*4 + $x;
        $board->[$pos] = $board->[$oldpos];
        $board->[$oldpos] = undef;
        $board->[$pos]->{piece_pos} = $pos;
        $board->[$pos]->translate(-$x*PIECE_SIZE, -$y*PIECE_SIZE);
        $pos = $oldpos;
    }
}
#}}}

#{{{  Reparent
package Reparent;
use Gtk2;
use Glib qw(TRUE FALSE);

sub create_canvas {
    my $pkg = shift;
    my ($w, $alignment, $frame, $canvas, $root, $parent1, $parent2, $item, $group);
    my $vbox = Gtk2::VBox->new;
    $vbox->show;
    $vbox->set_border_width(4);
    # Instructions
    $w = Gtk2::Label->new("Reparent test:  click on the items to switch them between parents");
    $vbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;
    # Frame and canvas
    $alignment = Gtk2::Alignment->new(0.5, 0.5, 0, 0);
    $vbox->pack_start($alignment, FALSE, FALSE, 0);
    $alignment->show;
    $frame = Gtk2::Frame->new();
    $frame->set_shadow_type('in');
    $alignment->add($frame);
    $frame->show;
    $canvas = Goo::Canvas->new;
    $root = $canvas->get_root_item;
    $canvas->set_size_request( 400, 200);
    $canvas->set_bounds( 0, 0, 400, 200);
    $frame->add($canvas);
    $canvas->show;
    # First parent and box
    $parent1 = Goo::Canvas::Group->new($root);
    Goo::Canvas::Rect->new(
        $parent1, 0, 0, 200, 200,
        'fill-color' => 'tan'
    );
    # Second parent and box
    $parent2 = Goo::Canvas::Group->new($root);
    $parent2->translate(200, 0);
    Goo::Canvas::Rect->new(
        $parent2, 0, 0, 200, 200,
        'fill-color' => '#204060'
    );
    # Big circle to be reparented
    $item = Goo::Canvas::Ellipse->new(
        $parent1, 100, 100, 90, 90,
        'stroke-color' => 'black',
        'fill-color' => 'mediumseagreen',
        'line-width' => 3,
    );
    $item->{parent1} = $parent1;
    $item->{parent2} = $parent2;
    $item->signal_connect(
        'button-press-event' => \&on_button_press
    );
    # A group to be reparented
    $group = Goo::Canvas::Group->new($parent2);
    $group->translate(100, 100);
    Goo::Canvas::Ellipse->new(
        $group, 0, 0, 50, 50,
        'stroke-color' => 'black',
        'fill-color' => 'wheat',
        'line-width' => 3,
    );
    Goo::Canvas::Ellipse->new(
        $group, 0, 0, 25, 25,
        'fill-color' => 'steelblue',
    );
    $group->{parent1} = $parent1;
    $group->{parent2}  = $parent2;
    $group->signal_connect(
        'button-press-event' => \&on_button_press
    );
    return $vbox;
}

sub on_button_press {
    my ($item, $target, $ev) = @_;
    if ( $ev->button != 1 || $ev->type ne 'button-press' ) {
        return FALSE;
    }
    my $parent1 = $item->{parent1};
    my $parent2 = $item->{parent2};
    my $parent = $item->get_parent;
    my $child_num = $parent->find_child($item);
    $parent->remove_child($child_num);
    if ( $parent == $parent1 ) {
        $parent2->add_child($item, -1);
    }
    else {
        $parent1->add_child($item, -1);
    }
    return TRUE;
}

#}}}

#{{{  Scalability
package Scalability;
use Gtk2;
use Glib qw(TRUE FALSE);
use constant {
  N_COLS  => 5,
  N_ROWS  => 20,
  PADDING => 10,
};

sub create_canvas {
    my $pkg = shift;
    my $vbox = Gtk2::VBox->new;
    my ($table, $frame, $canvas, $root, $width, $height, $pixbuf,
        $swin, $item);
    my $use_image = 1;
    $vbox->show;
    $vbox->set_border_width(4);
    $table = Gtk2::Table->new(2, 2, FALSE);
    $table->set_row_spacings(4);
    $table->set_col_spacings(4);
    $vbox->pack_start($table, TRUE, TRUE, 0);
    $table->show;
    $frame = Gtk2::Frame->new();
    $frame->set_shadow_type('in');
    $table->attach($frame, 0,1, 0,1,
                   ['expand', 'fill', 'shrink'],
                   ['expand', 'fill', 'shrink'],
                   0, 0);
    $frame->show;
    # Create the canvas and board
    $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file("$FindBin::Bin/toroid.png");
    if ( $use_image ) {
        $width = $pixbuf->get_width + 3;
        $height = $pixbuf->get_height + 1;
    }
    else {
        $width = 37;
        $height  = 19;
    }
    $canvas = Goo::Canvas->new;
    $root = $canvas->get_root_item;
    $canvas->set_size_request( 600, 450);
    $canvas->set_bounds( 0, 0, N_COLS*($width+PADDING), N_ROWS*($height+PADDING));
    $canvas->show;
    $swin = Gtk2::ScrolledWindow->new();
    $swin->show;
    $frame->add($swin);
    $swin->add($canvas);
    for my $i( 0..N_COLS-1 ) {
        for my $j ( 0..N_ROWS-1 ) {
            if ( $use_image ) {
                $item = Goo::Canvas::Image->new(
                    $root, $pixbuf, $i*($width+PADDING), $j*($height+PADDING),
                );
            }
            else {
                $item = Goo::Canvas::Rect->new(
                    $root, $i*($width+PADDING), $j*($height+PADDING),
                    $width, $height,
                    'fill-color' => (($i+$j)%2 ? 'mediumseagreen' : 'steelblue'),
                );
            }
        }
    }
                         
    return $vbox;
}
#}}}

#{{{  Grabs
package Grabs;
use Gtk2;
use Glib qw(TRUE FALSE);

sub create_canvas {
    my $pkg = shift;
    my ($w);
    my $table = Gtk2::Table->new(5, 2, FALSE);
    $table->set_border_width(12);
    $table->set_row_spacings(12);
    $table->set_col_spacings(12);
    $table->show;
    $w = Gtk2::Label->new(<<INS);
Move the mouse over the widgets and canvas items on the right to see what events they receive.
Click buttons to start explicit or implicit pointer grabs and see what events they receive now.
(They should all receive the same events.)
INS
    $table->attach($w, 0,2, 0,1, [],[],0,0);
    $w->show;
    # Drawing area with explicit grabs. 
    create_fixed ($table, 1,
                  "Widget with Explicit Grabs:",
                  "widget-explicit");

    # Drawing area with implicit grabs. 
    create_fixed ($table, 2,
                  "Widget with Implicit Grabs:",
                  "widget-implicit");

    # Canvas with explicit grabs. 
    _create_canvas ($table, 3,
                   "Canvas with Explicit Grabs:",
                   "canvas-explicit");

    # Canvas with implicit grabs. 
    _create_canvas ($table, 4,
                   "Canvas with Implicit Grabs:",
                   "canvas-implicit");

    return $table;
}

sub create_fixed {
    my ($table, $row, $text, $id) = @_;
    my ($label, $fixed, $drawing_area, $view_id);
    $label = Gtk2::Label->new($text);
    $table->attach($label, 0, 1, $row, $row+1, [], [], 0, 0);
    $label->show;
    $fixed = Gtk2::Fixed->new;
    $fixed->set_has_window(TRUE);
    $fixed->set_events(
        ['exposure_mask',            'button_press_mask',
         'button_release_mask',      'pointer_motion_mask',
         'pointer_motion_hint_mask', 'key_press_mask',
         'key_release_mask',         'enter_notify_mask',
         'leave_notify_mask',        'focus_change_mask']
    );
    $fixed->set_size_request(200, 100);
    $table->attach($fixed, 1, 2, $row, $row+1, [], [], 0, 0);
    $fixed->show;
    $view_id = "$id-background";
    $fixed->signal_connect(
        'expose_event', \&on_widget_expose, $view_id
    );
    $fixed->signal_connect( "enter_notify_event",
                            \&on_widget_enter_notify, $view_id);
    $fixed->signal_connect( "leave_notify_event",
                            \&on_widget_leave_notify, $view_id);
    $fixed->signal_connect( "motion_notify_event",
                            \&on_widget_motion_notify, $view_id);
    $fixed->signal_connect( "button_press_event",
                            \&on_widget_button_press, $view_id);
    $fixed->signal_connect( "button_release_event",
                            \&on_widget_button_release, $view_id);
    # Left
    my $pos = 20;
    for ( 'left', 'right' ) {
        $drawing_area = Gtk2::DrawingArea->new;
        $drawing_area->set_events(
            ['exposure_mask',            'button_press_mask',
             'button_release_mask',      'pointer_motion_mask',
             'pointer_motion_hint_mask', 'key_press_mask',
             'key_release_mask',         'enter_notify_mask',
             'leave_notify_mask',        'focus_change_mask']
        );
        $drawing_area->set_size_request(60, 60);
        $fixed->put($drawing_area, $pos, 20);
        $pos += 100;
        $drawing_area->show;
        $view_id = "$id-$_";
        $drawing_area->signal_connect( "enter_notify_event",
                                       \&on_widget_enter_notify, $view_id);
        $drawing_area->signal_connect( "leave_notify_event",
                                       \&on_widget_leave_notify, $view_id);
        $drawing_area->signal_connect( "motion_notify_event",
                                       \&on_widget_motion_notify, $view_id);
        $drawing_area->signal_connect( "button_press_event",
                                       \&on_widget_button_press, $view_id);
        $drawing_area->signal_connect( "button_release_event",
                                       \&on_widget_button_release, $view_id);
    }
}

sub _create_canvas {
    my ($table, $row, $text, $id) = @_;
    my ($label, $canvas, $root, $rect);
    $label  = Gtk2::Label->new($text);
    $table->attach($label, 0, 1, $row, $row+1, [], [], 0, 0);
    $label->show;
    $canvas = Goo::Canvas->new;
    $canvas->set_size_request(200, 100);
    $canvas->set_bounds(0, 0, 200, 100);
    $table->attach($canvas, 1, 2, $row, $row+1, [], [], 0, 0);
    $canvas->show;
    $root = $canvas->get_root_item;
    $rect = Goo::Canvas::Rect->new(
        $root, 0, 0, 200, 100,
        'stroke-pattern' => undef,
        'fill-color' => 'yellow',
    );
    $rect->{id} = "$id-yellow";
    setup_item_signals($rect);
    $rect = Goo::Canvas::Rect->new(
        $root, 20, 20, 60, 60,
        'stroke-pattern' => undef,
        'fill-color' => 'blue',
    );
    $rect->{id} = $id.'-blue';
    setup_item_signals($rect);
    $rect = Goo::Canvas::Rect->new(
        $root, 120, 20, 60, 60,
        'stroke-pattern' => undef,
        'fill-color' => 'red',
    );
    $rect->{id} = $id.'-red';
    setup_item_signals($rect);
}

sub setup_item_signals {
    my $item = shift;
    $item->signal_connect( "enter_notify_event",
                           \&on_enter_notify);
    $item->signal_connect( "leave_notify_event",
                           \&on_leave_notify);
    $item->signal_connect( "motion_notify_event",
                           \&on_motion_notify);
    $item->signal_connect( "button_press_event",
                           \&on_button_press);
    $item->signal_connect( "button_release_event",
                           \&on_button_release);
}
# FIXME: the box is not showed
sub on_widget_expose {
    my ($widget, $ev, $id) = @_;
    print "$id received 'expose' signal\n";
    $widget->style->paint_box(
        $widget->window, 'normal','in',$ev->area, $widget, undef,
        0, 0, $widget->allocation->width, $widget->allocation->height
    );
    return FALSE;
}

sub on_widget_enter_notify {
    my ($widget, $ev, $id) = @_;
    print "$id received 'enter-notify' signal\n";
    return TRUE;
}

sub on_widget_leave_notify {
    my ($widget, $ev, $id) = @_;
    print "$id received 'leave-notify' signal\n";
    return TRUE;
}

sub on_widget_motion_notify {
    my ($widget, $ev, $id) = @_;
    print "$id received 'motion-notify' signal(window: ",
        sprintf("0x%x", $ev->window->get_pointer), ")\n";
    if ( $ev->is_hint ) {
        $ev->window->get_pointer();
    }
    return TRUE;
}

sub on_widget_button_press {
    my ($widget, $ev, $id) = @_;
    print "$id received 'button-press' signal\n";
    if ( $id =~ /explicit/ ) {
        my $mask = [
            'button_press_mask',   'button_release_mask',
            'pointer_motion_mask', 'pointer_motion_hint_mask',
            'enter_notify_mask',   'leave_notify_mask',
        ];
        my $staus = $widget->window->pointer_grab(FALSE, $mask, FALSE, undef, $ev->time);
        if ( $staus eq 'success' ) {
            print "grabbed pointer\n";
        } else {
            print "pointer grab failed\n";
        }
    }
    return TRUE;
}

sub on_widget_button_release {
    my ($widget, $ev, $id) = @_;
    print "$id received 'button-release' signal\n";
    if ( $id =~ /explicit/ ) {
        my $display = $widget->get_display;
        $display->pointer_ungrab($ev->time);
        print "released pointer grab\n";
    }
    return TRUE;
}

sub on_enter_notify {
    my ($item, $target, $ev) = @_;
    print "$item->{id} received 'enter-notify' signal\n";
    return FALSE;
}
sub on_leave_notify {
    my ($item, $target, $ev) = @_;
    print "$item->{id} received 'leave-notify' signal\n";
    return FALSE;
}

sub on_motion_notify {
    my ($item, $target, $ev) = @_;
    print "$item->{id} received 'motion-notify' signal\n";
    return FALSE;
}

sub on_button_press {
    my ($item, $target, $ev) = @_;
    print "$item->{id} received 'button-press' signal\n";
    if ( $item->{id} =~ /explicit/ ) {
        my $mask = [
            'button_press_mask',   'button_release_mask',
            'pointer_motion_mask', 'pointer_motion_hint_mask',
            'enter_notify_mask',   'leave_notify_mask',
        ];
        my $canvas = $item->get_canvas;
        my $staus = $canvas->pointer_grab( $item, $mask, undef, $ev->time);
        if ( $staus eq 'success' ) {
            print "grabbed pointer\n";
        } else {
            print "pointer grab failed\n";
        }
    }
    return FALSE;
}

sub on_button_release {
    my ($item, $target, $ev) = @_;
    print "$item->{id} received 'button-released' signal\n";
    if ( $item->{id} =~ /explicit/ ) {
        my $canvas = $item->get_canvas;
        $canvas->pointer_ungrab($item, $ev->time);
        print "released pointer grab\n";
    }
    return FALSE;
}

#}}}

#{{{  Events
package Events;
use Gtk2;
use Glib qw(TRUE FALSE);

sub create_canvas {
    my $pkg = shift;
    my $vbox = Gtk2::VBox->new;
    my ($alignment, $frame, $label, $canvas);
    
    $vbox->show;
    $vbox->set_border_width(4);
    # Instructions
    $label = Gtk2::Label->new(<<INS);
Move the mouse over the items to check they receive the right motion events.
The first 2 items in each group are 1) invisible and 2) visible but unpainted.
INS
    $label->show;
    $vbox->pack_start($label, FALSE, FALSE, 0);
    # Frame and canvas
    $alignment = Gtk2::Alignment->new(0.5, 0.5, 0, 0);
    $vbox->pack_start($alignment, FALSE, FALSE, 0);
    $alignment->show;
    $frame = Gtk2::Frame->new();
    $frame->set_shadow_type('in');
    $alignment->add($frame);
    $frame->show;
    $canvas = Goo::Canvas->new;
    $canvas->set_size_request(600, 450);
    $canvas->set_bounds(0, 0, 600, 450);
    $frame->add($canvas);
    $canvas->show;
    create_events_area($canvas, 0, 'none', 'none');
    create_events_area($canvas, 1, 'visible-painted', 'visible-painted');
    create_events_area($canvas, 2, 'visible-fill', 'visible-fill');
    create_events_area($canvas, 3, 'visible-stroke', 'visible-stroke');
    create_events_area($canvas, 4, 'visible', 'visible');
    create_events_area($canvas, 5, 'painted', 'painted');
    create_events_area($canvas, 6, 'fill', 'fill');
    create_events_area($canvas, 7, 'stroke', 'stroke');
    create_events_area($canvas, 8, 'all', 'all');
    return $vbox;
}

sub create_events_area {
    my ($canvas, $area_num, $pointer_events, $label) = @_;
    my $row = int($area_num/3);
    my $col = $area_num%3;
    my $x = $col * 200;
    my $y = $row * 150;
    my $root = $canvas->get_root_item;
    my $dash = Goo::Canvas::LineDash->new([5, 5]);
    my $rect;
    
    # Create invisible item
    $rect = Goo::Canvas::Rect->new(
        $root, $x+45, $y+35, 30, 30,
        'fill-color' => 'red',
        'visibility' => 'invisible',
        'line-width' => 5,
        'pointer_events' => $pointer_events
    );
    $rect->{id} = $label . ' invisible';
    setup_item_signals($rect);
    # Display a thin rect around it to indicate it is there
    $rect = Goo::Canvas::Rect->new(
        $root, $x+42.5, $y+32.5, 36, 36,
        'line-dash' => $dash,
        'line-width' => 1,
        'stroke-color' => 'gray',
    );
    # Create unpainted item.
    $rect = Goo::Canvas::Rect->new(
        $root, $x+85, $y+35, 30, 30,
        'stroke-pattern' => undef,
        'line-width' => 5,
        'pointer_events' => $pointer_events
    );
    $rect->{id} = $label . ' unpainted';
    setup_item_signals($rect);
    # Display a thin rect around it to indicate it is there
    $rect = Goo::Canvas::Rect->new(
        $root, $x+82.5, $y+32.5, 36, 36,
        'line-dash' => $dash,
        'line-width' => 1,
        'stroke-color' => 'gray',
    );
    # Create stroked item
    $rect = Goo::Canvas::Rect->new(
        $root, $x+125, $y+35, 30, 30,
        'line-width' => 5,
        'pointer_events' => $pointer_events
    );
    $rect->{id} = $label . ' stroked';
    setup_item_signals($rect);
    # Create filled item
    $rect = Goo::Canvas::Rect->new(
        $root, $x+60, $y+75, 30, 30,
        'fill-color' => 'red',
        'stroke-pattern' => undef,
        'line-width' => 5,
        'pointer_events' => $pointer_events
    );
    $rect->{id} = $label . ' filled';
    setup_item_signals($rect);
    # Create filled & filled item
    $rect = Goo::Canvas::Rect->new(
        $root, $x+100, $y+75, 30, 30,
        'fill-color' => 'red',
        'line-width' => 5,
        'pointer_events' => $pointer_events
    );
    $rect->{id} = $label . ' filled & filled';
    setup_item_signals($rect);
    Goo::Canvas::Text->new(
        $root, $label, $x+100, $y+130, -1, 'center',
        'font' => 'Sans 12',
        'fill-color' => 'blue',
    );
}

sub setup_item_signals {
    my $item = shift;
    $item->signal_connect(
        'motion_notify_event' => \&on_motion_notify
    );
}

sub on_motion_notify {
    my $item = shift;
    print "$item->{id} received 'motion-notify' signal\n";
}

#}}}

#{{{  Paths
package Paths;
use Gtk2;
use Glib qw(TRUE FALSE);

sub create_canvas {
    my $pkg = shift;
    my ($swin, $canvas);
    my $vbox = Gtk2::VBox->new;
    $vbox->show;
    $vbox->set_border_width(4);
    $swin = Gtk2::ScrolledWindow->new();
    $swin->set_shadow_type('in');
    $swin->show;
    $vbox->add($swin);
    $canvas = Goo::Canvas->new;
    $canvas->set_size_request(600, 450);
    $canvas->set_bounds(0, 0, 1000, 1000);
    $canvas->show;
    $swin->add($canvas);
    setup_canvas($canvas);
    return $vbox;
}

sub setup_canvas {
    my $canvas = shift;
    my $root   = $canvas->get_root_item;
    my $path;
    $path = Goo::Canvas::Path->new( $root, "M 20 20 L 40 40", );
    $path = Goo::Canvas::Path->new( $root, "M30 20 l20, 20", );
    $path = Goo::Canvas::Path->new( $root, "M 60 20 H 80", );
    $path = Goo::Canvas::Path->new( $root, "M60 40 h20", );
    $path = Goo::Canvas::Path->new( $root, "M 100,20 V 40", );
    $path = Goo::Canvas::Path->new( $root, "M 120 20 v 20", );
    $path = Goo::Canvas::Path->new( $root, "M 140 20 h20 v20 h-20 z", );
    $path =
      Goo::Canvas::Path->new( $root,
        "M 180 20 h20 v20 h-20 z m 5,5 h10 v10 h-10 z",
        "fill-color", "red", "fill-rule", 'even_odd', );

    $path = Goo::Canvas::Path->new( $root, "M 220 20 L 260 20 L 240 40 z",
        "fill-color", "red", "stroke-color", "blue", "line-width", 3.0, );

    # Test the bezier curve commands: CcSsQqTt.
    $path =
      Goo::Canvas::Path->new( $root,
        "M20,100 C20,50 100,50 100,100 S180,150 180,100",
      );

    $path =
      Goo::Canvas::Path->new( $root, "M220,100 c0,-50 80,-50 80,0 s80,50 80,0",
      );

    $path =
      Goo::Canvas::Path->new( $root, "M20,200 Q60,130 100,200 T180,200", );

    $path = Goo::Canvas::Path->new( $root, "M220,200 q40,-70 80,0 t80,0", );

    # Test the elliptical arc commands: Aa.
    $path =
      Goo::Canvas::Path->new( $root, "M200,500 h-150 a150,150 0 1,0 150,-150 z",
        "fill-color", "red", "stroke-color", "blue", "line-width", 5.0, );

    $path =
      Goo::Canvas::Path->new( $root, "M175,475 v-150 a150,150 0 0,0 -150,150 z",
        "fill-color", "yellow", "stroke-color", "blue", "line-width", 5.0, );

    $path = Goo::Canvas::Path->new(
        $root,
        "M400,600 l 50,-25 "
          . "a25,25 -30 0,1 50,-25 l 50,-25 "
          . "a25,50 -30 0,1 50,-25 l 50,-25 "
          . "a25,75 -30 0,1 50,-25 l 50,-25 "
          . "a25,100 -30 0,1 50,-25 l 50,-25",
        "stroke-color",
        "red",
        "line-width",
        5.0,
    );

    $path = Goo::Canvas::Path->new( $root, "M 525,75 a100,50 0 0,0 100,50",
        "stroke-color", "red", "line-width", 5.0, );
    $path = Goo::Canvas::Path->new( $root, "M 725,75 a100,50 0 0,1 100,50",
        "stroke-color", "red", "line-width", 5.0, );
    $path = Goo::Canvas::Path->new( $root, "M 525,200 a100,50 0 1,0 100,50",
        "stroke-color", "red", "line-width", 5.0, );
    $path = Goo::Canvas::Path->new( $root, "M 725,200 a100,50 0 1,1 100,50",
        "stroke-color", "red", "line-width", 5.0, );
}


#}}}

#{{{  Focus
package Focus;
use Gtk2;
use Glib qw(TRUE FALSE);

sub create_canvas {
    my $pkg = shift;
    my ($label, $swin, $canvas);
    my $vbox = Gtk2::VBox->new;
    $vbox->show;
    $vbox->set_border_width(4);
    $label = Gtk2::Label->new("Use Tab, Shift+Tab or the arrow keys to move the keyboard focus between the canvas items.");
    $swin = Gtk2::ScrolledWindow->new();
    $swin->set_shadow_type('in');
    $swin->show;
    $vbox->add($swin);
    $canvas = Goo::Canvas->new;
    $canvas->can_focus(TRUE);
    $canvas->set_size_request(600, 450);
    $canvas->set_bounds(0, 0, 1000, 1000);
    $canvas->show;
    $swin->add($canvas);
    setup_canvas($canvas);
    return $vbox;
}

sub setup_canvas {
    my $canvas = shift;
    create_focus_box ($canvas, 110, 80, 50, 30, "red");
    create_focus_box ($canvas, 300, 160, 50, 30, "orange");
    create_focus_box ($canvas, 500, 50, 50, 30, "yellow");
    create_focus_box ($canvas, 70, 400, 50, 30, "blue");
    create_focus_box ($canvas, 130, 200, 50, 30, "magenta");
    create_focus_box ($canvas, 200, 160, 50, 30, "green");
    create_focus_box ($canvas, 450, 450, 50, 30, "cyan");
    create_focus_box ($canvas, 300, 350, 50, 30, "grey");
    create_focus_box ($canvas, 900, 900, 50, 30, "gold");
    create_focus_box ($canvas, 800, 150, 50, 30, "thistle");
    create_focus_box ($canvas, 600, 800, 50, 30, "azure");
    create_focus_box ($canvas, 700, 250, 50, 30, "moccasin");
    create_focus_box ($canvas, 500, 100, 50, 30, "cornsilk");
    create_focus_box ($canvas, 200, 750, 50, 30, "plum");
    create_focus_box ($canvas, 400, 800, 50, 30, "orchid");
}

sub create_focus_box {
    my ($canvas, $x, $y, $width, $height, $color) = @_;
    my $root = $canvas->get_root_item;
    my $item = Goo::Canvas::Rect->new(
        $root, $x, $y, $width, $height,
        'stroke-pattern' => undef,
        'fill-color' => $color,
        'line-width' => 5,
        'can-focus' => TRUE,
    );
    $item->{id} = $color;
    $item->signal_connect('focus_in_event' => \&on_focus_in);
    $item->signal_connect('focus_out_event' => \&on_focus_out);
    $item->signal_connect('button_press_event' => \&on_button_press);
    $item->signal_connect('key_press_event' => \&on_key_press);
}

sub on_key_press {
    my($item, $target, $ev) = @_;
    print $item->{id} || "Unknown", " received key_press event\n";
    return FALSE;
}
sub on_button_press {
    my($item, $target, $ev) = @_;
    print $item->{id} || "Unknown", " received button_press event\n";
    my $canvas = $item->get_canvas;
    $canvas->grab_focus($item);
    return TRUE;
}
sub on_focus_out {
    my ($item, $target, $ev) = @_;
    print $item->{id} || "Unknown", " received focus_out event\n";
    $item->set("stroke-pattern" => undef);
    return FALSE;
}
sub on_focus_in {
    my ($item, $target, $ev) = @_;
    print $item->{id} || "Unknown", " received focus_in event\n";
    $item->set("stroke-color" => "black");
    return FALSE;
}

#}}}

#{{{  Animation
package Animation;
use Gtk2;
use Glib qw(TRUE FALSE);

sub create_canvas {
    my $pkg = shift;
    my ($hbox, $w, $swin, $canvas);
    my $vbox = Gtk2::VBox->new;
    $vbox->show;
    $vbox->set_border_width(4);
    $hbox = Gtk2::HBox->new(FALSE, 4);
    $vbox->pack_start($hbox, FALSE, FALSE, 0);
    $hbox->show;
    $w = Gtk2::ToggleButton->new('Start Animation');
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $w->show;
    $w->signal_connect('toggled', \&toggle_animation_clicked);
    $swin = Gtk2::ScrolledWindow->new();
    $swin->set_shadow_type('in');
    $swin->show;
    $vbox->add($swin);
    $canvas = Goo::Canvas->new;
    $canvas->set_size_request(600, 450);
    $canvas->set_bounds(0, 0, 1000, 1000);
    $canvas->show;
    $w->{canvas} = $canvas;
    $swin->add($canvas);
    setup_canvas($canvas);
    return $vbox;
}

sub setup_canvas {
    my $canvas = shift;
    my $root = $canvas->get_root_item;
    my ($rect1, $rect2, $rect3, $rect4, $ellipse1, $ellipse2);
    # Absolute
    $ellipse1 = Goo::Canvas::Ellipse->new(
        $root, 0, 0, 25, 15,
        'fill-color' => 'blue',
    );
    $ellipse1->translate(100, 100);
    $rect1 = Goo::Canvas::Rect->new(
        $root, -10, -10, 20, 20,
        'fill-color' => 'blue',
    );
    $rect1->translate(100, 200);
    $rect3 = Goo::Canvas::Rect->new(
        $root, -10, -10, 20, 20,
        'fill-color' => 'blue',
    );
    $rect3->translate(200, 200);
    # Relative
    $ellipse2 = Goo::Canvas::Ellipse->new(
        $root, 0, 0, 25, 15,
        'fill-color' => 'red',
    );
    $ellipse2->translate(100, 400);
    $rect2 = Goo::Canvas::Rect->new(
        $root, -10, -10, 20, 20,
        'fill-color' => 'red',
    );
    $rect2->translate(100, 500);
    $rect4 = Goo::Canvas::Rect->new(
        $root, -10, -10, 20, 20,
        'fill-color' => 'red',
    );
    $rect4->translate(200, 500);
    $canvas->{items} = [$rect1, $rect2, $rect3, $rect4, $ellipse1, $ellipse2];
}

sub toggle_animation_clicked {
    my $but = shift;
    if ( $but->get_active ) {
        $but->set_label('Stop Animation');
        start_animation($but);
    }
    else {
        $but->set_label('Start Animation');
        stop_animation($but);
    }
}
sub start_animation {
    my $but = shift;
    my ($rect1, $rect2, $rect3, $rect4, $ellipse1, $ellipse2) = @{$but->{canvas}{items}};
    
    # Absolute
    $ellipse1->set_simple_transform (100, 100, 1, 0);
    $ellipse1->animate (500, 100, 2, 720, TRUE, 2000, 40,
                        'bounce');

    $rect1->set_simple_transform (100, 200, 1, 0);
    $rect1->animate (100, 200, 1, 350, TRUE, 40 * 36, 40,
                     'restart');

    $rect3->set_simple_transform (200, 200, 1, 0);
    $rect3->animate (200, 200, 3, 0, TRUE, 400, 40,
                     'bounce');

    # Relative
    $ellipse2->set_simple_transform (100, 400, 1, 0);
    $ellipse2->animate (400, 0, 2, 720, FALSE, 2000, 40,
                        'bounce');

    $rect2->set_simple_transform (100, 500, 1, 0);
    $rect2->animate (0, 0, 1, 350, FALSE, 40 * 36, 40,
                     'restart');

    $rect4->set_simple_transform (200, 500, 1, 0);
    $rect4->animate (0, 0, 3, 0, FALSE, 400, 40,
                     'bounce');
}    

sub stop_animation {
    my $but = shift;
    my ($rect1, $rect2, $rect3, $rect4, $ellipse1, $ellipse2) = @{$but->{canvas}{items}};
    $ellipse1->stop_animation ();
    $ellipse2->stop_animation ();
    $rect1->stop_animation ();
    $rect2->stop_animation ();
    $rect3->stop_animation ();
    $rect4->stop_animation ();
}

#}}}

#{{{  Clipping
package Clipping;
use Gtk2;
use Glib qw(TRUE FALSE);

sub create_canvas {
    my $pkg = shift;
    my ($hbox, $swin, $canvas);
    my $vbox = Gtk2::VBox->new;
    $vbox->show;
    $vbox->set_border_width(4);
    $swin = Gtk2::ScrolledWindow->new();
    $swin->set_shadow_type('in');
    $swin->show;
    $vbox->add($swin);
    $canvas = Goo::Canvas->new;
    $canvas->set_size_request(600, 450);
    $canvas->set_bounds(0, 0, 1000, 1000);
    $canvas->show;
    $swin->add($canvas);
    setup_canvas($canvas);
    return $vbox;
}

sub setup_canvas {
    my $canvas = shift;
    my $root = $canvas->get_root_item;
    my $item;
    $item = Goo::Canvas::Ellipse->new(
        $root, 0, 0, 50, 30,
        'fill-color' => 'blue',
    );
    $item->translate(100, 100);
    $item->rotate(30, 0, 0);
    $item->signal_connect('button-press-event' => \&on_button_press,
                          "Blue ellipse (unclipped)");
    $item = Goo::Canvas::Rect->new(
        $root, 200, 50, 100, 100,
        'fill-color' => 'red',
        'clip-fill-rule' => 'even-odd'
    );
    $item->signal_connect('button-press-event' => \&on_button_press,
                      "Red rectangle (unclipped)");
    $item = Goo::Canvas::Rect->new(
        $root, 380, 50, 100, 100,
        'fill-color' => 'yellow'
    );
    $item->signal_connect('button-press-event' => \&on_button_press,
                      "Yellow rectangle(unclipped)");
    # clipped items
    $item = Goo::Canvas::Ellipse->new(
        $root, 0, 0, 50, 30,
        'fill-color' => 'blue',
        'clip-path' => "M 0 0 h 100 v 100 h -100 Z"
    );
    $item->translate (100, 300);
    $item->rotate (30, 0, 0);
    $item->signal_connect('button-press-event' => \&on_button_press,
                      "Blue ellipse");
    $item = Goo::Canvas::Rect->new(
        $root, 200, 250, 100, 100,
        'fill-color' => 'red',
        'clip-path' => "M 250 300 h 100 v 100 h -100 Z",
        'clip-fill-rule' => 'even-odd'
    );
    $item->signal_connect('button-press-event' => \&on_button_press,
                      "Red rectangle");
    $item = Goo::Canvas::Rect->new(
        $root, 380, 250, 100, 100,
        'fill-color' => 'yellow',
        'clip-path' => "M480,230 l40,100 l-80 0 z",
    );
    $item->signal_connect('button-press-event' => \&on_button_press,
                      'Yellow rectangle');
    # Table with clipped items
    my $table = Goo::Canvas::Table->new($root);
    $table->translate (200, 400);
    $table->rotate (30, 0, 0);
    $item = Goo::Canvas::Ellipse->new(
        $table, 0, 0, 50, 30,
        'fill-color' => 'blue',
        'clip-path' => "M 0 0 h 100 v 100 h -100 Z",
    );
    $item->translate (100, 300);
    $item->rotate (30, 0, 0);
    $item->signal_connect('button-press-event' => \&on_button_press,
                      'Blue ellipse');
    $item = Goo::Canvas::Rect->new(
        $table, 200, 250, 100, 100,
        'fill-color' => 'red',
        "clip-path" => "M 250 300 h 100 v 100 h -100 Z",
        "clip-fill-rule" => 'even-odd',
    );
    $table->set_child_properties(
        $item,
        'column' => 1,
    );
    $item->signal_connect('button-press-event' => \&on_button_press,
                          'Red rectangle');
    $item = Goo::Canvas::Rect->new(
        $table, 380, 250, 100, 100,
        'fill-color' => 'yellow',
        'clip-path' =>  "M480,230 l40,100 l-80 0 z"
    );
    $table->set_child_properties(
        $item,
        'column' => 2,
    );
    $item->signal_connect('button-press-event' => \&on_button_press,
                      'Yellow rectangle');
}

sub on_button_press {
    my ($item, $target, $ev, $id) = @_;
    printf "%s received 'button-press' at %g, %g, (root: %g, %g)\n",
        $id, $ev->x, $ev->y, $ev->x_root, $ev->y_root;
    return TRUE;
}
    
#}}}
