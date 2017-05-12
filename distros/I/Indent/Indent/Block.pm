package Indent::Block;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Indent::Utils qw(line_size_check string_len);
use Readonly;

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $LINE_SIZE => 79;

# Version.
our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Line size.
	$self->{'line_size'} = $LINE_SIZE;

	# Next indent.
	$self->{'next_indent'} = "\t";

	# Output.
	$self->{'output_separator'} = "\n";

	# Strict mode - without white space optimalization.
	$self->{'strict'} = 1;

	# Process params.
	set_params($self, @params);

	# 'line_size' check.
	line_size_check($self);

	# Save current piece.
	$self->{'_current'} = $EMPTY_STR;

	# Object.
	return $self;
}

# Parses tag to indented data.
sub indent {
	my ($self, $data_ar, $act_indent, $non_indent) = @_;

	# Undef indent.
	if (! $act_indent) {
		$act_indent = $EMPTY_STR;
	}

	# Input data.
	my @input = @{$data_ar};

	# If non_indent data, than return.
	if ($non_indent) {
		return $act_indent.join($EMPTY_STR, @input);
	}

	# Indent.
	my @data = ();
	my ($first, $second);
	$first = shift @input;
	my $tmp_indent = $act_indent;
	while (@input) {
		$second = shift @input;
		if ($self->_compare($first, $second, $tmp_indent)) {
			push @data, $self->{'_current'};
			$first = $second;
			$second = $EMPTY_STR;
			$tmp_indent = $act_indent.$self->{'next_indent'};
		} else {
			$first .= $second;
		}
	}

	# Add other data to @data array.
	if ($first) {

		# White space optimalization.
		if (! $self->{'strict'}) {
			$first =~ s/^\s*//ms;
			$first =~ s/\s*$//ms;
		}
		if ($first ne $EMPTY_STR) {
			push @data, $tmp_indent.$first;
		}
	}

	# Return as array or one line with output separator between its.
	return wantarray ? @data : join($self->{'output_separator'}, @data);
}

# Compare strings with 'line_size' and save right current string.
sub _compare {
	my ($self, $first, $second, $act_indent) = @_;

	# Without optimalization.
	if ($self->{'strict'}) {
		if (length $first > 0
			&& (string_len($act_indent.$first)
			>= $self->{'line_size'}
			|| string_len($act_indent.$first.$second)
			> $self->{'line_size'})) {

			$self->{'_current'} = $act_indent.$first;
			return 1;
		} else {
			return 0;
		}

	# With optimalizaton.
	# TODO Rewrite.
	} else {
		my $tmp1 = $first;
		$tmp1 =~ s/^\s*//ms;
		$tmp1 =~ s/\s*$//ms;
		if (length $tmp1 > 0
			&& string_len($act_indent.$tmp1)
			>= $self->{'line_size'}) {

			$self->{'_current'} = $act_indent.$tmp1;
			return 1;
		} else {
			my $tmp2 = $first.$second;
			$tmp2 =~ s/^\s*//ms;
			$tmp2 =~ s/\s*$//ms;
			if (length $tmp1 > 0
				&& string_len($act_indent.$tmp2)
				> $self->{'line_size'}) {

				$self->{'_current'} = $act_indent.$tmp1;
				return 1;
			} else {
				return 0;
			}
		}
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Indent::Block - Class for block indenting.

=head1 SYNOPSIS

 use Indent::Block;
 my $i = Indent::Block->new(%parameters);
 print $i->indent($data, [$act_indent, $non_indent]);

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor.

=over 8

=item * C<line_size>

 Sets indent line size value.
 Default value is 'line_size' => 79.

=item * C<next_indent>

 Sets next indent string.
 Default value is 'next_indent' => "\t" (tabelator).

=item * C<output_separator>

 Sets output separator between indented datas for string context.
 Default value is 'output_separator' => "\n" (new line).

=item * C<strict>

 Sets or unsets strict mode.
 Unset strict mode means whitespace optimalization.
 Default value is 'strict' => 1.

=back

=item C<indent($data_ar, [$act_indent, $non_indent])>

 Indent method.
 - $data_ar - Reference to array with strings to indent.
 - $act_indent - String to actual indent.
 - $non_indent - Flag, that says 'no-indent' for current time.

=back

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Indent::Utils::line_size_check():
                 'line_size' parameter must be a positive number.
                         line_size => %s

=head1 EXAMPLE

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Indent::Block;

 # Object.
 my $i = Indent::Block->new(
         'line_size' => 2,
	 'next_indent' => '',
 );

 # Print in scalar context.
 print $i->indent(['text', 'text', 'text'])."\n";

 # Output:
 # text
 # text
 # text

=head1 DEPENDENCIES

L<Class::Utils>,
L<Indent::Utils>,
L<Readonly>.

=head1 SEE ALSO

L<Indent>,
L<Indent::Comment>,
L<Indent::Data>,
L<Indent::Utils>,
L<Indent::Word>.

=head1 REPOSITORY

L<https://github.com/tupinek/Indent>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

BSD License.

=head1 VERSION

0.03

=cut
