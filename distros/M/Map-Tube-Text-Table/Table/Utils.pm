package Map::Tube::Text::Table::Utils;

# Pragmas.
use base qw(Exporter);
use strict;
use warnings;

# Modules.
use List::Util qw(sum);
use Readonly;
use Text::UnicodeBox;
use Text::UnicodeBox::Control qw(:all);

# Constants.
Readonly::Array our @EXPORT_OK => qw(table);
Readonly::Scalar our $EMPTY_STR => q{};
Readonly::Scalar our $SPACE => q{ };
Readonly::Scalar our $SPACE_ON_END_COUNT => 1;

# Version.
our $VERSION = 0.04;

# Print table.
sub table {
	my ($title, $data_len_ar, $header_ar, $data_ar) = @_;

	# Check data.
	if (! @{$data_ar}) {
		return $EMPTY_STR;
	}

	my $t = Text::UnicodeBox->new;

	# Table title.
	my $pipes_in_count = @{$data_len_ar} * 2 - 2;
	$t->add_line(
		BOX_START('bottom' => 'light', 'top' => 'light'),
		_column_left($title, sum(map { $_ + $SPACE_ON_END_COUNT }
			@{$data_len_ar}) + $pipes_in_count),
		BOX_END(),
	);

	# Legend.
	if (defined $header_ar) {
		$t->add_line(
			BOX_START('bottom' => 'light', 'top' => 'light'),
			_columns($header_ar, $data_len_ar),
		);
	}

	# Data.
	while (my $row_ar = shift @{$data_ar}) {
		$t->add_line(
			BOX_START(
				@{$data_ar} == 0 ? ('bottom' => 'light') : (),
			),
			_columns($row_ar, $data_len_ar),
		);
	}

	# Render to output.
	return $t->render;
}

# Column text with left align.
sub _column_left {
	my ($text, $width) = @_;
	my $text_len = length $text;
	return $SPACE.$text.($SPACE x ($width - $text_len));
}

# Get Text::UnicodeBox columns.
sub _columns {
	my ($data_ar, $data_len_ar) = @_;
	my @ret;
	my $i = 0;
	foreach my $item (@{$data_ar}) {
		push @ret, _column_left($item, $data_len_ar->[$i++]
			+ $SPACE_ON_END_COUNT);
		if (@{$data_ar} > $i) {
			push @ret, BOX_RULE;
		} else {
			push @ret, BOX_END;
		}
	}
	return @ret;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Map::Tube::Text::Table::Utils - Utilities for Map::Tube::Text::Table.

=head1 SYNOPSIS

 use Map::Tube::Text::Table::Utils qw(table);
 my $table = table($title, $data_len_ar, $header_ar, $data_ar);

=head1 SUBROUTINES

=over 8

=item C<table($title, $data_len_ar, $header_ar, $data_ar)>

 Print table.
 Returns text.

=back

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Module.
 use Encode qw(encode_utf8);
 use Map::Tube::Text::Table::Utils qw(table);

 # Get table.
 my $table = table('Title', [1, 2, 3], ['A', 'BB', 'CCC'], [
         ['E', 'A', 'A'],
         ['A', 'Ga', 'Acv'],
 ]);

 # Print table.
 print encode_utf8($table);

 # Output:
 # ┌──────────────┐
 # │ Title        │
 # ├───┬────┬─────┤
 # │ A │ BB │ CCC │
 # ├───┼────┼─────┤
 # │ E │ A  │ A   │
 # │ A │ Ga │ Acv │
 # └───┴────┴─────┘

=head1 DEPENDENCIES

L<Exporter>,
L<List::Util>,
L<Readonly>,
L<Text::UnicodeBox>,
L<Text::UnicodeBox::Control>.

=head1 SEE ALSO

L<Map::Tube>,
L<Map::Tube::Text::Table>,
L<Task::Map::Tube>.

=head1 REPOSITORY

L<https://github.com/tupinek/Map-Tube-Text-Table>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2014-2015 Michal Špaček
 Artistic License
 BSD 2-Clause License

=head1 VERSION

0.04

=cut
