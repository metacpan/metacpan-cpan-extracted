package Indent;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Readonly;

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};

our $VERSION = 0.08;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Default indent.
	$self->{'indent'} = $EMPTY_STR;

	# Every next indent string.
	$self->{'next_indent'} = "\t";

	# Process params.
	set_params($self, @params);

	# Check to 'next_indent' parameter.
	if (! defined $self->{'next_indent'}) {
		err "'next_indent' parameter must be defined.";
	}
	if (ref $self->{'next_indent'}) {
		err "'next_indent' parameter must be a string.";
	}

	# Check to 'indent' parameter.
	if (! defined $self->{'indent'}) {
		err "'indent' parameter must be defined.";
	}
	if (ref $self->{'indent'}) {
		err "'indent' parameter must be a string.";
	}

	# Object.
	return $self;
}

# Add an indent to global indent.
sub add {
	my ($self, $indent) = @_;
	if (! defined $indent) {
		$indent = $self->{'next_indent'};
	}
	$self->{'indent'} .= $indent;
	return 1;
}

# Get a indent value.
sub get {
	my $self = shift;
	return $self->{'indent'};
}

# Remove an indent from global indent.
sub remove {
	my ($self, $indent) = @_;
	if (! defined $indent) {
		$indent = $self->{'next_indent'};
	}
	my $indent_length = length $indent;
	if (substr($self->{'indent'}, -$indent_length) ne $indent) {
		err "Cannot remove indent '$indent'.";
	}
	$self->{'indent'} = substr $self->{'indent'}, 0, -$indent_length;
	return 1;
}

# Reseting indent.
sub reset {
	my ($self, $reset_value) = @_;
	if (! defined $reset_value) {
		$reset_value = $EMPTY_STR;
	}
	$self->{'indent'} = $reset_value;
	return 1;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Indent - Class for indent handling.

=head1 SYNOPSIS

 use Indent;

 my $indent = Indent->new(%parameters);
 $indent->add([$cur_indent]);
 my $string = $indent->get;
 $indent->remove([$cur_indent]);
 $indent->reset([$reset_value]);

=head1 METHODS

=head2 C<new>

 my $indent = Indent->new(%parameters);

Constructor.

Returns instance of object.

=over 8

=item * C<indent>

 Default indent.
 Default value is ''.

=item * C<next_indent>

 Next indent. Adding to internal indent variable after every add method
 calling.
 Default value is "\t" (tabelator).

=back

=head2 C<add>

 $indent->add([$cur_indent]);

Method for adding C<$cur_indent>, if defined, or 'next_indent'.

Returns undef.

=head2 C<get>

 my $string = $indent->get;

Get actual indent string.

Returns string.

=head2 C<remove>

 $indent->remove([$cur_indent]);

Method for removing C<$cur_indent>, if defined, or 'next_indent'. Only if
is removable.

Returns undef.

=head2 C<reset>

 $indent->reset([$reset_value]);

Resets internal indent string to C<$reset_value> or ''.

Returns undef.

=head1 ERRORS

 new():
         'next_indent' parameter must be defined.
         'next_indent' parameter must be a string.
         'indent' parameter must be defined.
         'indent' parameter must be a string.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 remove():
         Cannot remove indent '$indent'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Indent;

 # Indent object.
 my $indent = Indent->new(

        # Begin indent.
        'indent' => '->',

        # Next indent.
        'next_indent' => "->"
 );

 # Print example.
 print $indent->get;
 print "Example\n";

 # Add indent and print ok.
 $indent->add;
 print $indent->get;
 print "Ok\n";

 # Remove indent and print nex example.
 $indent->remove;
 print $indent->get;
 print "Example2\n";

 # Reset.
 $indent->reset;

 # Output:
 # ->Example
 # ->->Ok
 # ->Example2

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Readonly>.

=head1 SEE ALSO

=over

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

