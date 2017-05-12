# Declare our package
package Games::AssaultCube::Log::Line::ClientDisconnected;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

with	'Games::AssaultCube::Log::Line::Base::NickIP';

# TODO improve validation for everything here, ha!

has 'reason' => (
	isa		=> 'Str',
	is		=> 'ro',
	default		=> 'disconnected',
);

has 'forced' => (
	isa		=> 'Bool',
	is		=> 'ro',
	required	=> 1,
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return "Client " . $self->nick . " disconnected (" . $self->reason . ")";
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords ip

=head1 NAME

Games::AssaultCube::Log::Line::ClientDisconnected - Describes the ClientDisconnected event in a log line

=head1 ABSTRACT

Describes the ClientDisconnected event in a log line

=head1 DESCRIPTION

This module holds the "ClientDisconnected" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when a client disconnects from the AC server.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 nick

The nick of the client who just disconnected ( defaults to "unarmed" if not given )

=head3 ip

The ip of the client who just disconnected

=head3 reason

The reason the client disconnected ( defaults to "disconnected" if no reason given )

=head3 forced

A boolean value indicating if the server forced the disconnect or not

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
