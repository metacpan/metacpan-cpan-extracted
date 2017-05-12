# Declare our package
package Games::AssaultCube::Log::Line::AutoBalance;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

# TODO improve validation for everything here, ha!

has 'target' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'players' => (
	isa		=> 'HashRef[Int]',
	is		=> 'ro',
	required	=> 1,
);

has 'pick' => (
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
		return "Autobalance: forcing " . $self->pick . " to the other team based on target " . $self->target;
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
=head1 NAME

Games::AssaultCube::Log::Line::AutoBalance - Describes the AutoBalance event in a log line

=head1 ABSTRACT

Describes the AutoBalance event in a log line

=head1 DESCRIPTION

This module holds the "AutoBalance" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when the AC server is selecting a player to move to the other team for balancing.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 target

The target player "value" the server wants to select

=head3 players

A hashref of player connection numbers and their "value" as fields

=head3 pick

The connection number of the player the server selected for balancing

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
