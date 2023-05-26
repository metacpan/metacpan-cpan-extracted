package Khonsu::Syntax;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use Syntax::Kamelon;

use base 'Khonsu::Text';

sub attributes {
	my ($a) = shift;
	return (
		$a->SUPER::attributes(),
		syntax => { $a->RW, $a->STR },
		line_numbers => { $a->RW, $a->BOOL },
		line_number_width => { $a->RW, $a->NUM, default => sub { 15 } },
		highlight => { $a->RW, $a->HR, default => sub { 
			return {
				Alert => '#fff',
				Annotation => '#ff0000',
				Attribute => '#ffff00',
				BaseN => '#00ff00',
				BuiltIn => '#ad9b04',
				Char => '#00ffff',
				Comment => '#dadada',
				CommentVar => '#000',
				Constant => '#ff00ff',
				ControlFlow => '#00a4ff',
				DataType => '#aa7700',
				DecVal => '#ff0000',
				Documentation => '#000',
				Error => '#fff000',
				Extension => '#ff00ff',
				Float => '#ff0000',
				Function => '#000',
				Import => '#04ffc1',
				Information => '#0000ff', 
				Keyword => '#006699',
				Normal => '#000',
				Operator => '#0000FF',
				Others => '#00ffff',
				Preprocessor => '#0066ff',
				RegionMarker => '#000',
				SpecialChar => '#00a4ff',
				SpecialString => '#ff0000',
				String => '#0000ff',
				Variable => '#aa7700',
				VerbatimString  => '#000',
				Warning => '#edac33',
				Line => '#dadada'
			};
		} }
	);
}

sub add {
	my ($self, $file, %attributes) = @_;

	$attributes{y} ||= $file->page->y;

	$self->set_attributes(%attributes);

	my $kam = Syntax::Kamelon->new(
		syntax => $self->syntax || 'Perl',
	);

	$kam->Parse($self->text);

	my %points = $self->get_points();
	my $highlight = $self->highlight;
	my $line_number = 0;
	for my $line (@{ $kam->{FORMATTER}->{LINES} }) {
		if ($self->line_numbers) {
			$line_number++;
			$self->SUPER::add($file,
				margin => 0,
				font => { colour => $highlight->{Line} },
				text => "$line_number |",
				y => $points{y},
				x => $points{x},
				w => $self->line_number_width,
				align => 'right'
			);
			$self->align('');
		}
		if (! scalar @{$line}) {
			$file->page->y($file->page->y + $self->font->line_height);
		} else {
			for my $part (@{$line}) {
				$self->SUPER::add($file,
					font => { colour => $highlight->{$part->{tag}} },
					text => $part->{text},
					margin => 0,
					($self->end_w ? (
						x => $self->end_w,
						w => $file->page->width()
					) : ()),
					y => $points{y},
				);
			}
		}
		$self->end_w(0);
		$points{y} = $file->page->y;
	}

	return $file;
}

sub update_highlighting {
	my ($self, %highlighting) = @_;
	my $highlight = $self->highlight;
	$highlight = {%{$highlight}, %highlighting};
	$self->highlight($highlight);
	return $self;
}

1;

__END__

=head1 NAME

Khonsu::Syntax - Khonsu PDF Generation Syntax Highlighting Plugin/Component

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use khonsu;

	Khonsu->load_plugin(qw/+Syntax/);

	my $k = Khonsu->new('test', page_args => {padding => 20});

	my $json = q|{
		"one": 1,
		"two": 2,
		"three": 3,
		"four": 4
	}|;

	$k->add_syntax(
		syntax => 'JSON',
		line_numbers => 1,
		text => $json
	);

	$k->save();

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-khonsu-syntax at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Khonsu-Syntax>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Khonsu::Syntax


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Khonsu-Syntax>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Khonsu-Syntax>

=item * Search CPAN

L<https://metacpan.org/release/Khonsu-Syntax>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Khonsu::Syntax
