package MetaCPAN::Client::Pod::PDF;

use 5.006;
use strict;
use warnings;

use Moo;
use Mxpress::PDF;
use Pod::Simpler::Aoh;
use JSON;
our $VERSION = '0.03';

extends 'MetaCPAN::Client';

has toc_map => (
	is => 'ro',
	default => sub {{
		'head1' => 'h1',
		'head2' => 'h2',
		'head3' => 'h3',
		'head4' => 'h4',
		'head5' => 'h5',
		'head6' => 'h6'
	}}
);

has styles => (
	is => 'rw',
	default => sub{{
		plugins => [qw/h1 h2 h3 h4 h5 h6/],
		page => {
			padding => 15,
		},
		cover => {
			columns => 1
		},
		toc => {
			levels => [qw/title h1 h2 h3 h4 h5 h6/],
			font => { colour => '#00f' },
		},
		title => {
			margin_bottom => 3,
		},
		h1 => {
			margin_bottom => 3,
			font => {
				size => 26,
				line_height => 26
			}
		},
		h2 => {
			margin_bottom => 3,
			font => {
				size => 24,
				line_height => 24
			}
		},
		h3 => {
			margin_bottom => 3,
			font => {
				size => 22
			}
		},
		h4 => {
			margin_bottom => 3,
			font => {
				size => 20
			}
		},
		h5 => {
			margin_bottom => 3,
			font => {
				size => 18
			}
		},
		h6 => {
			margin_bottom => 3,
			font => {
				size => 16
			}
		},
		text => {
			margin_bottom => 3,
			align => 'justify',
		},
	}}
);

has header => (
	is => 'rw',
	default => sub {{
		show_page_num => 'left',
		page_num_text => "page {num}",
		h => 10,
		padding => 5
	}}
);

has footer => (
	is => 'rw',
	default => sub {{
		show_page_num => 'right',
		page_num_text => "page {num}",
		h => 10,
		padding => 5
	}}
);

sub set_style {
	$_[0]->styles->{$_[1]}->{$_[2]} = $_[3];
}

sub raw {
	my ($self, $name, $string, $stringify) = @_;
	my $pod = Pod::Simpler::Aoh->new->parse_string_document(
		$string
	);
	my $pdf = $self->_start_pdf($name);
	for my $section (@{$pod}) {
		$self->_add_pod_to_pdf($pdf, $section);
	}
	return $stringify ? $pdf->stringify() : $pdf->save();
}

sub pdf {
	my ($self, $module, $stringify) = @_;
	my $pod = Pod::Simpler::Aoh->new->parse_string_document(
		$self->pod($module)->x_pod
	);
	my $pdf = $self->_start_pdf($module);
	for my $section (@{$pod}) {
		$self->_add_pod_to_pdf($pdf, $section);
	}
	return $stringify ? $pdf->stringify() : $pdf->save();
}

sub dist_pdf {
	my ($self, $dist, $stringify) = @_;
	$dist =~ s/\:\:/-/g;
	my $release = $self->release($dist);
	my $pdf = $self->_start_pdf($dist);
	for my $module (@{$release->{data}{provides}}) {
		my $pod = $self->pod($module)->x_pod;
		next if eval { JSON->new->decode($pod) };
		$pod = Pod::Simpler::Aoh->new->parse_string_document(
			$pod
		);
		next if $module eq 'DBIx::Class::AccessorGroup';

		$pdf->toc->add(
			title => $module
		);
		$self->_add_pod_to_pdf($pdf, $_) for @{$pod};
	}
	return $stringify ? $pdf->stringify() : $pdf->save();
}

sub _start_pdf {
	my ($self, $module) = @_;
	my $pdf = Mxpress::PDF->new_pdf($module, %{$self->styles});

	$pdf->page->header->add(
		%{$self->header}
	);

	$pdf->page->footer->add(
		%{$self->footer}
	);

	$pdf->h1->add(
		'Table of Contents'
	)->toc->placeholder;

	return $pdf;
}

sub _add_pod_to_pdf {
	my ($self, $pdf, $section) = @_;
	if ($section->{title} && $section->{identifier}) {
		return if $section->{title} eq 'POD ERRORS';
		$pdf->toc->add(
			$self->toc_map->{$section->{identifier}} => $section->{title}
		);
	}

	if ($section->{content}) {
		$section->{content} =~ s/  /    /g;
		$pdf->text->add(
			$section->{content} // ''
		);
	} else {
		$pdf->text->add(
			''
		);
	}
}

1;

__END__

=head1 NAME

MetaCPAN::Client::Pod::PDF - The great new MetaCPAN::Client::Pod::PDF!

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

	use MetaCPAN::Client::Pod::PDF;

	my $client = MetaCPAN::Client::Pod::PDF->new();

	$client->pdf('Moo');

	$client->dist_pdf('Moo');

=head1 ATTRIBUTES

=head1 header

Configure the header of each page in the PDF.

	$pdf->header({
		show_page_num => 'left',
		page_num_text => "page {num}",
		h => 10,
		padding => 5
	});

=head1 footer

Configure the footer of each page in the PDF.

	$pdf->footer({
		show_page_num => 'right',
		page_num_text => "page {num}",
		h => 10,
		padding => 5
	});

=head1 styles

Configure the styles that are applied to the PDF.

	$pdf->styles({
		plugins => [qw/h1 h2 h3 h4 h5 h6/],
		page => {
			padding => 15,
		},
		cover => {
			columns => 1
		},
		toc => {
			levels => [qw/title h1 h2 h3 h4 h5 h6/],
			font => { colour => '#00f' },
		},
		title => {
			margin_bottom => 3,
		},
		h1 => {
			margin_bottom => 3,
			font => {
				size => 26,
				line_height => 26
			}
		},
		h2 => {
			margin_bottom => 3,
			font => {
				size => 24,
				line_height => 24
			}
		},
		h3 => {
			margin_bottom => 3,
			font => {
				size => 22
			}
		},
		h4 => {
			margin_bottom => 3,
			font => {
				size => 20
			}
		},
		h5 => {
			margin_bottom => 3,
			font => {
				size => 18
			}
		},
		h6 => {
			margin_bottom => 3,
			font => {
				size => 16
			}
		},
		text => {
			margin_bottom => 3,
		},
	});

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new MetaCPAN::Client::Pod::PDF Object.

	my $object = MetaCPAN::Client::Pod::PDF->new;

=head2 pdf

Generate a PDF for a individual module.

	$pdf->pdf('DBIx::Class');

	my $stringify = $pdf->pdf('DBIx::Class', 1);

=cut

=head2 dist_pdf

Generate a PDF for a distribution.

	$pdf->dist_pdf('DBIx::Class');
	
	my $stringify = $pdf->dist_pdf('DBIx::Class', 1);

=head2 raw

Generate a PDF from raw pod markup.

	my $pod = q|=head1 title

	picture yourself on a boat on a river.

	|;

	$pdf->raw('FileName', $pod);
	
	$pdf->raw('FileName', $pod, 1);

=cut

=head1 AUTHOR

lnation, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-metacpan-client-pod-pdf at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MetaCPAN-Client-Pod-PDF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MetaCPAN::Client::Pod::PDF


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MetaCPAN-Client-Pod-PDF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MetaCPAN-Client-Pod-PDF>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/MetaCPAN-Client-Pod-PDF>

=item * Search CPAN

L<https://metacpan.org/release/MetaCPAN-Client-Pod-PDF>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by lnation.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of MetaCPAN::Client::Pod::PDF
