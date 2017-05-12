package GSM::SMS::TransportRouter::TransportRouter;
use strict;
use vars qw( $VERSION );

=head1 NAME

GSM::SMS::TransportRouter::TransportRouter - Abstract router class

=head1 DESCRIPTION

An abstract TransportRouter base class. All concrete transport routers must
inherit from this class.

=cut

use Log::Agent;

=head1 METHODS

=over 4

=item B<new> - constructor

=cut

sub new {
	my ( $proto, %arg ) = @_;
	my $class = ref($proto) || $proto;

	logdbg "debug", "$class constructor called";

	bless { _transport => $arg{-transport} }, ref($proto) || $proto;
}

=item B<route> - the actual router method

  $route = $tr->route( $msisdn, @transport_list );

  Return 'undef' when no route found.

  ABSTRACT METHOD - needs to be implemented.

=cut

sub route {
	my ($self) = @_;

	my $object_class = ref($self);
	my ($file, $line, $method) = (caller(1))[1..3];
	die "Call to abstract method ${method} at $file, line $line\n";
}	

=item B<get_transport>

When an explicit transport has been given to the constructor, we'll only
try to route through this transport. This method can be used to get the name
of that specific transport.

=cut

sub get_transport { return $_[0]->{_transport}; }

=back

=cut


1;

__END__

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
