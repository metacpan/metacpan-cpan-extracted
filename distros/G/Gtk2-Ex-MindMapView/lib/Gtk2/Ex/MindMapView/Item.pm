package Gtk2::Ex::MindMapView::Item;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use List::Util;

use Gnome2::Canvas;

use POSIX qw(DBL_MAX);

use Glib ':constants';

use Glib::Object::Subclass
    Gnome2::Canvas::Group::,

    signals => {
	'layout'            => { flags => 'run-last' },
	'connection_adjust' => { flags => 'run-last' },
	'hotspot_adjust'    => { flags => 'run-last' },
    },

    properties => [
		   Glib::ParamSpec->scalar ('graph', 'graph',
					    'The graph that this item belongs to', G_PARAM_READWRITE),

		   Glib::ParamSpec->scalar ('column', 'column',
					    'The column this item belongs to', G_PARAM_READWRITE),

		   Glib::ParamSpec->scalar ('border', 'border',
					    'The border and containing content', G_PARAM_READWRITE),

		   Glib::ParamSpec->boolean ('visible', 'visible', 'Indicates whether the item is visible',
					     TRUE, G_PARAM_READWRITE),

		   Glib::ParamSpec->double ('x', 'x', 'Upper left X coord',
					    -(DBL_MAX), DBL_MAX, 0.0, G_PARAM_READWRITE),

		   Glib::ParamSpec->double ('y', 'y', 'Upper left y coord',
					    -(DBL_MAX), DBL_MAX, 0.0, G_PARAM_READWRITE),

		   Glib::ParamSpec->double ('height', 'height', 'Height of map item',
					    0.0, DBL_MAX, 25.0, G_PARAM_READWRITE),

		   Glib::ParamSpec->double ('width', 'width', 'Width of map item',
					    0.0, DBL_MAX, 300.0, G_PARAM_READWRITE),
		   ]
    ; 


sub INIT_INSTANCE
{
    my $self = shift(@_);

    $self->{graph}       = undef;

    $self->{column}      = undef;

    $self->{border}      = undef;

    $self->{hotspots}    = {};

    $self->{visible}     = TRUE;

    $self->{date_time}   = undef;
}


sub SET_PROPERTY
{
    my ($self, $pspec, $newval) = @_;

    my $param_name = $pspec->get_name;

#    print "Item, SET_PROPERTY: name: $param_name value: $newval\n";


    if ($param_name eq 'graph')
    {
	$self->{graph} = $newval;

	my @predecessors = $self->{graph}->predecessors($self);

	foreach my $predecessor_item (@predecessors)
	{
	    $predecessor_item->signal_emit('hotspot_adjust');
	}
    }


    if ($param_name eq 'border')
    {
	if (!$newval->isa('Gtk2::Ex::MindMapView::Border'))
	{
	    print "Item, border: $newval\n";
	    croak "Unexpected border. Must be 'Gtk2::Ex::MindMapView::Border' type.\n";
	}

	$newval->reparent($self);

	my $content = $newval->get('content');

	croak ("Cannot set border, no content defined.\n") if (!defined $content);

	$content->reparent($self);

	if (defined $self->{border})
	{
	    my ($x, $y, $width, $height) = $self->{border}->get(qw(x y width height));

	    $newval->set(x=>$x, y=>$y, width=>$width, height=>$height);

	    $self->{border}->get('content')->destroy();

	    $self->{border}->destroy();
	}

	$self->{border} = $newval;

	$self->set(width=>$newval->get('width'), height=>$newval->get('height'));
    }


    if ($param_name eq 'column')
    {
	if (!$newval->isa('Gtk2::Ex::MindMapView::Layout::Column'))
	{
	    croak "Unexpected column value.\nYou may only assign a " .
		  "'Gtk2::Ex::MindMapView::Layout::Column as a column.\n";
	}

	$self->{column} = $newval;
    }


    if ($param_name eq 'visible')
    {
	$self->{visible} = $newval;

	if ($newval)
	{
	    $self->show();
	}
	else
	{
	    $self->hide();
	}

	$self->signal_emit('connection_adjust');
    }


    if ($param_name eq 'x')
    {
	$self->{x} = $newval;

	if (defined $self->{border})
	{
	    $self->{border}->set(x=>$newval);

	    $self->signal_emit('hotspot_adjust');

	    $self->signal_emit('connection_adjust');
	}

	return;
    }

            
    if ($param_name eq 'y')
    {
	$self->{y} = $newval;

	if (defined $self->{border})
	{
	    $self->{border}->set(y=>$newval);

	    $self->signal_emit('hotspot_adjust');

	    $self->signal_emit('connection_adjust');
	}

	return;
    }            


    if ($param_name eq 'height')
    {
	$self->{height} = $newval;

	if (defined $self->{border})
	{
	    $self->{border}->set(height=>$newval);

	    $self->signal_emit('hotspot_adjust');

	    $self->signal_emit('connection_adjust');
	}

	return;
    }

    if ($param_name eq 'width')
    {
	$self->{width} = $newval;

	if (defined $self->{border})
	{
	    $self->{border}->set(width=>$newval);

	    $self->signal_emit('hotspot_adjust');

	    $self->signal_emit('connection_adjust');
	}

	return;
    }
}


# $item->add_hotspot

sub add_hotspot
{
    my ($self, $hotspot_type, $hotspot) = @_;

    $self->{hotspots}{$hotspot_type} = $hotspot;
}


# $item->get_column_no();

sub get_column_no
{
    my $self = shift(@_);

    my $column = $self->{column};

    if (!defined $column)
    {
	croak "Attempt to get column_no on undefined column.\n";
    }

    return $column->get('column_no');
}


# $item->get_connection_point('left');

sub get_connection_point
{
    my ($self, $side) = @_;

    return $self->{border}->get_connection_point($side);
}


# my ($top, $left, $bottom, $right) = $item->get_insets();

sub get_insets
{
    my $self = shift(@_);

    return $self->{border}->border_insets();
}


# my $min_height = $item->get_min_height();

sub get_min_height
{
    my $self = shift(@_);

    return 0 if (!defined $self->{border});

    return $self->{border}->get_min_height();
}


# my $min_width = $item->get_min_width();

sub get_min_width
{
    my $self = shift(@_);

    return 0 if (!defined $self->{border});

    return $self->{border}->get_min_width();
}


# $item->get_weight();

sub get_weight
{
    my $self = shift(@_);

    return ($self->get('height') * $self->get('width'));
}


# $item->is_visible();

sub is_visible
{
    my $self = shift(@_);

    return $self->get('visible');
}


# my @predecessors = $item->predecessors();

sub predecessors
{
    my $self = shift(@_);

    return () if (!defined $self->{graph});

    return $self->{graph}->predecessors($self);
}


# my @successors = $item->successors();
# my @successors = $item->successors('left');

sub successors
{
    my ($self, $side) = @_;

    return () if (!defined $self->{graph});

    my @items = $self->{graph}->successors($self);

    return () if (scalar @items == 0);

    return @items if (!defined $side);

    my $column = $self->get('column');

    return () if (!defined $column);

    my $column_no = $column->get('column_no');

    if ($side eq 'right')
    {
	return grep {$_->get_column_no() >= $column_no } @items;
    }

    # $side eq 'left'

    return grep {$_->get_column_no() <= $column_no } @items;
}


# resize: adjust the size of this item. This routine is needed because
# the simple: $self->set(x=>$x1, width=>$width, height=>$height) is
# too slow due to an excessive number of signals.

sub resize
{
    my ($self, $side, $delta_x, $delta_y) = @_;

    return if (!defined $self->{border});

    $self->raise(1);

    my ($x, $width, $height) = _resize($self, $side, $delta_x, $delta_y); 

    $self->{x} = $x;

    $self->{width} = $width;

    $self->{height} = $height;

    $self->{border}->set(x=>$x, width=>$width, height=>$height);

    $self->signal_emit('hotspot_adjust');

    $self->signal_emit('connection_adjust');
}


sub _resize
{
    my ($self, $side, $delta_x, $delta_y) = @_;

    my $min_height = $self->{border}->get_min_height();

    my $min_width = $self->{border}->get_min_width();

    my ($x, $width, $height) = $self->get(qw(x width height));

    if ($side eq 'right')
    {
	my $new_width = List::Util::max($min_width, ($width + $delta_x));

	my $new_height = List::Util::max($min_height, ($height + $delta_y));

	return ($x, $new_width, $new_height);
    }

    # $side eq 'left'

    my $new_width = List::Util::max($min_width, ($width - $delta_x));

    my $new_height = List::Util::max($min_height, ($height + $delta_y));

    my $new_x = ($new_width > $min_width) ? $x + $delta_x : $x;

    return ($new_x, $new_width, $new_height);
}


sub toggle
{
    my ($self, @items) = @_;

    my $number_visible = grep {$_->is_visible()} @items;

    foreach my $item (@items)
    {
	if ($number_visible == 0)
	{
	    my $date_time = $item->{hide_date_time};

	    $self->{graph}->traverse_DFS($item, sub { _set_visible($_[0], $date_time); });
	}
	else
	{
	    my $date_time = time();

	    $self->{graph}->traverse_DFS($item, sub { _set_invisible($_[0], $date_time); });
	}
    }

    $self->signal_emit('layout');
}


sub _set_visible
{
    my ($self, $date_time) = @_;

#    print "_set_visible, self: $self  date_time: $date_time  self date time: $self->{hide_date_time}\n";

    if ((!defined $self->{hide_date_time}) || ($self->{hide_date_time} == $date_time))
    {
	$self->set(visible=>TRUE);

	$self->{hide_date_time} = undef;
    }
}


sub _set_invisible
{
    my ($self, $date_time) = @_;

#    print "_set_invisible, self: $self  date_time: $date_time\n";

    if ($self->is_visible())
    {
	$self->set(visible=>FALSE);

	$self->{hide_date_time} = $date_time;
    }
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::Item: The border and text entered into the map.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::Item version 0.0.1

=head1 HEIRARCHY

 Glib::Object
 +----Gtk2::Object
      +----Gnome2::Canvas::Item
           +----Gnome2::Canvas::Group
                +----Gtk2::Ex::MindMapView::Item

=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::Item;


=head1 DESCRIPTION

Gtk2::Ex::MindMapView::Item items contain the border and content that
is displayed in the mind map. They may be created using
Gtk2::Ex::MindMapView::ItemFactory and may be placed into
Gtk2::Ex::MindMapView.

=head1 INTERFACE 

=head2 Properties

=over

=item C<graph> (Gtk2::Ex::MindMapView::Graph)

A reference to the Gtk2::Ex::MindMapView::Graph that contains all the
Gtk2::Ex::MindMapView::Item items.

=item C<column> (Gtk2::Ex::MindMapView::Layout::Column)

A reference to a Gtk2::Ex::MindMapView::Layout::Column that contains
this item. The column is used to place the item on the
Gtk2::Ex::MindMapView canvas.

=item C<border> (Gtk2::Ex::MindMapView::Border)

A reference to the Gtk2::Ex::MindMapView::Border that is drawn on the
canvas. The border contains a reference to the content.

=item C<visible> (boolean)

A flag indicating whether or not this item is visible.

=item C<x> (double)

The upper left x-coordinate of the item.

=item C<y> (double)

The upper left y-coordinate of the item.

=item C<height> (double)

The height of the item.

=item C<width> (double)

The width of the item.

=back

=head2 Methods

=over

=item C<INIT_INSTANCE>

This subroutine is called by Glib::Object::Subclass whenever a
Gtk2::Ex::MindMapView::Item is instantiated. It initialized the
internal variables used by this object. This subroutine should not be
called by you. Leave it alone.

=item C<SET_PROPERTY>

This subroutine is called by Glib::Object::Subclass whenever a
property value is being set.  Property values may be set using the
C<set()> method. For example, to set the width of an item to 100
pixels you would call set as follows:
C<$item-E<gt>set(width=E<gt>100);>

=item C<add_hotspot ($hotspot_type, $hotspot)>

Add a Gtk2::Ex::MindMapView::ItemHotSpot to an item. There are four
types of hotspots ('lower_left', 'lower_right', 'toggle_left',
'toggle_right').

The "toggle" hotspots correspond to the small circles you see on a
view item that allow for expansion or collapse of the mind map view.

The "lower" (or "resize") hotspots correspond to the hot spots that
allow you to resize an item.

You should add a hotspot for each hotspot type to an item. If you use
the Gtk2::Ex::MindMapView::ItemFactory to create items, this will be
done for you.

When you add a hotspot the hotspot type is used to position the
hotspot on the item. You may only add one hotspot of each type.


=item C<disable_hotspots ()>

This method is used to disable and hide the "toggle" hotspots, which
only appear on an item if they are needed.


=item C<enable_hotspots ($successor_item)>

This method enables and shows the "toggle" hotspots provided that they
are needed by the item. In item needs a toggle hotspot if it has
successor items attached to it.

=item C<get_column_no>

Return the column number that this item belongs to. The column number
is used to determine the relative position of items in the layout.

=item C<get_connection_point ($side)>

Return the x,y coordinates of the point at which a
Gtk2::Ex::MindMapView::Connection may connect to. This coordinate is
also used to detemine where to place the "toggle" hotspots.

=item C<get_insets ()>

Return the C<($top, $left, $bottom, $right)> border insets. The insets
are used by the Grips and Toggles to position themselves.

=item C<get_min_height()>

Return the minimum height of this item.

=item C<get_min_width()>

Return the minimum width of this item.

=item C<get_weight ()>

Return the "weight" of a view item. The weight is the product of the
item height and width. The weight is used by
Gtk2::Ex::MindMapView::Layout::Balanced to determine the side of the
mind map on which to place the item.

=item C<is_visible ()>

Return true if this item is visible.

=item C<predecessors ()>

Return an array of predecessor items of this item.

=item C<resize ()>

Adjust the height and width of the item, and then signal to the
toggles, grips and connections to redraw themselves.

=item C<successors ()>

Return an array of successor items of this item.

=item C<successors ($side)>

Return an array of items that are on one side of this item. The side
may be 'left' or 'right'.

=item C<toggle ()>

Either expand or collapse a subtree of the mind map. Toggle uses a
time stamp to decide how much of the tree to expand.

=back


=head1 DIAGNOSTICS

=over

=item C<Unexpected border value. You may only assign a
Gtk2::Ex::MindMapView::Border::RoundedRect as a border at this time.>

For the alpha release, only Gtk2::Ex::MindMapView::Border::RoundedRect
objects may be used.

=item C<Cannot set border, no content defined.>

You must supply a Gtk2::Ex::MindMapView::Content::EllipsisText object
as content to be placed inside the border.

=item C<Unexpected column value. You may only assign a
Gtk2::Ex::MindMapView::Layout::Column as a column.>

A Gtk2::Ex::MindMapView::Item may only belong to a
Gtk2::Ex::MindMapView::Layout::Column. Don't try to use anything else.

=item C<Unexpected hotspot type: $hotspot_type. Valid are:
'toggle_right', 'toggle_left', 'lower_left', 'lower_right'>

There are currently four possible hotspot types. These are:
'toggle_right', 'toggle_left', 'lower_left', 'lower_right'. Use these
names when referring to the hotspots created by the
Gtk2::Ex::MindMapView::ItemFactory.

=item C<Attempt to get column_no on undefined column>

An item is created, and then it is placed in a column. You have called
C<get_column_no()> on an item that has not yet been placed into a
column.

=back

=head1 DEPENDENCIES

This module depends on the following modules:

=over

=item Gnome2::Canvas::Group

=item Gtk2::Ex::MindMapView::ItemHotSpot

=item Gtk2::Ex::MindMapView::Border::RoundedRect

=item Gtk2::Ex::MindMapView::Content::EllipsisText

=back


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-gtk2-ex-mindmapview@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

James Muir  C<< <hemlock@vtlink.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, James Muir C<< <hemlock@vtlink.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
