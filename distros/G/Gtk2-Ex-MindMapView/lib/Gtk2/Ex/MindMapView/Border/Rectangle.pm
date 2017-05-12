package Gtk2::Ex::MindMapView::Border::Rectangle;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use List::Util;

use Gnome2::Canvas;

use Gtk2::Ex::MindMapView::ArgUtils;

use base 'Gtk2::Ex::MindMapView::Border';

sub new
{
    my $class = shift(@_);

    my $self = $class->SUPER::new(@_);

    my %attributes = @_;

    args_valid(\%attributes, qw(group content x y width height width_pixels 
				padding_pixels fill_color_gdk outline_color_gdk));

    arg_default($self, "fill_color_gdk", Gtk2::Gdk::Color->parse('white'));

    arg_default($self, "outline_color_gdk", Gtk2::Gdk::Color->parse('gray'));

    $self->{border} = $self->border_get_image();

    $self->{content}->set(anchor=>'north-west');

    my ($top, $left, $bottom, $right) = $self->border_insets();

    $self->{width} = $self->{content}->get('width') + ($left + $right);

    $self->{height} = $self->{content}->get('height') + ($top + $bottom);

    return $self;
}


sub border_get_image
{
    my $self = shift(@_);

    return Gnome2::Canvas::Item->new($self->{group}, 'Gnome2::Canvas::Rect',
				     'fill-color-gdk'=>$self->{fill_color_gdk},
				     'outline-color-gdk'=>$self->{outline_color_gdk});
}


sub border_set_x
{
    my ($self, $value) = @_;

    $self->{border}->set(x1=>$value);

    $self->{border}->set(x2=>$value + $self->{width});
}


sub border_set_y
{
    my ($self, $value) = @_;

    $self->{border}->set(y1=>$value);

    $self->{border}->set(y2=>$value + $self->{height});
}


sub border_set_width
{
    my ($self, $value) = @_;

    $self->{border}->set(x2=>$self->{x} + $value);
}


sub border_set_height
{
    my ($self, $value) = @_;

    $self->{border}->set(y2=>$self->{y} + $value);
}


sub border_set_param
{
    my ($self, $name, $value) = @_;

    $self->{border}->set($name=>$value);
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::Border::Rectangle: Create a rectangular border.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::Border::Rectangle
version 0.0.1

=head1 HEIRARCHY

 Gtk2::Ex::MindMapView::Border
 +----Gtk2::Ex::MindMapView::Border::Rectangle

=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::Border::Rectangle;
  
=head1 DESCRIPTION

This module is internal to Gtk2::Ex::MindMapView. It draws a
rectangular border for a Gtk2::Ex::MindMapView::Item. This rectangle
is instantiated as part of the item creation process in
Gtk2::Ex::MindMapView::ItemFactory.

=head1 INTERFACE 

=head2 Properties

=over

=item 'content' (Gtk2::Ex::MindMapView::Content)

The content to be placed in the border.

=item 'x' (double)

The x-coordinate of the upper left corner of the border bounding box.

=item 'y' (double)

The y-coordinate of the upper left corner of the border bounding box.

=item 'width' (double)

The width of the border bounding box.

=item 'height' (double)

The height of the border bounding box.

=item 'width-pixels' (double)

The width of the border line (in pixels).

=item 'padding-pixels' (double)

The spacing between the content and the border (in pixels).

=back

=head2 Methods

=over

=item C<new(group=E<gt>$group, content=E<gt>$content, ...)>

Instantiate a rectangular border. You must provide the
Gnome2::Canvas::Group on which this border is to place itself. You
must also provide a content object, Gtk2::Ex::MindMapView::Content.

=item C<border_get_image>

This method overrides the border_get_image method defined in
Border.pm. It instantiates a Gnome2::Canvas::Rect.

=item C<border_set_x>

This method overrides the border_set_x method defined in Border.pm. It
sets the value of the border x1 coordinate, and adjusts the x2 value
so that the border retains it's width.

=item C<border_set_y>

This method overrides the border_set_y method defined in Border.pm. It
sets the value of the border y1 coordinate, and adjusts the y2 value
so that the border retains it's height.

=item C<border_set_width>

This method overrides the border_set_width method defined in
Border.pm. It sets the value of the border x2 coordinate to reflect
the new width.

=item C<border_set_height>

This method overrides the border_set_height method defined in
Border.pm. It sets the value of the border y2 coordinate to reflect
the new height.

=item C<border_set_param>

This method overrides the border_set_param method defined in
Border.pm. It sets parameters in the Gnome2::Canvas::Rect object
instantiated by this module.

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
