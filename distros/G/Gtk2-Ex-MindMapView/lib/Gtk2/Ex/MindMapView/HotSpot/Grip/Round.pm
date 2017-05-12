package Gtk2::Ex::MindMapView::HotSpot::Grip::Round;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Gtk2::Ex::MindMapView::ArgUtils;

use constant IMAGE_RADIUS=>3;

use Glib ':constants';

use Gnome2::Canvas;

use base 'Gtk2::Ex::MindMapView::HotSpot::Grip';

sub new
{
    my ($class, @attributes) = @_;

    my $self = $class->SUPER::new(@attributes);

    my %attributes = @attributes;

    args_valid(\%attributes, qw(item side enabled radius
				fill_color_gdk outline_color_gdk hotspot_color_gdk));

    arg_default($self, 'enabled', FALSE);

    arg_default($self, 'radius', 10);

    arg_default($self, 'fill_color_gdk',    Gtk2::Gdk::Color->parse('white'));

    arg_default($self, 'outline_color_gdk', Gtk2::Gdk::Color->parse('gray'));

    arg_default($self, 'hotspot_color_gdk', Gtk2::Gdk::Color->parse('orange'));

    $self->{image}   = $self->hotspot_get_image();

    return $self;
}


# $self->hotspot_adjust_event_handler($item);

sub hotspot_adjust_event_handler
{
    my ($self, $item) = @_;

    my $offset = 1;

    my $r = $self->{radius};

    my ($x, $y, $width, $height) = $self->{item}->get(qw(x y width height));

    if ($self->{side} eq 'left')
    {
	_set_point($self, $x + ($r / 2) + $offset, $y + $height - ($r / 2) - $offset);
    }
    else # $self->{side} eq 'right'
    {
	_set_point($self, $x + $width - ($r / 2) - $offset, $y + $height - ($r / 2) - $offset);
    }
}


# my $image = $self->hotspot_get_image();

sub hotspot_get_image
{
    my $self = shift(@_);

    return Gnome2::Canvas::Item->new($self->{item}, 'Gnome2::Canvas::Ellipse',
				     fill_color_gdk=>$self->{fill_color_gdk},
				     outline_color_gdk=>$self->{outline_color_gdk});
}


sub _set_point
{
    my ($self, $x, $y) = @_;

    $self->{image}->set(x1=>$x - IMAGE_RADIUS, y1=>$y - IMAGE_RADIUS,
			x2=>$x + IMAGE_RADIUS, y2=>$y + IMAGE_RADIUS);
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::HotSpot::Grip::Round - Manage a round grip type
"hot spot" on a view item.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::HotSpot::Grip::Round
version 0.0.1


=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::HotSpot::Grip::Round;

  
=head1 DESCRIPTION

The Gtk2::Ex::MindMapView::HotSpot::Grip::Round is a round grip that
may be used to resize a Gtk2::Ex::MindMapView::Item.

=head1 INTERFACE 

=head2 Properties

=over

=item 'item' (Gtk2::Ex::MindMapView::Item)

The item this grip is attached to.

=item 'enabled' (boolean)

If enabled, this grip is ready for action.

=item 'side' (string)

The side on which to attach the grip. May be C<left> or C<right>.

=item 'fill_color_gdk' (Gtk2::Gdk::Color)

The color with which to fill in the hotspot.

=item 'outline_color_gdk' (Gtk2::Gdk::Color)

The color with which to fill in the hotspot outline. Grips usually
have the outline set to the same color as the item fill color.

=item 'hotspot_color_gdk' (Gtk2::Gdk::Color)

The color of the hotspot once it is engaged. A hotspot becomes engaged
when the mouse is placed close to it.

=back

=head2 Methods

=over

=item C<new (item=E<gt>$item)>

Instantiates a Gtk2::Ex::MindMapView::HotSpot::Grip::Round hotspot.

=item C<hotspot_adjust_event_handler>

Positions the grip at the lower left or right corner of the rectangle
defined by the insets. This will change for the next release.

=item C<hotspot_get_image>

Returns a circle (Gnome2::Canvas::Ellipse) as grip image.

=back

=head1 DIAGNOSTICS

=over

No diagnostics.

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
