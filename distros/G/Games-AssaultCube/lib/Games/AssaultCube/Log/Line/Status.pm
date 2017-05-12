# Declare our package
package Games::AssaultCube::Log::Line::Status;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

# TODO improve validation for everything here, ha!

has 'datetime' => (
	isa		=> 'DateTime',
	is		=> 'ro',
	required	=> 1,
);

has 'players' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'sent' => (
	isa		=> 'Num',
	is		=> 'ro',
	required	=> 1,
);

has 'recv' => (
	isa		=> 'Num',
	is		=> 'ro',
	required	=> 1,
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return "Status: " . $self->players . " players, sent " . $self->sent . " bytes, recv " . $self->recv . " bytes at " . $self->datetime->datetime;
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords datetime kbytes sec

=head1 NAME

Games::AssaultCube::Log::Line::Status - Describes the Status event in a log line

=head1 ABSTRACT

Describes the Status event in a log line

=head1 DESCRIPTION

This module holds the "Status" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted once in a while as the AC server goes through the game.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 datetime

The DateTime object representing the time this event was logged

=head3 players

The number of connected players

=head3 sent

The number of Kbytes sent per sec ( float )

=head3 recv

The number of Kbytes sent per sec ( float )

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
