# Declare our package
package Games::AssaultCube::Log::Line::ClientAdmin;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

with	'Games::AssaultCube::Log::Line::Base::NickIP';

# TODO improve validation for everything here, ha!

has 'password' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'unbanned' => (
	isa		=> 'Bool',
	is		=> 'ro',
	default		=> 0,
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return $self->nick . " logged in as admin from " . $self->ip . " using password line: " . $self->password;
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords admin configfile ip

=head1 NAME

Games::AssaultCube::Log::Line::ClientAdmin - Describes the ClientAdmin event in a log line

=head1 ABSTRACT

Describes the ClientAdmin event in a log line

=head1 DESCRIPTION

This module holds the "ClientAdmin" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when a client uses the admin password to gain admin status.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 nick

The nick of the client that used admin password

=head3 ip

The ip of the client

=head3 password

The line in the admin password configfile the client used as password

=head3 unbanned

Boolean value indicating if the client unbanned themselves using the admin login

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
