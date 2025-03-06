package Khonsu;
use strict;
use warnings;
our $VERSION = '0.13';
use PDF::API2;

use base 'Khonsu::File';

sub new {
	my ($pkg, $name, %args) = @_;
	return $pkg->SUPER::new(
		file_name => $name,
		pages => [],
		page_size => 'A4',
		page_args => {},
		pdf => PDF::API2->new( -file => sprintf("%s.pdf", $name) ),
		%args
	);
}

sub open { ... }

1;

=head1 NAME

Khonsu - PDF Generation!

=head1 VERSION

Version 0.13

=cut

=head1 SYNOPSIS

	my @words = ('Aker', 'Anubis', 'Hapi', 'Khepri', 'Maahes', 'Thoth', 'Bastet', 'Hatmehit', 'Tefnut', 'Menhit', 'Imentet');

	my $generate_text = sub {
		my $length = shift;
		return join " ", map { $words[int(rand(scalar @words))] } 1 .. $length;
	};

	use Khonsu;

	Khonsu->load_plugin(qw/+Syntax/);

	my $padding = 20;
	my $page_padding = $padding * 2;
	my $khonsu = Khonsu->new(
		'Ra',
		configure => {
			page_header => {
				padding => $padding,
				show_page_num => 'right',
				page_num_text => 'page {num}',
				h => $padding,
				cb => sub {
					my ($self, $file, %atts) = @_;
					$self->add(
						$file,
						text => 'Ra',
						align => 'center',
						%attrs,
					);
				}
			},
			page_footer => {
				padding => $padding,
				show_page_num => 'left',
				page_num_text => 'page {num}',
				h => $padding,
				cb => sub {
					my ($self, $file, %atts) = @_;
					$self->add(
						$file,
						text => 'Ra',
						align => 'center',
						%attrs,
					);
				}
			},
			toc => {
				title => 'Table of contents',
				title_font_args => {
					size => 50,
				},
				title_padding => 10,
				font_args => {
					size => 20,
				},
				padding => 5,
			},
			h1 => {
				font => { colour => '#0EE' }
			}
		}
	);

	$khonsu->add_image(
		image => 't/test.png',
		x => $padding,
		y => $padding,
		w => $khonsu->page->w - $page_padding,
		h => $khonsu->page->h - $page_padding,
	)->add_page;

	$khonsu->add_toc();

	$khonsu->set_columns(2);

	for (0 .. 100) {
		$khonsu->add_h1(
			text => $generate_text->(3),
			toc => 1,
		)->add_text(
			text => $generate_text->(2000),
			indent => 4,
			font => {
				colour => '#fff'
			},
		);
	}

	$khonsu->set_columns(1);

	$khonsu->add_h1(
		text => 'A simple form',
		toc => 1
	);

	$khonsu->add_input(
		text => 'Name:'
	);

	$khonsu->add_select(
		text => 'Colour:',
		options => [qw/red yellow green/]
	);

	$khonsu->add_checkbox(
		text => 'Checkbox:'
	);

	$khonsu->add_syntax(
		text => $perl_string
	);

	$khonsu->save();

=head1 ATTRIBUTES

=cut

=head2 file_name

Get and set the PDF file name.

	$khonsu->file_name();
	$khonsu->file_name('PDFName');

=cut

=head2 pdf

Get and set the PDF::API2 object.

	$khonsu->pdf();
	$khonsu->pdf(PDF::API2->new( -file => sprintf("%s.pdf", $khonsu->file_name()) ));

=cut

=head2 pages

Get and set the pdf pages Objects.

	$khonsu->pages();
	$khonsu->pages([Khonsu::Page->new(
                page_size =>'A4',
                num => 1,
        )->add($khonsu)];

=cut

=head2 page

Get and set the current page.

	$khonsu->page();
	$khonsu->page($khonsu->pages()->[0]);

=head2 page_args

Get and set the default page_args used when creating/adding a new page.

	$khonsu->page_args();
	$khonsu->page_args({ background => '#fff' });

=cut

=head2 page_offset

Get and set the page_offset used while generating the table of contents.

	$khonsu->page_offset();
	$khonsu->page_offset(5);

=cut

=head2 onsave_cbs

Get and set onsave callbacks.

	$khonsu->onsave_cbs();
	$khonsu->onsave_cbs([
		'text',
		'add',
		{
			text => 'On save callback',
		}
	]);

=cut

=head2 line

Get and set the Khonsu::Shape::Line object.

	$khonsu->line();
	$khonsu->line(Khonsu::Shape::Line->new(%line));

=cut

=head2 box

Get and set the Khonsu::Shape::Box object.

	$khonsu->box();
	$khonsu->box(Khonsu::Shape::Box->new(%box));

=cut

=head2 circle

Get and set the Khonsu::Shape::Circle object.

	$khonsu->circle();
	$khonsu->circle(Khonsu::Shape::Circle->new(%circle));

=cut

=head2 pie

Get and set the Khonsu::Shape::Pie object.

	$khonsu->pie();
	$khonsu->pie(Khonsu::Shape::Pie->new(%pie));

=cut

=head2 ellipse

Get and set the Khonsu::Shape::Ellipse object.

	$khonsu->ellipse();
	$khonsu->ellipse(Khonsu::Shape::Ellipse->new(%ellipse));

=cut

=head2 font

Get and set the Khonsu::Font object.

	$khonsu->font();
	$khonsu->font(Khonsu::Font->new(%font));

=cut

=head2 text

Get and set the Khonsu::Text object.

	$khonsu->text();
	$khonsu->text(Khonsu::Text->new(%text));

=cut

=head2 h1

Get and set the Khonsu::Text::H1 object.

	$khonsu->h1();
	$khonsu->h1(Khonsu::Text::H1->new(%h1));

=cut

=head2 h2

Get and set the Khonsu::Text::H2 object.

	$khonsu->h2();
	$khonsu->h2(Khonsu::Text::H2->new(%h2));
=cut

=head2 h3

Get and set the Khonsu::Text::H3 object.

	$khonsu->h3();
	$khonsu->h3(Khonsu::Text::H3->new(%h3));

=cut

=head2 h4

Get and set the Khonsu::Text::H4 object.

	$khonsu->h4();
	$khonsu->h4(Khonsu::Text::H4->new(%h4));

=cut

=head2 h5

Get and set the Khonsu::Text::H5 object.

	$khonsu->h5();
	$khonsu->h5(Khonsu::Text::H5->new(%h5));

=cut

=head2 h6

Get and set the Khonsu::Text::H6 object.

	$khonsu->h6();
	$khonsu->h6(Khonsu::Text::H6->new(%h6));
=cut

=head2 image

Get and set the Khonsu::Image object.

	$khonsu->image();
	$khonsu->image(Khonsu::Image->new(%image));

=cut

=head2 toc

Get and set the Khonsu::TOC object.

	$khonsu->toc();
	$khonsu->toc(Khonsu::TOC->new(%toc));

=cut

=head2 form

Get and set the Khonsu::Form object.

	$khonsu->form();
	$khonsu->form(Khonsu::Form->new(%form));

=cut

=head2 input

Get and set the Khonsu::Form::Field::Input object.

	$khonsu->input();
	$khonsu->input(Khonsu::Form::Field::Input->new(%input));

=cut

=head2 select

Get and set the Khonsu::Form::Field::Select object.

	$khonsu->select();
	$khonsu->select(Khonsu::Form::Field::Select->new(%select));

=cut

=head2 checkbox

Get and set the Khonsu::Form::Field::Checkbox object.

	$khonsu->checkbox();
	$khonsu->checkbox(Khonsu::Form::Field::Checkbox->new(%checkbox));

=cut

=head1 METHODS

=cut

=head2 load_plugin

Load an external custom plugin.

	package Khonsu::Test;

	use parent 'Khonsu::Text';

	sub add {
		my ($self, $file, %attributes) = @_;
		return $self->SUPER::add($file, %attributes);
	}

	1;

	...

	Khonsu->load_plugin(qw/+Test/);

	my $khonsu = Khonsu->new(
		'PDFName',
		configure => {
			test => {
				...
			}
		}
	);

	$khonsu->add_test(...);

=cut

=head2 new

Instantiate a new Khonsu Object and create an empty single page pdf.

	my $khonsu = Khonsu->new(
		'PDFName',
		%ATTRIBUTES,
		configure => {
			page_header => {
				padding => $padding,
				show_page_num => 'right',
				page_num_text => 'page {num}',
				h => $padding,
				cb => sub {
					my ($self, $file, %atts) = @_;
					$self->add(
						$file,
						text => 'Ra',
						align => 'center',
						%attrs,
					);
				}
			},
			page_footer => {
				padding => $padding,
				show_page_num => 'left',
				page_num_text => 'page {num}',
				h => $padding,
				cb => sub {
					my ($self, $file, %atts) = @_;
					$self->add(
						$file,
						text => 'Ra',
						align => 'center',
						%attrs,
					);
				}
			},
			toc => {
				title => 'Table of contents',
				title_font_args => {
					size => 50,
				},
				title_padding => 10,
				font_args => {
					size => 20,
				},
				padding => 5,
			},
		}
	);

=cut

=head2 add_page

Add a new page to the pdf.

	$khonsu->add_page(
		page_size => 'A4',
		background => '#fff',
		columns => 1,
		column => 1,
		column_y => 0,
		is_rotated => 0,
		header => Khonsu::Page::Header->new(%header),
		footer => Khonsu::Page::Footer->new(%footer),
		padding => 20,
		toc => 0,
		x => 0,
		y => 0,
		h => 842,
		w => 595,
		box => Khonsu::Shape::Box->new(%box)

	);

=cut

=head2 set_columns

Set the number of page columns. 

	$khonsu->set_columns(2);

=cut

=head2 open_page

Open an existing page of the pdf.

	$khonsu->open_page(1);

=cut

=head2 add_page_header

Add a custom header to the current page and all pages created/added after it.

	$khonsu->add_page_header(
		padding => 20,
		show_page_num => 'right',
		page_num_text => 'page {num}',
		h => 20,
		cb => sub {
			my ($self, $file, %atts) = @_;
			$self->add(
				$file,
				text => 'Khonsu',
				align => 'center',
				%attrs,
			);
		}
	);

=cut

=head2 add_page_footer

Add a custom footer to the current page and all pages created/added after it.

	$khonsu->add_page_footer(
		padding => 20,
		show_page_num => 'left',
		page_num_text => 'page {num}',
		h => 20,
		cb => sub {
			my ($self, $file, %atts) = @_;
			$self->add(
				$file,
				text => 'Khonsu',
				align => 'center',
				%attrs,
			);
		}
	);

=cut

=head2 remove_page_header_and_footer 

Remove the page header and footer for the current page.

	$khonsu->remove_page_header_and_footer();

=cut

=head2 remove_page_header

Remove the page header for the current page.

	$khonsu->remove_page_header();

=cut

=head2 remove_page_footer

Remove the page footer for the current page.

	$khonsu->remove_page_footer();

=cut

=head2 add_toc

Add a table of contents to the document.

	$khonsu->add_toc(
		title => 'Table of contents',
		title_font_args => {
			size => 50,
		},
		title_padding => 10,
		font_args => {
			size => 20,
		},
		padding => 5,
		x => 20,
		y => 20,
		w => $khonsu->page->w - 40,
		h => $khonsu->page->h - 40
	);

=cut

=head2 add_text

Add text to the document.

	$khonsu->add_text( 
		text => 'This is a test ' x 24,
		x => 20,
		y => 120,
		w => 100,
		h => 120,
	);

=cut

=head2 add_h1

Add a h1 to the document.

	$khonsu->add_h1( 
		text => 'This is a h1',
	);

=cut

=head2 add_h2

Add a h2 to the document.

	$khonsu->add_h2( 
		text => 'This is a h2',
	);
=cut

=head2 add_h3

Add a h3 to the document.

	$khonsu->add_h3( 
		text => 'This is a h3',
	);

=cut

=head2 add_h4

Add a h4 to the document.

	$khonsu->add_h4( 
		text => 'This is a h4',
	);
=cut

=head2 add_h5

Add a h5 to the document.

	$khonsu->add_h5( 
		text => 'This is a h5',
	);

=cut

=head2 add_h6

Add a h6 to the document.

	$khonsu->add_h6( 
		text => 'This is a h6',
	);

=cut

=head2 add_image

Add a image to the document.

	$khonsu->add_image(
		image => 't/test.png',
		align => 'center'
	);

=cut

=head2 add_form

Start a pdf form.

	$khonsu->add_form();

=cut

=head2 add_input

Add a input to the document.

	$khonsu->add_input(
		text => 'Input:',
		pad => '_'
	);

=cut

=head2 add_select

Add a select to the document.

	$khonsu->add_input(
		text => 'Select:',
		options => [qw/one two three four/],
		pad => '_'
	);

=cut

=head2 add_checkbox

Add a checkbox to the document.

	$khonsu->add_checkbox(
		text => 'Checkbox:',
	);

=cut

=head2 add_line

Add a line to the document.

	$khonsu->add_line(
		fill_colour => '#000',
		x => 140, 
		y => 20, 
		ex => 240,
		ey => 20 
	);

=cut

=head2 add_box

Add a box to the document.

	$khonsu->add_box(
		fill_colour => '#000',
		x => 20, 
		y => 20, 
		w => 100, 
		h => 100 
	);

=cut

=head2 add_circle

Add a circle to the document.

	$khonsu->add_circle(
		fill_colour => '#000',
		x => 260,
		y => 20,
		r => 50
	);


=cut

=head2 add_pie

Add a pie to the document.

	$khonsu->add_pie(
		fill_colour => '#000',
		x => 380,
		y => 20,
		r => 50,
		rx => 360,
		ry => 40
	);

	$khonsu->add_pie(
		fill_colour => '#fff',
		x => 380,
		y => 20,
		r => 50,
		rx => 400,
		ry => 360
	);

=cut

=head2 add_ellipse

Add a ellipse to the document.

	$khonsu->add_ellipse(
		fill_colour => '#000',
		x => 500,
		y => 20,
		w => 30,
		h => 50
	);

=cut

=head2 load_font

Load a custom font.

	$khonsu->load_font(
		colour => '#000',
		size => 20,
		family => 'Times',
		line_height => 25,
	);

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-khonsu at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Khonsu>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Khonsu

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Khonsu>

=item * Search CPAN

L<https://metacpan.org/release/Khonsu>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Khonsu
