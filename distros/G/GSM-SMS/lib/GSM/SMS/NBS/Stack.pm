package GSM::SMS::NBS::Stack;
use GSM::SMS::PDU;
use Data::Dumper;

$VERSION = '0.1';

# $__NBSSTACK_PRINT++;

# Keep the packets alive for 1 day 
$__TIME_TO_LIVE = 60*60*24;

# Constructor
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
 
    my $self = {};
	$self->{STACK} = {};
	my %arg = @_;
	$self->{TRANSPORT} = $arg{"-transport"};

    bless($self, $class);
    return $self;
}   

# receive NBS/SMS messages
sub receive {
	my ($self, $ref_oa, $ref_msg, $ref_timestamp, $ref_transport, $ref_port, $block) =@_;

	my ($stack) = $self->{STACK};
	my $t = $self->{TRANSPORT};

	$self->_prt( "entering receive" );

 	while ($self->_complete_message_on_stack($stack, $ref_oa, $ref_msg, $ref_timestamp, $ref_transport, $ref_port)) {	
		
		$self->_prt( "CHECK\n" );

		# look for new datagrams on the stack
		foreach my $transporter ( $t->get_transports() ) {
			$self->_prt( "x" );
			$self->_prt( "T: " . $transporter->get_name() . "\n" );
			my $pdu;
			if (!$transporter->receive(\$pdu)) {
				$self->_prt(  "SOMETHING\n" );
				$self->_place_message_on_stack($stack, $pdu, $transporter->get_name());
				$self->_prt( "RCV: $pdu\n" );	
			}
		}	
		# Do some garbage collection -> when a datagram is not complete after a certain time frame
		# +/- 2h then delete this datagram from the stack! (Long living stack with 'dead' messages.
		$self->_garbage_collect($stack);

		select(undef, undef, undef, 0.25);
		return -1 unless $block;
		$self->_prt( "BLOCKING LOOP" );
	}
	return 0;
}

sub _complete_message_on_stack {
	my ($self, $stack, $ref_oa, $ref_msg, $ref_timestamp, $ref_transport, $ref_port) = @_;
	my ($message, $complete, $msisdn, $timestamp, $transport, $port);
	my ($oa_del, $dg_del);

	$self->_prt( "IN ($stack)\n" );

	foreach my $i (keys %$stack) {
		my $oa = $stack->{$i};
		$self->_prt( $oa."\n" );
		$oa_del = $i;
		foreach my $j (keys %$oa) {
			my $dg = $oa->{$j};
			$dg_del = $j;	
						
			# $dg is a datagram ref with ->{Fragments} = $PDU / ->{Timestamp} = time
			# Check if we need to kill this datagram -> TTL expired
			if ( (time - $dg->{Timestamp}) > $__TIME_TO_LIVE) {
				$self->_prt( "TTL expired!\n" );
				$self->_prt( $__TIME_TO_LIVE );
				$self->_prt( $dg->{Timestamp} );
				$self->_prt( "------------------" );			
				delete $oa->{$j};
				next;
			}

			my $decoded_pdu = $dg->{Fragments}->[1];
			
			if ($decoded_pdu) {
				$port = $decoded_pdu->{'TP-DPORT'};
				$msisdn = $decoded_pdu->{'TP-OA'};	
				$message= $decoded_pdu->{'TP-UD'};
				$timestamp= $decoded_pdu->{'TP-SCTS'};
				$transport  = $decoded_pdu->{'XTRA-TRANSPORT'};
			}	

			if ($decoded_pdu && $decoded_pdu->{'TP-DPORT'}) {
				$self->_prt( "PORT!\n" );
				$self->_prt( "-> " . $decoded_pdu->{'TP-DPORT'} ."\n" );
				# We have a UDHI header structure here
				my $l = $decoded_pdu->{'TP-FRAGMAX'};
				$msisdn = $decoded_pdu->{'TP-OA'};
				
				# assume complete ... 
				$complete++;
				for (my $cnt=1; $cnt<=$l; $cnt++) {
					if ($dg->{Fragments}->[$cnt]) {
						$self->_prt( "CNT $cnt passed\n" );
						my $frag = $dg->{Fragments}->[$cnt];
						$message.=$frag->{'TP-UD'};	# When having text headers '//SCK', we concatenate also the //SCK for the moment
												# we need a revision here for PDU.pm to solve this 
						$self->_prt( "[[".$frag->{'TP-UD'}."]]\n" );
					} else {
							$complete = undef;
					}
				}
			}

			if ($decoded_pdu && !$decoded_pdu->{'TP-DPORT'}) {
				# We have a simple sms message
				$self->_prt( "SIMPLE\n" );
				$msisdn 	= $decoded_pdu->{'TP-OA'};	
				$message 	= $decoded_pdu->{'TP-UD'};
				$timestamp 	= $decoded_pdu->{'TP-SCTS'};
				$transport  = $decoded_pdu->{'XTRA-TRANSPORT'};
				$complete++;
			}
			last if ($complete);
		}
		last if ($complete);
	}
	if ($complete) {
		# Communicate message to caller
		$$ref_oa  = $msisdn;
		$$ref_msg = $message;
		$$ref_timestamp = $timestamp;
		$$ref_transport = $transport;
		$$ref_port = $port;

		# delete reference
		$self->_prt( "delete $oa_del, $dg_del :::::>>>>> ".$stack->{$oa_del}->{$dg_del}->{Fragments}->[1]->{'TP-UD'} );
		$self->_prt( "\n" );

		delete $stack->{$oa_del}->{$dg_del};
		return 0;
	}
	return -1;
}


sub _place_message_on_stack {
	my ($self, $stack, $msg, $transport) = @_;

	my $p = GSM::SMS::PDU->new();
	my $decoded_pdu = $p->SMSDeliver($msg);

	my $oa = $decoded_pdu->{'TP-OA'};
	my $dg = $decoded_pdu->{'TP-DATAGRAM'}	|| 1;
	my $id = $decoded_pdu->{'TP-FRAGSQN'}	|| 1;


	# a "hack" to add the name of the transport to the stack

	$decoded_pdu->{'XTRA-TRANSPORT'} = $transport;

	if (!$stack->{$oa}) {				# Create a new datagram on the 'stack'
		$stack->{$oa} = {};
		$stack->{$oa}->{$dg} = {};
		$stack->{$oa}->{$dg}->{Fragments} = [];
		$stack->{$oa}->{$dg}->{Timestamp} = undef;
	}
	$self->_prt( "[$oa][$dg][$id]\n" );

	$stack->{$oa}->{$dg}->{Fragments}->[$id] = $decoded_pdu;
	$stack->{$oa}->{$dg}->{Timestamp} = time;	# update timestamp
}


sub _garbage_collect {
	my ($self, $stack) = @_;

	# I implemented the garbage collect intrinsic on the _complete_message on stack
	# It will kill of messages on the stack with an old timestamp ( > delta_time )

}

sub _prt {
	my ($self, $txt) = @_;

	print $txt  if ($__NBSSTACK_PRINT);
}

1;

=head1 NAME

GSM::SMS::NBS::Stack - Narrow Bandwidth Socket protocol stack.

=head1 DESCRIPTION

Implements the Reassmbly part for the NBS messages.

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
