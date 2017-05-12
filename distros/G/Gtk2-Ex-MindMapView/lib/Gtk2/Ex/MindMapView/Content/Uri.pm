package Gtk2::Ex::MindMapView::Content::Uri;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use List::Util;

use Gnome2::Canvas;

use Gtk2::Ex::MindMapView::ArgUtils;
use Gtk2::Ex::MindMapView::Content;

use base 'Gtk2::Ex::MindMapView::Content::EllipsisText';

sub new
{
    my $class = shift(@_);

    my $self = $class->SUPER::new(@_);

    my %attributes = @_;

    args_valid(\%attributes, qw(group x y width height browser text uri text_color_gdk font_desc));

    args_required(\%attributes, qw(group browser text uri));

    $self->{image}->set(underline=>'single');

    $self->{image}->signal_connect(event=>\&_event_handler, $self);

    return $self;
}


# $content->set(uri=>'http://...');

sub set
{
    my $self = shift(@_);

    my %attributes = @_;

    foreach my $param_name (keys %attributes)
    {
	my $value = $attributes{$param_name};

	if ($param_name eq 'uri')
	{
	    $self->{uri} = $value;

	    next;
	}

	$self->SUPER::set($param_name=>$value);
    }
}


sub _event_handler
{
    my ($item, $event, $self) = @_;

    my $event_type = $event->type;

    if ($event_type eq 'button-press')
    {
	my $uri = $self->{uri};

	if (!($uri =~ /^(?:(\w+):\/\/|mailto:)/))
	{
	    croak "Invalid uri in Gtk2::Ex::MindMapView::Content::Url. Uri is: $uri\n";
	}

	my $protocol = $1;

	if (!grep { $_ eq $protocol } qw( file http mailto))
	{
	    croak "Unknown uri in Gtk2::Ex::MindMapView::Content::Url. Uri is: $uri\n";
	}
 
	$uri =~ s/^file:\/\/// if ($protocol eq 'file');

	my $command = $self->{browser};

	$command =~ s/\%s/$uri/;

	unless (fork)
	{ # child process
	    exec "$command";

	    exit 1;
	}
    }
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::Content::Uri - Display an clickable Uri.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::Content::Uri version
0.0.1

=head1 HEIRARCHY

 Gtk2::Ex::MindMapView::Content
 +----Gtk2::Ex::MindMapView::Content::EllipsisText  
      +----Gtk2::Ex::MindMapView::Content::Uri  

=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::Content::Uri;

  
=head1 DESCRIPTION

Displays a text on a Gnome2::Canvas and turns it into a clickable
hyperlink. If there is too much text to fit in the space allotted, the
text will be truncated and an ellipsis will be appended.

=head1 INTERFACE 

=head2 Properties

=over

=item 'browser' (string)

The command to execute that operates on the URI. The command must have
a "%s" in it that will be used to insert the URI.

=item 'font_desc' (Gtk2::Pango::FontDescription)

A description of the font to use when displaying the Uri text.
 
=item 'group' (Gnome2::Canvas::Group)

The canvas group on which this uri will be drawn.

=item 'height' (double)

The height of the uri bounding box.

=item 'text' (string)

The text to display.

=item 'text_color_gdk' (Gtk2::Gdk::Color)

The color of the text to display.

=item 'uri' (string)

The URI that is to be acted on by the browser (see above)

=item 'width' (double)

The width of the uri bounding box.

=item 'x' (double)

The x-coordinate of the top left corner of the uri bounding box.

=item 'y' (double)

The y-coordinate of the top left corner of the uri bounding box.

=back

=head2 Methods

=over

=item C<new(group=E<gt>$group, browser=E<gt>$browser, text=E<gt>$text, uri=E<gt>$uri, ...)>

Instantiate a Gtk2::Ex::MindMapView::Content::Uri content item. You
must give a Gnome2::Canvas::Group on which to place the content item,
a browser to be used to invoke the Uri, a text string that is to be
displayed, and the URI to be accessed when the user clicks on the
link.

The browser may be a web browser or a file browser, or any program on
your machine that works with the URI you have specified.

=item C<set(property=E<gt>$value>

This method is used to aet the value of a property.

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
