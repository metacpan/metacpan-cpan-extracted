package GSM::SMS::Transport;
use strict;
use vars qw( $VERSION );

use Carp;
use GSM::SMS::Config;
use GSM::SMS::Spool;
use GSM::SMS::TransportRouterFactory;
use Log::Agent;

$VERSION = "0.161";

=head1 NAME

GSM::SMS::Transport - Act as a single point of access to the transports

=head1 DESCRIPTION

This class implements an object factory for the transports found in the
GSM::SMS::Transport:: namespace. Given a transport config file, it will
dynamically loads the transports and initialize them. It will keep a
reference to all instantiated transports.

=head1 METHODS

=over 4

=item B<new> - Constructor

Create a new transport layer with the settings as in the config file. 
Please look in the example config file for the transport specific 
configuration settings.

=cut

# Constructor
##########################################################################
sub new {
	my ($proto, %arg) = @_;
	my $class = ref($proto) || $proto;
	my $self = {};	

	bless($self, $class);	

	logdbg "debug", "GSM::SMS::Transport constructor called";

	$self->{_config_file} = $arg{-config_file};
	$self->{_specified_transport} = $arg{-transport};

	my $config_file = $self->{_config_file};
	my $transport = $self->{_specified_transport};

	my $config = GSM::SMS::Config->new( 
						-file 	=> $config_file,
						-check	=> 1
					 );

	if ( $transport && !$config->get_config( $transport ) ) {
		logdbg "debug", "The specified transport ($transport) is not defined in the configuration.";
		logerr "The specified transport ($transport) is not defined in the configuration.";
		return undef;
	}

	unless ( $config ) {
		logcroak("Could not load config file ($config_file)");
	}
	$self->{_config} = $config;
	
	$self->{_spool} = GSM::SMS::Spool->new( 
								-spool_dir =>  $config->get_value( undef, 'spooldir' )
								);

	my $router_type = $config->get_value( undef, 'router' );
	unless ( $self->{_router} = GSM::SMS::TransportRouterFactory->factory(
							-type => $router_type,
							-transport => $transport
							))
	{
		logcroak("Could not instantiate router of type $router_type");
	}

	# initialise transport
	$self->{"__TRANSPORTS__"} = [];
	unless ( $self->_init() ) {
		logcroak "Could not initialise all transports";
	}

	return $self;
}

=item B<send> - Send a PDU message.

Send a PDU message to the the msisdn. The transport layer will choose a transport according to the regular expression defined in the config file. This regexp matches against the msisdn.

	$transport->send( $msisdn, $pdu );

=cut

# Send
##########################################################################
sub send {
	my ($self, $msisdn, $pdu) = @_;

	my $spoolid = $self->{_spool}->add_to_spool( $msisdn, $pdu );

	my $transport = $self->_route($msisdn);
	logdbg "debug", "send [$pdu] to $msisdn on " . ref($transport);

	if ( $transport ) {
		unless ( $transport->send($msisdn, $pdu) ) {
			$self->{_spool}->remove_from_spool( $spoolid );	
			return -1;	
		}
	}
	return 0;
}

=item B<receive> - Receive a PDU message

Receive a pdu message from the transport layer. Undef when no new message available.

	$pdu = $transport->receive();

=cut

# Receive
##########################################################################
sub receive {
	my ($self) = @_;
	my $pdu;

	foreach my $transport ( $self->get_transports() ) {
		if ( $pdu = $transport->receive() ) {
			logdbg "debug", "received [$pdu] on " . ref($transport)
			                . " (" . $transport->get_name() . ")";
			return $pdu;
		}
	}
	return $pdu;
}

=item B<get_transports> - Return an array containg the transports

	@transports = $transport->get_transports();
	foreach my $i (@transports) {
		print $i->ping();
	}
	
=cut

sub get_transports {
	my $self = shift;
	return @{$self->{"__TRANSPORTS__"}};
}

=item B<add_transport> - Push a transport on the transport stack

=cut

sub add_transport {
	my ($self, $transport) = @_;

	push( @{$self->{"__TRANSPORTS__"}}, $transport );
}

=item B<get_transport_by_name> - Return a specific transport by name

  my $serial_transport = $transport->get_transport_by_name('serial01');
  $serial_transport->at("ATDT 555");

This method allows to get a reference to a specific transport object. It
can be usefull if you want to do other things with the transport. It is
especially intented for use with the serial transport, so you can do
other things with your GSM modem without the need to close the transports.

=cut

sub get_transport_by_name {
	my ($self, $name) = @_;

	my @t = $self->get_transports;
	foreach my $i (@t) {
		if ($i->get_name eq $name) {
			return $i;
		}
	}
	return undef;
}

=item B<close>

Shut down transport layer, calls the transport specific close method.

=cut

sub close {
	my $self = shift;

	logdbg "debug", "closing all transports";

	foreach my $transport ( $self->get_transports ) {
		logdbg "debug", "closing transport " . ref($transport) ." (" 
							 . $transport->get_name() . ")";
		
		$transport->close();
	}
}

=back

=cut

##########################################################################
# P R I V A T E
##########################################################################

# Route
#	Give us the handle to the correct transport to use
#	Implements the routing.
#	Routing is now only done by the 'prefix' config parameter
sub _route {
	my ($self, $msisdn) = @_;
	
	logdbg "debug", "routing ...";

	my $router = $self->{_router};

	return $router->route( $msisdn, $self->get_transports() );
}

# Init
#	Create the actual transports and initialize them
sub _init {
	my ($self) = @_;

	logdbg "debug", "Initializing transports ...";

	my $config = $self->{_config};
	
	foreach my $transport ( $config->get_section_names() ) {
		# skip default config section, rest is transports ...
		next if $transport =~ /default/;

		# get the transport config
		my $transport_config = $config->get_config( $transport);

		# determine type and corresponding class
		my $transport_type = $transport_config->{"type"};
		my $transport_class = 'GSM::SMS::Transport::' . $transport_type;
		logdbg "debug", "loading transport of class $transport_class";

		# is the class available?
		unless ( eval "require $transport_class" ) {
			my $msg = "the requested transport class '$transport_class' is not
			available : $@";

			logdbg "debug", $msg;
			logcarp $msg;
			next;
		}

		# rewrite config keys to reflect constructor attributes
		my %args = ();
		foreach my $attr ( keys %{$transport_config} ) {
			next if $attr eq $transport_type;

			$args{"-" . $attr} = $transport_config->{$attr};
		}
		# add a 'name' attribute - actually the section name
		$args{-name} = $transport;

		# instantiate the class
		my $transport_instance = $transport_class->new( %args );
		unless ( $transport_instance ) {
			logdbg "debug", "error loading transport ($transport_class)";
			return undef;
		}	
	
		# and save handle
		$self->add_transport( $transport_instance );
	}
	return 1;
}

1;

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
