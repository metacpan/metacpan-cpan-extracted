package Gtk2::Ex::MindMapView::HotSpot::GripFactory;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Gtk2::Ex::MindMapView::HotSpot::Grip::Round;
use Gtk2::Ex::MindMapView::HotSpot::Grip::Lentil;
use Gtk2::Ex::MindMapView::HotSpot::Grip::RightAngle;
use Gtk2::Ex::MindMapView::HotSpot::Grip::EllipseRound;

use Gtk2::Ex::MindMapView::ArgUtils;

use List::Util;

use Glib ':constants';

sub new
{
    my $class = shift(@_);

    my @attributes = @_;

    my $self = {};

    bless $self, $class;

    my %attributes = @attributes;

    args_valid(\%attributes, qw(fill_color_gdk hotspot_color_gdk));

    args_store($self, \%attributes);

    arg_default($self, "fill_color_gdk", Gtk2::Gdk::Color->parse('white'));

    arg_default($self, "hotspot_color_gdk", Gtk2::Gdk::Color->parse('orange'));

    return $self;
}


sub create_grip
{
    my ($self, @attributes) = @_;

    my %attributes = @attributes;

    args_valid(\%attributes, qw(item border side fill_color_gdk hotspot_color_gdk));

    args_required(\%attributes, qw(item border side));

    my $item = $attributes{item};

    if (!$item->isa('Gtk2::Ex::MindMapView::Item'))
    {
	croak "Invalid item. Item must be a 'Gtk2::Ex::MindMapView::Item'.\n";
    }

    my $side = $attributes{side};

    if (!grep { $_ eq $side } qw(right left))
    {
	croak "Invalid side. Must be 'right' or 'left'.\n";
    }

    my $border = $attributes{border};

    my $fill_color_gdk = (defined $attributes{fill_color_gdk}) ?
	                     $attributes{fill_color_gdk} : $self->{fill_color_gdk};

    my $hotspot_color_gdk = (defined $attributes{hotspot_color_gdk}) ?
	                     $attributes{hotspot_color_gdk} : $self->{hotspot_color_gdk};

    my $color_gdk = ($side eq 'right') ? $hotspot_color_gdk : $fill_color_gdk;

    if ($border->isa('Gtk2::Ex::MindMapView::Border::Ellipse'))
    {
	return Gtk2::Ex::MindMapView::HotSpot::Grip::EllipseRound->new(
		       item=>$item, side=>$side,
		       hotspot_color_gdk=>$hotspot_color_gdk,
		       outline_color_gdk=>$fill_color_gdk,
		       fill_color_gdk=>$color_gdk,
		       enabled=>TRUE);
    }

    if ($border->isa('Gtk2::Ex::MindMapView::Border::RoundedRect'))
    {
	return Gtk2::Ex::MindMapView::HotSpot::Grip::Lentil->new(
		       item=>$item, side=>$side,
		       hotspot_color_gdk=>$hotspot_color_gdk,
		       outline_color_gdk=>$fill_color_gdk,
		       fill_color_gdk=>$color_gdk,
		       enabled=>TRUE);
    }


    if ($border->isa('Gtk2::Ex::MindMapView::Border::Rectangle'))
    {
	return Gtk2::Ex::MindMapView::HotSpot::Grip::RightAngle->new(
		       item=>$item, side=>$side,
		       hotspot_color_gdk=>$hotspot_color_gdk,
		       outline_color_gdk=>$fill_color_gdk,
		       fill_color_gdk=>$color_gdk,
		       enabled=>TRUE);
    }

    croak "Cannot make grip. Unexpected border: $border\n";
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::HotSpot::GripFactory - Maker of standard grips.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::HotSpot::GripFactory
version 0.0.1


=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::HotSpot::GripFactory;
  
=head1 DESCRIPTION

This factory makes grips that are used to resize Gtk2::Ex::MindMapView::Items.

The following types of grips are supported:

Gtk2::Ex::MindMapView::HotSpot::Grip::Round - A circular grip.

Gtk2::Ex::MindMapView::HotSpot::Grip::Lentil - A lentil shaped grip.

Gtk2::Ex::MindMapView::HotSpot::Grip::RightAngle - A right triangle shaped grip.

Gtk2::Ex::MindMapView::HotSpot::Grip::EllipseRound - A special round grip for ellipses.

This factory is used by the Gtk2::Ex::MindMapView::ItemFactory.

=head1 INTERFACE 

=head2 Properties

=over

=item 'item' (Gtk2::Ex::MindMapView::Item)

The item to attach the grip to.

=item 'border' (Gtk2::Ex::MindMapView::Border)

The border that is used to determine the type of grip to create.

=item 'side' (string)

The side of the item to attach to. May be: C<left> or C<right>.

=item 'fill_color_gdk' (Gtk2::Gdk::Color)

The color of the grip.
 
=item 'hotspot_color_gdk' (Gtk2::Gdk::Color)

The color of the grip when it is engaged.

=back

=head2 Methods

=over

=item C<new ( ...)>

Constructor for the grip factory.

=item C<create_grip (item=E<gt>$item, border=E<gt>$border, side=E<gt>$side, ...)>

Creates a new Gtk2::Ex::MindMapView::HotSpot::Grip given the
Gtk2::Ex::MindMapView::Item that the grip will attach to. The
Gtk2::Ex::MindMapView::Border is used to determine what grip to return
to the caller. The side may be C<left> or C<right>.

=back

=head1 DIAGNOSTICS

=over

=item C<Invalid item. Item must be a 'Gtk2::Ex::MindMapView::Item'>

You must pass in a Gtk2::Ex::MindMapView::Item argument.

=item C<Invalid side. Must be 'right' or 'left'>

You must set the side to be either: C<left> or C<right>.

=item C<Unexpected border: $border>

You must give one of the known border types at this time.

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
