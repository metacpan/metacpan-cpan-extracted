package Gtk2::Ex::MindMapView::HotSpot::Grip;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Glib ':constants';

use Gnome2::Canvas;

use base 'Gtk2::Ex::MindMapView::HotSpot';

sub new
{
    my $class = shift(@_);

    my $self = $class->SUPER::new(@_);

    $self->{x}       = 0;

    $self->{y}       = 0;

    $self->{x_prime} = 0;

    $self->{y_prime} = 0;

    return $self;
}


# $self->hotspot_button_press($item, $event);

sub hotspot_button_press
{
    my ($self, $item, $event) = @_;

    my @coords = $self->{item}->w2i($event->coords); # cursor position.

    $self->{x_prime} = $coords[0];

    $self->{y_prime} = $coords[1];
}


# $self->hotspot_button_release($item, $event);

sub hotspot_button_release
{
    my ($self, $item, $event) = @_;

    $self->{item}->signal_emit('layout');
}


# $self->hotspot_motion_notify($item, $event);

sub hotspot_motion_notify
{
    my ($self, $item, $event) = @_;

    my @coords = $self->{item}->w2i($event->coords); # cursor position.

    $self->{x} = $coords[0];

    $self->{y} = $coords[1];

    $self->{item}->resize($self->{side}, ($self->{x} - $self->{x_prime}), ($self->{y} - $self->{y_prime}));

    $self->{x_prime} = $self->{x};

    $self->{y_prime} = $self->{y};
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::HotSpot::Grip - Manage a grip type "hot spot"
on a view item.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::HotSpot::Grip version
0.0.1


=head1 SYNOPSIS

use base 'Gtk2::Ex::MindMapView::HotSpot::Grip';

  
=head1 DESCRIPTION

The Gtk2::Ex::MindMapView::HotSpot::Grip defined grip type hotspots. This
kind of hot spot is used to resize Gtk2::Ex::MindMapView::Items.

=head1 INTERFACE 


=head2 Properties

=over

=item 'x' (double)

The x-coordinate of the mouse location when resizing an item.

=item 'y' (double)

The y-coordinate of the mouse location when resizing an item.

=item 'x_prime' (double)

The x-coordinate of the previous mouse location when resizing an item.

=item 'y_prime' (double)

The y-coordinate of the previous mouse location when resizing an item.

=back

=head2 Methods

=over

=item C<new (item=E<gt>$item)>

Instantiates a grip type hotspot.

=item C<hotspot_button_press>

Overrides method defined in Gtk2::Ex::MindMapView::HotSpot. This
method records the position of the cursor when the mouse is first
pressed.

=item C<hotspot_button_release>

Overrides method defined in Gtk2::Ex::MindMapView::HotSpot. This
method signals that the mind map should be redrawn.

=item C<hotspot_motion_notify>

Overrides method defined in Gtk2::Ex::MindMapView::HotSpot. This
method actually resizes the Gtk2::Ex::MindMapView::Item.

=back

=head1 DIAGNOSTICS

=over

No Diagnostics.

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
