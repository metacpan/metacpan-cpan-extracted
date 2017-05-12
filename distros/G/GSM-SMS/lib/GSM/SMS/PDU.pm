package GSM::SMS::PDU;
use strict;
use vars qw( $VERSION );
# (c) 1999 tektonica
# author: Johan Van den Brande 

$VERSION = '0.1';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

	my $self = {};
	$self->{TPDU} = {};
	bless($self, $class);
	return $self;
}

sub SMSDeliver {
	my ($self, $data) = @_;
	my $tpdu = $self->{TPDU};
	my @msg = split //, $data;
	
	###########################################################################
	# 1) Get SERVICE CENTER ADDRESS 
	# -------------------------------------------------------------------------
	# Structure:	(n) = number of octets
	# +-----------+-------------------+------------------+
	# | length(1) | type of number(2) | BCD digits(0..8) |
	# +-----------+-------------------+------------------+
	#	length :
	#		number of octets for BCD + 1 octet for type of number
	#	type of number :
	#		81H	:	national number (e.g. 0495123456)
	#		91H : 	international number (e.g. 32495123456 => need to prepend a '+')	 
	#	BCD:
	#		If the number of BCD octets is odd, the last digit shall be filled with an end
	#		mark, coded as FH (H = Hex ...)
	#		Every Octet get's splitted in 2 nibbles. Per octet we need to swap the nibbles to get
	#		the correct order.
	# -------------------------------------------------------------------------
	$tpdu->{'TP-SCN'} = $self->getServiceCenterAddress(\@msg);
	###########################################################################
	
	###########################################################################
	# 2) Get PDU type
	# -------------------------------------------------------------------------
	# Structure: (n) = bits
	# +--------+----------+---------+-------+-------+--------+
	# | RP (1) | UDHI (1) | SRI (1) | X (1) | X (1) | MTI(2) |
	# +--------+----------+---------+-------+-------+--------+
	#	RP:
	#		Reply path
	#	UDHI:
	#		User Data Header Indicator = Does the UD contains a header
	#		0 : Only the Short Message
	#		1 : Beginning of UD containsheader information
	#	SRI:
	#		Status Report Indication.
	#		The SME (Short Message Entity) has requested a status report.
	#	MTI:
	#		00 for SMS-Deliver
	#
	# -------------------------------------------------------------------------	
	$tpdu->{'TP-PDU'} = $self->getoctet(\@msg);
	###########################################################################
	
	###########################################################################
	# 3) Get originating address
	# -------------------------------------------------------------------------
	# Structure:	(n) = number of octets
	# +-----------+-------------------+------------------+
	# | length(1) | type of number(2) | BCD digits(0..10) |
	# +-----------+-------------------+------------------+
	#	length :
	#		number of BCD digits 	(This is different for the SCN!)
	#	type of number :
	#		81H	:	national number (e.g. 0495123456)
	#		91H : 	international number (e.g. 32495123456 => need to prepend a '+')	 
	#	BCD:
	#		If the number of BCD octets is odd, the last digit shall be filled with an end
	#		mark, coded as FH (H = Hex ...)
	#		Every Octet get's splitted in 2 nibbles. Per octet we need to swap the nibbles to get
	#		the correct order.
	# -------------------------------------------------------------------------	
	$tpdu->{'TP-OA'} = $self->getOriginatingAddress(\@msg);

	###########################################################################
	# 4) Get Protocol identifier (PID)
	# -------------------------------------------------------------------------
	# Structure:
	#	XXH
	#		00H:	Short Message (SMS) 
	#		41H:	Replace Short Message Type1
	#		...
	#		47H:	Replace Short Message Type7
	#		Can be used to replace previously sent SMS messgaes in the MS (Mobile Station)
	# -------------------------------------------------------------------------	
	$tpdu->{'TP-PID'} = $self->getoctet(\@msg);
	###########################################################################	
	
	###########################################################################
	# 5) Get data coding scheme
	# -------------------------------------------------------------------------
	# Structure:
	#	bits	    7 6 5 4      3   2   1   0
	#           +--------------+---+---+---+---+
	#			| Coding group | 0 | X | X | X |	
	#           +--------------+---+---+---+---+	
	# Examples:
	#				0 0 0 0      0   0   0   0		: 00H	: 7-bit datacoding, default alphabet
	#				1 1 1 1      0   1   1   0		: F6H	: 8-bit datacoding Class 2
	#
	# Coding group	 |	Alphabet indication
	# ---------------+---------------------------------------------------------
	# 	0000         | 0000		Default alphabet
	#                | 0001		Reserved
	#                | ...		"    " 
	#                | 1111		"    "
	# ---------------+---------------------------------------------------------
	#   0001-1110    | Reserved coding groups
	# ---------------+---------------------------------------------------------
	#   1111		 | bit 3 		: Reserved, always 0
	#                | bit 2 		: Data Coding
	#				 |					0	:	Default alphabet (7bit)
	#				 |					1	:	8 bit encoding INTEL-ASCII
	#                | bits 1 0 	: Message Class
	#                |					0 0	:	Class 0, immedidate display
	#                |                  0 1 :	Class 1, ME specific	(Mobile Equiment)
	#				 |					1 0 :	Class 2, SIM specific	
	#				 |					1 1 :	Class 3, TE specific    (Terminate Equipment)
	# ---------------+---------------------------------------------------------
	#   We have 2 possible ways of interpreting this for our SMS software
	#	7 bit default alphabet	:	00000000	111100xx
	#	8 bit intel-ascii       :	111101xx
	#		x being a wild card
	###########################################################################
	$tpdu->{'TP-DCS'} = $self->getoctet(\@msg);
	
	###########################################################################
	# 6) Get service center timestamp
	# -------------------------------------------------------------------------
	# Structure:
	#	Octets: 1      1      1      1      1         1         1 
	#   	+------+-------+-----+------+--------+--------+-----------+
	#		| YEAR | MONTH | DAY | HOUR | MINUTE | SECOND | TIME ZONE | (2 1), means
	#       | (2 1)| (2 1) |(2 1)| (2 1)|  (2 1) |  (2 1) |    (2 1)  | nibbles need to
	#       +------+-------+-----+------+--------+--------+-----------+ be swapped for correct order
	#  The TIMEZONE indicates difference in quarters of an hour, between the
	#  local time and Greenwhich Main Time (GMT)
	###########################################################################
	$tpdu->{'TP-SCTS'} = $self->getoctet(\@msg, 7, 1);
	###########################################################################
	
	###########################################################################
	# 7) Get User Data (UDL) and decode
	# -------------------------------------------------------------------------
	# We need to decode according to the DCS.
	$tpdu->{'TP-UDL'} = hex($self->getoctet(\@msg));

 	#   We have 2 possible ways of interpreting this for our SMS software
	#	7 bit default alphabet	:	00000000	111100xx
	#	8 bit intel-ascii       :	111101xx
	#		x being a wild card
	my $dcs = hex($tpdu->{'TP-DCS'});
	if ($dcs == 0) { 	
		# decode 7 bit
		$tpdu->{'TP-UD'} = $self->decode_7bit(join("", @msg), $tpdu->{'TP-UDL'});
		# translate to default alphabet
		$tpdu->{'TP-UD'} = $self->translate($tpdu->{'TP-UD'});
		
		# Do we have NBS with Text based headers?
		my $ud = $tpdu->{'TP-UD'};
		if (substr($ud, 0, 5) eq '//SCK') {
			# print "We have a text encoded NBS\n";
			$tpdu->{'TP-SCK'}++;
			if ($ud=~/\/\/SCK(\w\w)(\w\w)(\w\w)(\w\w)(\w\w)\s/) {
				# print "D: $1, S: $2, DATAGRAM: $3, MAX: $4, SQN: $5\n";
                $tpdu->{'TP-DPORT'} = hex($1);
                $tpdu->{'TP-SPORT'} = hex($2);				
                $tpdu->{'TP-DATAGRAM'} = hex($3);
                $tpdu->{'TP-FRAGMAX'} =  hex($4);
                $tpdu->{'TP-FRAGSQN'} =  hex($5);
			}
			if ($ud=~/\/\/SCKL(\w\w\w\w)(\w\w\w\w)(\w\w)(\w\w)(\w\w)\s/) {
                # print "D: $1, S: $2, DATAGRAM: $3, MAX: $4, SQN: $5\n";
                $tpdu->{'TP-DPORT'} = hex($1);
                $tpdu->{'TP-SPORT'} = hex($2);        
                $tpdu->{'TP-DATAGRAM'} = hex($3);
                $tpdu->{'TP-FRAGMAX'} =  hex($4);
                $tpdu->{'TP-FRAGSQN'} =  hex($5);
            }
			if ($ud=~/\/\/SCK(\w\w)\s/) {
				# print "D: $1, S: $1\n";
                $tpdu->{'TP-DPORT'} = hex($1);
                $tpdu->{'TP-SPORT'} = hex($1);        
                $tpdu->{'TP-DATAGRAM'} = 1;
                $tpdu->{'TP-FRAGMAX'} =  1;
                $tpdu->{'TP-FRAGSQN'} = 1; 
			}
			if ($ud=~/\/\/SCKL(\w\w\w\w)\s/) {
				# print "D: $1, S: $1\n";
                $tpdu->{'TP-DPORT'} = hex($1);
                $tpdu->{'TP-SPORT'} = hex($1);
                $tpdu->{'TP-DATAGRAM'} = 1;
                $tpdu->{'TP-FRAGMAX'} =  1;
                $tpdu->{'TP-FRAGSQN'} = 1;
			}
		}
	} elsif (($dcs & 0xF0) == 0xF0) {
		# Do we have a UDH?
		my $pdu = hex($tpdu->{'TP-PDU'});
		if (($pdu & 0x40) == 0x40) {
			my $udhl = hex($self->getoctet(\@msg));
			my @ud = splice(@msg, 0, $udhl*2);
			while ($#ud>-1) {
				my $iei = $self->getoctet(\@ud);
				my $lei = hex($self->getoctet(\@ud));
				my @dei = splice(@ud, 0, $lei*2);
				# print "UDHL: $udhl, IEI: $iei, LEI: $lei, DATA:".join ( "", @dei ) . "\n";
				if (hex($iei) == 5) {
					# 16 bit port
					my $dport = hex( $self->getoctet(\@dei, 2) );
					my $sport = hex( $self->getoctet(\@dei, 2) );
					# print "16 bit @ D:$dport S:$sport\n";				
					$tpdu->{'TP-DPORT'} = $dport;
                    $tpdu->{'TP-SPORT'} = $sport;
				
					# When receivingwe do not have necessarily the Fragment idenetifier!, so if not already defined
					# (FI maybe! can come b4 PORTS), set them to a bogus number (1,1,1)
					if (!$tpdu->{'TP-DATAGRAM'}) {
						$tpdu->{'TP-DATAGRAM'} = 1;
						$tpdu->{'TP-FRAGMAX'} = 1;
						$tpdu->{'TP-FRAGSQN'} = 1;
					}
				}
				if (hex($iei) == 0) {
					# Fragment identifier
					my $fdatagram = hex( $self->getoctet(\@dei) );
					my $fmax = hex( $self->getoctet(\@dei) );
					my $fid = hex( $self->getoctet(\@dei) );
					# print "datagram $fdatagram fragment $fid from $fmax\n";
                    $tpdu->{'TP-DATAGRAM'} = $fdatagram;
                    $tpdu->{'TP-FRAGMAX'} =  $fmax;
                    $tpdu->{'TP-FRAGSQN'} =  $fid;
				}
			}
		}
		# decode 8 bit
		pop @msg;
		$tpdu->{'TP-UD'} = $self->decode_8bit(join("", @msg), $tpdu->{'TP-UDL'});
		# translate to default alphabet
		$tpdu->{'TP-UD'} = $self->translate($tpdu->{'TP-UD'});
	} else {
		$tpdu->{'TP-UD'} = "";
	}
	###########################################################################
	return $tpdu;
}

sub SMSSubmit {
	my ($self, $servicecenter, $phonenumber, $data, $dcs, $vp, $udhi) = @_;

	my $pdu = '';
	my $pdutype = 0;	

	###########################################################################
	# 1) Service center address
	# -------------------------------------------------------------------------
	# Look at SMSDeliver for notes
	# -------------------------------------------------------------------------
	$pdu.=$self->encodeServiceCenterAddress($servicecenter); 
	###########################################################################
	
	###########################################################################
	# 2) PDU type
	# -------------------------------------------------------------------------
	# Structure :	(n) = bits
	# +--------+----------+---------+---------+--------+---------+
	# | RP (1) | UDHI (1) | SRR (1) | VPF (2) | RD (1) | MTI (2) |
	# +--------+----------+---------+---------+--------+---------+
	# RP:
	#	Reply path : 0 = not set / 1 = set
	# UDHI:
	#	User data only contains short message : 0
	#	User data contains a header :			1
	# SRR:
	#	Status report requested	:	0 = no / 1 = yes
	# VPF:
	#	Validity period field
	#	0 0	:	Not set
	#	0 1 :	Reserved
	#	1 0	:	VP field present : relative (integer)
	#	1 1 :	VP field present : absolute	(semi-octet)
	# RD:
	#	Reject (1)  or accept (0) an SMS in the SMSC with the same MR and DA from the same OA
	# MTI:
	#	Message type
	#	0 0	:	SMS deliver SMSC -> MS
	#	0 1	:	SMS Submit	MS->SMSC
	#
	# We default this field to: 00010001, which means
	#	Validity period in relative format if $vp
	#	SMSSubmit type of message
	#	Accept the same message in the SMSC again
	# -------------------------------------------------------------------------
	$pdutype=1;						# SMS Submit
	$pdutype|=0x10 if ($vp);	 	# Vailidity period
	$pdutype|=0x40 if ($udhi);		# User data header present	
	$pdu.=sprintf("%02x", $pdutype);
	# $pdu.='11';
	# $pdu.='44';
	###########################################################################

	###########################################################################
	# 3) Message reference
	# -------------------------------------------------------------------------
	# The M20 generates this himself, so we can dummy to 00H
	# -------------------------------------------------------------------------
	$pdu.='00';				
	###########################################################################
	
	###########################################################################
	# Destination address
	# -------------------------------------------------------------------------
	# See SMSDeliver for a description
	# -------------------------------------------------------------------------
	$pdu.=$self->encodeDestinationAddress($phonenumber);
	###########################################################################
		
	###########################################################################	
	# protocol identifier
	# -------------------------------------------------------------------------
	# See SMSDeliver for a description
	#	00H : SMS
	# -------------------------------------------------------------------------
	$pdu.='00';
	###########################################################################	
	
	###########################################################################	
	# Data coding scheme (probably need to experiment withthis one!)
	# -------------------------------------------------------------------------
	# See SMSDeliver for a description
	#	We use 	'00' for 7bit, SIM specific			'7bit'	(default)
	#			'F0' for 7bit, immediate display	'7biti'
	#			'F6' for 8bit, SIM specific			'8bit'
	#			'F4' for 8bit, immediate display	'8biti'
	#			'F5' for 8bit, ME specific			'8bitm'	
	# -------------------------------------------------------------------------	
	$pdu.=$self->encodeDataCodingScheme($dcs);
	###########################################################################	
		
	###########################################################################	
	# Validity period
	# -------------------------------------------------------------------------
	# Look at encodeValidityPeriod
	# -------------------------------------------------------------------------
	if ($vp) {
		# $pdu.=$self->encodeValidityPeriod($vp);
		$pdu.='FF';
	}
	###########################################################################
	
	
	###########################################################################
	# Length of message (Length of user data)
	# -------------------------------------------------------------------------	
	# $pdu.=sprintf("%.2X", length($data));
	###########################################################################
	

	###########################################################################
	# Message of user data. 
	# -------------------------------------------------------------------------
	if (($dcs eq '8bit') || ($dcs eq '8biti' || ($dcs eq '8bitm'))) {
		$pdu.=sprintf("%.2X", length($data)/2);
		$pdu.=$self->encode_8bit(substr($data,0,160*2));
	} else {
	# First to the alphabet translation on the data...
		$pdu.=sprintf("%.2X", length($data));
		$data = $self->inversetranslate($data);
		$pdu.=$self->encode_7bit(substr($data,0,160));
	}	
	###########################################################################
		
	return $pdu;
}

# decode a SMSSubmit message (experimental!)
sub SMSSubmit_decode {
	my ($self, $data) = @_;
	my @msg = split //, $data;
	
	# Get service center
	my $sca = $self->getServiceCenterAddress(\@msg);

	# Get PDU type
	my $pdu = $self->getoctet(\@msg);

	# message ref
	my $mref = $self->getoctet(\@msg);

	# destination address
	my $da = $self->getOriginatingAddress(\@msg);

	#  protocol identifier
	my $pi = $self->getoctet(\@msg);

	# data scheme
	my $ds = $self->getoctet(\@msg);

	# vp
	my $vp = $self->getoctet(\@msg);

	# length
	my $dl = $self->getoctet(\@msg);

	my $udh;
	my $payload;

	# print join "|", @msg;
	# print "\n";

	if ($pdu=~/51/) {
		# we have a user data header
		my $udhl = hex($msg[0].$msg[1]);
	
		# print "udhl ($msg[0]): $udhl\n";

		$udh = $self->getoctet(\@msg, $udhl+1); 
		$payload = join("", @msg);
	} else {
		$payload = $self->decode_7bit( join("", @msg), 160 );
	}	

	 # print "da : $da\n";
	 # print "pdu type : $pdu\n";
	 # print "data scheme : $ds\n";
	 # print "length : $dl\n";	
	 # print "udh : $udh\n";
	 # print "pay : $payload\n";	

	return ($da, $pdu, $ds, $udh, $payload);
}

# Get an Adress (OA / DA )
sub getServiceCenterAddress {
	my($self, $ref_msg_arr) = @_;
	my $adr;
	
	# First get address length
	my $len 	= 	 hex($self->getoctet($ref_msg_arr));
	if ($len>0) {
		# Second get Type of address
		my $typ 	= 	 $self->getoctet($ref_msg_arr);

		# Third get  address itself ...
		for (my $pos=0;$pos<$len-1;$pos++) {
			$adr.= $self->swapoctet($self->getoctet($ref_msg_arr));
		}

		# If length is odd we have a trailing F;
		(($len) & 0x1) && chop($adr);
	
		# Append a '+' to make a valid international number, when type is 91
		$adr = ($typ == 91)?'+'.$adr:$adr;
	}
	return $adr;
}


# Get an Adress (OA / DA )
sub getOriginatingAddress {
	my($self, $ref_msg_arr) = @_;
	my $adr;
	
	# First get address length
	my $len 	= 	 hex($self->getoctet($ref_msg_arr));
	# Second get Type of address
	my $typ 	= 	 $self->getoctet($ref_msg_arr);
	# Third get  address itself ...
	
	for (my $pos=0;$pos<$len;$pos+=2) {
		$adr.= $self->swapoctet($self->getoctet($ref_msg_arr));
	}

	# If length is odd we have a trailing F;
	(($len) & 0x1) && chop($adr);
	
	# Append a '+' to make a valid international number, when type is 91
	$adr = ($typ == 91)?'+'.$adr:$adr;
	
	return $adr;
}
	
# Validity period
# For the moment, only integer relative scheme
# 	IN: Validity Period in ns(econds), nm(inutes), nh(ours), nd(ays), nw(eeks)
#			n e R
#  OUT: integer representation of validity period
sub encodeValidityPeriod {
	my ($self, $ti) = @_;

	my	$vp = 0;
	
	my %timeslice = (
			's'	=>	1,
			'm' =>	60,
			'h' =>	60*60,
			'd' =>	60*60*24,
			'w' =>	60*60*24*7
					);
					
	$ti =~/([\d\.]+)([smhdw])/i;
	my $s = $1 * $timeslice{lc $2};	# So we have it in seconds
						
	switch: {
		$s <= 43200		&& do { $vp=($s/300)-1; last switch; };
		$s <= 86400		&& do { $vp=(($s-(12*3600))/(30*60))+143; last switch; };		
		$s <= 2592000 	&& do { $vp=($s/(24*3600))+166; last switch; };
		$s <= 38102400	&& do { $vp=($s/(24*3600*7))+192; last switch; };
	}
	return sprintf("%.2X", $vp);
}

sub encodeDataCodingScheme {
	my ($self, $dcs) = @_;
	my $c = '00';			# default '7bit'
	DCS: {
		$dcs eq '7bit'	&& do { $c = '00';	last; };	
		$dcs eq '7biti'	&& do { $c = 'F0';	last; };
		$dcs eq '8bit'	&& do { $c = 'F6';	last; };
		$dcs eq '8biti'	&& do { $c = 'F4';	last; };
		$dcs eq '8bitm' && do { $c = 'F5';  last; };
	};
	return $c;	
}

sub encodeDestinationAddress {
	my ($self, $number) = @_;
	my $pdu;
	
	# Find type of phonenumber
	# no + => unknown number, + => international number
	my $type = (substr($number,0,1) eq '+')?'91':'81';
	
	# Delete any non digits => + etc...
	$number =~ s/\D//g;
	
	$pdu.= sprintf("%.2X%s",length($number),$type);
	$number.= "F";				# For odd number of digits
	while ($number =~ /^(.)(.)(.*)$/) {	# Get pair of digits
		$pdu.= "$2$1";
		$number = $3;
	}
	return $pdu;
}


sub encodeServiceCenterAddress {
	my ($self, $number) = @_;
	my $pdu;
	
	return '00' if ($number eq '');
	
	# Find type of phonenumber
	# no + => unknown number, + => international number
	my $type = ($number=~/^\+/)?'91':'81';
	
	# Delete any non digits => + etc...
	$number =~ s/\D//g;
	
	$pdu.= sprintf("%.2X%s",(length($number) >> 1)+1,$type);
	$number.= "F";				# For odd number of digits
	while ($number =~ /^(.)(.)(.*)$/) {	# Get pair of digits
		$pdu.= "$2$1";
		$number = $3;
	}
	return $pdu;
}

sub getoctet {
	my ($self, $ar, $len, $swap) = @_;

	my $o = $ar->[0].$ar->[1];
	$o=$self->swapoctet($o) if ($swap);
	shift @$ar;
	shift @$ar;
	while (defined($len) && ($len - 1 > 0)) {
		my $oo = $ar->[0].$ar->[1];
		$oo=$self->swapoctet($oo) if ($swap);
		$o.= $oo;
		shift @$ar;
		shift @$ar;
		$len--;
	}
	return $o;	
}

sub swapoctet {
	my ($self, $o) = @_;
	my @o = split //, $o;
	return $o[1].$o[0];
}

sub decode_7bit {
	my ($self, $ud, $len) = @_;
	my ($msg,$bits);
	my $cnt=0;
	$ud = $ud || "";
	$len = $len || 0;
	$msg = "";
	my $byte = unpack('b8', pack('H2', substr($ud, 0, 2)));
	while (($cnt<length($ud)) && (length($msg)<$len)) {
		$msg.= pack('b7', $byte);
		$byte = substr($byte,7,length($byte)-7);
		if ( (length( $byte ) < 7) ) {
			$cnt+=2; 
			$byte = $byte.unpack('b8', pack('H2', substr($ud, $cnt, 2)));
		}
	}
	return $msg;
}

sub encode_7bit {
	my ($self, $msg) = @_;
	my ($bits, $ud, $octet);

	foreach (split(//,$msg)) {
		$bits .= unpack('b7', $_);
	}
	while (defined($bits) && (length($bits)>0)) {
		$octet = substr($bits,0,8);
		$ud .= unpack("H2", pack("b8", substr($octet."0" x 7, 0, 8)));
		$bits = (length($bits)>8)?substr($bits,8):"";
	}
	return uc $ud;
}

sub decode_8bit {
	my ($self, $ud) = @_;
	my $msg;

	while ( length($ud) ) {
		$msg .= pack('H2',substr($ud,0,2));
		$ud = substr($ud,2);
	}
	return $msg;
}

sub encode_8bit {
	my ($self, $ud) = @_;
	my $msg;

	#while (length($ud)) {
	#	$msg .= sprintf("%.2X", ord(substr($ud,0,1)));
	#	$ud = substr($ud,1);
	#}
	return $ud;
}

sub translate {
	my ($self, $msg) = @_;
	$msg=~ tr (\x00\x02) (\@\$);
	$msg=~ tr (\x07\x0f\x7f\x04\x05\x1f\x5c\x7c\x5e\x7e) (iaaeeEOoUu);	
	return $msg;
}

sub inversetranslate {
	my ($self, $msg) = @_;
	# $msg=~ tr (\@\$) (\x00\x02);
	# $msg=~ tr (iaaeeEOoUu) (\x07\x0f\x7f\x04\x05\x1f\x5c\x7c\x5e\x7e);	
	return $msg;
}
1;

=head1 NAME

GSM::SMS::PDU - Codec for Protocol Data Units.

=head1 DESCRIPTION

This module implements 2 PDUs ( Protocol Data Units ) ,SMS-DELIVER and SMS-SUBMIT, as defined in the SM-TL (Short Message Transport Layer ) specifications.
These PDUs are defined in the GSM03.40 specification from the ETSI ( www.etsi.org ). These PDUs are sufficient to implement NBS ( Narrow Bandwidth Sockets ).
Specification GSM07.05 explains the MMI ( Man Machine Interface ) for the AT+Cellular commands to be able to talk to a GSM modem.

=head1 METHODS

	use GSM::SMS::PDU;
	my $pdu = GSM::SMS::PDU->new();

=head2 SMSDeliver

Decode a short message that comes from the SMSC (Short Message Service Center) to the MS (Mobile Station) (SMS-DELIVER). 
Returns itself as a hash and you can access values the following way:
	
	my $originating_address = $pdu->{'TP-OA'}; 

=head2 SMSSubmit

Encode a short message for sending from the MS to the SMSC (SMS-SUBMIT).

	my $encoded = $pdu->SMSSubmit( 
			$servicecenteraddress, 
			$phonenumber, 
			$payload, $datacodingscheme, 
			$validityperiod, 
			$userdataincluded );

=head2 SMSSubmit_decode

Decode a SMS-SUBMIT PDU.	

=head1 ISSUES

No real OO design. The NBS part that filters out the port-number in the UD ( User Data ) should be migrated to a higher (abstraction) layer.
No support for charsets.

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
