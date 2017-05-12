# Declare our package
package Games::AssaultCube::Log::Line::ScoreboardStart;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return "Starting Scoreboard";
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
=head1 NAME

Games::AssaultCube::Log::Line::ScoreboardStart - Describes the ScoreboardStart event in a log line

=head1 ABSTRACT

Describes the ScoreboardStart event in a log line

=head1 DESCRIPTION

This module holds the "ScoreboardStart" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when the AC server starts to print it's scoreboard.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

No extra attributes.

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
