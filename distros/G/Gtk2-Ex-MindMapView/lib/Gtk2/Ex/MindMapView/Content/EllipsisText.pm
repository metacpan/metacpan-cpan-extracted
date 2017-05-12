package Gtk2::Ex::MindMapView::Content::EllipsisText;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use constant MAX_WIDTH=>300; # pixels.
use constant MAX_HEIGHT=>300; # pixels.

use List::Util;

use Gnome2::Canvas;

use Gtk2::Ex::MindMapView::ArgUtils;
use Gtk2::Ex::MindMapView::Content;

use base 'Gtk2::Ex::MindMapView::Content';

sub new
{
    my $class = shift(@_);

    my $self = $class->SUPER::new(@_);

    my %attributes = @_;

#    args_valid(\%attributes, qw(group x y width height text text_color_gdk font_desc));

    args_required(\%attributes, qw(group text));

    my $canvas = $self->{group}->canvas();

    arg_default($self, "font_desc", Gtk2::Pango::FontDescription->from_string('Ariel Normal 10'));

    arg_default($self, "text_color_gdk", Gtk2::Gdk::Color->parse('black'));

    $self->{image}      = $self->content_get_image();

    # Normally the text is made to fit the space determined by the
    # width and height properties. On instantiation, the initial size
    # of the text is determined by the text itself and the MAX_WIDTH.

    $self->{min_height} = $self->{image}->get('text-height');

    $self->{height}     = $self->{image}->get('text-height');

    $self->{width}      = $self->{image}->get('text-width');

    if ($self->{width} > MAX_WIDTH)
    {
	$self->{width} = MAX_WIDTH;

	_layout_text($self);
    }

    $self->{image}->set(clip=>1);

    $self->{image}->set(clip_height=>$self->{height});

    $self->{image}->set(clip_width=>$self->{width});

#    print "EllipsisText, new, height: $self->{height}  width: $self->{width}\n";

    return $self;
}


# my $image = $content->content_get_image();

sub content_get_image
{
    my $self = shift(@_);
    
    my $image = Gnome2::Canvas::Item->new($self->{group}, 'Gnome2::Canvas::Text',
					  text=>$self->{text},
					  font_desc=>$self->{font_desc},
					  fill_color_gdk=>$self->{text_color_gdk}
					  );
    return $image;
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

    $self->{image}->set('clip-width'=>$value);

    _layout_text($self);
}


# $self->content_set_height($value);

sub content_set_height
{
    my ($self, $value) = @_;

    $self->{image}->set('clip-height'=>$value);
    
    _layout_text($self);
}


# $self->content_set_param($param_name, $value);

sub content_set_param
{
    my ($self, $param_name, $value) = @_;

    $self->{image}->set($param_name=>$value);
}


# $content->set(x=>0, y=>10, width=>20, height=>30);

sub set
{
    my $self = shift(@_);

    my %attributes = @_;

    foreach my $param_name (keys %attributes)
    {
	my $value = $attributes{$param_name};

	if ($param_name eq 'text_color_gdk')
	{
	    $self->{text_color_gdk} = $value;

	    $self->{image}->set('fill-color-gdk'=>$value);

	    next;
	}

	if ($param_name eq 'text')
	{
	    $self->{text} = $value;

	    _layout_text($self);

	    next;
	}

	$self->SUPER::set($param_name=>$value);
    }
}


# _layout_text: Layout the text to fit into the area defined by the
# width and height properties.  Append an ellipsis if the text won't
# fit in the area. This is done because Gnome2::Canvas::Text does not
# have the hooks we need to get at it's internal layout.

sub _layout_text
{
    my $self = shift(@_);

    my $text = $self->{text};

    my $height = $self->{height};

    my $width  = $self->{width};

    $self->{image}->set(text=>$text);

    my $line_height = $self->{image}->get('text-height');

    my @words = split " ", $text;

    my $rows = List::Util::max(1, int($height / $line_height));

    my @display_lines = ();

#    print "EllipsisText, line_height: $line_height  height: $height  width: $width  rows: $rows  words: @words\n";

    for my $i (1..$rows)
    {
	my $line = "";

	my $word = shift(@words);

	last if (!defined $word);

	my $line_candidate = $word;

        $self->{image}->set(text=>$line_candidate);

	while ($self->{image}->get('text-width') <= $width)
	{
	    $line = $line_candidate;

	    $word = shift(@words);

	    last if (!defined $word);

	    $line_candidate = "$line_candidate $word";

            $self->{image}->set(text=>$line_candidate);
	}

	if ($line eq "") # Couldn't fit a word on the line.
	{
	    push @display_lines, $line_candidate;
	}
	else
	{
	    unshift @words, $word if (defined $word);

	    push @display_lines, $line;
	}
    }

    if ((scalar @words) > 0) # Couldn't fit entire text.
    {
	my $last_line = pop(@display_lines);

	if (!defined $last_line)
	{
	    push @display_lines, " ...";
	}
	else
	{
            $self->{image}->set(text=>"$last_line ...");

	    while ($self->{image}->get('text-width') > $width)
	    {
		my @words = split " ", $last_line;

		pop @words;

		last if ((scalar @words) == 0);

		$last_line = join " ", @words;

                $self->{image}->set(text=>"$last_line ...");
	    }

	    push @display_lines, "$last_line ...";
	}
    }

    $self->{image}->set(text=>(join "\n", @display_lines));
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::Content::EllipsisText - Display text with an
ellipsis.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::Content::EllipsisText
version 0.0.1

=head1 HEIRARCHY

 Gtk2::Ex::MindMapView::Content
 +----Gtk2::Ex::MindMapView::Content::EllipsisText  

=head1 SYNOPSIS

use Gtk2::Ex::MindMapView::Content::EllipsisText;

  
=head1 DESCRIPTION

Displays text on a Gnome2::Canvas. If there is too much text to fit in
the space allotted, the text will be truncated and an ellipsis will be
appended.

=head1 INTERFACE 

=head2 Properties

=over

=back

=head2 Methods

=over

=item C<new(group=E<gt>$group, text=E<gt>$text, ...)>

Instantiate a Gtk2::Ex::MindMapView::Content::EllipsisText content
item. You must give a Gnome2::Canvas::Group on which to place the
content item, and you must give a text string that is to be displayed.

=item C<content_get_image()>

Returns a Gnome2::Canvas::Text item contains the text content.

=item C<content_set_x()>

Sets the x-coordinate of the Gnome2::Canvas::Text item, and adjusts
the layout of the text.

=item C<content_set_y()>

Sets the y-coordinate of the Gnome2::Canvas::Text item, and adjusts
the layout of the text.

=item C<content_set_width()>

Sets the width of the Gnome2::Canvas::Text item, and adjusts the
layout of the text.

=item C<content_set_height()>

Sets the height of the Gnome2::Canvas::Text item, and adjusts the
layout of the text.

=item C<content_set_param()>

Sets the value of a Gnome2::Canvas::Text property.

=item C<set(property=E<gt>$value>

Sets the color of the text, or assigns new text to the
Gnome2::Canvas::Text item.

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
