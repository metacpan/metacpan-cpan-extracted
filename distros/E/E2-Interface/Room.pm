# E2::Room.pm
# Jose M. Weeks <jose@joseweeks.com>
# 05 June 2003
#
# See bottom for pod documentation.

package E2::Room;

use 5.006;
use strict;
use warnings;
use Carp;

use E2::Node;

our @ISA = "E2::Node";
our $VERSION = "0.32";
our $DEBUG; *DEBUG = *E2::Interface::DEBUG;

# Prototypes

sub new;
sub clear;

sub description;
sub can_enter;

# Private

sub type_as_string;
sub twig_handlers;

# Object Methods

sub new {
	my $arg   = shift;
	my $class = ref( $arg ) || $arg;
	my $self  = $class->SUPER::new();

	# See clear for the other members of $self

	$self->clear;
	return $self;
}

sub clear {
	my $self = shift	or croak "Usage: clear E2USERGROUP";

	warn "E2::Room::clear\n"	if $DEBUG > 1;

	$self->{description}	= undef;
	$self->{can_enter}	= undef;

	# Now clear parent

	return $self->SUPER::clear;
}

sub twig_handlers {
	my $self = shift or croak "Usage: twig_handlers E2USERGROUP";

	return (
		'description' => sub {
			(my $a, my $b) = @_;
			$self->{description} = $b->text;
		},
		'canenter' => sub {
			(my $a, my $b) = @_;
			$self->{can_enter} = $b->text;
		}
	);
}			

sub type_as_string {
	return 'room';
}

sub description {
	my $self = shift	or croak "Usage: description E2ROOM";
	return $self->{description};
}

sub can_enter {
	my $self = shift	or croak "Usage: can_enter E2ROOM";
	return $self->{can_enter};
}

1;
__END__
		
=head1 NAME

E2::Room - A module for loading rooms on L<http://everything2.com>.

=head1 SYNOPSIS

	use E2::Room;

	my $room = new E2::Room;

	$room->login( "username", "password" ); # See E2::Interface

	if( $room->load( "test" ) ) {                       # See E2::Node
		print 'Room name: ' . $room->title;         # See E2::Node
		print '\nDescription: . $group->description;
		print '\nYou ' . 
			($room->can_enter ? "can" : "can't") .
			"enter.\n";
	}

=head1 DESCRIPTION

This module provides access to L<http://everything2.com>'s rooms. It inherits L<E2::Node|E2::Node>.

=head1 CONSTRUCTOR

=over

=item new

C<new> creates a new C<E2::Room> object. Until that object is logged in in one way or another (see L<E2::Interface>), it will use the "Guest User" account.

=back

=head1 METHODS

=over

=item $room-E<gt>clear

C<clear> clears all the information currently stored in $room.

=item $room-E<gt>description

This method returns the description string of the currently-loaded room. It returns C<undef> if no usergroup is loaded.

=item $room-E<gt>can_enter

This method returns a boolean value: whether or not the currently-logged-in user can enter this room.

=back

=head1 SEE ALSO

L<E2::Interface>,
L<E2::Node>,
L<http://everything2.com>,
L<http://everything2.com/?node=clientdev>

=head1 AUTHOR

Jose M. Weeks E<lt>I<jose@joseweeks.com>E<gt> (I<Simpleton> on E2)

=head1 COPYRIGHT

This software is public domain.

=cut
