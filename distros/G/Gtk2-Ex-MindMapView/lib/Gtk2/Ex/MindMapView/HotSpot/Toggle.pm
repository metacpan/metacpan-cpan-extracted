package Gtk2::Ex::MindMapView::HotSpot::Toggle;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Glib ':constants';

use Gnome2::Canvas;

use base 'Gtk2::Ex::MindMapView::HotSpot';


# $self->hotspot_adjust_event_handler($item);

sub hotspot_adjust_event_handler
{
    my ($self, $item) = @_;

    $self->set(enabled=>FALSE);

    my @items = $self->{item}->successors($self->{side});

    if (scalar @items > 0)
    {
	$self->set(enabled=>TRUE);
    }
}


# $self->hotspot_button_release($item, $event);

sub hotspot_button_release
{
    my ($self, $item, $event) = @_;

    my @items = $self->{item}->successors($self->{side});

    return if (scalar @items == 0);

    $self->{item}->toggle(@items);
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::HotSpot::Toggle - Manage a toggle type "hot
spot" on a view item.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::HotSpot::Toggle version 0.0.1

=head1 HEIRARCHY

=head1 SYNOPSIS

use base 'Gtk2::Ex::MindMapView::HotSpot::Toggle';

  
=head1 DESCRIPTION

The Gtk2::Ex::MindMapView::HotSpot::Toggle defines toggle type
hotspots. This kind of hot spot is used to expand and collapse
Gtk2::Ex::MindMapView::Items.

=head1 INTERFACE 

=head2 Properties

=over

No properties defined.

=back

=head2 Methods

=over

=item C<new (item=E<gt>$item)>

Instantiates a toggle type hotspot.

=item C<hotspot_adjust_event_handler>

Overrides method defined in Gtk2::Ex::MindMapView::HotSpot. This
method sets the proper state of the toggle when a "hotspot_adjust"
event occurs.


=item C<hotspot_button_release>

Overrides method defined in Gtk2::Ex::MindMapView::HotSpot. This
method actually toggles items in the mind map view.

=back

=head1 DIAGNOSTICS

=over

No Diagnostics

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
