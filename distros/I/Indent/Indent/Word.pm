package Indent::Word;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English qw(-no_match_vars);
use Error::Pure qw(err);
use Indent::Utils qw(line_size_check);
use Readonly;

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $LINE_SIZE => 79;

our $VERSION = 0.08;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Use with ANSI sequences.
	$self->{'ansi'} = undef;

	# Options.
	$self->{'line_size'} = $LINE_SIZE;
	$self->{'next_indent'} = "\t";

	# Output.
	$self->{'output_separator'} = "\n";

	# Process params.
	set_params($self, @params);

	# 'line_size' check.
	line_size_check($self);

	if (! defined $self->{'ansi'}) {
		if (exists $ENV{'NO_COLOR'}) {
			$self->{'ansi'} = 0;
		} elsif (defined $ENV{'COLOR'}) {
			$self->{'ansi'} = 1;
		} else {
			$self->{'ansi'} = 0;
		}
	}

	# Check rutine for removing ANSI sequences.
	if ($self->{'ansi'}) {
		eval {
			require Text::ANSI::Util;
		};
		if ($EVAL_ERROR) {
			err "Cannot load 'Text::ANSI::Util' module.";
		}
	}

	# Object.
	return $self;
}

# Indent text by words to line_size block size.
sub indent {
	my ($self, $data, $indent, $non_indent) = @_;

	# 'indent' initialization.
	if (! defined $indent) {
		$indent = $EMPTY_STR;
	}

	# If non_indent data, than return.
	if ($non_indent) {
		return $indent.$data;
	}

	my ($first, $second) = (undef, $indent.$data);
	my $last_second_length = 0;
	my @data;
	my $one = 1;
	while ($self->_length($second) >= $self->{'line_size'}
		&& $second =~ /^\s*\S+\s+/ms
		&& $last_second_length != $self->_length($second)) {

		# Last length of non-parsed part of data.
		$last_second_length = $self->_length($second);

		# Parse to indent length.
		($first, my $tmp) = $self->_parse_to_indent_length($second);

		# If string is non-breakable in indent length, than parse to
		# blank char.
		if (! $first
			|| $self->_length($first) < $self->_length($indent)
			|| $first =~ /^$indent\s*$/ms) {

			($first, $tmp) = $second
				=~ /^($indent\s*[^\s]+?)\s(.*)$/msx;
		}

		# If parsing is right.
		if ($tmp) {

			# Non-parsed part of data.
			$second = $tmp;

			# Add next_indent to string.
			if ($one == 1) {
				$indent .= $self->{'next_indent'};
			}
			$one = 0;
			$second = $indent.$second;

			# Parsed part of data to @data array.
			push @data, $first;
		}
	}

	# Add other data to @data array.
	$second =~ s/\s+$//ms;
	if ($second) {
		push @data, $second;
	}

	# Return as array or one line with output separator between its.
	return wantarray ? @data : join($self->{'output_separator'}, @data);
}

# Get length.
sub _length {
	my ($self, $string) = @_;
	if ($self->{'ansi'}) {
		return length Text::ANSI::Util::ta_strip($string);
	} else {
		return length $string;
	}
}

# Parse to indent length.
sub _parse_to_indent_length {
	my ($self, $string) = @_;
	my @ret;
	if ($self->{'ansi'}) {
		my $string_wo_ansi = Text::ANSI::Util::ta_strip($string);

		# First part.
		my ($first_wo_ansi) = $string_wo_ansi
			=~ m/^(.{0,$self->{'line_size'}})\s+(.*)$/msx;
		push @ret, Text::ANSI::Util::ta_trunc($string, length $first_wo_ansi);

		# Second part. (Remove first part + whitespace from string.)
		my $other_string_wo_ansi = Text::ANSI::Util::ta_strip(
			Text::ANSI::Util::ta_substr($string, length $first_wo_ansi,
				Text::ANSI::Util::ta_length($string))
		);
		$other_string_wo_ansi =~ m/^(\s*)/ms;
		my $count_of_spaces = length $1;
		push @ret, Text::ANSI::Util::ta_substr($string, 0, (length $first_wo_ansi)
			+ $count_of_spaces, '');
	} else {
		@ret = $string =~ m/^(.{0,$self->{'line_size'}})\s+(.*)$/msx;
	}
	return @ret;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Indent::Word - Class for word indenting.

=head1 SYNOPSIS

 use Indent::Word;

 my $obj = Indent::Word->new(%parameters);
 my $string = $obj->indent('text text text');
 my @data = $obj->indent('text text text');

=head1 METHODS

=head2 C<new>

 my $obj = Indent::Word->new(%parameters);

Constructor.

Returns instance of object.

=over 8

=item * C<ansi>

 Use with ANSI sequences.
 Default value is:
 - 1 if COLOR env variable is set
 - 0 if NO_COLOR env variable is set
 - 0 otherwise

=item * C<line_size>

 Sets indent line size value.
 Default value is 79.

=item * C<next_indent>

 Sets output separator between indented datas for string context.
 Default value is "\t" (tabelator).

=item * C<output_separator>

 Output separator between data in scalar context.
 Default value is "\n" (new line).

=back

=head2 C<indent>

 my $string = $obj->indent('text text text');

or

 my @data = $obj->indent('text text text');

Indent text by words to line_size block size.

 $act_indent - Actual indent string. Will be in each output string.
 $non_indent - Is flag for non indenting. Default is 0.

Returns string or array with data to print.

=head1 ENVIRONMENT

Output is controlled by env variables C<NO_COLOR> and C<COLOR>.
See L<https://no-color.org/>.

=head1 ERRORS

 new():
         Cannot load 'Text::ANSI::Util' module.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Indent::Utils::line_size_check():
                 'line_size' parameter must be a positive number.
                         line_size => %s

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Indent::Word;

 # Object.
 my $i = Indent::Word->new(
         'line_size' => 20,
 );

 # Indent.
 print $i->indent(join(' ', ('text') x 7))."\n";

 # Output:
 # text text text text
 # <--tab->text text text

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Indent::Word;
 use Term::ANSIColor;

 # Object.
 my $i = Indent::Word->new(
         'ansi' => 1,
         'line_size' => 20,
 );

 # Indent.
 print $i->indent('text text '.color('cyan').'text'.color('reset').
         ' text '.color('red').'text'.color('reset').' text text')."\n";

 # Output:
 # text text text text
 # <--tab->text text text

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<Indent::Utils>,
L<Readonly>.

L<Text::ANSI::Util> for situation with 'ansi' => 1.

=head1 SEE ALSO

=over

=item L<Indent>

Class for indent handling.

=item L<Indent::Block>

Class for block indenting.

=item L<Indent::Data>

Class for data indenting.

=item L<Indent::String>

Class for text indenting.

=item L<Indent::Utils>

Utilities for Indent classes.

=item L<Text::Wrap>

line wrapping to form simple paragraphs

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Indent>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2005-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.08

=cut
