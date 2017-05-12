package GSM::SMS::TransportRouterFactory;
use strict;
use vars qw( $VERSION );

=head1 NAME

GSM::SMS::TransportRouterFactory - router object factory

=head1 DESCRIPTION

This class instantiates a TransportRouter object of a defined type, if
available.

=cut

use Log::Agent;

=head1 METHODS

=over 4

=item B<factory> - Return the router of the specific type

=cut

sub factory {
	my ($proto, %arg) = @_;

	my $router_type = $arg{-type} || logcroak "'-type' is mandatory";
	my $router_class = 'GSM::SMS::TransportRouter::' . $router_type;

	my $transport = $arg{-transport};

	unless ( eval "require $router_class" )
	{
		my $msg = "the requested router class '$router_class' is not available : $@";
		logdbg "debug", $msg;
		logcroak $msg;
	}

	my $router_instance = $router_class->new( -transport => $transport );
	unless ( $router_instance )
	{
		logdbg "debug", "error loading router ($router_class)";
		return undef;
	}

	return $router_instance;
}

=back

=cut

1;

__END__

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
