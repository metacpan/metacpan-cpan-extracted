# Declare our package
package Games::AssaultCube::Log::Line::MasterserverReply;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

# TODO improve validation for everything here, ha!

has 'reply' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'success' => (
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
		return "Masterserver reply(" . ( $self->success ? "OK" : "FAIL" ) . "): " . $self->reply;
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords masterserver
=head1 NAME

Games::AssaultCube::Log::Line::MasterserverReply - Describes the MasterserverReply event in a log line

=head1 ABSTRACT

Describes the MasterserverReply event in a log line

=head1 DESCRIPTION

This module holds the "MasterserverReply" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when the AC server receives a reply from the masterserver.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 reply

The text of the reply from the masterserver

=head3 success

A boolean value indicating if the request was successful or not

NOTE: We don't know every possible reply, so it assumes success for the ones we can't parse!

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
