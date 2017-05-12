package Gtk2::Ex::MindMapView::HotSpot;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Gtk2::Ex::MindMapView::ArgUtils;

use Glib ':constants';

use Gnome2::Canvas;

sub new
{
    my ($class, @attributes) = @_;

    my $self  = {};

    bless $self, $class;

    my %attributes = @attributes;

    args_required(\%attributes, qw(item side));

    args_store($self, \%attributes);

    if (! grep { $_ eq $self->{side} } qw(right left))
    {
	croak "Unexpected side: $self->{side}. Valid are: 'right' and 'left'\n";
    }

    if (!$self->{item}->isa('Gtk2::Ex::MindMapView::Item'))
    {
	croak "Item argument is not a Gtk2::Ex::MindMapView::Item.\n";
    }

    $self->{engaged} = FALSE;

    $self->{item}->signal_connect(hotspot_adjust=>
				  sub { $self->hotspot_adjust_event_handler($_[1]); });

    $self->{item}->signal_connect(event=>\&_event_handler, $self);

#    $self->{image}   = $self->hotspot_get_image();

    return $self;
}


# $self->hotspot_adjust_event_handler($item);

sub hotspot_adjust_event_handler
{
    my ($self, $item) = @_;

    croak "You must supply a handler for the 'hotspot_adjust' event.\n";
}


# $self->hotspot_button_press($item, $event);

sub hotspot_button_press
{
    my ($self, $item, $event) = @_;
}


# $self->hotspot_button_release($item, $event);

sub hotspot_button_release
{
    my ($self, $item, $event) = @_;
}


# my $flag = $self->hotspot_engaged(\@coords);

sub hotspot_engaged
{
    my ($self, $coords_ref) = @_;

    return FALSE if (!$self->{enabled});

    my @coords = @$coords_ref;

    my ($x1, $y1, $x2, $y2) = $self->{image}->get_bounds();

    return FALSE if (($coords[0] < $x1) || ($coords[0] > $x2));

    return FALSE if (($coords[1] < $y1) || ($coords[1] > $y2));

    return TRUE;
}


# $self->hotspot_enter_notify($item, $event);

sub hotspot_enter_notify
{
    my ($self, $item, $event) = @_;
}


# my $image = $self->hotspot_get_image();

sub hotspot_get_image
{
    my $self = shift(@_);

    croak "No hotspot image given. Every hotspot must \n" .
	  "have a Gnome2::Canvas::Item for an image.\n";
}


# $self->hotspot_leave_notify($item, $event);

sub hotspot_leave_notify
{
    my ($self, $item, $event) = @_;
}


# $self->hotspot_motion_notify($item, $event);

sub hotspot_motion_notify
{
    my ($self, $item, $event) = @_;
}


# $hotspot->set(...);

sub set
{
    my $self = shift(@_);

    my %attributes = @_;

    args_valid(\%attributes, qw(visible enabled	fill_color_gdk
				outline_color_gdk hotspot_color_gdk));

    foreach my $key (keys %attributes)
    {
	if ($key eq 'enabled')
	{
	    $self->{enabled} = $attributes{$key};

	    if ($self->{enabled})
	    {
		$self->{image}->show();
	    }
	    else
	    {
		$self->{image}->hide();
	    }

	    next;
	}

	if ($key eq 'fill_color_gdk')
	{
	    my $fill_color_gdk = $attributes{$key};

	    if (!$fill_color_gdk->isa('Gtk2::Gdk::Color'))
	    {
		croak "set(fill_color_gdk=>...) expecting a Gtk2::Gdk::Color\n";
	    }

	    $self->{fill_color_gdk} = $fill_color_gdk;

	    $self->{image}->set(fill_color_gdk=>$fill_color_gdk);

	    next;
	}

	if ($key eq 'outline_color_gdk')
	{
	    my $outline_color_gdk = $attributes{$key};

	    if (!$outline_color_gdk->isa('Gtk2::Gdk::Color'))
	    {
		croak "set(outline_color_gdk=>...) expecting a Gtk2::Gdk::Color\n";
	    }

	    $self->{outline_color_gdk} = $outline_color_gdk;

	    $self->{image}->set(outline_color_gdk=>$outline_color_gdk);

	    next;
	}

	if ($key eq 'hotspot_color_gdk')
	{
	    my $hotspot_color_gdk = $attributes{$key};

	    if (!$hotspot_color_gdk->isa('Gtk2::Gdk::Color'))
	    {
		croak "set(hotspot_color_gdk=>...) expecting a Gtk2::Gdk::Color\n";
	    }

	    $self->{hotspot_color_gdk} = $hotspot_color_gdk;

	    next;
	}
    }
}


sub _cursor_grab
{
    my ($self, $item, $time) = @_;

    $item->grab ([qw/pointer-motion-mask button-release-mask leave-notify-mask button-press-mask/],
		 Gtk2::Gdk::Cursor->new('hand2'), $time);

    $self->{image}->set(fill_color_gdk=>$self->{hotspot_color_gdk});
}


sub _cursor_release
{
    my ($self, $item, $time) = @_;

    $item->ungrab($time);

    $self->{image}->set(fill_color_gdk=>$self->{fill_color_gdk});
}


sub _event_enter_notify
{
    my ($self, $item, $event) = @_;

    my @coords = $event->coords; # world

    $self->{engaged} = $self->hotspot_engaged(\@coords);

    if ($self->{engaged})
    {
	_cursor_grab($self, $item, $event->time);

	$self->hotspot_enter_notify($item, $event);
    }
}


sub _event_button_press
{
    my ($self, $item, $event) = @_;

    if ($event->button == 1)
    {
	my @coords = $event->coords; # world

	$self->{engaged} = $self->hotspot_engaged(\@coords);

	if ($self->{engaged})
	{
	    _cursor_grab($self, $item, $event->time);

	    $self->hotspot_button_press($item, $event);
	}
    }
}


sub _event_leave_notify
{
    my ($self, $item, $event) = @_;

    if ($self->{engaged})
    {
	_cursor_release($self, $item, $event->time);

	$self->hotspot_leave_notify($item, $event);
    }
}


sub _event_button_release
{
    my ($self, $item, $event) = @_;

    _cursor_release($self, $item, $event->time);

    if ($self->{engaged})
    {
	$self->hotspot_button_release($item, $event);

	$self->{engaged} = FALSE;
    }
}


sub _event_motion_notify
{
    my ($self, $item, $event) = @_;

    if ($event->state >= 'button1-mask')
    {
	if ($self->{engaged})
	{
	    $self->hotspot_motion_notify($item, $event);
	}
    }
}


sub _event_handler
{
    my ($item, $event, $self) = @_;

    my $event_type = $event->type;

    my @coords = $event->coords;

#    print "event_type: $event_type  event_coords: @coords\n";

    if ($event_type eq 'motion-notify')
    {
	_event_motion_notify($self, $item, $event);
    }

    elsif ($event_type eq 'button-press')
    {
	_event_button_press($self, $item, $event);
    }

    elsif ($event_type eq 'button-release')
    {
	_event_button_release($self, $item, $event);
    }

    elsif ($event_type eq 'enter-notify')
    {
	_event_enter_notify($self, $item, $event);
    }

    elsif ($event_type eq 'leave-notify')
    {
	_event_leave_notify($self, $item, $event);
    }
}



1; # Magic true value required at end of module

__END__

=head1 NAME

Gtk2::Ex::MindMapView::HotSpot - Base class for grips and toggles.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::HotSpot version 0.0.1


=head1 SYNOPSIS

use base 'Gtk2::Ex::MindMapView::HotSpot';

  
=head1 DESCRIPTION

This module is internal to Gtk2::Ex::MindMapView. Four
Gtk2::Ex::MindMapView::HotSpots are created for each
Gtk2::Ex::MindMapView::Item. The hotspots are areas on a mind map item
that when clicked, cause an action to be performed on an item. These
hotspots allow the user to expand/collapse the items in the mind map,
or to resize an item.


=head1 INTERFACE 

=head2 Properties

Use the C<set> method to set these properties. Accessing them directly
will only cause you trouble.

=over

=item 'item' (Gtk2::Ex::MindMapView::Item)

Items and hotspots are rather fond of each other. This item is the one
this hotspot is attached to.

=item 'enabled' (boolean)

If enabled, this hotspot is ready for action. The type of action
depends on whether it is a grip or a toggle. Grips are used to resize
an item. Toggles are used to expand or collapse paths on the mind map
graph.

=item 'fill_color_gdk' (Gtk2::Gdk::Color)

The color with which to fill in the hotspot.

=item 'outline_color_gdk' (Gtk2::Gdk::Color)

The color with which to fill in the hotspot outline. Toggles normally
have a visible outline, while grips usually have the outline set to
the same color as the item fill color.

=item 'hotspot_color_gdk' (Gtk2::Gdk::Color)

The color of the hotspot once it is engaged. A hotspot becomes engaged
when the mouse is placed close to it.

=back

=head2 Methods

=over

=item C<new (item=E<gt>$item)>

Instantiates a hotspot that is associated with the
Gtk2::Ex::MindMapView::Item.

This module connects to the Gnome2::Canvas::Item "event" event, and
depending on the event type will call back to it's
Gtk2::Ex::MindMapView::Item.

=item C<hotspot_adjust_event_handler>

This method must be overridden. It handles the "hotspot_adjust" event.

=item C<hotspot_button_press>

This method may optionally be overridden to handle the "button-press"
event.

=item C<hotspot_button_release>

This method may optionally be overridden to handle the
"button-release" event.

=item C<hotspot_engaged>

This method may optionally be overridden to set the "engaged" flag in
a non-standard way.

=item C<hotspot_enter_notify>

This method may optionally be overridden to handle the "enter-notify"
event.

=item C<hotspot_get_image()>

This method must be overridden. It is used to instantiate a hotspot
toggle or grip.

=item C<hotspot_leave_notify>

This method may optionally be overridden to handle the "leave-notify"
event.

=item C<hotspot_motion_notify>

This method may optionally be overridden to handle the "motion-notify"
event.

=back

=head1 DIAGNOSTICS

=over

=item C<set(fill_color_gdk=E<gt>...) expecting a Gtk2::Gdk::Color>

You did not pass in a Gtk2::Gdk::Color for the color argument. Here's
an example of how to get a Gtk2::Gdk::Color:

     my $red_color = Gtk2::Gdk::Color->parse("red");

=item C<set(outline_color_gdk=E<gt>...) expecting a Gtk2::Gdk::Color>

You did not pass in a Gtk2::Gdk::Color for the color argument. Here's
an example of how to get a Gtk2::Gdk::Color:

     my $red_color = Gtk2::Gdk::Color->parse("red");

=item C<set(hotspot_color_gdk=E<gt>...) expecting a Gtk2::Gdk::Color>

You did not pass in a Gtk2::Gdk::Color for the color argument. Here's
an example of how to get a Gtk2::Gdk::Color:

     my $red_color = Gtk2::Gdk::Color->parse("red");

=item C<Unexpected side: $self->{side}. Valid are: 'right' and 'left'>

You have to specify whether this hotspot is on the left or right side 
of the item it is attached to. Choose either 'left' or 'right'.

=item C<Item argument is not a Gtk2::Ex::MindMapView::Item.>

Hotspots want to attach themselves to a
Gtk2::Ex::MindMapView::Item. Don't bother trying to hook them up to
something else. They just won't like it and will complain about it.

=item C<You must supply a handler for the 'hotspot_adjust' event.>

Every hotspot must be subclassed, and the "hotspot_adjust" event
handler method should be overridden. See
Gtk2::Ex::MindMapView::HotSpot::Grip.pm or
Gtk2::Ex::MindMapView::HotSpot::Toggle.pm for an example of how to do
this.

=item C<No hotspot image given. Every hotspot must have a Gnome2::Canvas::Item
for an image.>

Every hotspot should have a visible image associated with it. You must
override the hotspot_get_image method to supply the image.

=back


=head1 DEPENDENCIES

None.


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
