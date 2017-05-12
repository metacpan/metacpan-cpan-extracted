package GSM::SMS::Transport::Serial;
use strict;
use vars qw( $VERSION $AUTLOAD );

use base qw( GSM::SMS::Transport::Transport );

$VERSION = '0.2';

=head1 NAME

GSM::SMS::Transport::Serial - Send and receive SMS messages via a GSM modem

=head1 DESCRIPTION

This class implements a serial transport. It uses Device::SerialPort to 
communicate to the modem. At the moment the modem that I recommend is the 
WAVECOM modem. The serial transport has also been  tested for the M20 modem 
module from SIEMENS. 

This module is in fact the root of the complete GSM::SMS package, as the 
project started as a simple perl script that talked to a Nokia6110 connected 
via a software modem ( as that model did not implement standard AT ) on a 
WINNT machine, using Win32::SerialPort and Activestate perl. 

I first used the Nokia6110, then moved to the Falcom A1 GSM modem, then moved 
to the SIEMENS M20 and then moved to the WAVECOM series. Both M20 and WAVECOM 
work best, but I could crash the firmware in the M20 by sending some fake 
PDU messages. Therefore I only use the wavecom now.

=cut

use GSM::SMS::Support::SerialPort;
use Log::Agent;

{
	my %_attrs = (
		_name				=> 'read',
		_originator			=> 'read/write',
		_match				=> 'read/write',
		_pin_code			=> 'read',
		_csca				=> 'read',
		_serial_port		=> 'read',
		_serialport_object	=> 'read/write',
		_baud_rate			=> 'read',
		_memorylimit		=> 'read'
	);	

	sub _accessible
	{
		my ($self, $attr, $mode) = @_;
		$_attrs{$attr} =~ /$mode/
	}
}

my $__TO = 200;

=head1 METHODS

=over 4

=item B<new> - Constructor

  my $s = GSM::SMS::Transport::Serial->new(
    -name => 'serial',
    -originator => 'GSM::SMS',
    -match => '.*',
    -pin_code => '0000',
    -csca => '+32475161616',
    -serial_port => '/dev/ttyS0',
    -baud_rate => '9600',
    -memorylimit => '10'
  }

=cut

sub new {
	my ($proto, %arg) = @_;
	my $class = ref($proto) || $proto;
	
	logdbg "debug", "$class constructor called";

	my $self = $class->SUPER::new(%arg);

	$self->{_pin_code} = $arg{-pin_code} || logcroak("missing -pin_code");
	$self->{_csca}	= $arg{-csca} || logcroak("missing csca");
	$self->{_serial_port} = $arg{-serial_port} || logcroak("missing -serial_port");
	$self->{_baud_rate}	= $arg{-baud_rate} || logcroak("missing -baud-rate");
	$self->{_memorylimit} = $arg{-memorylimit} || logcroak("missing -memorylimit");

	bless($self, $class);
	return $self->init();
} 

=item B<DESTROY> - Destructor

The DESTRUCTOR is necessary for compatibility with Win32. It seems that the serial port needs to be closed explicitly before being able to reuse it in the same
process.

=cut

sub DESTROY {
	my $self = shift;

	logdbg 'debug', 'Destructor for serial transport called';

	$self->close;
} 

=item B<send> - Send a PDU encoded message

=cut

sub send {
	my($self, $msisdn, $p) = @_;
	chomp($p);

	logdbg "debug", "Serial:" . $self->get_name() . " msisdn=$msisdn";
	logdbg "debug", "Serial:" . $self->get_name() . " pdu=$p";

	# calculate length of message
	my $len =  length($p)/2 - 1;
	$len-=hex( substr($p, 0, 2) );
  
	# $self->_at("ATE0\r", $__TO);
    $self->_at("AT+CMGF=0\r", $__TO);
    $self->_at("AT+CMGS=$len\r", $__TO, ">");
    my $res = $self->_at("$p\cz", $__TO);

	if ($res=~/OK/) {
		logdbg "debug", "Serial:" . $self->get_name() . " send [$p]";
		return 0;
	} else {
		logdbg "debug", "Serial:" . $self->get_name() . " error sending [$p]";
		logerr "Serial:" . $self->get_name() . " error sending [$p]";
		return -1;
	}
}

=item B<receive> -  Receive a PDU encoded message

  Will return a PDU string in $pduref from the modem IF we have 
  a message pending return:
     0 if PDU received
    -1 if no message pending

=cut
	
sub receive {
	my ($self, $pduref) = @_;

	my $ar = $self->{MSGARRAY};
	# shift because we want to delete lower index first (problem with modem)
	my $msg = shift (@$ar); 	
	if (!$msg) {
		
		# Read in pending messages
		my $msgarr = $self->_getSMS();
		foreach my $msg (@$msgarr) {
			push @$ar, $msg;
		}
		$msg = shift (@$ar);	# shift same reason as above
	}
	if ($msg) {
		$$pduref = $msg->{MSG};
		if ($msg->{LENGTH}) {
			$self->_delete($msg->{ID});
		}
		return 0;
	}
	return -1;
}

=item B<init> - Initialise this transport layer

  No init file -> default initfile for transport
 
=cut

sub init {
	my ($self) = @_;

	# Start of log ...
	logdbg "debug","Starting Serial Transport for " . $self->get_name();
	
	# Get configuration from config file

	my $port 	= $self->get_serial_port();
	my $br   	= $self->get_baud_rate();
	my $pc   	= $self->get_pin_code();
	my $csca 	= $self->get_csca();
	my $modem 	= $self->get_name();
	
	logdbg "debug", "serial-port: $port";
	logdbg "debug", "baud-rate: $br";
	logdbg "debug", "pin-code: $pc";
	logdbg "debug", "csca: $csca";
	logdbg "debug", "name: $modem";

	# Start up serial port

	my $portobject = GSM::SMS::Support::SerialPort->new ($port);
   	$portobject->baudrate($br);
   	$portobject->parity("none");
   	$portobject->databits(8);
   	$portobject->stopbits(1);
	$self->set_serialport_object( $portobject );

	unless ( $portobject ) {
		logdbg "debug", "Could not open serial port";
		logerr "Could not open serial port";
		return undef;
	}

	# Try to communicate to the port
	$self->_at("ATZ\r", $__TO);
	$self->_at("ATE0\r", $__TO);
	my $res = $self->_at("AT\r", $__TO);
	
	logdbg "debug", "Serial: AT yielded [$res]";
	unless ($res =~/OK/is) {
		logerr "Could not communicate to $port, expected 'OK' but got '$res'";
		return undef;
	}

	# Check the modem status (PIN, CSCA and network connection)
	return undef unless ( $self->_register );

	$self->{MSGARRAY} = [];

	logdbg "debug", "Modem is alive! (SQ=" . $self->_getSQ() . "dBm)";
	return $self;
}

=item B<close> - Close the init file

=cut

sub close {
	my ($self) =@_;

	my $l = $self->{log};
	my $portobject = $self->get_serialport_object();
	$portobject->close;
	undef $portobject;

	logdbg "debug", "Serial:" . $self->get_name() . " closed";
}

=item B<ping> - A ping command

  .. just return an informative string on success

=cut

sub ping {
	my ($self) = @_;

	return $self->_getSQ();
}

=item B<get_info> - Give some info about this transport

=cut

sub get_info {
	my ($self) = @_;

	my $revision = '$Revision: 1.5 $';
	my $date = '$Date: 2002/12/13 21:29:11 $';

print <<EOT;
Serial transport $VERSION

Revision: $revision

Date: $date

EOT
}

=back

=cut

###############################################################################
# Transport layer specific functions
#
sub _getSMS {
	my ($self) = @_;
	my $result = [];
	my $msgcount=0;

	# to pdu mode
	$self->_at("AT+CMGF=0\r", $__TO);

	# loop from 1 to cfg->memorylimit to get messages
	my $limit = $self->get_memorylimit() || 10;
	for (my $i=1; $i<=$limit; $i++) {
		my $res = $self->_at( "AT+CMGR=$i\r", $__TO );

		next if ($res=~/ERROR/ig);

		# find +CMGR: ..,..,..
		my $cmgr_start 	= index( $res, "+CMGR:" );
		my $cmgr_stop	= index( $res, "\r", $cmgr_start );
		my $cmgr = substr($res, $cmgr_start, $cmgr_stop - $cmgr_start);

		# find PDU string
		my $pdu_start	= $cmgr_stop + 2;
		my $pdu_stop	= index( $res, "\r", $pdu_start );
		my $pdu  = substr($res, $pdu_start, $pdu_stop - $pdu_start);

		# message settings
		$cmgr=~/\+CMGR:\s+(\d*),(\d*),(\d*)/;

		my $msg = $result->[$msgcount++] = {};
		$msg->{'ID'} = $i;
		$msg->{'STAT'} = $1;
		$msg->{'LENGTH'} = $3;
		$msg->{'MSG'}.=$pdu;
	}
	return $result;
}


sub _delete {
	my ($self, $id) = @_;
	
	$self->_at("AT+CMGF=1\r", $__TO);
	my $res = $self->_at("AT+CMGD=".$id."\r", $__TO);

	if ($res=~/OK/) {
	} else {
		exit(0);
	}
}


sub _at {
    my ($self, $at, $timeout, $expect) = @_;
 
	my $ob = $self->get_serialport_object();

    $ob->purge_all;
    $ob->write("$at");
    $ob->write_drain;
 
    my $in = "";
    my $max = 500;
    my $count = 0;
    my $found = 0;
    my $to_read;
    my $readcount;
    my $input;
    my $counter=0;

    do {
        select(undef,undef,undef, 0.1);
        $to_read = $max - $count;
 
        ($readcount, $input) = $ob->read($to_read);
        $in.=$input;
        $count+=$readcount;
 
        if ( ($in=~/OK\r\n/) || ($in=~/ERROR\r\n/) ) {
            $found=1;
        }
 
        if ( $expect ) {
            if ( index($in, $expect) > -1 ) {
                $found=1;
            }
        }
        $counter++;
 
 
    } while ( ($found==0) && ($counter<$timeout) );


	while ( my $input = $ob->input ) {
		$in .= $input;
	}

	return $in;
}                                                                                          

sub _getSQ {
	my ($self) = @_;
	my $res = $self->_at("AT+CSQ\r", $__TO);
	$res=~/\+CSQ:\s+(\d+),(\d+)/igs;
	$res=$1;
	
	my $dbm;

	# transform into dBm
	$dbm = -113 if ($res == 0);
	$dbm = -111 if ($res == 1);
	$dbm = -109 + 2*($res-2) if (($res >= 2) && ($res <=30));
	$dbm = 0 if ($res == 99); 

	return $dbm;
}

# Register modem: PIN, CSCA, Wait for network connectivity for a certain period
sub _register {
	my ($self) = @_;
	my $res;

	my $pc   = $self->get_pin_code();
	my $csca = $self->get_csca();	
	
    logdbg "debug", "Checking if modem ready ..";

	# 1. Do we need to give in the PIN ?
	$res = $self->_at("AT+CPIN?\r", $__TO, "+CPIN:");

	if ( $res=~/\+CPIN: SIM PIN/i ) {
		# Put PIN
		logdbg "debug", "Modem needs PIN ...";
		$self->_at("AT+CPIN=\"$pc\"\r", $__TO);
		 
		# Check PIN
		$res = $self->_at("AT+CPIN?\r", $__TO , "+CPIN:");
		if( $res!~/\+CPIN: READY/i ) {
			logdbg "debug", "Modem did not accept PIN!";
			logerr "Modem did not accept PIN!";
			return 0;
		}
	}

	# 2. Set the CSCA
	$res = $self->_at("AT+CSCA=\"$csca\"\r", $__TO);
	$res = $self->_at("AT+CSCA=\"$csca\"\r", $__TO);

	# 3. Wait for registration on network
	my $registered = 0;
	my $stime = time;
	do {
		$res = $self->_at("AT+CREG?\r", $__TO , "+CREG");
		if ( $res=~/1/i ) {
			$registered++;
		}
	}
	until ( $registered || ((time - $stime) > 10 ) );

	if( $registered==0 ) {
		logdbg "debug", "Modem could not register on network!";
		logerr "Modem could not register on network!";
		return 0;
	}

	# 4. Wait until SIM chip is ready (give it 3 mins) - by checking +cmgf
    my $simReady = 0;
    $stime = time;
    do {
        $res = $self->_at("AT+CMGF=0\r", $__TO , "+CMGF");
        if ( $res=~/OK/i ) {
            $simReady++;
        } else {
            sleep 1;
        }
    }
    until ( $simReady || ((time - $stime) > 180 ) );

    if( $simReady==0 ) {
        logdbg "debug", "SIM will not respond!";
        logerr "SIM will not respond!";
		return 0;
    }

	# All went fine!

	return -1;
}
1;

=head1 ISSUES

The Device::SerialPort (Win32::SerialPort) puts a big load on your system (active polling).

The initialisation does not always work well and sometimes you have to
initialize your modem manually using minicom or something like that.
Win32 users can use I<terminal> to connect to the modem and run these tests.

	>minicom -s
	AT
	AT+CPIN?
	AT+CPIN="nnn"
	AT+CSCA?
	AT+CSCA="+32475161616"

+CPIN puts the pin-code in the modem; Be carefull, only 3 tries and then you have to provide the PUK code etc ...

+CSCA sets the service center address

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
