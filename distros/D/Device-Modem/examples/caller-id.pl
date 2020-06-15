#!/usr/bin/perl
#
# Demo of "Caller id" feature: detect who is calling us!
# Thanks to Marcelo Fernandez (mfernandez@lq.com.ar)
#
# $Id: caller-id.pl,v 1.1 2004-08-18 07:29:10 cosimo Exp $
#
use Device::Modem;

# Init modem
my $port = '/dev/ttyS0';
my $baud = 9600;
my $modem = Device::Modem->new( port => $port );

die "Can't connect to port $port!\n" unless $modem->connect( baudrate => $baud );
print "Connected to $port.\n\n";

# Init ATs
#$modem->atsend('AT S7=45 S0=0 L1 V1 X4 &c1 E1 Q0'.Device::Modem::CR); # 'Stolen' from minicom :P

# Set modem in autoanswer mode (to receive incoming calls)
# Doesn't work (it says "NO CARRIER") if I uncomment it
# $modem->atsend('ATA'.Device::Modem::CR);

# Enable Caller ID info
$modem->atsend('AT#CID=1'.Device::Modem::CR);

# Poll state of modem
my $received_call = 0;
my $number = '';

print "Waiting for call...\n";

while( ! $received_call ) {

	# Listen for data coming from modem
	my $cid_info = $modem->answer(undef, 3);  # 3 seconds timeout
	print "$cid_info\n" if ($cid_info);

	# If something received, take a look at it
	if( $cid_info =~ /NMBR\s*=\s*([\d\s]+)/ ) {

		# Ok, received! Number is in $1 var
		$number = $1;
		$received_call++;
		print "\nNumber $number IS CALLING!!\n";
	} elsif( $cid_info ) {
		# Received something else, we must investigate
	} else {
		# No data received. No call arrived.
	}
	# Repeat until done
}

$modem->disconnect();
