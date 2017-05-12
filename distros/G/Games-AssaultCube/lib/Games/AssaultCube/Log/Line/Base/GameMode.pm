# the gamemode role
package Games::AssaultCube::Log::Line::Base::GameMode;
use Moose::Role;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

use Games::AssaultCube::Utils qw( get_gamemode_from_name get_gamemode_from_fullname get_gamemode_name get_gamemode_fullname );

has 'gamemode' => (
	isa		=> 'Int',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		if ( exists $self->{'gamemode_name'} ) {
			return get_gamemode_from_name( $self->gamemode_name );
		} else {
			return get_gamemode_from_fullname( $self->gamemode_fullname );
		}
	},
);

has 'gamemode_name' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return get_gamemode_name( $self->gamemode );
	},
);

has 'gamemode_fullname' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return get_gamemode_fullname( $self->gamemode );
	},
);

sub BUILD {
	my $self = shift;

	# check role
	if ( ! exists $self->{'gamemode'} and ! exists $self->{'gamemode_name'} and ! exists $self->{'gamemode_fullname'} ) {
		die "Gamemode information is missing";
	}
	return;
}

1;
__END__

=for stopwords CTF TDM gamemode
=head1 NAME

Games::AssaultCube::Log::Line::Base::GameMode - The GameMode role for subclasses

=head1 ABSTRACT

This module provides the GameMode role for subclasses.

=head1 DESCRIPTION

This module provides the GameMode role for subclasses. This is the AssaultCube game mode.

=head2 Attributes

Those attributes are part of the role, and will be applied to subclasses that use this.

=head3 gamemode

The numeric AssaultCube gamemode ( look at L<Games::AssaultCube::Utils> for more info )

P.S. It's better to use the gamemode_fullname or gamemode_name accessors

=head3 gamemode_name

The gamemode name ( CTF, TDM, etc )

=head3 gamemode_fullname

The full gamemode name ( "capture the flag", "team one shot one kill", etc )

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
