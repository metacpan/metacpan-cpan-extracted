# Declare our package
package Games::AssaultCube::Log::Line::FlagReset;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

with	'Games::AssaultCube::Log::Line::Base::TeamInfo';

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return "The server reset the " . $self->team_name . " flag";
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords CLA RVSF
=head1 NAME

Games::AssaultCube::Log::Line::FlagReset - Describes the FlagReset event in a log line

=head1 ABSTRACT

Describes the FlagReset event in a log line

=head1 DESCRIPTION

This module holds the "FlagReset" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when the server resets a flag for a team.

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

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
