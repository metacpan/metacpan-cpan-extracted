package Gtk2::Ex::MindMapView::BorderFactory;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Gtk2::Ex::MindMapView::Border::Ellipse;
use Gtk2::Ex::MindMapView::Border::Rectangle;
use Gtk2::Ex::MindMapView::Border::RoundedRect;

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

    args_valid(\%attributes, qw(view fill_color_gdk outline_color_gdk));

    args_required(\%attributes, qw(view));

    args_store($self, \%attributes);

    if (!($self->{view}->isa('Gtk2::Ex::MindMapView')))
    {
	carp "Invalid Gtk2::Ex::MindMapView argument.\n";
    }

    arg_default($self, "fill_color_gdk", Gtk2::Gdk::Color->parse('white'));

    arg_default($self, "outline_color_gdk", Gtk2::Gdk::Color->parse('gray'));

    return $self;
}


sub create_border
{
    my ($self, @attributes) = @_;

    my %attributes = @attributes;

    args_valid(\%attributes, qw(type content fill_color_gdk outline_color_gdk));

    args_required(\%attributes, qw(type content));

    my $content = $attributes{content};

    if (!$content->isa('Gtk2::Ex::MindMapView::Content'))
    {
	croak "Invalid content. 'content' parameter must be a 'Gtk2::Ex::MindMapView::Content'.\n";
    }

    my $type              = $attributes{type};

    my $fill_color_gdk    = (defined $attributes{fill_color_gdk}) ?
	                     $attributes{fill_color_gdk} : $self->{fill_color_gdk};

    my $outline_color_gdk = (defined $attributes{outline_color_gdk}) ?
	                     $attributes{outline_color_gdk} : $self->{outline_color_gdk};

    if ($type eq 'Gtk2::Ex::MindMapView::Border::Ellipse')
    {
	return Gtk2::Ex::MindMapView::Border::Ellipse->new(
		       group=>$self->{view}->root,
		       content=>$content,
		       fill_color_gdk=>$fill_color_gdk,
		       outline_color_gdk=>$outline_color_gdk);
    }

    if ($type eq 'Gtk2::Ex::MindMapView::Border::RoundedRect')
    {
	return Gtk2::Ex::MindMapView::Border::RoundedRect->new(
		       group=>$self->{view}->root,
		       content=>$content,
		       fill_color_gdk=>$fill_color_gdk,
		       outline_color_gdk=>$outline_color_gdk);
    }


    if ($type eq 'Gtk2::Ex::MindMapView::Border::Rectangle')
    {
	return Gtk2::Ex::MindMapView::Border::Rectangle->new(
		       group=>$self->{view}->root,
		       content=>$content,
		       fill_color_gdk=>$fill_color_gdk,
		       outline_color_gdk=>$outline_color_gdk);
    }

    croak "Unexpected border type: $type\n";
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::BorderFactory - Maker of standard border items.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::BorderFactory version 0.0.1


=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::BorderFactory;
  
=head1 DESCRIPTION

This factory makes borders for mind map view items. The following
types of borders are currently supported:

Gtk2::Ex::MindMapView::Border::RoundedRect - A rounded rectangle
border.

Gtk2::Ex::MindMapView::Border::Rectangle - A rectangular border.

Gtk2::Ex::MindMapView::Border::Ellipse - An ellipse shaped border.


=head1 INTERFACE 

=head2 Properties

=over

=item 'view' (Gtk2::Ex::MindMapView)

The canvas on which the border will be drawn.

=item 'type' (string)

The type of border to draw (see above).

=item 'content' (Gtk2::Ex::MindMapView::Content)

The content to be placed in the border.

=item 'fill_color_gdk' (Gtk2::Gdk::Color)

The color of the interior of the border.

=item 'outline_color_gdk' (Gtk2::Gdk::Color)

The color of the border outline.

=back

=head2 Methods

=over

=item C<new (view=>$view, ...)>

Constructor for this factory. Pass in a Gtk2::Ex::MindMapView
argument.

=item C<create_border (type=>$border_type, content=>$content, ...)>

Creates a new Gtk2::Ex::MindMapView::Border border with the specified
content.

=back

=head1 DIAGNOSTICS

=over

=item C<Invalid Gtk2::Ex::MindMapView argument.>

The 'view' parameter must be a Gtk2::Ex::MindMapView.

=item C<Invalid content. 'content' parameter must be 'Gtk2::Ex::MindMapView::Content')>

The only content types that subclass 'Gtk2::Ex::MindMapView::Content' are permitted.

=item C<Unexpected border type: $type>

Only the border types listed above are currently supported.

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
