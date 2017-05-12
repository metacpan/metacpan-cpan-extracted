package Gtk2::Ex::MindMapView::Content::Picture;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use List::Util;

use Gnome2::Canvas;

use constant MAX_HEIGHT => 700; # Pixels
use constant MAX_WIDTH  => 700; # Pixels

use Gtk2::Ex::MindMapView::ArgUtils;
use Gtk2::Ex::MindMapView::Content;

use base 'Gtk2::Ex::MindMapView::Content';

sub new
{
    my $class = shift(@_);

    my $self = $class->SUPER::new(@_);

    my %attributes = @_;

    args_valid(\%attributes, qw(group pixbuf x y width height));

    args_required(\%attributes, qw(group pixbuf));

    if (!$self->{pixbuf}->isa('Gtk2::Gdk::Pixbuf'))
    {
	croak "The pixbuf parameter must be a 'Gtk2::Gdk::Pixbuf'.\n";
    }

    my $width = $self->{pixbuf}->get_width();

    if ($width > MAX_WIDTH)
    {
	croak "The picture is too wide to be displayed.\n";
    }

    my $height = $self->{pixbuf}->get_height();

    if ($height > MAX_HEIGHT)
    {
	croak "The picture is too tall to be displayed.\n";
    }

    $self->{width}      = $width;

    $self->{height}     = $height;

    $self->{min_width}  = $width;

    $self->{min_height} = $height;

    $self->{image}      = $self->content_get_image();

    return $self;
}


# my $image = $content->content_get_image();

sub content_get_image
{
    my $self = shift(@_);
    
    return Gnome2::Canvas::Item->new($self->{group},
	      'Gnome2::Canvas::Pixbuf', pixbuf=>$self->{pixbuf});
}


# $self->content_set_x($value);

sub content_set_x
{
    my ($self, $value) = @_;

    $self->{image}->set(x=>$value);
}


# $self->content_set_y($value);

sub content_set_y
{
    my ($self, $value) = @_;

    $self->{image}->set(y=>$value);
}


# $self->content_set_width($value);

sub content_set_width
{
    my ($self, $value) = @_;

#    $self->{image}->set('width-set'=>$value);
}


# $self->content_set_height($value);

sub content_set_height
{
    my ($self, $value) = @_;

#    $self->{image}->set('height-set'=>$value);
}


# $self->content_set_param($param_name, $value);

sub content_set_param
{
    my ($self, $param_name, $value) = @_;

#    $self->{image}->set($param_name=>$value);
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::Content::Picture - Display a picture.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::Content::Picture
version 0.0.1

=head1 HEIRARCHY

 Gtk2::Ex::MindMapView::Content
 +----Gtk2::Ex::MindMapView::Content::Picture

=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::Content::Picture

  
=head1 DESCRIPTION

Displays a picture on a Gnome2::Canvas. The image is not scaled or
clipped. The caller must prepare the image before it is passed to this
module.

=head1 INTERFACE 

=head2 Properties

=over

=item 'group' (Gnome2::Canvas::Group)

The canvas group on which this picture will be drawn.

=item 'pixbuf' (Gtk2::Gdk::Pixbuf)

The pixbuf that will be drawn on the canvas group.

=item 'x' (double)

The x-coordinate of the top left corner of the picture.

=item 'y' (double)

The y-coordinate of the top left corner of the picture.

=item 'width' (double)

The width of the picture.

=item 'height' (double)

The height of the picture.

=back

=head2 Methods

=over

=item C<new(group=E<gt>$group, pixbuf=E<gt>$pixbuf, ...)>

Instantiate a Gtk2::Ex::MindMapView::Content::Picture content
item. You must give a Gnome2::Canvas::Group on which to place the
content item, and you must give a Gtk2::Gdk::Pixbuf that contains the
picture to be displayed.

=item C<content_get_image()>

Overrides the method in Gtk2::Ex::MindMapView::Content. Returns the
Gnome2::Canvas::Pixbuf that is displayed on the canvas.

=item C<content_set_x()>

Overrides the method in Gtk2::Ex::MindMapView::Content. Sets the
x-coordinate of the top left corner of the picture.

=item C<content_set_y()>

Overrides the method in Gtk2::Ex::MindMapView::Content. Sets the
y-coordinate of the top left corner of the picture.

=item C<content_set_width()>

Overrides the method in Gtk2::Ex::MindMapView::Content. Sets the width
of the picture.

=item C<content_set_height()>

Overrides the method in Gtk2::Ex::MindMapView::Content. Sets the
height of the picture.

=item C<content_set_param()>

Overrides the method in Gtk2::Ex::MindMapView::Content. Passes a
parameter to the Gnome2::Canvas::Pixbuf.

=back

=head1 DIAGNOSTICS

None.

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
