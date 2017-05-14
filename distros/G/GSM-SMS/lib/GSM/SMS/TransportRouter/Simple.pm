package GSM::SMS::TransportRouter::Simple;
use strict;
use vars qw( $VERSION );

=head1 NAME

GSM::SMS::TransportRouter::Simple - A simple router

=head1 DESCRIPTION

Iterates over the transports until one return true on the I<has_valid_route>
method.

=cut

$VERSION = "0.161";

use base qw( GSM::SMS::TransportRouter::TransportRouter );
use Log::Agent;

=head1 METHODS

=over 4

=item B<route> - the route method

  $transport = $router->route( $msisdn, @transport_list );

=cut

sub route {
	my($self, $msisdn, @transport_list) = @_;

	logdbg "debug", "called Simple->route( $msisdn )";

	foreach my $transport ( @transport_list ) {

		if ( $self->get_transport() ) {
			logdbg "debug", "A specific transport (" . $self->get_transport() .
			                ") has been defined.";
			
			unless ( $self->get_transport() eq $transport->get_name() ) {
				logdbg "debug", "Only the specified transport is allowed to route messages, not this transport (" . 
					 $transport->get_name() . ").";
				next;
			}
		}
	
		logdbg "debug", 
			sprintf( "we received a %d from %s", 
						$transport->has_valid_route($msisdn),
						$transport->get_name()
				   );

		if ( $transport->has_valid_route($msisdn) ) {
			logdbg "debug", "route on " 
					 . ref($transport) 
					 . " ( " . $transport->get_name() . ")";
			return $transport;
		}
	}
	return undef;
}

=back

=cut

1;

__END__

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
