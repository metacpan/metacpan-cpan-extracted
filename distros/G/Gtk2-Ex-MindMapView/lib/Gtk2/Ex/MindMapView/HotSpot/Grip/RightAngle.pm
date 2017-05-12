package Gtk2::Ex::MindMapView::HotSpot::Grip::RightAngle;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Gtk2::Ex::MindMapView::ArgUtils;

use Glib ':constants';

use Gnome2::Canvas;

use base 'Gtk2::Ex::MindMapView::HotSpot::Grip';

sub new
{
    my ($class, @attributes) = @_;

    my $self = $class->SUPER::new(@attributes);

    my %attributes = @attributes;

    args_valid(\%attributes, qw(item side enabled
				fill_color_gdk outline_color_gdk hotspot_color_gdk));

    arg_default($self, 'enabled', FALSE);

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

    # FIXME: Item is not defined...

    $self->{image}->set_path_def(_get_path_def($self));

    $self->{image}->request_update();
}


# my $image = $self->hotspot_get_image();

sub hotspot_get_image
{
    my $self = shift(@_);

    my $image = Gnome2::Canvas::Item->new($self->{item}, 'Gnome2::Canvas::Shape',
					  fill_color_gdk=>$self->{fill_color_gdk},
					  outline_color_gdk=>$self->{outline_color_gdk});

    $image->set_path_def(_get_path_def($self));

    return $image;
}


sub _get_path_def
{
    my $self = shift(@_);

    my $offset = 2;

    my $h = 10;

    my ($x, $y, $height, $width) = $self->{item}->get(qw(x y height width));

    my @p = ();

    if ($self->{side} eq 'left')
    {
	my $x0 = $x + $offset;

	my $y0 = $y + $height - $offset;

	@p = ($x0,$y0, $x0,$y0-$h, $x0+$h,$y0);
    }
    else # $self->{side} eq 'right'
    {
	my $x0 = $x + $width - $offset;

	my $y0 = $y + $height - $offset;

	@p = ($x0,$y0-$h, $x0-$h,$y0, $x0,$y0);
    }

    my $pathdef = Gnome2::Canvas::PathDef->new();

    $pathdef->moveto  ($p[0], $p[1]);

    $pathdef->lineto  ($p[2], $p[3]);

    $pathdef->lineto  ($p[4], $p[5]);

    $pathdef->lineto  ($p[0], $p[1]);

    $pathdef->closepath_current;

    return $pathdef;
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::HotSpot::Grip::Lentil - Manage a lentil shaped
grip "hot spot" on a view item.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::HotSpot::Grip::Lentil
version 0.0.1


=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::HotSpot::Grip::Lentil;

=head1 HEIRARCHY


  
=head1 DESCRIPTION

A LentilGrip hotspot may be used to resize a
Gtk2::Ex::MindMapView::Item. Normally, this grip will be used with an
Gtk2::Ex::MindMapView::Border:RoundedRect.

=head1 INTERFACE 

=head2 Properties

=over

=item 'item' (Gtk2::Ex::MindMapView::Item)

The item this grip is attached to.

=item 'enabled' (boolean)

If enabled, this grip is ready for action.

=item 'side' (string)

The side of the item on which to attach the grip. May be C<left> or C<right>.

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

=item C<new (item=E<gt>$item, side=E<gt>'left')>

Instantiates a hotspot. The following properties may be passed: item,
side, visible, enabled, fill_color_gdk, outline_color_gdk,
hotspot_color_gdk.

=item C<hotspot_adjust_event_handler>

Positions the grip at the lower left or right corner of the rectangle
defined by the insets. This will change for the next release.

=item C<hotspot_get_image>

Returns a right triangle shaped grip image.

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
