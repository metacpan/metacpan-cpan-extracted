# Declare our package
package Games::AssaultCube::Log::Line::MasterserverRequest;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

# TODO improve validation for everything here, ha!

has 'server' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return "Sending request to Masterserver " . $self->server;
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords masterserver
=head1 NAME

Games::AssaultCube::Log::Line::MasterserverRequest - Describes the MasterserverRequest event in a log line

=head1 ABSTRACT

Describes the MasterserverRequest event in a log line

=head1 DESCRIPTION

This module holds the "MasterserverRequest" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when the AC server sends a reply to the masterserver.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 server

The server we sent the request to

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
