package Indent::Data;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Error::Pure qw(err);
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

	# Options.
	$self->{'line_size'} = $LINE_SIZE;
	$self->{'next_indent'} = "\t";

	# Output.
	$self->{'output_separator'} = "\n";

	# Process params.
	set_params($self, @params);

	# 'line_size' check.
	line_size_check($self);

	# Error with 'next_indent' length greater than 'line_size'.
	if ($self->{'line_size'} <= length $self->{'next_indent'}) {
		err "Bad line_size = '$self->{'line_size'}' ".
			"or length of string '$self->{'next_indent'}'.";
	}

	# Object.
	return $self;
}

# Parses tag to indented data.
sub indent {
	my ($self, $data, $act_indent, $non_indent) = @_;

	# Undef indent.
	if (! $act_indent) {
		$act_indent = $EMPTY_STR;
	}

	# If non_indent data, than return.
	if ($non_indent) {
		return $act_indent.$data;
	}

	# Check to actual indent maximal length.
	if (string_len($act_indent) > ($self->{'line_size'}
		- string_len($self->{'next_indent'}) - 1)) {

		err 'Bad actual indent value. Length is greater then '.
			'(\'line_size\' - \'size of next_indent\' - 1).';
	}

	# Splits data.
	my $first = undef;
	my $second = $act_indent.$data;
	my @data;
	while (string_len($second) >= $self->{'line_size'}) {
		$first = substr($second, 0, $self->{'line_size'});
		$second = $act_indent.$self->{'next_indent'}.substr($second,
			$self->{'line_size'});

		# Parsed part of data to @data array.
		push @data, $first;
	}

	# Add other data to @data array.
	if ($second && $second ne $act_indent.$self->{'next_indent'}) {
		push @data, $second;
	}

	# Return as array or one line with output separator between its.
	return wantarray ? @data : join($self->{'output_separator'}, @data);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Indent::Data - Class for data indenting.

=head1 SYNOPSIS

 use Indent::Data;
 my $indent_data = Indent::Data->new(%parameters);
 my @data = $indent_data->indent($data, [$indent, $non_indent]);

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor.

=over 8

=item * C<line_size>

 Sets indent line size value.
 Default value is 79.

=item * C<next_indent>

 Sets next indent string.
 Default value is tabelator (\t).

=item * C<output_separator>

 Sets output separator between indented datas for string context.
 Default value is newline (\n).

=back

=item C<indent($data, [$act_indent, $non_indent])>

 Indent text data to line_size block size.
 $act_indent - Actual indent string. Will be in each output string.
 Length of $act_indent variable must be less then ('line_size' - length of 'next_indent' - 1).
 $non_indent - Is flag for non indenting. Default is 0.

=back

=head1 ERRORS

 new():
         Bad 'line_size' = '%s' or length of string '%s'.
         Bad actual indent value. Length is greater then ('line_size' - 'size of next_indent' - 1).
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 indent():
         From Indent::Utils::line_size_check():
                 'line_size' parameter must be a positive number.
                         line_size => %s

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Indent::Data;

 # Indent::Data object.
 my $i = Indent::Data->new(
        'line_size' => '10',
        'next_indent' => '  ',
        'output_separator' => "|\n",
 );

 # Print indented text.
 print $i->indent('text text text text text text')."|\n";

 # Output:
 # text text |
 #   text tex|
 #   t text t|
 #   ext|

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Indent::Data;

 # Indent::Data object.
 my $i = Indent::Data->new(
        'line_size' => '10',
        'next_indent' => '  ',
        'output_separator' => "|\n",
 );

 # Print indented text.
 print $i->indent('text text text text text text', '<->')."|\n";

 # Output:
 # <->text te|
 # <->  xt te|
 # <->  xt te|
 # <->  xt te|
 # <->  xt te|
 # <->  xt|

=head1 EXAMPLE3

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Indent::Data;

 # Indent::Data object.
 my $i = Indent::Data->new(
        'line_size' => '10',
        'next_indent' => '  ',
        'output_separator' => "|\n",
 );

 # Print indented text.
 print $i->indent('text text text text text text', '<->', 1)."|\n";

 # Output:
 # <->text text text text text text|

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Indent::Utils>,
L<Readonly>.

=head1 SEE ALSO

L<Indent>,
L<Indent::Block>,
L<Indent::Comment>,
L<Indent::Utils>,
L<Indent::Word>.

=head1 REPOSITORY

L<https://github.com/tupinek/Indent>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

BSD license.

=head1 VERSION

0.03

=cut

