package IPDR::Collection::Client;

use warnings;
use strict;
use IO::Select;
use IO::Socket;
use IO::Socket::SSL qw(debug3);
use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);
use Time::localtime;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres );
use Math::BigInt;
$SIG{CHLD}="IGNORE";

=head1 NAME

IPDR::Collection::Client - IPDR Collection Client

=head1 VERSION

Version 0.40

=cut

our $VERSION = '0.40';

=head1 SYNOPSIS

This is a IPDR module primarily written to connect and collect data
using IPDR from a Motorola BSR6400 CMTS. Some work is still required.

It is not very pretty code, nor perhaps the best approach for some of
the code, but it does work and will hopefully save time for other people
attempting to decode the IPDR protocol (even using the specification it
is hard work).

An example configuration for Cisco is

    cable metering destination 192.168.1.1 5000 192.168.1.2 4000 1 15 non-secure

The IP addresses and ports specified are those of a collector that
the CMTS will send data to. The Cisco implementation does not provide
all IPDR functionality. Setting up a secure connection is not too difficult
(this release does not support it) from a collector point of view however
the Cisco implementation for secure keys is somewhat painful.
This Cisco module opens a socket on the local server waiting for a connection
from a Cisco router.

An example configuration for Motorola BSR is    

    ipdr enable
    ipdr collector 192.168.1.1 5000 3
    ipdr collector 192.168.1.2 4000 2

The IP addresses and ports specicified are those of a collector that will 
connect to the CMTS. You can have multiple collectors connected but only
the highest priority collector will receive data, all others will received
keep alives. 
The Client module makes a connection to the destination IP/Port specified.

An example on how to use this module is shown below. It is relatively simple 
use the different module for Cisco, all others use Client.

    #!/usr/local/bin/perl

    use strict;
    use IPDR::Collection::Client;

    my $ipdr_client = new IPDR::Collection::Client (
                        [
                        VendorID => 'IPDR Client',
                        ServerIP => '192.168.1.1',
                        ServerPort => '5000',
                        KeepAlive => 60,
                        Capabilities => 0x01,
                        DataHandler => \&display_data,
                        Timeout => 2,
                        ]
                        );

    # We send a connect message to the IPDR server
    $ipdr_client->connect();

    # If we do not connect stop.
    if ( !$ipdr_client->connected )
        {
        print "Can not connect to destination.\n";
        exit(0);
        }

    # We now send a connect message
    $ipdr_client->check_data_available();

    print "Error was '".$ipdr_client->get_error()."'\n";

    exit(0);

    sub display_data
    {
    my ( $remote_ip ) = shift;
    my ( $remote_port ) = shift;
    my ( $data ) = shift;
    my ( $self ) = shift;

    foreach my $sequence ( sort { $a<=>$b } keys %{$data} )
        {
        print "Sequence  is '$sequence'\n";
        foreach my $attribute ( keys %{${$data}{$sequence}} )
                {
                print "Sequence '$sequence' attribute '$attribute'";
		print " value '${$data}{$sequence}{$attribute}'\n";
                }
        }

    }

This is the most basic way to access the data. There are multiple scripts in
the examples directory which will allow you to collect and process the IPDR
data.

=head1 FUNCTIONS

=head2 new

The new construct builds an object ready to used by the rest of the module and
can be passed the following varaibles

    VendorID - This defaults to 'Generic Client' but can be set to any string

    ServerIP - 

         Client: This is the IP address of the destination exporter.
         Cisco: This is the IP address of the local server to receive the data

    ServerPort - 

         Client: This is the port of the destination exporter.
         Cisco: This is the port on the local server which will be used to 
                receive data

    KeepAlive - This defaults to 60, but can be set to any value.
    Capabilities - This defaults to 0x01 and should not be set to much else.
    TimeOut - This defaults to 5 and is passed to IO::Socket (usefulness ?!)
    DataHandler - This MUST be set and a pointer to a function (see example)
    DEBUG - Set at your peril, 5 being the highest value.

An example of using new is

    my $ipdr_client = new IPDR::Collection::Client (
                        [
                        VendorID => 'IPDR Client',
                        ServerIP => '192.168.1.1',
                        ServerPort => '5000',
                        KeepAlive => 60,
                        Capabilities => 0x01,
                        DataHandler => \&display_data,
                        Timeout => 2,
                        ]
                        );

=head2 connect

This uses the information set with new and attempts to connect/setup a 
client/server configuration. The function returns 1 on success, 0
on failure. It should be called with

    $ipdr_client->connect();

=head2 connected

You can check if the connect function succeeded. It should return 0
on not connected and 1 if the socket/connection was opened. It can be
checked with

    if ( !$ipdr_client->connected )
        {
        print "Can not connect to destination.\n";
        exit(0);
        }

=head2 check_data_available

This function controls all the communication for IPDR. It will, when needed,
send data to the DataHandler function. It should be called with

    $ipdr_client->check_data_available();

=head2 ALL OTHER FUNCTIONs

The remaining of the functions should never be called and are considered internal
only. They do differ between Client and Cisco however both module provide the same
generic methods, high level, so the internal workings should not concern the 
casual user.

XDR File Location http://www.ipdr.org/public/DocumentMap/XDR3.6.pdf

=cut

sub new {

        my $self = {};
        bless $self;

        my ( $class , $attr ) =@_;

	my ( %template );
	my ( %session );
	my ( %current_data );
	my ( %complete_decoded_data );
	my ( @handles );

	$self->{_GLOBAL}{'DEBUG'}=0;

        while (my($field, $val) = splice(@{$attr}, 0, 2))
                { $self->{_GLOBAL}{$field}=$val; }

        $self->{_GLOBAL}{'STATUS'}="OK";

	if ( !$self->{_GLOBAL}{'VendorID'} )
		{ $self->{_GLOBAL}{'VendorID'}="Generic Client"; }

	if ( !$self->{_GLOBAL}{'ServerIP'} )
		{ die "ServerIP Required"; }

	if ( !$self->{_GLOBAL}{'ServerPort'} )
		{ die "ServerPort Required"; }

	if ( !$self->{_GLOBAL}{'KeepAlive'} )
		{ $self->{_GLOBAL}{'KeepAlive'}=60; }

	if ( !$self->{_GLOBAL}{'Capabilities'} )
		{ $self->{_GLOBAL}{'Capabilities'} = 0x01; } 

	if ( !$self->{_GLOBAL}{'Timeout'} )
		{ $self->{_GLOBAL}{'Timeout'}=10; }

	if ( !$self->{_GLOBAL}{'SessionName'} )
		{ $self->{_GLOBAL}{'SessionName'}=""; }

	if ( !$self->{_GLOBAL}{'MaxRecords'} )
		{ $self->{_GLOBAL}{'MaxRecords'}=0; }

        if ( !$self->{_GLOBAL}{'DataHandler'} )
                { die "DataHandler Function Must Be Defined"; }

        if ( !$self->{_GLOBAL}{'RemoteIP'} )
                { $self->{_GLOBAL}{'RemoteIP'}=""; }

        if ( !$self->{_GLOBAL}{'RemotePort'} )
                { $self->{_GLOBAL}{'RemotePort'}=""; }

        if ( !$self->{_GLOBAL}{'RemotePassword'} )
                { $self->{_GLOBAL}{'RemotePassword'}=""; }

        if ( !$self->{_GLOBAL}{'RemoteSpeed'} )
                { $self->{_GLOBAL}{'RemoteSpeed'}=10; }

        if ( !$self->{_GLOBAL}{'PacketDirectory'} )
                { $self->{_GLOBAL}{'PacketDirectory'}=""; }

        if ( !$self->{_GLOBAL}{'XMLDirectory'} )
                { $self->{_GLOBAL}{'XMLDirectory'}=""; }

	if ( !$self->{_GLOBAL}{'AckTimeOverride'} )
		{ $self->{_GLOBAL}{'AckTimeOverride'}=0; }

	if ( !$self->{_GLOBAL}{'AckSequenceOverride'} )
		{ $self->{_GLOBAL}{'AckSequenceOverride'}=0; }

        if ( !$self->{_GLOBAL}{'PollTime'} )
	                { $self->{_GLOBAL}{'PollTime'}=900 }

        if ( !$self->{_GLOBAL}{'MACFormat'} )
	                { $self->{_GLOBAL}{'MACFormat'}=1 }

        if ( !$self->{_GLOBAL}{'LogDirectory'} )
	                { $self->{_GLOBAL}{'LogDirectory'}=""; }

        if ( !$self->{_GLOBAL}{'LocalAddr'} )
	                { $self->{_GLOBAL}{'LocalAddr'}=""; }

        if ( !$self->{_GLOBAL}{'LogEnabled'} )
	                { $self->{_GLOBAL}{'LogEnabled'}=0; }

        if ( !$self->{_GLOBAL}{'BigLittleEndian'} )
	                { $self->{_GLOBAL}{'BigLittleEndian'}=0; }

        if ( !$self->{_GLOBAL}{'Warning64BitOff'} )
                        { $self->{_GLOBAL}{'Warning64BitOff'}=0; }

        if ( !$self->{_GLOBAL}{'hexBinarySingle'} )
                        { $self->{_GLOBAL}{'hexBinarySingle'}=0; }

        if ( !$self->{_GLOBAL}{'InitiatorID'} )
                        { $self->{_GLOBAL}{'InitiatorID'}=""; }


	$self->{_GLOBAL}{'data_ack'}=0;
	$self->{_GLOBAL}{'ERROR'}="" ;
	$self->{_GLOBAL}{'data_processing'}=0;

	$self->{_GLOBAL}{'template'}= \%template;
	$self->{_GLOBAL}{'sessioninfo'}= \%session;
	$self->{_GLOBAL}{'current_data'}= \%current_data;
        $self->{_GLOBAL}{'complete_decoded_data'} = \%complete_decoded_data;

	$self->{_GLOBAL}{'AckTime'}=0;
	$self->{_GLOBAL}{'AckSequence'}=0;
	$self->{_GLOBAL}{'data_capture_running'}=0;
	$self->{_GLOBAL}{'data_capture_running_time'}=0;
	$self->{_GLOBAL}{'data_capture_data_count'}=0;
	$self->{_GLOBAL}{'data_capture_keep_alive'}=0;
	$self->{_GLOBAL}{'Session'}=0;

        return $self;
}

sub return_keep_alive
{
my ( $self ) = shift;
return $self->{_GLOBAL}{'KeepAlive'};
}

sub construct_capabilities
{
my ( $self ) = shift;
my ( $required_capabilities ) = shift;

my ($set_capabilities);
# This must be a hash pointer, so that we can then
# generate the value required.

my ( %capabilities ) = (
        'STRUCTURE'             =>      0x01,
        'MULTISESSION'          =>      0x02,
        'TEMPLATENEGO'          =>      0x03,
        'REQUESTRESPONSE'       =>      0x04
        );

foreach my $requested ( keys %{$required_capabilities} )
        { $set_capabilities+=$capabilities{$requested}; }
return $set_capabilities;
}

sub create_vendor_id
{
my ($vendor_name) =@_;
my $utf8string = to_utf8({ -string => $vendor_name, -charset => 'ISO-8859-1' });
return $utf8string;
}

sub generate_ipdr_message_header
{
my ( $self ) = shift;
my ( $version ) = shift;
my ( $message_id ) = shift;
my ( $length ) = shift;
# now we assume the length given is that of the payload
# we return the header, with the new length in the header.

my ( $session_id );

if ( $self->{_GLOBAL}{'Session'}>0 )
	{
	print "IPDR Header session is greater than 0 of '".$self->{_GLOBAL}{'Session'}."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	$session_id = $self->{_GLOBAL}{'Session'};
	}
	else
	{
	$session_id=0;
	}

print "IPDR Header session id is '".$session_id."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

$message_id = _transpose_message_names($message_id);

# We know the header is 8 long, so we need to add that to 
# the length of the payload size, thus making the total
# correct.

$length+=8;
my ($header) = pack("CCCCN", $version, $message_id, $session_id, 0, $length);
if ($self->{_GLOBAL}{'DEBUG'}>0 )
	{
	print "Version is '$version'\n";
	print "Message type is '"._transpose_message_numbers($message_id)."'\n";
	print "Message length is '$length'\n";
	}
return ($header);
}

sub return_current_type
{
my ( $self ) = shift;
my ( $test ) = $self->{_GLOBAL}{'current_data'};
if ( !$test ) { return ""; }
if ( !${$test}{'Type'} ) { return "NULL"; }
return ${$test}{'Type'};
}

sub decode_message_type
{
my ( $self ) = shift;
$self->{_GLOBAL}{'current_data'}={};
my ( $decode_data ) = $self->{_GLOBAL}{'current_data'};
# First we get the version and type
# version is not important ( but might be later )
# type is the message ID
# session is the current session ID
# flags should always be 0 at the moment
# length is the total message length

my ( $message ) = $self->{_GLOBAL}{'data_received'};

if ( !$message ) { return 0; }
if ( length($message)<8 ) { return 0; }
if ( $self->{_GLOBAL}{'DEBUG'}>0 )
	{ ${$decode_data}{'RAWDATARETURNED'}=$message; }
my ( $version, $type, $session, $flags, $length ) = unpack ("CCCCN",$message);
${$decode_data}{'Version'}=$version;
${$decode_data}{'Type'}=_transpose_message_numbers($type);
${$decode_data}{'Session'}=$session;
${$decode_data}{'Flags'}=$flags;
${$decode_data}{'Length'}=$length;

$self->{_GLOBAL}{'data_processing'}=0;

if ( !${$decode_data}{'Type'} )
	{
	${$decode_data}{'Type'}="";
	}

print "Message type in decoder is '".${$decode_data}{'Type'}."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
print "Message length in decode is '".${$decode_data}{'Length'}."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
print "Message length is '".length($message)."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

if ( length($message)<${$decode_data}{'Length'} )
	{
	print "Data lengths are incorrect skipping data.\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	${$decode_data}{'Type'}="DEAD";
	return 1;
	}

print "Length of data received is '".length( $self->{_GLOBAL}{'data_received'} )."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

$self->{_GLOBAL}{'data_received'} = substr( $self->{_GLOBAL}{'data_received'}, ${$decode_data}{'Length'},
					length($self->{_GLOBAL}{'data_received'})-(${$decode_data}{'Length'}) );

print "Length of data after new block is '".length( $self->{_GLOBAL}{'data_received'} )."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
if ( length($message)>${$decode_data}{'Length'} )
	{
	$self->{_GLOBAL}{'data_processing'}=1;
	}

$message=substr($message,8,length($message)-8);

if ( ${$decode_data}{'Type'}=~/^connect_response$/i )
	{
	my ( $caps, $keepalive ) = unpack ( "SN",$message );
	my ( $vendor ) = substr($message,6,length($message)-6);
	${$decode_data}{'Capabilities'}=$caps;
	${$decode_data}{'KeepAlive'}=$keepalive;
	${$decode_data}{'VendorID'}=$vendor;
	if ( $self->{_GLOBAL}{'DEBUG'}>0 )
		{
		print "Connect response decoded.\n";
		foreach my $key ( keys %{$decode_data} )
			{
			next if $key=~/^RAWDATARETURNED$/i;
			next if $key=~/^Next_Message$/i;
			print "Variable is '$key' value is '${$decode_data}{$key}'\n";
			}
		}
	return 1;
	}

if ( ${$decode_data}{'Type'}=~/^template_data$/i )
	{
	my ( $config, $template_flags,$something ) = unpack ( "SCN",$message );
	${$decode_data}{'Template_Config'} = $config;
	${$decode_data}{'Template_Flags'} = $template_flags;
	${$decode_data}{'Template_PreData'} = $something;
	#${$decode_data}{'Template_Data'} = substr($message,7,length($message)-7);
	$self->_extract_template_data( substr($message,7,length($message)-7), $self->{_GLOBAL}{'template'} );
	#$self->_extract_template_data( substr($message,7,length($message)-7), $decode_data );
	if ( $self->{_GLOBAL}{'DEBUG'}>0 )
		{
		print "Template Data response decoded.\n";
                foreach my $key ( keys %{$decode_data} )
                        {
                        next if $key=~/^RAWDATARETURNED$/i;
                        print "Variable is '$key' value is '${$decode_data}{$key}'\n";
                        }
		foreach my $key ( keys %{$self->{_GLOBAL}{'template'}} )
			{
			print "Key is '$key'\n";
			}
		}
	#$self->template_store( $template_info );
	return 1;
	}

if ( ${$decode_data}{'Type'}=~/^session_start$/i )
	{
	my ( $uptime ) = unpack("N",$message); $message = substr($message,4,length($message)-4);
	my ( $records ) = decode_64bit_number($message); $message = substr($message,8,length($message)-8);
	my ( $gap_records ) = decode_64bit_number($message); $message = substr($message,8,length($message)-8);
	my ( $primary, $ack_time, $ack_sequence, $document_id ) = unpack ( "CNNS",$message );

	${$decode_data}{'Uptime'} = $uptime;
	${$decode_data}{'Records'} = $records;
	${$decode_data}{'GapRecords'} = $gap_records;
	${$decode_data}{'Primary'} = $primary;
	${$decode_data}{'AckTime'} = $ack_time;
	${$decode_data}{'AckSequence'} = $ack_sequence;
	${$decode_data}{'DocumentID'} = $document_id;

	# added timer for acktime
	# Added some timer margin so AckTime should not fail
	my ( $margin_time ) = $ack_time*0.05;
	if ( $margin_time>15 ) { $margin_time=15; }
	$ack_time = $ack_time-$margin_time;
	if ( !$self->{_GLOBAL}{'AckTime'} || $self->{_GLOBAL}{'AckTime'}==0 || $ack_time<$self->{_GLOBAL}{'AckTime'})
		{
		$self->{_GLOBAL}{'AckTime'} = $ack_time;
		print "Ack time is set to '".$self->{_GLOBAL}{'AckTime'}."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
		}

	if ( !$self->{_GLOBAL}{'AckSequence'} || $self->{_GLOBAL}{'AckSequence'}==0 || $ack_sequence<$self->{_GLOBAL}{'AckSequence'} )
		{
		$self->{_GLOBAL}{'AckSequence'} = $ack_sequence;
		print "Ack time is set to '".$self->{_GLOBAL}{'AckSequence'}."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
		}

	if ( $self->{_GLOBAL}{'AckSequenceOverride'}>0 )
		{
		$self->{_GLOBAL}{'AckSequence'} = $self->{_GLOBAL}{'AckSequenceOverride'};
		}
	
	if ( $self->{_GLOBAL}{'AckTimeOverride'} > 0 )
		{
		$self->{_GLOBAL}{'AckTime'} = $self->{_GLOBAL}{'AckTimeOverride'};
		}

        if ( $self->{_GLOBAL}{'DEBUG'}>0 )
                {
                print "Session start decoded.\n";
                foreach my $key ( keys %{$decode_data} )
                        {
			next if $key=~/^RAWDATARETURNED$/i;
                        print "Variable is '$key' value is '${$decode_data}{$key}'\n";
                        }
		}
	return 1;
	}

if ( ${$decode_data}{'Type'}=~/^get_sessions_response$/i )
	{
	# There is something odd here, the spec says it should be a short
	# the data returned signifies an int ...
	my ( $request_id ) = unpack ("S",$message );
	print "Request id is '$request_id'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	${$decode_data}{'SESSIONS_RequestID'} = $request_id;
	$self->_extract_session_data( substr($message,2,length($message)-2), $self->{_GLOBAL}{'sessioninfo'} );
	$self->update_session_parameters();
	return 1;
	}

if ( ${$decode_data}{'Type'}=~/^data$/i )
	{
	if ( !$self->{_GLOBAL}{'data_capture_running'} )
		{
		$self->{_GLOBAL}{'data_capture_running_time'}=time();
		$self->{_GLOBAL}{'data_capture_running'}=0;
		}
	if ( !$self->{_GLBOAL}{'data_capture_keep_alive'} )
		{
		$self->{_GLBOAL}{'data_capture_keep_alive'}=time();
		}

	$self->{_GLOBAL}{'data_capture_running'}++;
	$self->{_GLOBAL}{'data_capture_data_count'}++;
	my ( $template_id, $config_id, $flags ) = unpack("SSC",$message);
	$message = substr($message,5,length($message)-5);
	my ( $sequence_num ) = decode_64bit_number($message); $message = substr($message,8,length($message)-8);
	my ( $record_type );
	${$decode_data}{'DATA_TemplateID'}=$template_id;
	${$decode_data}{'DATA_ConfigID'}=$config_id;
	${$decode_data}{'DATA_Flags'}=$flags;
	${$decode_data}{'DATA_Sequence'}=$sequence_num;
	${$decode_data}{'DATA_Data'} = $message;
	print "Data Epoch is '".time()."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	print "TemplateID is '${$decode_data}{'DATA_TemplateID'}'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	print "ConfigID is '${$decode_data}{'DATA_ConfigID'}'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	print "Flags is '${$decode_data}{'DATA_Flags'}'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	print "Sequence is '${$decode_data}{'DATA_Sequence'}'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	#${$decode_data}{'records'}=_decode_data_record( ${$decode_data}{'DATA_Data'} );
	return 1;
	}

if ( ${$decode_data}{'Type'}=~/^session_stop$/i )
	{
	my ( $reason_code ) = unpack ("S", $message ); $message = substr($message,2,length($message)-2);
	my ( $reason , $message ) = _extract_utf8_string ( $message );
	${$decode_data}{'reasonCode'} = $reason_code;
	${$decode_data}{'reason'} = $reason;
        if ( $self->{_GLOBAL}{'DEBUG'}>0 )
                {
                print "SessionStop response decoded.\n";
                foreach my $key ( keys %{$decode_data} )
                        {
                        next if $key=~/^RAWDATARETURNED$/i;
                        print "Variable is '$key' value is '${$decode_data}{$key}'\n";
                        }
                }
	return 1;
	}

if ( ${$decode_data}{'Type'}=~/^error$/i )
	{
	my ( $time, $error_code ) = unpack ("NS",$message ) ; $message = substr($message,6,length($message)-6);
	my ( $reason , $message ) = _extract_utf8_string ( $message );
	${$decode_data}{'timeStamp'} = $time;
	${$decode_data}{'errorCode'} = $error_code;
	${$decode_data}{'reason'} = $reason;
        if ( $self->{_GLOBAL}{'DEBUG'}>0 )
                {
                print "Error response decoded.\n";
                foreach my $key ( keys %{$decode_data} )
                        {
                        next if $key=~/^RAWDATARETURNED$/i;
                        print "Variable is '$key' value is '${$decode_data}{$key}'\n";
                        }
                }
	return 1;
	}

if ( $self->{_GLOBAL}{'DEBUG'}>0 )
	{
	print "Message received '${$decode_data}{'Type'}'\n";
	}

return 0;
}

sub send_disconnect
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $result ) = $self->send_message( $self->construct_disconnect() );
return $result;
}

sub send_flow_stop
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $code ) = shift;
my ( $reason ) = shift;
my ( $result ) = $self->send_message( $self->construct_flow_stop($code,$reason) );
return $result;
}

sub max_records_segment
{
my ( $self ) = shift;
$self->{_GLOBAL}{'data_capture_running'}=0;
my $child;
if ($child=fork)
	{ } elsif (defined $child)
		{
		my $xml_transform;
		#print "Remote IP is '".$self->{_GLOBAL}{'RemoteIP'}."'\n";
		#print "Remote Port is '".$self->{_GLOBAL}{'RemotePort'}."'\n";
		if ( ($self->{_GLOBAL}{'RemoteIP'} &&
			$self->{_GLOBAL}{'RemotePort'}) || length($self->{_GLOBAL}{'XMLDirectory'})>5 )
			{
			print "Transformed into XML\n\n$xml_transform\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
			$xml_transform = $self->_transform_into_xml($self->{_GLOBAL}{'complete_decoded_data'});
			}
		if ( $self->{_GLOBAL}{'RemoteIP'} && $self->{_GLOBAL}{'RemotePort'} )
			{
			$self->_send_to_clear_destination ($xml_transform);
			}
		if ( length($self->{_GLOBAL}{'XMLDirectory'})>5 )
			{
			if ( open (__FILE,">".$self->{_GLOBAL}{'XMLDirectory'}."/".$$self->{_GLOBAL}{'ServerIP'} ) )
				{
				print __FILE $xml_transform;
				close __FILE;
				}
			}
		$self->{_GLOBAL}{'DataHandler'}->(
			$self->{_GLOBAL}{'ServerIP'},
			$self->{_GLOBAL}{'ServerPort'},
			$self->{_GLOBAL}{'complete_decoded_data'},
			$self
			);
		waitpid($child,0);
		exit(0);
		}
$self->{_GLOBAL}{'current_data'}={};
$self->{_GLOBAL}{'complete_decoded_data'}={};
return 1;
}


sub send_get_keepalive
{
my ( $self ) = shift;
my ( $data ) = shift;
if ( $self->get_internal_value('data_ack') )
	{
	print "Data ACK is set\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	$self->send_data_ack( 
		$self->get_internal_value('dsn_configID'), 
		$self->get_internal_value('dsn_sequence') 
		);
	# we also need to reset  the capture_count
	$self->{_GLOBAL}{'data_capture_running'}=0;
	$self->{_GLOBAL}{'data_capture_running_time'}=0;
	$self->{_GLOBAL}{'data_capture_data_count'}=0;

	# here we need to add the remote sending of the extracted
	# data. More than likely a fork is required so not to stall
	# the collection process. A fork maybe needed anyway as if
	# the dataset exceeds, say 10,000 entries ( easily done )
	# and being processed locally, any data store *may* not be
	# quick enough.
	my $child;
	if ($child=fork)
		{ } elsif (defined $child)
		{
		my $xml_transform="";
		#print "Remote IP is '".$self->{_GLOBAL}{'RemoteIP'}."'\n";
		#print "Remote Port is '".$self->{_GLOBAL}{'RemotePort'}."'\n";
		if ( ($self->{_GLOBAL}{'RemoteIP'} &&
				$self->{_GLOBAL}{'RemotePort'}) || length($self->{_GLOBAL}{'XMLDirectory'})>5 )
			{
			print "Transformed into XML\n\n$xml_transform\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
			$xml_transform = $self->_transform_into_xml($self->{_GLOBAL}{'complete_decoded_data'});
			}
		if ( $self->{_GLOBAL}{'RemoteIP'} && $self->{_GLOBAL}{'RemotePort'} )
			{
			$self->_send_to_clear_destination ($xml_transform);
			}

		if ( length($self->{_GLOBAL}{'XMLDirectory'})>5 )
			{
			if ( open (__FILE,">".$self->{_GLOBAL}{'XMLDirectory'}."/".$$self->{_GLOBAL}{'ServerIP'} ) )
				{
				print __FILE $xml_transform;
				close __FILE;
				}
			}

		$self->{_GLOBAL}{'DataHandler'}->(
			$self->{_GLOBAL}{'ServerIP'},
			$self->{_GLOBAL}{'ServerPort'},
			$self->{_GLOBAL}{'complete_decoded_data'},
			$self
			);
		waitpid($child,0);
		exit(0);
		}

	$self->{_GLOBAL}{'complete_decoded_data'}={};
	$self->set_internal_value('data_ack',0);
	$self->{_GLOBAL}{'current_data'}={};
	}

my ( $result ) = $self->send_message( $self->construct_get_keepalive() );
return $result;
}

sub send_get_sessions
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $result ) = $self->send_message( $self->construct_get_sessions() );
return $result;
}

sub send_data_ack
{
my ( $self ) = shift;
my ( $config_id ) = shift;
my ( $seq_number ) = shift;
print "ACK data config_id is '$config_id' sequence number is '$seq_number'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
my ( $result ) = $self->send_message( $self->construct_data_ack($config_id,$seq_number) );
return $result;
}

sub send_final_template_data_ack
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $result ) = $self->send_message( $self->construct_final_template_data_ack() );
return $result;
}

sub send_flow_start_message
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $result ) = $self->send_message( $self->construct_flow_start() );
return $result;
}

sub send_connect_message
{
my ( $self ) = shift;
my $result = $self->send_message( $self->construct_connect_message() );
return $result;
}

sub construct_data_ack
{
my ( $self ) = shift;
my ( $config_id ) = shift;
my ( $sequence ) = shift;
print "Constructed id is '$config_id'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
print "Constructed sequence us '$sequence'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
my ( $message ) = pack("S",$config_id);
my ( $sequence_encode ) = encode_64bit_number($sequence);
$message.=$sequence_encode;
if ( $self->{_GLOBAL}{'DEBUG'}>0 )
	{
	print "Packed message is - " if $self->{_GLOBAL}{'DEBUG'}>0;
	for($a=0;$a<length($message);$a++)
       		{
        	print ord (substr($message,$a,1))." ";
        	}
	print "\n";
	}

my ( $header ) = $self->generate_ipdr_message_header(
                        2,"DATA_ACK",length($message));
$header.=$message;
return $header;
}


sub construct_final_template_data_ack
{
my ( $self ) = shift;
my ( $header ) = $self->generate_ipdr_message_header(
                        2,"FINAL_TEMPLATE_DATA_ACK",0);
return $header;
}

sub construct_flow_stop
{
my ( $self ) = shift;
my ( $code ) = shift;
my ( $reason ) = shift;
my ( $message ) = pack("S",$code); $message.=$reason;
my ( $header ) = $self->generate_ipdr_message_header(
                        2,"FLOW_STOP",length($message));
$header.=$message;
return $header;
}

sub construct_disconnect
{
my ( $self ) = shift;
my ( $header ) = $self->generate_ipdr_message_header(
                        2,"DISCONNECT",0);
return $header;
}


sub construct_get_sessions
{
my ( $self ) = shift;
my ( $message ) = pack("S",4096);
my ( $header ) = $self->generate_ipdr_message_header(
                        2,"GET_SESSIONS",length($message));
$header.=$message;
return $header;
}

sub construct_get_keepalive
{
my ( $self ) = shift;
my ( $header ) = $self->generate_ipdr_message_header(
                        2,"KEEP_ALIVE",0);
return $header;
}


sub construct_flow_start
{
my ( $self ) = shift;
if ( !$self->create_initiator_id() )
        { return 0; }
my ( $header ) = $self->generate_ipdr_message_header(
                        2,"FLOW_START",0);
return $header;
}

sub construct_connect_message
{
my ( $self ) = shift;

if ( !$self->create_initiator_id() )
	{
	return 0;
	}
# so we know all the below
my ( $message ) = pack("NSNN",
		$self->create_initiator_id(),
		$self->{_GLOBAL}{'LocalPort'},
		$self->{_GLOBAL}{'Capabilities'},
		$self->{_GLOBAL}{'KeepAlive'} );
$message.=$self->{_GLOBAL}{'VendorID'};
my ( $header ) = $self->generate_ipdr_message_header(
			2,"CONNECT",length($message));
$header.=$message;

return $header;
}

sub disconnect
{
my ( $self ) = shift;
$self->{_GLOBAL}{'Handle'}->close();
return 1;
}

sub connect
{
my ( $self ) = shift;

if ( !$self->test_64_bit() )
	{
	# if you forgot to run make test, this will clobber
	# your run anyway.
        if ( $self->{_GLOBAL}{'Warning64BitOff'}!=1 )
                {
                warn '64Bit support not available using BigInt - Milleage will vary! Turn off with Warning64BitOff => 1.';
                }
	}

my $lsn;

if ( length($self->{_GLOBAL}{'LocalAddr'})>0 )
	{
	$lsn = IO::Socket::INET->new
                        (
                        PeerAddr => $self->{_GLOBAL}{'ServerIP'},
                        PeerPort => $self->{_GLOBAL}{'ServerPort'},
			LocalAddr => $self->{_GLOBAL}{'LocalAddr'},
                        ReuseAddr => 1,
                        Proto     => 'tcp',
			Timeout    => $self->{_GLOBAL}{'Timeout'}
                        );
	}
	else
	{
	$lsn = IO::Socket::INET->new
                        (
                        PeerAddr => $self->{_GLOBAL}{'ServerIP'},
                        PeerPort => $self->{_GLOBAL}{'ServerPort'},
                        ReuseAddr => 1,
                        Proto     => 'tcp',
			Timeout    => $self->{_GLOBAL}{'Timeout'}
                        );
	}
if (!$lsn)
	{
	$self->{_GLOBAL}{'STATUS'}="Failed To Connect";
	$self->{_GLOBAL}{'ERROR'}=$!;
	return 0;
	}

if ( length($self->{_GLOBAL}{'InitiatorID'})>0 )
	{
	$self->{_GLOBAL}{'LocalIP'}=$self->{_GLOBAL}{'InitiatorID'};
	}
	else
	{
	$self->{_GLOBAL}{'LocalIP'}=$lsn->sockhost();
	}
$self->{_GLOBAL}{'LocalPort'}=$lsn->sockport();
$self->{_GLOBAL}{'Handle'} = $lsn;
$self->{_GLOBAL}{'Selector'}=new IO::Select( $lsn );
$self->{_GLOBAL}{'STATUS'}="Success Connected";

$self->{_GLOBAL}{'data_ack'}=0;
$self->{_GLOBAL}{'ERROR'}="" ;
$self->{_GLOBAL}{'data_processing'}=0;

$self->{_GLOBAL}{'template'}= {};
$self->{_GLOBAL}{'sessioninfo'}= {};
$self->{_GLOBAL}{'current_data'}= {};
$self->{_GLOBAL}{'complete_decoded_data'} = {};

$self->{_GLOBAL}{'AckTime'}=0;
$self->{_GLOBAL}{'AckSequence'}=0;
$self->{_GLOBAL}{'data_capture_running'}=0;
$self->{_GLOBAL}{'data_capture_running_time'}=0;
$self->{_GLOBAL}{'data_capture_data_count'}=0;
$self->{_GLOBAL}{'data_capture_keep_alive'}=0;
$self->{_GLOBAL}{'Session'}=0;

if ( $self->{_GLOBAL}{'DEBUG'} > 0 )
	{
	my $test = $self->{_GLOBAL};
	foreach my $setting ( keys %{$test} )
		{
		print "Global setting '$setting' value is '${$test}{$setting}'\n";
		}
	}

return 1;
}

sub connected
{
my ( $self ) = shift;
return $self->{_GLOBAL}{'Selector'};
}

sub send_message
{
my ( $self ) = shift;
my ( $message ) = shift;
if ( !$self->{_GLOBAL}{'Handle'} ) { return 0; }
my ( $length_sent ) = 0;
eval {
	local $SIG{ALRM} = sub { die "alarm\n" };
	alarm 5;
	$length_sent = syswrite ( $self->{_GLOBAL}{'Handle'}, $message );
	alarm 0;
	};

if ( $@=~/alarm/i )
        { return 0; }

print "Sending message of size '".length($message)."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

if ( $self->{_GLOBAL}{'DEBUG'}>4 )
	{
	for($a=0;$a<length($message);$a++)
		{
		printf("%02x-", ord(substr($message,$a,2)));
		}
	print "\n";
	}

if ( $length_sent==length($message) )
	{ return 1; }
return 0;
}

sub create_initiator_id
{
my ( $self ) = @_;
my ( $initiator_id ) = $self->_IpQuadToInt( $self->{_GLOBAL}{'LocalIP'} );
return $initiator_id;
}

sub _IpQuadToInt 
{
my ($self)= shift;
my($Quad) = shift; 
if ( !$Quad ) { return 0; }
my($Ip1, $Ip2, $Ip3, $Ip4) = split(/\./, $Quad);
my($IpInt) = (($Ip1 << 24) | ($Ip2 << 16) | ($Ip3 << 8) | $Ip4);
return($IpInt);
}

sub _IpIntToQuad { my($Int) = @_;
my($Ip1) = $Int & 0xFF; $Int >>= 8;
my($Ip2) = $Int & 0xFF; $Int >>= 8;
my($Ip3) = $Int & 0xFF; $Int >>= 8;
my($Ip4) = $Int & 0xFF; return("$Ip4.$Ip3.$Ip2.$Ip1");
}

sub _message_types
{
my ( %messages ) = (
        'FLOW_START'                    => 0x01,
        'FLOW_STOP'                     => 0x03,
        'CONNECT'                       => 0x05,
        'CONNECT_RESPONSE'              => 0x06,
        'DISCONNECT'                    => 0x07,
        'SESSION_START'                 => 0x08,
        'SESSION_STOP'                  => 0x09,
        'KEEP_ALIVE'                    => 0x40,
        'TEMPLATE_DATA'                 => 0x10,
        'MODIFY_TEMPLATE'               => 0x1a,
        'MODIFY_TEMPLATE_RESPONSE'      => 0x1b,
        'FINAL_TEMPLATE_DATA_ACK'       => 0x13,
        'START_NEGOTIATION'             => 0x1d,
        'START_NEGOTIATION_REJECT'      => 0x1e,
        'GET_SESSIONS'                  => 0x14,
        'GET_SESSIONS_RESPONSE'         => 0x15,
        'GET_TEMPLATES'                 => 0x16,
        'GET_TEMPLATES_RESPONSE'        => 0x17,
        'DATA'                          => 0x20,
        'DATA_ACK'                      => 0x21,
        'ERROR'                         => 0x23,
        'REQUEST'                       => 0x30,
        'RESPONSE'                      => 0x31
                );
return \%messages;
}

sub _transpose_message_numbers
{
my ( $message_number ) =@_;
my $messages = _message_types();
my %reverse_pack;
foreach my $message ( keys %{$messages} )
        { $reverse_pack{ ${$messages}{$message} } = $message; }
return $reverse_pack{$message_number};
}

sub _transpose_message_names
{
my ( $message_name ) =@_;
my $messages = _message_types();
return ${$messages}{$message_name};
}

sub _extract_session_data
{
my ( $self ) = shift;
my ( $session_data ) = shift;
my ( $session_extract ) = shift;

print "Length of session data is '".length($session_data)."'\n" if $self->{_GLOBAL}{'DEBUG'}>1;
if ( $self->{_GLOBAL}{'DEBUG'}>4 )
        {
	print "Session data segment - ";
        for($a=0;$a<length($session_data);$a++)
                {
                printf("%02x-", ord(substr($session_data,$a,2)));
                }
        print "\n";
        }
my ( $sessions_count ) = unpack("N",$session_data);
$session_data = substr($session_data,4,length($session_data)-4);

print "Sessions count '$sessions_count'\n" if $self->{_GLOBAL}{'DEBUG'}>1;
for ( my $session_decode=0; $session_decode<$sessions_count; $session_decode++ )
	{
	my ( $session_id, $reserved ) = unpack("CC",$session_data);
	my ( $sessionName ) = "";
	my ( $sessionDescription ) = "";
	my ( $ackTime ) = 0;
	my ( $ackSeq ) = 0 ;

	$session_data = substr($session_data,2,length($session_data)-2);

	( $sessionName, $session_data ) = _extract_utf8_string ( $session_data );
	( $sessionDescription, $session_data ) = _extract_utf8_string ( $session_data );
	( $ackTime, $ackSeq ) = unpack ("NN", $session_data );

	print "Session id is '$session_id'\n" if $self->{_GLOBAL}{'DEBUG'}>1;
	print "Session name is '$sessionName'\n" if $self->{_GLOBAL}{'DEBUG'}>1;
	print "Session description is '$sessionDescription'\n" if $self->{_GLOBAL}{'DEBUG'}>1;
	print "Session ackTime '$ackTime'\n" if $self->{_GLOBAL}{'DEBUG'}>1;
	print "Session ackSeq '$ackSeq'\n" if $self->{_GLOBAL}{'DEBUG'}>1;

	${$session_extract}{$session_decode}{'SessionID'} = $session_id;
	${$session_extract}{$session_decode}{'SessionName'} = $sessionName;
	${$session_extract}{$session_decode}{'SessionDescription'} = $sessionDescription;
	${$session_extract}{$session_decode}{'ackTime'} = $ackTime;
	${$session_extract}{$session_decode}{'ackSeq'} = $ackSeq;

	$session_data = substr($session_data,8,length($session_data)-8);

	}
return 1;
}

sub update_session_parameters
{
my ( $self ) = shift;
my ( $session_extract ) =  $self->{_GLOBAL}{'sessioninfo'};
my ( $debug ) = $self->{_GLOBAL}{'DEBUG'};
my ( @sessions ) = keys %{$session_extract};
my ( $session_name_lock ) = 0;

print "Session Update\n\n" if $debug>0;
print "Number of sessions is '".scalar(@sessions)."'\n" if $debug>0;

if ( $debug>0 )
	{
	if ( scalar(@sessions)>1 )
		{
		print "More than one session found. Using First.\n";
		print "Or selecting by name if configured.\n";
		}
	}

if ( length($self->{_GLOBAL}{'SessionName'})>2 )
	{
	foreach my $sessions ( keys %{$session_extract} )
		{
		if ( ${$session_extract}{$sessions}{'SessionName'} eq $self->{_GLOBAL}{'SessionName'} )
			{
			print "Session name locked to value '".$sessions."'\n" if $debug>3;
			$session_name_lock = $sessions;
			}
		}
	}

print "Session Update\n\n" if $debug>0;

print "Session name in use is '".${$session_extract}{$session_name_lock}{'SessionName'}."'\n" if $debug>0;
print "Session description in use us '".${$session_extract}{$session_name_lock}{'SessionDescription'}."'\n" if $debug>0;

$self->{_GLOBAL}{'AckSequence'} = ${$session_extract}{$session_name_lock}{'ackSeq'};
print "Setting Ack Seq to '".$self->{_GLOBAL}{'AckSequence'}."'\n" if $debug>0;

my ( $margin_time ) = ${$session_extract}{$session_name_lock}{'ackTime'}*0.05;
if ( $margin_time>15 ) { $margin_time=15; }
if ( !$self->{_GLOBAL}{'AckTime'} || $self->{_GLOBAL}{'AckTime'}==0 )
	{
	$self->{_GLOBAL}{'AckTime'} = ${$session_extract}{$session_name_lock}{'ackTime'}-$margin_time;
	print "Ack time is set to '".$self->{_GLOBAL}{'AckTime'}."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	}

if ( !$self->{_GLOBAL}{'Session'} || $self->{_GLOBAL}{'Session'}==0 )
        {
        $self->{_GLOBAL}{'Session'} = ${$session_extract}{$session_name_lock}{'SessionID'};
        print "Session ID is set to '".$self->{_GLOBAL}{'Session'}."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
        }

print "Session Update\n\n" if $debug>0;

return 1;
}


sub _extract_template_data
{
my ( $self ) = shift;
my ( $template_data ) = shift;
my ( $template_extract) = shift;

my ( $record_type );
my ( $record_configuration );
my ( $field_id, $field_count, $field_name, $field_enabled );

while ( length($template_data)>10 )
        {
        my ( $template_id ) = unpack("S",$template_data);
        $template_data=substr($template_data,2,length($template_data)-2);

	print "Template found is '$template_id'\n" if $self->{_GLOBAL}{'DEBUG'}>1;

        ( $record_type, $template_data ) = _extract_utf8_string ( $template_data );
        ( $record_configuration , $template_data ) = _extract_utf8_string ( $template_data );

        ${$template_extract}{'Templates'}{$template_id}{'schemaName'}=$record_type;
        ${$template_extract}{'Templates'}{$template_id}{'typeName'}=$record_configuration;

	print "schemaName found is '$record_type'\n" if $self->{_GLOBAL}{'DEBUG'}>1;
	print "typeName found is '$record_configuration'\n" if $self->{_GLOBAL}{'DEBUG'}>1;

        ( $field_count ) =  unpack("N", $template_data ); $template_data=substr($template_data,4,length($template_data)-4);

        ${$template_extract}{'Templates'}{$template_id}{'fieldCount'}=$field_count;

        for ($a=0;$a<$field_count;$a++)
                {
                my ( $typeid, $fieldid ) = unpack("NN",$template_data);
                $template_data=substr($template_data,8,length($template_data)-8);
                ( $field_name , $template_data ) = _extract_utf8_string ( $template_data );
                ( $field_enabled ) = unpack("C",$template_data);
                $template_data=substr($template_data,1,length($template_data)-1);
                ${$template_extract}{'Templates'}{$template_id}{'fields'}{$a}{'name'}=$field_name;
                ${$template_extract}{'Templates'}{$template_id}{'fields'}{$a}{'typeID'}=$typeid;
                ${$template_extract}{'Templates'}{$template_id}{'fields'}{$a}{'fieldID'}=$fieldid;
                ${$template_extract}{'Templates'}{$template_id}{'fields'}{$a}{'enabled'}=$field_enabled;
		print "Field name '$field_name' type '$typeid' fieldid '$fieldid' enabled '$field_enabled' count '$a'\n"
			if $self->{_GLOBAL}{'DEBUG'}>1;
                }
        }
return 1;
}

sub _extract_utf8_string
{
my ( $data ) = @_;
my ( $string_len ) = unpack("N",$data); $data=substr($data,4,length($data)-4);
my ( $new_string ) = substr($data,0,$string_len);
#print "String length is '$string_len' string is '$new_string'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
if ( ( length($data)-$string_len ) < 0 )
	{
	$data="";
	}
	else
	{
	$data=substr($data,$string_len,length($data)-$string_len);
	}
return ($new_string,$data);
}

sub _extract_ip_string
{
my ( $data ) = @_;
my ( $new_string );
if ( !$data ) { return ("",""); }
( $new_string, $data ) = _extract_int_u ( $data );
( $new_string ) = _IpIntToQuad ( $new_string );
return ($new_string,$data);
}

sub _extract_int_u
{
# This is forced to be 32bits wide.
my ( $data ) = @_;
if ( length($data)<4 )
	{
	return ( length($data), $data );
	}
my ( $ip_int ) = unpack("N",$data); $data=substr($data,4,length($data)-4);
return ($ip_int,$data);
}

sub _extract_boolean
{
my ( $data ) = @_;
my ( $char);
( $char, $data ) = _extract_char($data);
return ($char,$data);
}

sub _extract_double
{
my ( $data ) = @_;
if ( length($data)<8 )
	{
	return ( length($data), $data );
	}
my ( $ip_int ) = unpack("NN",$data); $data=substr($data,8,length($data)-8);
return ($ip_int,$data);
}

sub _extract_float
{
# This is forced to be a single precision float
# the specification makes no reference to the
# float type.
my ( $data ) = @_;
if ( length($data)<4 )
	{
	return ( length($data), $data );
	}
my ( $ip_int ) = unpack("f",$data); $data=substr($data,4,length($data)-4);
return ($ip_int,$data);
}

sub _extract_int
{
my ( $self ) = shift;
my ( $data ) = shift;
if ( length($data)<4 )
	{
	return ( length($data), $data );
	}
my ( $flash_data ) = substr($data,1,4);
if ( $self->{_GLOBAL}{'DEBUG'} == 5 )
	{
	print "data is ".sprintf("%02x%02x%02x%02x",ord(substr($flash_data,1,1)),ord(substr($flash_data,2,1)),ord(substr($flash_data,3,1)),
			ord(substr($flash_data,4,1)) );
	}
if ( $self->{_GLOBAL}{'BigLittleEndian'}==1 )
	{ $flash_data = _reverse_pattern($flash_data); }
if ( $self->{_GLOBAL}{'DEBUG'} == 5 )
	{
	print "data is ".sprintf("%02x%02x%02x%02x",ord(substr($flash_data,1,1)),ord(substr($flash_data,2,1)),ord(substr($flash_data,3,1)),
			ord(substr($flash_data,4,1)) );
	}

my ( $ip_int ) = unpack("I",$flash_data); $data=substr($data,4,length($data)-4);
return ($ip_int,$data);
}

sub _extract_short
{
my ( $data ) = @_;
my ( $ip_int ) = unpack("S",$data); $data=substr($data,2,length($data)-2);
return ($ip_int,$data);
}

sub _extract_short_u
{
my ( $data ) = @_;
my ( $ip_int ) = unpack("S",$data); $data=substr($data,2,length($data)-2);
return ($ip_int,$data);
}

sub _extract_datetimeusec
{
my ( $data ) = @_;

my ($part1,$part2) = unpack("NN",$data);
$part1 = $part1<<32;
$part1+=$part2;

$data=substr($data,8,length($data)-8);

return ($part1, $data);
}

sub _extract_uuid
{
my ( $data ) = @_;

my ($length,$one_o, $one_t, $two_o, $two_t, $three_o, $three_t,
        $four_o, $four_t, $five_o, $five_t, $six_o, $six_t,
        $seven_o, $seven_t, $eight_o, $eight_t) = unpack("NCCCCCCCCCCCCCCCC",$data );

my ($ipv6addr) = sprintf("%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x",
                $one_o, $one_t, $two_t, $two_t,
                $three_o, $three_t, $four_o, $four_t,
                $five_o, $five_t, $six_o, $six_t,
                $seven_o, $seven_t, $eight_o, $eight_t);

$data=substr($data,20,length($data)-20);
return ($ipv6addr,$data);
}

sub _extract_ipaddr
{
my ( $data ) = @_;
my ( $length ) = unpack("N",$data);
my ( $ipaddr ) = "";
if ( $length == 16 )
	{ ( $ipaddr, $data ) = _extract_ipv6addr ( $data ); }

if ( $length == 4 )
	{ ( $ipaddr, $data ) = _extract_ip_string ( $data ); }

return ( $ipaddr , $data );
}

sub _extract_ipv6addr
{
my ( $data ) = @_;

my ($length,$one_o, $one_t, $two_o, $two_t, $three_o, $three_t,
        $four_o, $four_t, $five_o, $five_t, $six_o, $six_t,
        $seven_o, $seven_t, $eight_o, $eight_t) = unpack("NCCCCCCCCCCCCCCCC",$data );

my ($ipv6addr) = sprintf("%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x",
                $one_o, $one_t, $two_t, $two_t,
                $three_o, $three_t, $four_o, $four_t,
                $five_o, $five_t, $six_o, $six_t,
                $seven_o, $seven_t, $eight_o, $eight_t);

$data=substr($data,20,length($data)-20);
return ($ipv6addr,$data);
}

sub _extract_unknown
{
my ( $data, $count ) = @_;
( $count ) = (split(/\_/,$count))[1];
$data=substr($data,$count,length($data)-$count);
return ($data);
}

sub _extract_char
{
my ( $data ) = @_;
my ( $char ) = unpack("C",$data);
$data=substr($data,1,length($data)-1);
return ($char,$data);
}

sub _extract_char_u
{
my ( $data ) = @_;
my ( $char ) = unpack("C",$data);
$data=substr($data,1,length($data)-1);
return ($char,$data);
}

sub _extract_mac
{
my ( $self ) = shift;
my ( $data ) = @_;
my ( $return_data ) = "";
my ( $empty, $empty2, $mac1, $mac2, $mac3, $mac4, $mac5, $mac6 ) = unpack ("CCCCCCCC",$data);
if ( $self->{_GLOBAL}{'MACFormat'} == 1 )
	{ ( $return_data ) = sprintf("%02x%02x.%02x%02x.%02x%02x",$mac1,$mac2,$mac3,$mac4,$mac5,$mac6); }
if ( $self->{_GLOBAL}{'MACFormat'} == 2 )
	{ 
	( $return_data ) = sprintf("%02x-%02x-%02x-%02x-%02x-%02x",$mac1,$mac2,$mac3,$mac4,$mac5,$mac6); 
	$return_data=~tr/[a-z]/[A-Z]/; 
	}
$data=substr($data,8,length($data)-8);
return ($return_data,$data);
}

sub _extract_long_u
{
my ( $data ) = @_;
my ( $long ) = decode_64bit_number ( $data );
$data=substr($data,8,length($data)-8);
return ($long,$data);
}

sub _extract_long
{
my ( $data ) = @_;
my ( $long ) = decode_64bit_number ( $data );
$data=substr($data,8,length($data)-8);
return ($long,$data);
}

sub _extract_list
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $type ) = shift;

if ($self->{_GLOBAL}{'DEBUG'}>0 )
	{

print "Check self is '".$self."'\n";
print "Check data len is '".length($data)."'\n";
print "Check type is '$type'\n";
	}

my ( $string_len ) = 0;

# Looks like a field length is 16 bit 
# if the field type is serviceflowchSet 
# otherwise I am setting it to be 32bits
# per the default speficiation for field
# type list.
( $string_len ) = unpack ("N",$data);
# snarf the header
$data=substr($data,4,length($data)-4);

if ($self->{_GLOBAL}{'DEBUG'}>0 )
	{
	print "List Debug length is '".$string_len."'\n";
	print "List type is '$type'\n";
	}

# Remove the list data and return 
#
my ( $returned_list ) = "";

#if ( $type =~/^ServiceFlowChSet$/i )
#	{
	# This is bascially a list of numbers so we do that
	if ($self->{_GLOBAL}{'DEBUG'}>0 )
		{
		print "ServiceFlowChSet field being used.\n";
		print "Data extracted.\n";
		}
	if ( $string_len%2 > 0 )
		{
		# Here we have to capture the error but also
		# make the data available.
		if ($self->{_GLOBAL}{'DEBUG'}>0 )
			{
			print "Something serious happened here as length is wrong.\n";
			
			for ( $a=0; $a<$string_len; $a++ )
				{
				$returned_list.=ord(substr($data,$a,1)).",";
				}
			}
		}
		else
		{
		# We know we have a good data length so now we decode it
		if ($self->{_GLOBAL}{'DEBUG'}>0 )
			{
			print "ServiceFlowChSet length is correct modulus.\n";
			}
		# The default is the correct 16bit snarfing of a hexBinary
		# data string. Now, it appears that using the data as an 8bit
		# dataset is sometimes preferred, so by setting hexBinarySingle
		# we do that too.
		if ( $self->{_GLOBAL}{'hexBinarySingle'}==1 )
			{
			for ( $a=0; $a<$string_len; $a++ )
				{
				$returned_list.=ord(substr($data,$a,1)).",";
				}
			}
			else
			{
		for ( $a=0;$a<$string_len; $a+=2 )
			{
			if ($self->{_GLOBAL}{'DEBUG'}>0 )
				{
				print "Count routine is '".$a."'\n";
				}
			my $partial = substr($data,$a,2);
			if ($self->{_GLOBAL}{'DEBUG'}>0 )
				{
				print "Length of partial is '".length($partial)."'\n";
				}
			if ( length($partial)==2) 
				{
				if ($self->{_GLOBAL}{'DEBUG'}>0 )
					{
					print "Partial length correct.\n";
					}
				my ($unpp) = unpack("n",$partial);
				if ($self->{_GLOBAL}{'DEBUG'}>0 )
					{
					print "Value of decoded is '".$unpp."'\n";
					}
				$returned_list .=$unpp.",";
				}
				else
				{
				if ($self->{_GLOBAL}{'DEBUG'}>0 )
					{
					print "Partial extract wrong, ignoring.\n";
					}
				}
			}
			}
		}

#	}

#if ( $type !~/^ServiceFlowChSet$/i )
#	{
#	if ($self->{_GLOBAL}{'DEBUG'}>0 )
#		{
#		print "Field type '$type' being used.\n";
#		}
#
#	my ( $ip_list ) = substr($data,0,$string_len);
#	while ( length($ip_list)>0 )
#		{
#		my $structure = substr($ip_list,0,4);
#
#		$ip_list = substr($ip_list,4,length($ip_list)-4);
#
#		if ($self->{_GLOBAL}{'DEBUG'}>0 )
#			{
#			print "List Debug structure length is '".length($structure)."'\n";
#			print "Length of ip_list is '".length($ip_list)."'\n";
#		        for($a=0;$a<length($structure);$a++)
#       		         	{
#       		         	print ord (substr($structure,$a,1))." ";
#               		 	}
#			}
#		$returned_list.=ord(substr($structure,0,1)).".".ord(substr($structure,1,1)).".".ord(substr($structure,2,1)).".".ord(substr($structure,3,1)).",";
#		}
#	}

if ( length($returned_list)>0 )
	{ 
	chop($returned_list); 
	if ($self->{_GLOBAL}{'DEBUG'}>0 )
		{
		print "\n\n$returned_list\n\n";
		}
	}

$data=substr($data,$string_len,length($data)-$string_len);
return ($returned_list,$data);
}

sub template_store
{
my ( $self ) = shift;
my ( $data ) = shift;
$self->{_GLOBAL}{'data_template'} = $data;
}

sub template_return
{
my ( $self ) = shift;
return $self->{_GLOBAL}{'data_template'};
}

sub template_value_definitions
{
# this template is no longer needed and was
# originally put in for development purposes
# in the next few versions this will be removed.
#
# point of note, signed values *may* not be 
# correct due to endianess of a platform. Currently
# all set to unsigned. Tried on multiple platforms 
# and something not conforming to spec.
my %template_params;

$template_params{33}="network_int_u";
$template_params{34}="network_int_u";
$template_params{35}="long_u";
$template_params{36}="long_u";
$template_params{37}="float";
$template_params{38}="double";
$template_params{39}="ip_list";
$template_params{40}="string";
$template_params{41}="boolean";
$template_params{42}="byte_u";
$template_params{43}="byte_u";
$template_params{44}="short_u";
$template_params{45}="short_u";

$template_params{290}="network_int_u";
$template_params{548}="long";
$template_params{802}="network_ip";
$template_params{1063}="ipv6addr";
$template_params{1319}="uuid";
$template_params{1571}="datetimeusec";
$template_params{1827}="mac";
$template_params{2087}="ipaddr";

return %template_params;
}

sub decode_64bit_number_u
{
# see comments on 64bit stuff.
my ( $message ) =@_;
my ($part1,$part2) = unpack("NN",$message);
$part1 = $part1<<32;
$part1+=$part2;
return $part1;
}

sub decode_64bit_number
{
# see comments on 64bit stuff.
my ( $message ) =@_;
my ($part1,$part2) = unpack("NN",$message);
if ( !test_64_bit() )
        {
        return (
        Math::BigInt
              ->new("0x" . unpack("H*", pack("N2", $part1, $part2)))
                  );
        }
$part1 = $part1<<32;
$part1+=$part2;
return $part1;
}

#sub decode_64bit_number_u
#{
## see comments on 64bit stuff.
#my ( $message ) =@_;
#my ($part1,$part2) = unpack("NN",$message);
#$part1 = $part1<<32;
#$part1+=$part2;
#return $part1;
#}

sub encode_64bit_number
{
# It seems Q does not work, well not for me
# and this is the quickest way to fix it.
# You STILL NEED 64 BIT SUPPORT!!
my ( $number ) = @_;
if ( !test_64_bit() )
        {
	my $i = Math::BigInt->new($number);
	my $j = Math::BigInt->new($number)->brsft(32);
	return pack('NN', $j, $i );
        }
# any bit to 64bit number in.
my($test1) = $number & 0xFFFFFFFF; $number >>= 32;
my($test2) = $number & 0xFFFFFFFF;
my $message = pack("NN",$test2,$test1);
return $message;
}

#sub encode_64bit_number
#{
## It seems Q does not work, well not for me
## and this is the quickest way to fix it.
## You STILL NEED 64 BIT SUPPORT!!
#my ( $number ) = @_;
## any bit to 64bit number in.
#my($test1) = $number & 0xFFFFFFFF; $number >>= 32;
#my($test2) = $number & 0xFFFFFFFF;
#my $message = pack("NN",$test2,$test1);
#return $message;
#}

sub check_data_available
{
my ( $self ) = shift;

$self->send_connect_message();

# Check for data from the IPDR server.
while ( $self->check_data_handles && $self->{_GLOBAL}{'ERROR'}!~/not connected/i )
        {
        $self->get_data_segment();

	while ( $self->{_GLOBAL}{'data_processing'}==1 )
		{

        # If we manage to get some data correctly, decode the message
        # during decoding we may also store information, such as template
        # and data sequencing, however this is done internally to avoid
        # complex code here.
        $self->decode_message_type();

        my $last_message = $self->return_current_type();

	print "Last message was '$last_message'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

	if ( $last_message=~/NULL/i || !$last_message )
		{
		$self->{_GLOBAL}{'data_processing'}=0;
		}

        # If the message is a connect_response, send a flow_start
        if ( $last_message=~/^CONNECT_RESPONSE$/i )
                { 
		$self->log("CONNECT_RESPONSE");
		$self->send_get_sessions(); 
#		$self->update_session_parameters();
		}

	if ( $last_message=~/^GET_SESSIONS_RESPONSE$/i )
		{ $self->send_flow_start_message(); }

        # If the message is a template data, store the template
        # and ack the template
        if ( $last_message=~/^TEMPLATE_DATA$/i )
                {
		$self->log("TEMPLATE_DATA");
		$self->send_final_template_data_ack(); 
		}

        # If the message is a session_start just send a keep
        # alive.
        if ( $last_message=~/^SESSION_START$/i )
                { 
		$self->log("SESSION_START");
		$self->send_get_keepalive(); 
		}

        # If the message is a keep alive, send one back.
        # This function does a little more, but has been
        # made a wrapper to keep the code clean.
        if ( $self->return_current_type()=~/^KEEP_ALIVE$/i )
                { 
		$self->log("KEEP_ALIVE");
		$self->send_get_keepalive(); 
		}

        # If the message is a data message, process it.
        # This also sends one keepalive upon receipt
        # of the first data segment, so keeping to the
        # specification and allowing DSN generation.
        if ( $self->return_current_type()=~/^DATA$/i )
                {
		$self->decode_data( );
                }

	# We need to make sure we decoded the last message
	# before checking if we can throw it out.
        if ( $self->{_GLOBAL}{'data_capture_running'}>=$self->{_GLOBAL}{'MaxRecords'}
                && $self->{_GLOBAL}{'MaxRecords'}>0)
                {
		print "Max records reached was '".$self->{_GLOBAL}{'data_capture_running'}."'\n";
		print "Max records limit   was '".$self->{_GLOBAL}{'MaxRecords'}."\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
                $self->{_GLOBAL}{'data_capture_running'}=0;
                $self->max_records_segment();
                }

	# so if you are receiving more data than a keepalive you may need
	# to send a data_ack
        if ( ((time()-$self->{_GLOBAL}{'data_capture_running_time'})
                        > $self->{_GLOBAL}{'AckTime'})
			&& $self->return_current_type()=~/^DATA$/i )
                {
                if ( defined( $self->get_internal_value('dsn_sequence')) )
                        {
                        $self->{_GLOBAL}{'data_capture_running_time'}=time();
			$self->{_GLOBAL}{'data_capture_data_count'}=0;
			print "Sending AckTime data ack.\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
                        $self->send_data_ack(
                                $self->get_internal_value('dsn_configID'),
                                $self->get_internal_value('dsn_sequence')
                                        );
                        }
                }

	if ( ($self->{_GLOBAL}{'data_capture_data_count'}
			>= $self->{_GLOBAL}{'AckSequence'})
			&& $self->return_current_type()=~/^DATA$/i )
		{
		if ( defined( $self->get_internal_value('dsn_sequence')) )
			{
			$self->{_GLOBAL}{'data_capture_data_count'}=0;
			print "Sending AckSequence data ack.\n\n" if $self->{_GLOBAL}{'DEBUG'}>0;
			$self->send_data_ack(
				$self->get_internal_value('dsn_configID'),
				$self->get_internal_value('dsn_sequence')
					);
			}
		}
	
	if ( (time()-$self->{_GLOBAL}{'data_capture_keep_alive'})
			> $self->{_GLOBAL}{'KeepAlive'} )
		{
		$self->send_message( $self->construct_get_keepalive() );
		$self->{_GLOBAL}{'data_capture_keep_alive'}=time();
		}

        # If the message is a session_stop, we should probably
        # send a disconnect, but we dont as yet.
	# with session stop you need to send a keepalive, as
	# session stop is not always a disconnect.
        if ( $self->return_current_type()=~/^SESSION_STOP$/i )
                {
		$self->log("SESSION_STOP");
		$self->send_get_keepalive();
                #$ipdr_client->{_GLOBAL}{'Selector'}->remove( $ipdr_client->{_GLOBAL}{'Handle'} );
                }

        # If the message is an error message, stop, something
        # went wrong somewhere.
        if ( $self->return_current_type()=~/^ERROR$/i )
                {
		$self->log("ERROR");
		print "Disconnect and closed TCP.\n" if $self->{_GLOBAL}{'DEBUG'}>0;
                return 0;
                }
		}
        }

print "Disconnect and closed TCP.\n" if $self->{_GLOBAL}{'DEBUG'}>0;

return 1;
}

# ***************************************************************

sub log
{
my ( $self ) = shift;
my ( $message ) = shift;
my ( $decode_data ) = $self->{_GLOBAL}{'current_data'};
my ( $time ) = time();

return 1;
}

sub check_data_handles
{
my ( $self ) = shift;
my ( @handle ) = $self->{_GLOBAL}{'Selector'}->can_read( $self->{_GLOBAL}{'KeepAlive'} );
if ( !@handle ) {  $self->{_GLOBAL}{'ERROR'}="Not Connected"; }
$self->{_GLOBAL}{'ready_handles'}=\@handle;
}

sub get_data_segment
{
my ( $self ) = shift;
my ( $header );
my ( $buffer ) = "";
my ( $dataset ) ;

#$self->{_GLOBAL}{'data_received'} = ""; 

my $link;
my ( $version, $type, $session, $flags, $length );
my ( $handles ) = $self->{_GLOBAL}{'ready_handles'};

foreach my $handle ( @{$handles} )
	{ 

	eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 5;
        $link = sysread($handle,$buffer,1024);
        alarm 0;
        };

	if ( $@=~/alarm/i )
        	{ $handle->close(); return 1; }

	print "Read buffer size of '".length($buffer)."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

	if ( !$self->connected )
		{
		$handle->close(); return 1;
		}

	if ( length($buffer) == 0 )
		{
		$handle->close(); return 1;
		}

	$self->{_GLOBAL}{'data_received'} .=$buffer;
	}
print "Length in buffer is '".length($self->{_GLOBAL}{'data_received'})."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
$self->{_GLOBAL}{'data_processing'}=1;
}

sub ReturnPollTime
{
my ( $self ) = shift;
return $self->{_GLOBAL}{'PollTime'};
}

sub get_error
{
my ( $self ) = shift;
return $self->{_GLOBAL}{'ERROR'};
}

sub get_internal_value
{
my ( $self ) = shift;
my ( $attribute ) = shift;
return $self->{_GLOBAL}{$attribute};
}

sub set_internal_value
{
my ( $self ) = shift;
my ( $attrib ) = shift;
my ( $value ) = shift;
$self->{_GLOBAL}{$attrib}=$value;
}

sub decode_data
{
my ( $self ) = shift;
my ( %template_params ) = template_value_definitions();
my ( $resulting_value ) = "";

my ( $exported_data ) = $self->{_GLOBAL}{'complete_decoded_data'};
my ( $record ) = $self->{_GLOBAL}{'current_data'};
my ( $template ) = $self->{_GLOBAL}{'template'};
my ( $template_id ) = ${$record}{'DATA_TemplateID'};
my ( $data ) = ${$record}{'DATA_Data'};

if ( length( $self->{_GLOBAL}{'PacketDirectory'} ) > 0 )
	{
	my $location = $self->{_GLOBAL}{'PacketDirectory'};
	my $epoch = time();
	my $rand = int(rand(100000));
	open (__PACKET_DATA,">$location/packet_$epoch\_$rand");
	print __PACKET_DATA $data;
	close (__PACKET_DATA);
	}

$self->set_internal_value('dsn_sequence',${$record}{'DATA_Sequence'} );
$self->set_internal_value('dsn_configID',${$record}{'DATA_ConfigID'} );

if ( !$self->get_internal_value('data_ack') )
	{
	$self->set_internal_value('data_ack',1);
	$self->send_message( $self->construct_get_keepalive() );
	}

my ( $int_or_dir ) = unpack("N",$data);

# If you can figure out the first line, better person than I
# All i figured out was 'possibly' direction, but this
# might also be interface number so it has not been added 

$data = substr($data,4,length($data)-4);

#${$template}{'Templates'}{$template_id}{'fields'}{$a}{'name'}=$field_name;

foreach my $variable ( sort {$a<=> $b } keys %{${$template}{'Templates'}{$template_id}{'fields'}} )
	{
	print "Type id is '${$template}{'Templates'}{$template_id}{'fields'}{$variable}{'typeID'}' field is '$variable'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	my $type = $template_params{ ${$template}{'Templates'}{$template_id}{'fields'}{$variable}{'typeID'} };
	my $template_type = ${$template}{'Templates'}{$template_id}{'fields'}{$variable}{'name'};

	print "Type name is '".$type."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	print "Template variable name is '".$template_type."'\n" if $self->{_GLOBAL}{'DEBUG'}>0;

	if ( $type=~/^string$/i )
		{ ( $resulting_value, $data ) = _extract_utf8_string ( $data ); }
	if ( $type=~/^network_ip$/i )
		{ ( $resulting_value, $data ) = _extract_ip_string ( $data ); }

	if ( $type=~/^network_int_u$/i )
		{ ( $resulting_value, $data ) = _extract_int_u ( $data ); }

	if ( $type=~/^network_int$/i )
		{ ( $resulting_value, $data ) = $self->_extract_int ( $data ); }

	if ( $type=~/^unknown_/i )
		{ ( $data ) = _extract_unknown ( $data, $type ); }
	if ( $type=~/^mac$/i )
		{ ( $resulting_value, $data ) = _extract_mac ( $self, $data ); }

	if ( $type=~/^long$/i )
		{ ( $resulting_value, $data ) = _extract_long ( $data ); }
	if ( $type=~/^long_u$/i )
		{ ( $resulting_value, $data ) = _extract_long_u ( $data ); }

	if ( $type=~/^float$/i )
		{ ( $resulting_value, $data ) = _extract_float ( $data ); }

	if ( $type=~/^double$/i )
		{ ( $resulting_value, $data ) = _extract_double ( $data ); }

	if ( $type=~/^boolean$/i )
		{ ( $resulting_value, $data ) = _extract_boolean ( $data ); }

	if ( $type=~/^byte$/i )
		{ ( $resulting_value, $data ) = _extract_char ( $data ); }
	if ( $type=~/^byte_u$/i )
		{ ( $resulting_value, $data ) = _extract_char_u ( $data ); }

	if ( $type=~/^short$/i )
		{ ( $resulting_value, $data ) = _extract_short ( $data ); }
	if ( $type=~/^short_u$/i )
		{ ( $resulting_value, $data ) = _extract_short_u ( $data ); }

	if ( $type=~/^ipv6addr$/i )
		{ ( $resulting_value, $data ) = _extract_ipv6addr ( $data ); }

	if ( $type=~/^uuid$/i )
		{ ( $resulting_value, $data ) = _extract_uuid ( $data ); }

	if ( $type=~/^datetimeusec$/i )
		{ ( $resulting_value, $data ) = _extract_datetimeusec ( $data ); }

	if ( $type=~/^ipaddr$/i )
		{ ( $resulting_value, $data ) = _extract_ipaddr ( $data ); }


	if ( $type=~/^ip_list$/i )
		{ ( $resulting_value, $data ) = $self->_extract_list ( $data , $template_type); }
	print "Resulting value is '$resulting_value'\n" if $self->{_GLOBAL}{'DEBUG'}>0;
	${$exported_data}{ ${$record}{'DATA_Sequence'} }{ ${$template}{'Templates'}{$template_id}{'fields'}{$variable}{'name'} }=$resulting_value;
	}
return 1;
}

sub _reverse_pattern
{
my ( $data ) = @_;
my ( $result ) = "";
my ( $data_length ) = length($data);
for ( my $loop=0; $loop<$data_length; $loop++ )
        {
        $result.= substr( $data, ($data_length-$loop)-1, 1);
        }
return $result;
}

sub test_64_bit
{
my $self = shift;

my $tester=576466952313524498;

my $origin = $tester;

#print "Tester is '$tester'\n";

my($test1) = $tester & 0xFFFFFFFF; $tester >>= 32;
my($test2) = $tester & 0xFFFFFFFF;

my $message = pack("NN",$test2,$test1);

my ($part1,$part2) = unpack("NN",$message);

$part1 = $part1<<32;
#$part1 & 0xFFFFFFFF;
$part1+=$part2;

if ( $origin!=$part1 )
        {
        return 0;
        }
        else
        {
        return 1;
        }
}


sub _transform_into_xml
{
my $self = shift;
my $data_pointer = shift;
my $complete;
my $xml;
my $header;
my $footer;

my $ipdrrecorder;
my $ipdrcreationtime;

foreach my $sequence ( sort { $a<=>$b } keys %{$data_pointer} )
        {
	if ( !${$data_pointer}{$sequence}{'CMcpeIpv4List'} )
		{ ${$data_pointer}{$sequence}{'CMcpeIpv4List'}=""; }
	$xml.="<IPDR xsi:type=\"DOCSIS-Type\">";
	$xml.="<IPDRcreationTime>".${$data_pointer}{$sequence}{'RecCreationTime'}."</IPDRcreationTime>";
	$xml.="<CMTShostName>".${$data_pointer}{$sequence}{'CMTShostName'}."</CMTShostName>";
	$xml.="<CMTSipAddress>".${$data_pointer}{$sequence}{'CMTSipAddress'}."</CMTSipAddress>";
	$xml.="<CMTSsysUpTime>".${$data_pointer}{$sequence}{'CMTSsysUpTime'}."</CMTSsysUpTime>";
	$xml.="<CMTScatvIfName>".${$data_pointer}{$sequence}{'CMTScatvIfName'}."</CMTScatvIfName>";
	$xml.="<CMTScatvIfIndex>".${$data_pointer}{$sequence}{'CMTScatvIfIndex'}."</CMTScatvIfIndex>";
	$xml.="<CMTSdownIfName>".${$data_pointer}{$sequence}{'CMTSdownIfName'}."</CMTSdownIfName>";
	$xml.="<CMTSupIfName>".${$data_pointer}{$sequence}{'CMTSupIfName'}."</CMTSupIfName>";
	$xml.="<CMTSupIfType>".${$data_pointer}{$sequence}{'CMTSupIfType'}."</CMTSupIfType>";
	$xml.="<CMmacAddress>".${$data_pointer}{$sequence}{'CMMacAddress'}."</CMmacAddress>";
	$xml.="<CMipAddress>".${$data_pointer}{$sequence}{'CMipAddress'}."</CMipAddress>";
	$xml.="<CMdocsisMode>".${$data_pointer}{$sequence}{'CMdocsisMode'}."</CMdocsisMode>";
	$xml.="<CMCPEipAddress>".${$data_pointer}{$sequence}{'CMcpeIpv4List'}."</CMCPEipAddress>";
	$xml.="<RecType>".${$data_pointer}{$sequence}{'RecType'}."</RecType>";
	$xml.="<serviceIdentifier>".${$data_pointer}{$sequence}{'serviceIdentifier'}."</serviceIdentifier>";
	$xml.="<serviceClassName>".${$data_pointer}{$sequence}{'serviceClassName'}."</serviceClassName>";
	$xml.="<serviceDirection>".${$data_pointer}{$sequence}{'serviceDirection'}."</serviceDirection>";
	$xml.="<serviceOctetsPassed>".${$data_pointer}{$sequence}{'serviceOctetsPassed'}."</serviceOctetsPassed>";
	$xml.="<servicePktsPassed>".${$data_pointer}{$sequence}{'servicePktsPassed'}."</servicePktsPassed>";
	$xml.="<serviceSlaDropPkts>".${$data_pointer}{$sequence}{'serviceSlaDropPkts'}."</serviceSlaDropPkts>";
	$xml.="<serviceSlaDelayPkts>".${$data_pointer}{$sequence}{'serviceSlaDelayPkts'}."</serviceSlaDelayPkts>";
	$xml.="<serviceTimeCreated>".${$data_pointer}{$sequence}{'serviceTimeCreated'}."</serviceTimeCreated>";
	$xml.="<serviceTimeActive>".${$data_pointer}{$sequence}{'serviceTimeActive'}."</serviceTimeActive>";
	$xml.="</IPDR>";
	$ipdrrecorder = ${$data_pointer}{$sequence}{'CMTShostName'};
        }
$ipdrcreationtime = ctime();
$header = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
$header .= "<IPDRDoc ";
$header .= "xmlns=\"http://www.ipdr.org/namespaces/ipdr\" ";
$header .= "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" ";
$header .= "xsi:schemaLocation=\"DOCSIS-3.1-B.0.xsd\" ";
$header .= "docId=\"CEABBE99-0000-0000-0000-000000000000\" ";
$header .= "creationTime=\"".$ipdrcreationtime."\" ";
$header .= "IPDRRecorderInfo=\"$ipdrrecorder\" ";
$header .= "version=\"99.99\">";
$footer .= "<IPDRDoc.End count=\"".scalar( keys %{$data_pointer})."\" endTime=\"".$ipdrcreationtime."\"/>";
$footer .= "</IPDRDoc>";
$complete = $header.$xml.$footer;

return $complete;
}

sub _send_to_clear_destination
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $length_sent ) = 0;
my ( $send_size ) = 1000;

my $child;

if ( $self->{_GLOBAL}{'RemoteMulti'} )
        {
        # Multi remote needs to fork out the sending so it can
        # do all the destinations at once otherwise it *may*
        # take a while to get through any number of
        # destinations set.
        #
        # Multiple destination is set to the follow
        #
        # Destination IP:Destination Port:Destination Speed,
        #
        # if using secure then you need to make sure the
        # keys are the same for each destination host.
        #
        foreach my $destination ( split(/,/,$self->{_GLOBAL}{'RemoteMulti'}) )
                {
                if ($child=fork)
                        { } elsif (defined $child)
                                {
                                my ( $remoteip, $remoteport, $remotespeed ) = (split(/:/,$destination))[0,1,2];
				if ( !$remoteip || !$remoteport )
					{
					waitpid($child,0);
					exit(0);
					}
				if ( !$remotespeed )
					{
					$remotespeed=10;
					}
                                my $lsr;
                                if ( $self->{_GLOBAL}{'RemoteSecure'} )
                                        {
                                        $lsr = IO::Socket::SSL->new
                                                (
                                                PeerAddr => $remoteip,
                                                PeerPort => $remoteport,
                                                SSL_key_file => $self->{_GLOBAL}{'SSLKeyFile'},
                                                ReuseAddr => 1,
                                                Proto     => 'tcp',
                                                Timeout    => 5
                                                        );
                                        }
                                        else
                                        {
                                        $lsr = IO::Socket::INET->new
                                                (
                                                PeerAddr => $remoteip,
                                                PeerPort => $remoteport,
                                                ReuseAddr => 1,
                                                Proto     => 'tcp',
                                                Timeout    => 5
                                                        );
                                        }
#                                $lsr->autoflush(0);
                                if ( !$lsr )
                                        {
                                        waitpid($child,0);
                                        exit(0);
                                        }
                                my $selector = new IO::Select( $lsr );
                                my $timer = (1/($remotespeed/8) )*$send_size;
                                my $print_status = 1;
                                my $chunk;
                                while ( length($data)>0 && (my @ready = $selector->can_write ) )
                                        {
                                        foreach my $write ( @ready )
                                                {
                                                if ( $write == $lsr )
                                                        {
                                                        #print "handle is '$write'\n";
                                                        if ( length($data)<=$send_size)
                                                                {
                                                                #print "ASending '$data'\n\n\n";
                                                                $print_status = print $write $data;
                                                                $data = "";
                                                                }
                                                                else
                                                                {
                                                                $chunk = substr($data,0,$send_size);
                                                                $print_status = print $write $chunk;
                                                                #print "BSending '$chunk'\n\n\n";
                                                                $data = substr($data,$send_size,length($data)-$send_size);
                                                                }
                                                        }
                                                }
                                        # Timer added for remotesendspeed. Useful for management networks with limited
                                        # speed, such as 10mb/s or even t1/e1 speeds of 1.6/2 Mbp/s
                                        usleep($timer);
                                        #print "Ending pass for send.\n";
                                        }
				usleep(100000);
                                $lsr->close();
                                waitpid($child,0);
                                exit(0);
                                }
                }
        }
        else
        {
	if ($child=fork)
		{ } elsif (defined $child)
	{
        my $lsr;
        if ( $self->{_GLOBAL}{'RemoteSecure'} )
                {
                $lsr = IO::Socket::SSL->new
                        (
                        PeerAddr => $self->{_GLOBAL}{'RemoteIP'},
                        PeerPort => $self->{_GLOBAL}{'RemotePort'},
                        SSL_key_file => $self->{_GLOBAL}{'SSLKeyFile'},
                        ReuseAddr => 1,
                        Proto     => 'tcp',
                        Timeout    => 5
                        );
                }
                else
                {
		#print "Remote IP is '".$self->{_GLOBAL}{'RemoteIP'}."'\n";
		#print "Remote Port is '".$self->{_GLOBAL}{'RemotePort'}."'\n";
                $lsr = IO::Socket::INET->new
                        (
                        PeerAddr => $self->{_GLOBAL}{'RemoteIP'},
                        PeerPort => $self->{_GLOBAL}{'RemotePort'},
                        ReuseAddr => 1,
                        Proto     => 'tcp',
                        Timeout    => 5
                        );
                }
        if (!$lsr)
                {
		waitpid($child,0);
                return 0;
                }
#	$lsr->autoflush(0);
        my $selector = new IO::Select( $lsr );
        my $timer = (1/($self->{_GLOBAL}{'RemoteSpeed'}/8) )*$send_size;
        my $chunk;
        my $print_status = 1;
        while ( length($data)>0 && (my @ready = $selector->can_write ) && $print_status )
                {
                foreach my $write ( @ready )
                                {
                                if ( $write == $lsr )
                                        {
                                        #print "handle is '$write'\n";
                                        if ( length($data)<=$send_size)
                                                {
                                                print "ASending '$data'\n\n\n";
                                                $print_status = print $write $data;
						# we need the last data chunk
						#$padding = $data;
						$data = "";
						# we need the final write handle.
                                                }
                                                else
                                                {
                                                $chunk = substr($data,0,$send_size);
                                                $print_status = print $write $chunk;
                                                print "BSending '$chunk'\n\n\n";
                                                $data = substr($data,$send_size,length($data)-$send_size);
                                                }
                                        }
                                }
                usleep($timer);
                }
	# ok so why does this work ?
	# from experiments the final chunk does not seem to be sent, so here
	# we send it again ....
	usleep(100000);
        $lsr->close();
	waitpid($child,0);
        }

	}

return 1;
}


=head1 AUTHOR

Andrew S. Kennedy, C<< <shamrock at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-ipdr-cisco at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPDR-Collection-Client>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPDR::Collection::Client

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IPDR-Collection-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IPDR-Collection-Client>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPDR-Collection-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/IPDR-Collection-Client>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to http://www.streamsolutions.co.uk/ for my Flash Streaming Server

=head1 COPYRIGHT & LICENSE

Copyright 2011 Andrew S. Kennedy, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of IPDR::Collection::Client
