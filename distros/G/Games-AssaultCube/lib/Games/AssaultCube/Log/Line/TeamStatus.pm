# Declare our package
package Games::AssaultCube::Log::Line::TeamStatus;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

with	'Games::AssaultCube::Log::Line::Base::TeamInfo';

# TODO improve validation for everything here, ha!

has 'players' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'frags' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'flags' => (
	isa		=> 'Int',
	is		=> 'ro',
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return "Team Status for " . $self->team_name . ": " . $self->players . " players, " . $self->frags . " frags" . ( defined $self->flags ? ", " . $self->flags . " flags" : "" );
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords CLA RVSF admin configfile frags gamemode
=head1 NAME

Games::AssaultCube::Log::Line::TeamStatus - Describes the TeamStatus event in a log line

=head1 ABSTRACT

Describes the TeamStatus event in a log line

=head1 DESCRIPTION

This module holds the "TeamStatus" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when the AC server finishes a team-based game.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 team

The id of the team

	0 = CLA
	1 = RVSF
	2 = NONE

=head3 team_name

The team name ( CLA, RVSF, NONE )

=head3 players

The number of players on this team

=head3 frags

The total number of frags for this team

=head3 flags

The total number of captured flags this team did ( not always defined - depends on gamemode )

=head3

The number of passwords loaded

=head3 configfile

The admin password config filename

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
