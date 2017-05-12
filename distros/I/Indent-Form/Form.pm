package Indent::Form;

# Pragmas.
use strict;
use warnings;

# Modules.
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

# Version.
our $VERSION = 0.01;

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
	if ($self->{'line_size'} !~ /^\d*$/ms || $self->{'line_size'} < 0) {
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
			push @data, $dat->[0].$self->{'form_separator'}.
				$dat->[1];
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
		'line_size' => $self->{'line_size'} - $max
			- $self->_length($self->{'form_separator'}),
		'next_indent' => $next_indent,
	);

	foreach my $dat_ar (@{$data_ar}) {
		my $output = $actual_indent;

		# Left side.
		if ($self->{'align'} eq 'left') {
			$output .= $dat_ar->[0];
			$output .= $self->{'fill_character'}
				x ($max - $self->_length($dat_ar->[0]));
		} elsif ($self->{'align'} eq 'right') {
			$output .= $self->{'fill_character'}
				x ($max - $self->_length($dat_ar->[0]));
			$output .= $dat_ar->[0];
		}

		# Right side.
		if ($dat_ar->[1]) {
			$output .= $self->{'form_separator'};
			my @tmp = $word->indent($dat_ar->[1]);
			$output .= shift @tmp;
			push @data, $output;
			while (@tmp) {
				push @data, $actual_indent.shift @tmp;
			}
		} else {
			push @data, $output;
		}
	}

	# Return as array or one line with output separator between its.
	return wantarray ? @data : join $self->{'output_separator'}, @data;
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

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Indent::Form - A perl module for form indenting.

=head1 SYNOPSIS

 use Indent::Form;
 my $indent = Indent::Form->new(%parametes);
 $indent->indent($data_ar, $actual_indent, $non_indent_flag);

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

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

=item C<indent($data_ar[, $actual_indent, $non_indent_flag])>

 Indent data. Returns string.

 Arguments:
 $data_ar - Reference to data array ([['key' => 'value'], [..]]);
 $actual_indent - String to actual indent.
 $non_indent_flag - Flag, than says no-indent.

=back

=head1 ERRORS

 new():
         'align' parameter must be a 'left' or 'right' string.
         'line_size' parameter must be a number.
         Cannot load 'Text::ANSI::Util' module.
         From Class::Utils:
                 Unknown parameter '%s'.

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
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

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
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

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
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

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<Indent::Word>,
L<List::MoreUtils>,
L<Readonly>.

L<Text::ANSI::Util> for situation with 'ansi' => 1.

=head1 SEE ALSO

L<Indent>,
L<Indent::Block>,
L<Indent::Data>,
L<Indent::String>,
L<Indent::Utils>,
L<Indent::Word>.

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

BSD license.

=head1 VERSION

0.01

=cut
