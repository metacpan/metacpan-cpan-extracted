package Khonsu;
use strict;
use warnings;
our $VERSION = '0.08';
use PDF::API2;

use Khonsu::File;

sub new {
	my ($pkg, $name, %args) = @_;
	my $file = Khonsu::File->new(
		file_name => $name,
		pages => [],
		page_size => $args{page_size} || 'A4',
		page_args => $args{page_args} || {},
		pdf => PDF::API2->new( -file => sprintf("%s.pdf", $name) ),
		configure => $args{configure}
	);
	return $file;
}

sub open { ... }

1;

=head1 NAME

Khonsu - PDF Generation!

=head1 VERSION

Version 0.08

=cut

=head1 SYNOPSIS

	my @words = ('Aker', 'Anubis', 'Hapi', 'Khepri', 'Maahes', 'Thoth', 'Bastet', 'Hatmehit', 'Tefnut', 'Menhit', 'Imentet');

	my $generate_text = sub {
		my $length = shift;
		return join " ", map { $words[int(rand(scalar @words))] } 1 .. $length;
	};

	use Khonsu;

	my $padding = 20;
	my $page_padding = $padding * 2;
	my $khonsu = Khonsu->new(
		'Ra',
		page_size => 'A4',
		page_args => {
			background => '#3ff'
		},
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

	$khonsu->save();

=head1 METHODS

=cut

=head2 add_page

=cut

=head2 set_columns

=cut

=head2 open_page

=cut

=head2 add_page_header

=cut

=head2 add_page_footer

=cut

=head2 remove_page_header_and_footer 

=cut

=head2 remove_page_header

=cut

=head2 remove_page_footer

=cut

=head2 add_toc

=cut

=head2 add_text

=cut

=head2 add_h1

=cut

=head2 add_h2

=cut

=head2 add_h3

=cut

=head2 add_h4

=cut

=head2 add_h5

=cut

=head2 add_h6

=cut

=head2 add_image

=cut

=head2 add_form

=cut

=head2 add_input

=cut

=head2 add_select

=cut

=head2 add_line

=cut

=head2 add_box

=cut

=head2 add_circle

=cut

=head2 add_pie

=cut

=head2 add_ellipse

=cut

=head2 load_font

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

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Khonsu>

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
