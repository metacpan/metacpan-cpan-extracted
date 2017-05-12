package GSM::SMS::NBS::Message;
use	GSM::SMS::PDU;
use GSM::SMS::NBS::Frame;

$VERSION = '0.1';

use constant DATAGRAM_LENGTH => 128;

# SAR for NBS messages
# --------------------
# This part does the segmentation ... look in Stack.pm for reassembly

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {};
	$self->{'__FRAMES__'} = [];

	bless($self, $class);
	return $self;
}

# Create a message from a payload
sub create {
	my ($self, $number, $payload, $destination_port, $source_port, $datacodingscheme) = @_;

	# Reset the FRAME array
	$#{$self->{'__FRAMES__'}} = -1;


	my $nbs = GSM::SMS::NBS::Frame->new();
	my $pdu = GSM::SMS::PDU->new();

	my $datagram_length = DATAGRAM_LENGTH;

	$source_port = $destination_port if (!defined($source_port));
	my $dcs = '7bit';
	$dcs = '8bitm' if (defined($destination_port));
	
	# print "DATACODINGSCHEME: $datacodingscheme\n";
		
	$dcs = $datacodingscheme if (defined($datacodingscheme));

	my $udhi = -1;	
	$udhi = 0 if (!defined($destination_port));


    my $payload_len = length($payload)/2;
	my $frags;

	# test if the payload can fit in one message (6= length of minimal header)
	if (($payload_len + 6) <= 140) {
		# Ok we can have 1 message
		$frags=1;
		$datagram_length = $payload_len;
	} else {
    	$frags = int($payload_len/$datagram_length) + 1;
	}

    $nbs->destination_port($destination_port);
    $nbs->source_port($source_port);
	
	# If no destination port defined, then also no source port can be defined
	# There can be a problem ! what if 2 nbs's send a nbs to the same phone with 2 the same datagrams?
	# We have to solve this!
	$nbs->datagram_reference_number(int(rand(255)));
    $nbs->fragment_maximum($frags);

	my $ok = 0; 
    for (my $i=1; $i<=$frags; $i++) {
        my $subload = substr($payload, ($i-1)*$datagram_length*2, $datagram_length*2);
        $nbs->fragment_sequence_number($i);
		my $msg;
		if ($destination_port) {        
			$msg = uc $nbs->asString().$subload;
		} else {
			$msg = $subload;
		}
		# print "DCS-> $dcs\n";
        my $p =  $pdu->SMSSubmit('', $number, $msg, $dcs, '1d', $udhi);
  	# print "--> $p\n"; 
		# Push on to frame array
		push(@{$self->{'__FRAMES__'}}, $p );
   
	}     	
	return 0 if ($ok == $frags);
	return -1;
}

# Return the frames
sub get_frames {
	my $self = shift;
	return $self->{'__FRAMES__'};
}


1;

=head1 NAME

GSM::SMS::NBS::Message - SAR functionality for NBS messages.

=head1 DESCRIPTION

Implements the segmentation in the SAR engine ( Segmentation And Reassembly ).

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
