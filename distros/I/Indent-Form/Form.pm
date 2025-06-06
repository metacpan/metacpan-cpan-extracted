package Indent::Form;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English qw(-no_match_vars);
use Error::Pure qw(err);
use Indent::Word;
use List::MoreUtils qw(none);
use Readonly;

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $LINE_SIZE => 79;
Readonly::Scalar my $SPACE => q{ };

our $VERSION = 0.08;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Use with ANSI sequences.
	$self->{'ansi'} = 0;

	# Align.
	$self->{'align'} = 'right';

	# Fill character.
	$self->{'fill_character'} = $SPACE;

	# Form separator.
	$self->{'form_separator'} = ': ';

	# Line size.
	$self->{'line_size'} = $LINE_SIZE;

	# Next indent.
	$self->{'next_indent'} = undef;

	# Output separator.
	$self->{'output_separator'} = "\n";

	# Process params.
	set_params($self, @params);

	# Check align.
	if (none { $self->{'align'} eq $_ } qw(left right)) {
		err '\'align\' parameter must be a \'left\' or \'right\' '.
			'string.';
	}

	# 'line_size' check.
	if ($self->{'line_size'} !~ /^\d*$/ms) {
		err '\'line_size\' parameter must be a number.', 
			'line_size', $self->{'line_size'};
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

# Indent form data.
sub indent {
	my ($self, $data_ar, $actual_indent, $non_indent_flag) = @_;

	# Undef indent.
	if (! $actual_indent) {
		$actual_indent = $EMPTY_STR;
	}

	# Max size of key.
	my $max = 0;
	my @data;
	foreach my $dat (@{$data_ar}) {
		if ($self->_length($dat->[0]) > $max) {
			$max = $self->_length($dat->[0]);
		}

		# Non-indent.
		if ($non_indent_flag) {
			push @data, $self->_value($dat->[0]).$self->{'form_separator'}.
				$self->_value($dat->[1]);
		}
	}

	# If non-indent.
	# Return as array or one line with output separator between its.
	if ($non_indent_flag) {
		return wantarray ? @data
			: join $self->{'output_separator'}, @data;
	}

	# Indent word.
	my $next_indent = $self->{'next_indent'} ? $self->{'next_indent'}
		: $SPACE x ($max + $self->_length($self->{'form_separator'}));
	my $word = Indent::Word->new(
		'ansi' => $self->{'ansi'},
		'line_size' => $self->{'line_size'} - $max
			- $self->_length($self->{'form_separator'}),
		'next_indent' => $next_indent,
	);

	foreach my $dat_ar (@{$data_ar}) {
		my $output = $actual_indent;

		# Left side, left align.
		if ($self->{'align'} eq 'left') {
			$output .= $self->_value($dat_ar->[0]);
			$output .= $self->{'fill_character'}
				x ($max - $self->_length($dat_ar->[0]));

		# Left side, right align.
		} else {
			$output .= $self->{'fill_character'}
				x ($max - $self->_length($dat_ar->[0]));
			$output .= $self->_value($dat_ar->[0]);
		}

		# Right side.
		$output .= $self->{'form_separator'};
		my @tmp = $word->indent($self->_value($dat_ar->[1]));
		$output .= shift @tmp if @tmp;
		push @data, $output;
		while (@tmp) {
			push @data, $actual_indent.shift @tmp;
		}
	}

	# Return as array or one line with output separator between its.
	return wantarray ? @data : join $self->{'output_separator'}, @data;
}

# Get length.
sub _length {
	my ($self, $string) = @_;

	if (! defined $string) {
		return 0;
	}

	if ($self->{'ansi'}) {
		return length Text::ANSI::Util::ta_strip($string);
	} else {
		return length $string;
	}
}

sub _value {
	my ($self, $string) = @_;

	if (! defined $string) {
		return $EMPTY_STR;
	}

	return $string;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Indent::Form - A perl module for form indenting.

=head1 SYNOPSIS

 use Indent::Form;

 my $indent = Indent::Form->new(%parametes);
 my $string = $indent->indent($data_ar, $actual_indent, $non_indent_flag);
 my @string = $indent->indent($data_ar, $actual_indent, $non_indent_flag);

=head1 METHODS

=head2 C<new>

 my $indent = Indent::Form->new(%parametes);

Constructor.

Returns instance of object.

=over 8

=item * C<ansi>

 Use with ANSI sequences.
 Default value is 0.

=item * C<align>

 Align of left side of form.
 Default value is 'right'.

=item * C<fill_character>

 Fill character for left side of form.
 Default value is ' '.

=item * C<form_separator>

 Form separator.
 Default value of 'form_separator' is ': '.

=item * C<line_size>

 Line size.
 Default value of 'line_size' is 79 chars.

=item * C<next_indent>

 Next indent.
 Default value of 'next_indent' isn't define.

=item * C<output_separator>

 Output separator.
 Default value of 'output_separator' is new line (\n).

=back

=head2 C<indent>

 my $string = $indent->indent($data_ar, $actual_indent, $non_indent_flag);
 my @string = $indent->indent($data_ar, $actual_indent, $non_indent_flag);

Indent data. Scalar output is controlled by 'output_separator' parameter.

 Arguments:
 $data_ar - Reference to data array ([['key' => 'value'], [..]]);
 $actual_indent - String to actual indent.
 $non_indent_flag - Flag, than says no-indent.

Returns string or array of strings in array context.

=head1 ENVIRONMENT

Output is controlled by env variable C<NO_COLOR> via L<Term::ANSIColor> Perl
module. If we set 'ansi' parameter to 1 and env variable C<NO_COLOR> will be 1,
output will be without ANSI colors. See L<https://no-color.org/>.

=head1 ERRORS

 new():
         'align' parameter must be a 'left' or 'right' string.
         'line_size' parameter must be a number.
         Cannot load 'Text::ANSI::Util' module.
         From Class::Utils:
                 Unknown parameter '%s'.

=head1 EXAMPLE1

=for comment filename=default_indent.pl

 use strict;
 use warnings;

 use Indent::Form;

 # Indent object.
 my $indent = Indent::Form->new;

 # Input data.
 my $input_ar = [
         ['Filename', 'foo.bar'],
         ['Size', '1456kB'],
         ['Description', 'File'],
         ['Author', 'skim.cz'],
 ];

 # Indent.
 print $indent->indent($input_ar)."\n";

 # Output:
 #    Filename: foo.bar
 #        Size: 1456kB
 # Description: File
 #      Author: skim.cz

=head1 EXAMPLE2

=for comment filename=left_indent.pl

 use strict;
 use warnings;

 use Indent::Form;

 # Indent object.
 my $indent = Indent::Form->new(
         'align' => 'left',
 );

 # Input data.
 my $input_ar = [
         ['Filename', 'foo.bar'],
         ['Size', '1456kB'],
         ['Description', 'File'],
         ['Author', 'skim.cz'],
 ];

 # Indent.
 print $indent->indent($input_ar)."\n";

 # Output:
 # Filename   : foo.bar
 # Size       : 1456kB
 # Description: File
 # Author     : skim.cz

=head1 EXAMPLE3

=for comment filename=left_indent_with_dots.pl

 use strict;
 use warnings;

 use Indent::Form;

 # Indent object.
 my $indent = Indent::Form->new(
         'align' => 'left',
         'fill_character' => '.',
 );

 # Input data.
 my $input_ar = [
         ['Filename', 'foo.bar'],
         ['Size', '1456kB'],
         ['Description', 'File'],
         ['Author', 'skim.cz'],
 ];

 # Indent.
 print $indent->indent($input_ar)."\n";

 # Output:
 # Filename...: foo.bar
 # Size.......: 1456kB
 # Description: File
 # Author.....: skim.cz

=head1 EXAMPLE4

=for comment filename=default_indent_with_prefix.pl

 use strict;
 use warnings;

 use Encode qw(decode_utf8 encode_utf8);
 use Indent::Form;

 # Indent object.
 my $indent = Indent::Form->new;

 # Input data.
 my $input_ar = [
         ['Filename', 'foo.bar'],
         ['Size', '1456kB'],
         ['Description', 'File'],
         ['Author', 'skim.cz'],
 ];

 # Indent.
 print encode_utf8($indent->indent($input_ar, decode_utf8('|↔| ')))."\n";

 # Output:
 # |↔|    Filename: foo.bar
 # |↔|        Size: 1456kB
 # |↔| Description: File
 # |↔|      Author: skim.cz

=head1 EXAMPLE5

=for comment filename=default_indent_ansi.pl

 use strict;
 use warnings;

 use Indent::Form;
 use Term::ANSIColor;

 # Indent object.
 my $indent = Indent::Form->new(
         'ansi' => 1,
 );

 # Input data.
 my $input_ar = [
         [
                 color('cyan').'Filename'.color('reset'),
                 color('bold cyan').'f'.color('reset').'oo.'.color('bold cyan').'b'.color('reset').'ar',
         ],
         [
                 color('cyan').'Size'.color('reset'),
                 '1456kB',
         ],
         [
                 color('cyan').'Description'.color('reset'),
                 color('bold cyan').'F'.color('reset').'ile',
         ],
         [
                 color('cyan').'Author'.color('reset'),
                 'skim.cz',
         ],
 ];

 # Indent.
 print $indent->indent($input_ar)."\n";

 # Output (with ANSI colors):
 #    Filename: foo.bar
 #        Size: 1456kB
 # Description: File
 #      Author: skim.cz

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<Indent::Word>,
L<List::MoreUtils>,
L<Readonly>.

L<Text::ANSI::Util> for situation with 'ansi' => 1.

=head1 SEE ALSO

=over 8

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

=item L<Indent::Word>

 Class for word indenting.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Indent-Form>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2011-2023 Michal Josef Špaček

Artistic License

BSD 2-Clause License

=head1 VERSION

0.08

=cut
