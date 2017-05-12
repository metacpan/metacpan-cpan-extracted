# The "teaminfo" role
package Games::AssaultCube::Log::Line::Base::TeamInfo;
use Moose::Role;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

use Games::AssaultCube::Utils qw( get_team_from_name get_team_name );

has 'team' => (
	isa		=> 'Int',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return get_team_from_name( $self->team_name );
	},
);

has 'team_name' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return get_team_name( $self->team );
	},
);

sub BUILD {
	my $self = shift;
	if ( ! exists $self->{'team'} and ! exists $self->{'team_name'} ) {
		die "Team information is missing";
	}
	return;
}

1;
__END__

=for stopwords CLA RVSF
=head1 NAME

Games::AssaultCube::Log::Line::Base::TeamInfo - The TeamInfo role for subclasses

=head1 ABSTRACT

This module provides the TeamInfo role for subclasses.

=head1 DESCRIPTION

This module provides the TeamInfo role for subclasses. This is the AssaultCube team information.

=head2 Attributes

Those attributes are part of the role, and will be applied to subclasses that use this.

=head3 team

The id of the client's team

	0 = CLA
	1 = RVSF
	2 = NONE

=head3 team_name

The team name of the client ( CLA, RVSF, NONE )

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
