package Gtk2::Ex::MindMapView::HotSpot::Toggle::Round;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Gtk2::Ex::MindMapView::ArgUtils;

use constant IMAGE_RADIUS=>3;

use Glib ':constants';

use Gnome2::Canvas;

use base 'Gtk2::Ex::MindMapView::HotSpot::Toggle';

sub new
{
    my ($class, @attributes) = @_;

    my $self = $class->SUPER::new(@attributes);

    my %attributes = @attributes;

    args_valid(\%attributes, qw(item side enabled radius
				fill_color_gdk outline_color_gdk hotspot_color_gdk));

    arg_default($self, 'radius', 10);

    arg_default($self, 'enabled', FALSE);

    arg_default($self, 'fill_color_gdk',    Gtk2::Gdk::Color->parse('white'));

    arg_default($self, 'outline_color_gdk', Gtk2::Gdk::Color->parse('gray'));

    arg_default($self, 'hotspot_color_gdk', Gtk2::Gdk::Color->parse('orange'));

    $self->{image}   = $self->hotspot_get_image();

    if (!$self->{enabled})
    {
	$self->{image}->hide();
    }

    return $self;
}



# $self->hotspot_adjust_event_handler($item);

sub hotspot_adjust_event_handler
{
    my ($self, $item) = @_;

    $self->SUPER::hotspot_adjust_event_handler($item);

    my ($x, $y) = $self->{item}->get_connection_point($self->{side});

    $self->{image}->set(x1=>$x - IMAGE_RADIUS, y1=>$y - IMAGE_RADIUS,
			x2=>$x + IMAGE_RADIUS, y2=>$y + IMAGE_RADIUS);
}


# my $image = $self->hotspot_get_image();

sub hotspot_get_image
{
    my $self = shift(@_);

    return Gnome2::Canvas::Item->new($self->{item}, 'Gnome2::Canvas::Ellipse',
				     fill_color_gdk=>$self->{fill_color_gdk},
				     outline_color_gdk=>$self->{outline_color_gdk});
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::ItemHotSpot - Manage a "hot spot" on a view item.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::ItemHotSpot version 0.0.1


=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::ItemHotSpot;

  
=head1 DESCRIPTION

Four Gtk2::Ex::MindMapView::ItemHotSpots are created for each
Gtk2::Ex::MindMapView::Item. The hotspots are areas on the mind map,
that when clicked, cause an action to be performed on an item. These
hotspots allow the user to expand/collapse the items in the mind map,
or to resize an item.


=head1 INTERFACE 

=head2 Properties

=over

=item C<item> (Gtk2::Ex::MindMapView::Item)

The item that this hotspot belongs to.

=item C<enabled>

If true, the toggle is receiving events and may act on them. Otherwise
it is not receiving events.

=item C<fill_color_gdk> (Gtk2::Gdk::Color)

The color with which to fill the toggle.

=item C<outline_color_gdk> (Gtk2::Gdk::Color)

The color with which to fill in the hotspot outline. Toggles normally
have a visible outline, while grips usually have the outline set to
the same color as the item fill color.

=item C<hotspot_color_gdk> (Gtk2::Gdk::Color)

The color of the hotspot once it is engaged. A hotspot becomes engaged
when the mouse is placed close to it.

=back

=head2 Methods

=over

=item C<new (item=E<gt>$item)>

Instantiates a hotspot. The following properties may be passed: item,
enabled, fill_color_gdk, outline_color_gdk, hotspot_color_gdk.

=item C<hotspot_adjust_event_handler>

Overrides method defined in Gtk2::Ex::MindMapView::HotSpot. This
method sets the proper state of the toggle when a "hotspot_adjust"
event occurs.

=item C<hotspot_get_image>

Overrides method defined in Gtk2::Ex::MindMapView::HotSpot. Returns a
circle (Gnome2::Canvas::Ellipse) image.

=back

=head1 DIAGNOSTICS

=over

None.

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
