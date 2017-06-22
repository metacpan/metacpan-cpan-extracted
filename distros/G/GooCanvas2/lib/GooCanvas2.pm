package GooCanvas2;

use 5.006000;
use strict;
use warnings;
use Glib::Object::Introspection;

our $VERSION = '0.06';

# customization ------------------------------------------------------- #

my %_NAME_CORRECTIONS = (
	
);

my @_CLASS_STATIC_METHODS = qw/
	
/;
my @_FLATTEN_ARRAY_REF_RETURN_FOR = qw/	
	GooCanvas2::Canvas::get_items_at
	GooCanvas2::Canvas::get_items_in_area
	GooCanvas2::CanvasItem::get_items_at
	GooCanvas2::CanvasItem::class_list_child_properties
	GooCanvas2::CanvasItemModel::class_list_child_properties
/;

# HANDLE SENTINAL BOOLEAN FOR
# Unsicher bin ich mir bei GooCanvas2::CanvasItem::get_transform
# GooCanvas2::CanvasItem::get_simple_transform ist an sich eine Funktion, die ein 
# bool'sches und weitere out-Argumente zurückgibt. Allerdings sind diese nicht NULL
# wenn die Funktion unwahr zurückgibt (sd. bspw. undef, 0, 0, 1, 0). Daher lass ich es raus.
# Das selbe gilt für die entsprechenden Funktionen in CanvasItem (get_transform
# und get_simple_transform)
my @_HANDLE_SENTINEL_BOOLEAN_FOR = qw/
	
/;
my @_USE_GENERIC_SIGNAL_MARSHALLER_FOR = (
);


sub import {

	Glib::Object::Introspection->setup(
		basename => 'GooCanvas',
		version => '2.0',
		package => 'GooCanvas2',
		name_corrections => \%_NAME_CORRECTIONS,
		class_static_methods =>\@_CLASS_STATIC_METHODS,
		flatten_array_ref_return_for =>\@_FLATTEN_ARRAY_REF_RETURN_FOR,
		handle_sentinel_boolean_for => \@_HANDLE_SENTINEL_BOOLEAN_FOR);
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

GooCanvas2 - Perl binding for GooCanvas2 widget using Glib::Object::Introspection

=head1 SYNOPSIS

  	#!/usr/bin/perl -w
	use strict;
	use warnings;

	use Gtk3 -init;
	use GooCanvas2;
	
	my $window = Gtk3::Window->new();
	$window->set_default_size(640, 600);
	$window->signal_connect('destroy' => sub {Gtk3->main_quit()});

	my $scrolled_win = Gtk3::ScrolledWindow->new();
	$scrolled_win->set_shadow_type('in');

	my $canvas = GooCanvas2::Canvas->new();
	$canvas->set_size_request(600,450);
	$canvas->set_bounds(0,0,1000,1000);
	$scrolled_win->add($canvas);

	my $root = $canvas->get_root_item();

	# Add a few simple items
	my $rect_item = GooCanvas2::CanvasRect->new('parent' => $root,
						'x' => 100,
						'y' => 100,
						'width' => 300,
						'height' => 300,
						'line_width' => 10.0,
						'radius-x' => 20.0,
						'radius-y' => 10.0,
						'stroke-color' => 'yellow',
						'fill-color' => 'red');

	my $text_item = GooCanvas2::CanvasText->new('parent' => $root,
						'text' => 'Hello World',
						'x' => 300, 'y' => 300, 
						'width' => -1,
						'anchor' => 'center',
						'font' => 'Sans 24');
	$text_item->rotate(45, 300, 300);

	# Connect a signal handler for the rectangle item.
	$rect_item->signal_connect('button_press_event' => \&on_rect_button_press);

	$window->add($scrolled_win);
	$window->show_all;

	# Pass control to the Gtk3 main event loop
	Gtk3->main();

	# This handles button presses in item views. 
	#We simply output a message to the console
	sub on_rect_button_press {
		my ($item, $target, $event) = @_;
		print "rect item received button press event \n";
		return 1;
	}

=head1 INSTALLATION

You need to install the typelib file for GooCanvas-2.0. For example on Debian/Ubuntu it should be necessary to install the following package:

	sudo apt-get install gir1.2-goocanvas-2.0
	
On Mageia for example you have to install:

	urpmi lib64goocanvas-gir2.0
	
=head1 DESCRIPTION

GooCanvas2 is a new canvas widget for use with Gtk3 that uses the Cairo 2d library for drawing. This is a simple and basic implementation of this wonderful Canvas widget.

For more informations see  L<https://wiki.gnome.org/action/show/Projects/GooCanvas>

For instructions, how to use GooCanvas2, please study the API reference at L<https://developer.gnome.org/goocanvas/unstable/> for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem.

=head2 OBJECTS, ITEMS, MODELS

The GooCanvas2 module provides the following objects, items and models. For more details see L<https://wiki.gnome.org/action/show/Projects/GooCanvas>.

=head3 Core Objects

=over

=item * GooCanvas2::Canvas - the main canvas widget

=item * GooCanvas2::CanvasItem - the interface for canvas items

=item * GooCanvas2::CanvasItemModel - the interface for canvas item models.

=item * GooCanvas2::CanvasItemSimple - the base class for the standard canvas items.

=item * GooCanvas2::CanvasItemModelSimple - the base class for the standard canvas item models.

=item * GooCanvas2::CanvasStyle - support for cascading style properties for canvas items.

=back

=head3 Standard Canvas Items

=over

=item * GooCanvas2::CanvasGroup - a group of items.

=item * GooCanvas2::CanvasEllipse - an ellipse item.

=item * GooCanvas2::CanvasGrid - a grid item.

=item * GooCanvas2::CanvasImage - an image item.

=item * GooCanvas2::CanvasPath - a path item (a series of lines and curves).

=item * GooCanvas2::CanvasPolyline - a polyline item (a series of lines with optional arrows).

=item * GooCanvas2::CanvasRect - a rectangle item.

=item * GooCanvas2::CanvasText - a text item.

=item * GooCanvas2::CanvasWidget - an embedded widget item.

=item * GooCanvas2::CanvasTable - a table container to layout items.

=back

=head3 Standard Canvas Item Models

=over

=item * GooCanvas2::CanvasGroupModel - a model for a group of items.

=item * GooCanvas2::CanvasEllipseModel - a model for ellipse items.

=item * GooCanvas2::CanvasGridModel - a model for grid items.

=item * GooCanvas2::CanvasImageModel - a model for image items.

=item * GooCanvas2::CanvasPathModel - a model for path items (a series of lines and curves).

=item * GooCanvas2::CanvasPolylineModel - a model for polyline items (a series of lines with optional arrows).

=item * GooCanvas2::CanvasRectModel - a model for rectangle items.

=item * GooCanvas2::CanvasTextModel - a model for text items.

=item * GooCanvas2::CanvasTableModel - a model for a table container to layout items.

=back

=head2 Development status and informations

=head3 Customizations and overrides

In order to make things more Perlish, GooCanvas2 customizes the API generated by L<Glib::Object::Introspection> in a few spots:

=over
 
=item * The array ref normally returned by the following functions is flattened into a list:
 
=over
 
=item GooCanvas2::Canvas::get_items_at

=item GooCanvas2::Canvas::get_items_in_area

=item GooCanvas2::CanvasItem::get_items_at

=item GooCanvas2::CanvasItem::class_list_child_properties

=item GooCanvas2::CanvasItemModell::class_list_child_properties
 
=back

=back

=head1 SEE ALSO

=over

=item * GooCanvas Homepage at L<https://wiki.gnome.org/action/show/Projects/GooCanvas>

=item * GooCanvas2 API Reference L<https://developer.gnome.org/goocanvas/unstable/>

=item * L<Gtk3>

=item * L<Glib::Object::Introspection>

=back

=head1 AUTHOR

Maximilian Lika, E<lt>Maximilian-Lika@gmx.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
