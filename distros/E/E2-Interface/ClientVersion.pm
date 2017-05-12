# E2::ClientVersion
# Jose M. Weeks <jose@joseweeks.com>
# 05 June 2003
#
# See bottom for pod documentation.

package E2::ClientVersion;

use 5.006;
use strict;
use warnings;
use Carp;

use E2::Ticker;
use XML::Twig;

our $VERSION = "0.31";
our @ISA = qw(E2::Ticker);
our $DEBUG; *DEBUG = *E2::Interface::DEBUG;

sub new;

sub update;

sub clients;

sub new { 
	my $arg   = shift;
	my $class = ref( $arg ) || $arg;
	my $self  = $class->SUPER::new();

	$self->{clients} = {};

	return bless ($self, $class);
}


sub clients {
	my $self = shift	or croak "Usage: clients E2CLIENTVERSION";
	return $self->{clients};
}

sub update {
	my $self = shift or croak "Usage: update E2CLIENTVERSION";

	warn "E2::ClientVersion::Update\n"	if $DEBUG > 1;

	my $handlers = {
		'client' => sub {
			(my $a, my $b) = @_;
			my %client;

			$client{name} = $b->{att}->{client_class};
			$client{id}   = $b->{att}->{client_id};
			$client{version} =
				$b->first_child('version')->text;
			$client{homepage} =
				$b->first_child('homepage')->text;
			$client{download} =
				$b->first_child('download')->text;

			my $c = $b->first_child('maintainer');
			$client{maintainer} = $c->text;
			$client{maintainer_id} = $c->{att}->{node_id};

			$self->{clients}->{$client{name}} = \%client;
		}
	};

	$self->{clients} = {};

	return $self->parse(
		'clientversions',
		$handlers,
		[ 1 ]
	);
}

1;
__END__

=head1 NAME

E2::ClientVersion - Load client version information from everything2.com

=head1 SYNOPSIS

	use E2::ClientVersion;

	my $client = new E2::ClientVersion;

	$client->update;

	my $c = $client->clients;


	# Print the current and available version of e2interface

	my $ver   = $client->version;        # See E2::Interface;
	my $name  = $client->client_name;    # See E2::interface;

	print "We are using $name/$ver.";
	print "\nThe newest available version of $name is ";
	print $c->{$name}->{version};


	# List all registered e2 clients and their version numbers

	print "\n\nRegistered e2 clients:\n";
	foreach( keys %$c ) {
		print "$_: " . $c->{$_}->{version} . "\n";
	}


=head1 DESCRIPTION

This module allows a user to load his session information
This module provides an interface to everything2.com's search interface. It inherits L<E2::Ticker|E2::Ticker>.

=head1 CONSTRUCTOR

=over

=item new

C<new> creates an C<E2::Session> object.

=back

=head1 METHODS

=over

=item $client-E<gt>update

This method fetches the list of registered clients from e2.

=item $client-E<gt>clients

This metod returns a hashref to the information about registered clients on e2. The keys to this hashref are the names of the available clients, and the values are hashrefs to information about the clients with the following keys:

	name		# The client's name
	id		# The node_id of the client's superdoc
	version		# The most recent version of the client
	homepage	# The homepage of the client (URL)
	download	# The download page of the client (URL)
	maintainer	# The username of the client's maintainer
	maintainer_id	# The node_id of the client's maintainer

Example code:

	my $c = $client->clients;

	print $c->{e2client}->{version} # Prints the version number of 'e2client'

=back

=head1 SEE ALSO

L<E2::Interface>,
L<E2::Ticker>,
L<http://everything2.com/?node=clientdev>,
L<http://everything2.com/?node=e2interface>

=head1 AUTHOR

Jose M. Weeks E<lt>I<jose@joseweeks.com>E<gt> (I<Simpleton> on E2)

=head1 COPYRIGHT

This software is public domain.

=cut
