package GSM::SMS::NBS::Frame;

$VERSION = '0.1';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

	my $self = {};
	bless($self, $class);
	return $self;
}


sub destination_port {
	my ($self, $dest)=@_;

	$self->{destination} = $dest;
}


sub source_port {
	my ($self, $source)=@_;

	$self->{source} = $source;
}

sub datagram_reference_number {
	my ($self, $drn)=@_;

	$self->{drn} = $drn;
}


sub fragment_maximum {
	my ($self, $fmax)=@_;

	$self->{fmax} = $fmax;
}

sub fragment_sequence_number {
	my ($self, $fsn) = @_;

	$self->{fsn} = $fsn;
}


sub asString {
	my ($self) = @_;

	my $len;
	my $out='';
	my @NBS_HEADER;

	$NBS_HEADER[0]  = 11;		# header length, without this byte
	$NBS_HEADER[1]  = 5;		# Port address information element, 16bit
	$NBS_HEADER[2]  = 4;		# 	Length of the info element
	$NBS_HEADER[3]  = ($self->{destination} & 0xff00) >> 8; 	# high byte destination
	$NBS_HEADER[4]  = $self->{destination} & 0xff;				# low byte destination
	$NBS_HEADER[5]  = ($self->{source} & 0xff00) >> 8;			# high byte source
	$NBS_HEADER[6]  = $self->{source} & 0xff; 					# low byte source
	$NBS_HEADER[7]  = 0;		# Fragmentation information element
	$NBS_HEADER[8]  = 3;		# Length of Info el
	$NBS_HEADER[9]  = $self->{drn};		# fragment id
	$NBS_HEADER[10] = $self->{fmax}; 	# max amount of frags
	$NBS_HEADER[11] = $self->{fsn};		# sequence number fragment

	$len=12;
	if ($self->{fmax} == 1) {
		$len=7;
		$NBS_HEADER[0] = 6;
	}

	for (my $j=0; $j<$len; $j++) {
		$i=$NBS_HEADER[$j];
		$out.=sprintf("%02x", $i);	
	}

	return $out;
}

1;

=head1 NAME

GSM::SMS::NBS::Frame - Encapsulates frames for NBS messages.

=head1 DESCRIPTION

Create a frame for a NBS message.

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
