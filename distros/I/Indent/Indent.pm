package Indent;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Readonly;

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};

# Version.
our $VERSION = 0.03;

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
 $indent->get;
 $indent->remove([$cur_indent]);
 $indent->reset([$reset_value]);

=head1 METHODS

=over 8

=item C<new($option =E<gt> $value)>

This is a class method, the constructor for Indent. Options are passed
as keyword value pairs. Recognized options are:

=over 8

=item * C<indent>

 Default indent.
 Default value is ''.

=item * C<next_indent>

 Next indent. Adding to internal indent variable after every add method 
 calling.
 Default value is "\t" (tabelator).

=back

=item C<add([$cur_indent])>

 Method for adding $cur_indent, if defined, or 'next_indent'.

=item C<get()>

 Get actual indent string.

=item C<remove([$cur_indent])>

 Method for removing $cur_indent, if defined, or 'next_indent'. Only if 
 is removable.

=item C<reset([$reset_value])>

 Resets internal indent string to $reset_value or ''.

=back

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

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
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

L<Indent::Block>,
L<Indent::Data>,
L<Indent::String>,
L<Indent::Utils>,
L<Indent::Word>.

=head1 REPOSITORY

L<https://github.com/tupinek/Indent>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

BSD licence.

=head1 VERSION

0.03

=cut

