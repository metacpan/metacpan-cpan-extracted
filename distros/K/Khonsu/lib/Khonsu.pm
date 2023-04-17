package Khonsu;
use strict;
use warnings;
our $VERSION = '0.04';
use PDF::API2;

use Khonsu::File;

sub new {
	my ($pkg, $name, %args) = @_;
	my $file = Khonsu::File->new(
		file_name => $name,
		pages => [],
		page_size => $args{page_size} || 'A4',
		page_args => $args{page_args} || {},
		pdf => PDF::API2->new( -file => sprintf("%s.pdf", $name) )
	);
	return $file;
}

sub open { ... }

1;

=head1 NAME

Khonsu - The great new Khonsu!

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	my @words = ('Aker', 'Anubis', 'Hapi', 'Khepri', 'Maahes', 'Thoth', 'Bastet', 'Hatmehit', 'Tefnut', 'Menhit', 'Imentet');

	my $generate_text = sub {
		my $length = shift;
		return join " ", map { $words[int(rand(scalar @words))] } 1 .. $length;
	};

	use Khonsu;

	my $khonsu = Khonsu->new(
		'Ra',
		page_size => 'A4',
		page_args => {
			background => '#36b636'
		}
	)->add_page;

	my $padding = 20;
	my $page_padding = $padding * 2;
	$khonsu->add_h1(
		text => $generate_text->(3),
		x => 20,
		y => $padding,
		w => $khonsu->page->w - $page_padding,
		font => {
			colour => '#fff'
		}
	)->add_text(
		text => $generate_text->(2000),
		x => 20,
		y => ($padding * 2) + $khonsu->h1->line_height,
		w => $khonsu->page->w - 40,
		h => $khonsu->page->h - ($khonsu->h1->line_height + $page_padding + $padding),
		indent => 4,
		font => {
			colour => '#fff'
		},
		overflow => 1,
	);

	$khonsu->add_page(
		background => '#fff'
	)->add_image(
		image => 't/test.png',
		x => 20,
		y => 20,
		w => $khonsu->page->w - 40,
		h => $khonsu->page->h - 40,
	);

	$khonsu->save();


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
