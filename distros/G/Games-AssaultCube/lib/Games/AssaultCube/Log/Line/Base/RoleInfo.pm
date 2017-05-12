# the "roleinfo" role
package Games::AssaultCube::Log::Line::Base::RoleInfo;
use Moose::Role;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

use Games::AssaultCube::Utils qw( get_role_from_name get_role_name );

has 'role' => (
	isa		=> 'Int',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return get_role_from_name( $self->role_name );
	},
);

has 'role_name' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return get_role_name( $self->role );
	},
);

sub BUILD {
	my $self = shift;

	# check role
	if ( ! exists $self->{'role'} and ! exists $self->{'role_name'} ) {
		die "Role information is missing";
	}
	return;
}

1;
__END__

=for stopwords ADMIN
=head1 NAME

Games::AssaultCube::Log::Line::Base::RoleInfo - The RoleInfo role for subclasses

=head1 ABSTRACT

This module provides the RoleInfo role for subclasses.

=head1 DESCRIPTION

This module provides the RoleInfo role for subclasses. This is the AssaultCube player "role" in the game.

=head2 Attributes

Those attributes are part of the role, and will be applied to subclasses that use this.

=head3 role

The id of the client's role

	0 = DEAFULT
	1 = ADMIN

=head3 role_name

The role name of the client ( DEFAULT, ADMIN )

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
