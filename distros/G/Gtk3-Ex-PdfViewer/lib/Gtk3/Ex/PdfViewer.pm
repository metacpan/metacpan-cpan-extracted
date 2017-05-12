=pod

=head1 NAME

Gtk3::Ex::PdfViewer - Complete PDF viewer widget for GTK3 applications

=head1 SYNOPSIS

  use Gtk3::Ex::PdfViewer;
  my $viewer = Gtk3::Ex::PdfViewer->new();
  my $window = Gtk3::Window->new();
  $window->add( $viewer );
  $viewer->show_file( '/home/robert/test.pdf' );

=head1 DESCRIPTION

Gtk3::Ex::PdfViewer creates a scrolled window that displays a PDF file. It
provides controls for moving forward and backward through the document. Embed
the viewer inside of L<Gtk3::Box> to integrate it with your application.

Gtk3::Ex::PdfViewer is object oriented. Each instance creates an entirely
independent viewer. Your application can create as many viewer widegets as
it needs.

=cut

package Gtk3::Ex::PdfViewer;

use 5.14.0;
use warnings;

use File::Slurp;
use Gtk3;
use List::AllUtils qw/max min/;
use Moose;
use Poppler;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head3 widget

This attribute returns the viewer's Gtk3::Box. Use C<widget> to place the
viewer inside of its parent. Gtk3::Ex::PdfViewer creates all of the child
widgets and connects the signals to flip through the document.

=cut

has 'widget' => (
	builder => '_build_widget',
	is      => 'ro',
	isa     => 'Gtk3::Box',
);


sub _build_widget {
	my ($self) = @_;

	# Page switcher area...
	my $pager = Gtk3::Box->new( 'horizontal', 5 );
	$pager->set_halign( 'center' );
	$pager->set_homogeneous( 1 );
	$pager->pack_start( $self->previous, 0, 1, 0 );
	$pager->pack_start( $self->page_of, 0, 1, 0 );
	$pager->pack_start( $self->next, 0, 1, 0 );

	# PDF document viewing area...
	my $scrolled = Gtk3::ScrolledWindow->new( undef, undef );
	$scrolled->add_with_viewport( $self->drawing_area );

	# The main viewer widget...
	my $box = Gtk3::Box->new( 'vertical', 5 );
	$box->set_halign( 'fill' );
	$box->set_valign( 'fill' );
	$box->pack_start( $scrolled, 1, 1, 0 );
	$box->pack_start( $pager, 0, 1, 0 );

	$box->show_all;
	return $box;
}


=head3 show_blob( $data )

This method displays the binary representation of a PDF document. You can get
a binary representation from a PDF generator or the BLOB field of a database.
C<show_blob> takes the PDF data as its only argument.

=cut

sub show_blob {
	my ($self, $data) = @_;

	if (defined $data) {
		$self->_set_pdf( Poppler::Document->new_from_data(
			$data, length( $data )
		) );

		my $pages = $self->pdf->get_n_pages;
		$self->_set_pages( $pages );
		$self->page( 1 );	# This draws the first page too.
	} else { $self->clear; }
}


=head3 show_file( $path )

This method displays the PDF document from a file. It takes a path to the PDF
file as its only argument.

=cut

sub show_file {
	my ($self, $path) = @_;
	$self->_debug( "show_file $path" );

	# Force scalar context so that it returns the blob.
	my $data = read_file( $path, {binmode => ':raw'} );
	$self->show_blob( $data );
}


=head3 clear()

Blank out the PDF area. This is for when there is no PDF to display. It merely
shows an empty, grey box.

=cut

sub clear {
	my ($self) = @_;

	$self->_set_pdf( undef );
	$self->_set_pages( 0 );
	$self->page( 0 );	# Also redraws the blank area.
}


=head3 page

C<page> tells you the currently displayed page number. Page numbers start at 1.
A page number of zero means that the viewer is empty (no PDF document).

If you pass in a page number, the viewer jumps to that page in the document.

=cut

has '_page' => (
	default => 0,
	is      => 'rw',
	isa     => 'Int',
);

sub page {
	my $self  = shift;
	my $pages = $self->pages;

	if ($pages < 1) {
		$self->next->set_sensitive( 0 );
		$self->previous->set_sensitive( 0 );

		$self->_page( 0 );
		$self->page_of->set_label( "0 / 0" );

		$self->drawing_area->queue_draw;
	} elsif (scalar( @_ ) == 1) {
		my $value = max( 1, min( shift, $pages ) );

		$self->next->set_sensitive( $value == $pages ? 0 : 1 );
		$self->previous->set_sensitive( $value == 1 ? 0 : 1 );

		$self->_page( $value );
		$self->page_of->set_label( "$value / $pages" );

		$self->drawing_area->queue_draw;
	} elsif (scalar( @_ ) > 1) {
		die 'Too many arguments - "page" only accepts one page number at a time';
	}

	return $self->_page;
}


=head3 pages

C<pages> tells you the total number of pages in the PDF document. It is set
by C<show_file> or C<show_blob>.

=cut

has 'pages' => (
	default => 0,
	is      => 'ro',
	isa     => 'Int',
	writer  => '_set_pages',
);


=head3 pdf

This attribute is the Poppler object for manipulating the PDF document. It is
set by C<show_file> or C<show_blob>.

=cut

# WARNING: Don't use "handles" to replace the "pages" attribute. I want
# "pages" to return zero not "undef" if there is no PDF.

has 'pdf' => (
	is     => 'ro',
	isa    => 'Maybe[Poppler::Document]',
	writer => '_set_pdf',
);


=head2 Default signal handlers

Gtk3::Ex::PdfViewer assigns default signal handlers to the widgets that it
creates. These are not methods of the object. They are GTK callback functions.
You can connect them to your own widgets - like menu options - to control the
PDF viewer.

=head3 on_drawingarea_draw

This method responds to the I<draw> event of the L</drawing_area> widget. It
displays a single page from the PDF in the scrolling area.

=cut

sub on_drawingarea_draw {
	my ($widget, $context, $self) = @_;
	$self->_debug( '_draw_page...' );

	# The default is an empty grey background.
	$context->set_source_rgb( 0.72, 0.72, 0.72 );	# Grey
	$context->fill;

	# Change the default if we have an actual page.
	my $pdf = $self->pdf;
	if (defined $pdf) {
		my $page = $pdf->get_page( $self->page() - 1 );
		if (defined $page) {
			my $height = $page->get_size->get_height;
			my $width  = $page->get_size->get_width;
			$self->_debug( "Height: $height", "Width: $width" );

			$widget->set_size_request( $width, $height );
			$context->rectangle( 0, 0, $width, $height );
			$context->set_source_rgb( 1, 1, 1 );	# White
			$context->fill;
			$page->render_to_cairo( $context );
		}
	}

	# Display the contents.
	$context->show_page;
	$self->_debug( '..._draw_page' );
}


=head3 on_button_next_click

This routine responds to a click of the right arrow. It moves forward one page
in the document.

=cut

sub on_button_next_click {
	my ($button, $self) = @_;
	$self->page( $self->page() + 1 );
}


=head3 on_button_previous_click

This routine responds to a click of the left arrow. It moves back one page in
the document.

=cut

sub on_button_previous_click {
	my ($button, $self) = @_;
	$self->page( $self->page() - 1 );
}


=head2 Widgets

These attributes reference the individual widgets of the viewer. You can use
these to customize their behavior.

=head3 drawing_area

This Gtk3::DrawingArea displays the image of the PDF. By default, it calls
L</on_drawingarea_draw> to handle the I<draw> event. L</on_drawingarea_draw>
does the actual document display.

=cut

has 'drawing_area' => (
	builder => '_build_drawing_area',
	is      => 'ro',
	isa     => 'Gtk3::DrawingArea',
);

sub _build_drawing_area {
	my $widget = Gtk3::DrawingArea->new();
	$widget->signal_connect( 'draw' => \&on_drawingarea_draw, shift );
	return $widget;
}


=head3 next

This button moves to the next page in the document. It calls
L</on_button_next_click>.

=cut

has 'next' => (
	builder => '_build_next',
	is      => 'ro',
	isa     => 'Gtk3::Button',
);

sub _build_next {
	my $widget = Gtk3::Button->new_from_stock( 'gtk-go-forward' );
	$widget->set_sensitive( 0 );
	$widget->signal_connect( 'clicked' => \&on_button_next_click, shift );
	return $widget;
}


=head3 page_of

This label displays the current page. It sits between the next and previous
buttons. The text is changed whenever the viewer shows a new page.

=cut

has 'page_of' => (
	builder => '_build_page_of',
	is      => 'ro',
	isa     => 'Gtk3::Label',
);

sub _build_page_of { Gtk3::Label->new( '0 / 0' ); }


=head3 previous

This button moves to the prvious page in the document. It calls
L</on_button_previous_click>.

=cut

has 'previous' => (
	builder => '_build_previous',
	is      => 'ro',
	isa     => 'Gtk3::Button',
);

sub _build_previous {
	my $widget = Gtk3::Button->new_from_stock( 'gtk-go-back' );
	$widget->set_sensitive( 0 );
	$widget->signal_connect( 'clicked' => \&on_button_previous_click, shift );
	return $widget;
}


=head2 Internal Methods & Attributes

The B<Gtk3::PdfViewer> object uses these methods internally. You should never
use them in your own code. They will change without notice. I documented them
for the maintainers.

=head3 debug

This boolean flag displays status messages so that you can trace down problems.
A B<true> value displays the messages. B<false> hides them. The default value
is B<false>.

=cut

has 'debug' => (
	default => 0,
	is      => 'rw',
	isa     => 'Bool',
);

sub _debug {
	my $self = shift;
	say STDERR join( "\n", @_ ) if $self->debug;
}


=head1 BUGS/CAVEATS/etc

This is a very simple viewer. It does handle zoom, printing, or any other
amentities.

The widget displays PDFs one page at a time. You must use the buttons to
change pages. The scroll bars do not cross pages.

=head1 AUTHOR

Robert Wohlfarth (rbwohlfarth@gmail.com)

=head1 SEE ALSO

L<https://developer.gnome.org/gtk3/stable/|GTK3 Reference Guide>

L<https://developer.gnome.org/poppler/unstable/|Poppler PDF API>

=head1 LICENSE

Copyright (c) 2013  Robert Wohlfarth

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. This software comes with NO WARRANTY of any
kind.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
