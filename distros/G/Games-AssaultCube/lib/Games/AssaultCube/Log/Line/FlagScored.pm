# Declare our package
package Games::AssaultCube::Log::Line::FlagScored;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::FlagStole';

with	'Games::AssaultCube::Log::Line::Base::TeamInfo';

# TODO improve validation for everything here, ha!

has 'score' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return $self->nick . " scored the flag for team " . $self->team_name . " with score " . $self->score;
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords CLA RVSF ip

=head1 NAME

Games::AssaultCube::Log::Line::FlagScored - Describes the FlagScored event in a log line

=head1 ABSTRACT

Describes the FlagScored event in a log line

=head1 DESCRIPTION

This module holds the "FlagScored" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when a client scores a flag for a team.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 nick

The nick of the client who scored the flag

=head3 ip

The ip of the client

=head3 team

The id of the client's team

	0 = CLA
	1 = RVSF
	2 = NONE

=head3 team_name

The team name of the client ( CLA, RVSF, NONE )

=head3 score

The new score for the team

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
