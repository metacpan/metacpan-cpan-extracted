# Declare our package
package Games::AssaultCube::Log::Line::FlagLost;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::FlagStole';

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return $self->nick . " lost the flag";
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords ip

=head1 NAME

Games::AssaultCube::Log::Line::FlagLost - Describes the FlagLost event in a log line

=head1 ABSTRACT

Describes the FlagLost event in a log line

=head1 DESCRIPTION

This module holds the "FlagLost" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when a client loses a flag.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 nick

The nick of the client who lost the flag

=head3 ip

The ip of the client

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
