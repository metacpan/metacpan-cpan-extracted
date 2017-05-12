package Lego::Part::Transfer;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);

# Version.
our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	# Object.
	return $self;
}

# Convert element to design.
sub element2design {
	my ($self, $part) = @_;
	$self->_check_part($part);
	err "This is abstract class. element2design() method not implemented.";
	return;
}

# Convert design to element.
sub design2element {
	my ($self, $part) = @_;
	$self->_check_part($part);
	err "This is abstract class. design2element() method not implemented.";
	return;
}

# Check part class.
sub _check_part {
	my ($self, $part) = @_;
	if (! blessed($part) || ! $part->isa('Lego::Part')) {
		err "Part must be Lego::Part object.";
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Lego::Part::Transfer - Lego part transfer abstract class.

=head1 SYNOPSIS

 use Lego::Part::Transfer;
 my $obj = Lego::Part::Transfer->new;
 $obj->element2design($part);
 $obj->design2element($part);

=head1 METHODS

=over 8

=item * C<new()>

 Constructor.
 Returns object.

=item * C<element2design($part)>

 Convert element to design.
 Returns undef.

=item * C<design2element($part)>

 Convert design to element.
 Returns undef.

=back

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<Task::Lego>

Install the Lego modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Lego-Part>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2013-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.03

=cut
