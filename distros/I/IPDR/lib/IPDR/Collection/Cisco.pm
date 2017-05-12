package IPDR::Collection::Cisco;

use warnings;
use strict;
use IO::Select;
use IO::Socket;
use IO::Socket::SSL;
use POSIX;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres );

$SIG{CHLD}="IGNORE";

=head1 NAME

IPDR::Collection::Cisco - IPDR Collection Client (Cisco Specification)

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
    use IPDR::Collection::Cisco;

    my $ipdr_client = new IPDR::Collection::Cisco (
                        [
                        VendorID => 'IPDR Client',
                        ServerIP => '192.168.1.1',
                        ServerPort => '5000',
                        Timeout => 2,
                        Type => 'docsis',
                        DataHandler => \&display_data,
                        ]
                        );

    # Check for data from the IPDR server.
    my $status = $ipdr_client->connect();

    if ( !$status )
        {
        print "Status was '".$ipdr_client->return_status()."'\n";
        print "Error was '".$ipdr_client->return_error()."'\n";
        exit(0);
        }

    $ipdr_client->check_data_available();

    exit(0);

    sub display_data
    {
    my ( $remote_ip ) = shift;
    my ( $remote_port ) = shift;
    my ( $data ) = shift;
    my ( $self ) = shift;

    foreach my $host ( sort { $a<=> $b } keys %{$data} )
        {
        print "Host  is '$host' \n";
        foreach my $document_attribute ( keys %{${$data}{$host}{'document'}} )
                {
                print "Document id '$document_attribute' ";
                print "value is '${$data}{$host}{'document'}{$document_attribute}'\n";
                }

        foreach my $sequence ( keys %{${$data}{$host}} )
                {
                next if $sequence=~/^document$/i;
                foreach my $attribute ( keys %{${$data}{$host}{$sequence}} )
                        {
                        print "Sequence is '$sequence' Attribute is '$attribute' ";
                        print "value is '${$data}{$host}{$sequence}{$attribute}'\n";
                        }
                }
        }
    return 1;
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

    Type -

         Cisco: Only applied to Cisco and currently only 'docsis' works.
                If omitted then the raw XML data is returned

    XMLDirectory -

         Cisco: Only applied to the Cisco module and will force the writing
                of the XML to the directory specific, filename being the IP
                address of the sending router.

    RemoteAddr
	
         IP address of remote server to send on data to

    RemotePort

         Port of remote server to send on data to

    RemoteTimeOut

         Timeout for connection

    RemoteSpeed

         Speed at which to send data. It is a number in Mbps, the
         default is 10. You can use decimal such as 0.5 to mean 500kbps.

    RemoteMulti

         This paramter allows multiple destinations to receive XML. The
         list is a comma separate list of remote end points and their
         parameters. An example would be

         10.1.1.1:9000:10,20.1.1.1:9000:50

         The parameters are as follows

         Destination IP:Destination Port:Destination Bandwidth

         You can omit destination bandwidth and it will default to 10

    Force32BitMode

         This turns OFF all 64bit checks. Useful for running with older
         routers such as Cisco7200 UBRs.
        
    KeepAlive - This defaults to 60, but can be set to any value.
    Capabilities - This defaults to 0x01 and should not be set to much else.
    TimeOut - This defaults to 5 and is passed to IO::Socket (usefulness ?!)
    DataHandler - This MUST be set and a pointer to a function (see example)
    DEBUG - Set at your peril, 5 being the highest value.

An example of using new is

    my $ipdr_client = new IPDR::Collection::Cisco (
                        [
                        VendorID => 'IPDR Client',
                        ServerIP => '192.168.1.1',
                        ServerPort => '5000',
                        DataHandler => \&display_data,
			Type => 'docsis',
                        Timeout => 2,
                        ]
                        );

=head2 connect

This uses the information set with new and attempts to connect/setup a
client/server configuration. The function returns 1 on success, 0
on failure. It should be called with

    $ipdr_client->connect();

=head2 check_data_available

This function controls all the communication for IPDR. It will, when needed,
send data to the DataHandler function. It should be called with

    $ipdr_client->check_data_available();

=head2 ALL OTHER FUNCTIONs

The remaining of the functions should never be called and are considered internal
only. They do differ between Client and Cisco however both module provide the same
generic methods, high level, so the internal workings should not concern the
casual user.

=cut

sub new {

        my $self = {};
        bless $self;

        my ( $class , $attr ) =@_;

        my ( %handles );
	my ( %complete_decoded_data );

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

        if ( !$self->{_GLOBAL}{'Timeout'} )
                { $self->{_GLOBAL}{'Timeout'}=5; }

        if ( !$self->{_GLOBAL}{'Type'} )
                { $self->{_GLOBAL}{'Type'}=0; }

	if ( !$self->{_GLOBAL}{'RemoteIP'} )
		{ $self->{_GLOBAL}{'RemoteIP'}=""; }

	if ( !$self->{_GLOBAL}{'RemotePort'} )
		{ $self->{_GLOBAL}{'RemotePort'}=""; }

	if ( !$self->{_GLOBAL}{'RemotePassword'} )
		{ $self->{_GLOBAL}{'RemotePassword'}=""; }

	if ( !$self->{_GLOBAL}{'RemoteTimeOut'} )
		{ $self->{_GLOBAL}{'RemoteTimeOut'}=120; }

	if ( !$self->{_GLOBAL}{'RemoteSpeed'} )
		{ $self->{_GLOBAL}{'RemoteSpeed'}=10; }

	if ( !$self->{_GLOBAL}{'Force32BitMode'} )
		{ $self->{_GLOBAL}{'Force32BitMode'}=0; }

        if ( !$self->{_GLOBAL}{'XMLDirectory'} )
                { $self->{_GLOBAL}{'XMLDirectory'}=0; }

        if ( !$self->{_GLOBAL}{'DataHandler'} )
                { die "DataHandler Function Must Be Defined"; }

        if ( !$self->{_GLOBAL}{'PollTime'} )
                { $self->{_GLOBAL}{'PollTime'}=900 }

        $self->{_GLOBAL}{'handles'}= \%handles;
	$self->{_GLOBAL}{'complete_decoded_data'} = \%complete_decoded_data;

        return $self;
}

sub get_data_segment
{
my ( $self ) = shift;
my ( $dataset ) = "";

my ( $handles ) = $self->{_GLOBAL}{'handles'};
my ( $current_handles ) = $self->{_GLOBAL}{'ready_handles'};

foreach my $handle ( @{$current_handles} )
        {
	print "Handle is '$handle'\n" if $self->{_GLOBAL}{'DEBUG'}>5;
	if ( $handle==$self->{_GLOBAL}{'Handle'} )
		{
		my $new = $self->{_GLOBAL}{'Handle'}->accept;
		$self->{_GLOBAL}{'Selector'}->add($new);
		$self->send_connection_header($new);
		}
		else
		{
		my $link = 0;
		$dataset="";
		$link = sysread($handle,$dataset,1024);
		if ( !$link )
			{
			my $child;
			${$handles}{$handle}{'data'}.=$dataset;
			if ($child=fork)
				{ } elsif (defined $child)
				{
				
				print "rmote address is '".${$handles}{$handle}{'addr'}."'\n" if $self->{_GLOBAL}{'DEBUG'}>5;
				print "rmote port is '".${$handles}{$handle}{'port'}."'\n" if $self->{_GLOBAL}{'DEBUG'}>5;
				if ( $self->{_GLOBAL}{'XMLDirectory'} )
					{
					if ( !${$handles}{$handle}{'data'} )
					{} else {
					if ( open (__FILE,">".$self->{_GLOBAL}{'XMLDirectory'}."/".${$handles}{$handle}{'addr'}) )
						{
						print __FILE ${$handles}{$handle}{'data'};
						close __FILE; 
						}
						}
					}
				#$SIG{CHLD}="IGNORE";
				#setsid;
				foreach my $handler ( keys %{$handles} )
					{ if ( $handler ne $handle ) { delete ${$handles}{$handler}; } }
				if ( !${$handles}{$handle} ) { waitpid($child,0); exit(0); }
				if ( $self->{_GLOBAL}{'Type'}=~/^docsis/ig )
					{
					my %result = $self->_process_docsis(${$handles}{$handle}{'addr'},${$handles}{$handle}{'data'});
					if ( scalar(keys %result)>0 )
						{
						$self->{_GLOBAL}{'DataHandler'}->(
						${$handles}{$handle}{'addr'},
						${$handles}{$handle}{'port'},
						\%result,
						$self
						);
						}
					}
					else
					{
					$self->{_GLOBAL}{'DataHandler'}->(
						${$handles}{$handle}{'addr'},
						${$handles}{$handle}{'port'},
						${$handles}{$handle}{'data'},
						$self
						);
					}
				# remote sending needs to go here.
				if ( $self->{_GLOBAL}{'RemoteIP'} && $self->{_GLOBAL}{'RemotePort'} )
					{
					$self->_send_to_clear_destination(${$handles}{$handle}{'data'});
					}
				waitpid($child,0);
				exit(0);
				}
			if ( ${$handles}{$handle}{'addr'} )
				{
				if ( $self->{_GLOBAL}{'complete_decoded_data'}{ ${$handles}{$handle}{'addr'} } )
					{ undef $self->{_GLOBAL}{'complete_decoded_data'}{ ${$handles}{$handle}{'addr'} }; }
				}
			delete ${$handles}{$handle};
			$self->{_GLOBAL}{'Selector'}->remove($handle);
			$handle->close();
			}
	
			if ( $link )
				{
				${$handles}{$handle}{'data'}.=$dataset;
				${$handles}{$handle}{'addr'}=$handle->peerhost() if !${$handles}{$handle}{'addr'};
				${$handles}{$handle}{'port'}=$handle->peerport() if !${$handles}{$handle}{'port'};
				}
		}
	}
return 1;
}

sub ReturnPollTime
{
my ( $self ) = shift;
return $self->{_GLOBAL}{'PollTime'};
}

sub return_error
{
my ( $self ) = shift;
return $self->{_GLOBAL}{'ERROR'};
}

sub return_status
{
my ( $self ) = shift;
return $self->{_GLOBAL}{'STATUS'};
}

sub connect
{
my ( $self ) = shift;

if ( !$self->test_64_bit() && $self->{_GLOBAL}{'Force32BitMode'}==0 )
        {
        # if you forgot to run make test, this will clobber
        # your run anyway.
	die '64Bit support not available must stop.';
	}

my $lsn = IO::Socket::INET->new
                        (
			Listen	  => 1024,
			LocalAddr => $self->{_GLOBAL}{'ServerIP'},
			LocalPort => $self->{_GLOBAL}{'ServerPort'},			
                        ReuseAddr => 1,
                        Proto     => 'tcp',
                        Timeout    => $self->{_GLOBAL}{'Timeout'}
                        );
if (!$lsn)
        {
        $self->{_GLOBAL}{'STATUS'}="Failed to bind to address '".$self->{_GLOBAL}{'ServerIP'}."' ";;
	$self->{_GLOBAL}{'STATUS'}.="and port '".$self->{_GLOBAL}{'ServerPort'};
        $self->{_GLOBAL}{'ERROR'}=$!;
        return 0;
        }

$self->{_GLOBAL}{'Handle'} = $lsn;
$self->{_GLOBAL}{'Selector'}=new IO::Select( $lsn );
$self->{_GLOBAL}{'STATUS'}="Success Connected";
return 1;
}

sub check_data_available
{
my ( $self ) = shift;

while ( $self->check_data_handles )
        { $self->get_data_segment(); }

$self->{_GLOBAL}{'STATUS'}="Socket Closed";
$self->{_GLOBAL}{'ERROR'}="Socket Closed";
}


sub check_data_handles
{
my ( $self ) = shift;
my ( @handle ) = $self->{_GLOBAL}{'Selector'}->can_read;
$self->{_GLOBAL}{'ready_handles'}=\@handle;
}

sub send_connection_header
{
my ( $self ) = shift;
my ( $handle ) = shift;
my ( $header ) = $self->{_GLOBAL}{'VendorID'};
if ( $self->{_GLOBAL}{'DEBUG'}>0 )
	{ $header.=" Debug Level ".$self->{_GLOBAL}{'DEBUG'}; }
$header.="\n";
syswrite($handle,$header,length($header));
return 1;
}

sub _process_docsis
{
my ( $self ) = shift;
my ( $host_ip ) = shift;
my ( $raw_data ) = shift;

my ( %result, $direction );
if ( $raw_data!~/ipdrdoc/ig )
        { return %result; }

# now we should really use a XML parser
# two problems
# i) this module really needs to be fast
# ii) Cisco CMTS depending on the IOS version send out
#     unparsable XML.

my ( $header,$body,$footer ) = (split(/<IPDRDoc/,$raw_data))[0,1,2];
my ( @body_parts ) = split(/\<IPDR\s/,$body);

my @footer_params = qw [ count endTime ];
foreach my $footerp ( @footer_params )
	{
	my ( $value ) = (split(/\"/,(split(/$footerp=\"/,$footer))[1]))[0];
	$result{$host_ip}{'document'}{$footerp}=$value;
	}

$header=$body_parts[0];

my @header_params = qw [ docId creationTime IPDRRecorderInfo version xmlns xmlns:xsi xsi:schemaLocation ];
foreach my $headerp ( @header_params )
	{
	my ( $value ) = (split(/\"/,(split(/$headerp=\"/,$header))[1]))[0];
	$result{$host_ip}{'document'}{$headerp}=$value;
	}
#my $version=substr($result{$host_ip}{'document'}{'version'},0,3);

my $version=$result{$host_ip}{'document'}{'version'}; $version = (split(/-/,$version))[0];

my ( @direction_name )= qw [ blank Downstream Upstream ];

# Load up the the different IPDR version templates we can use
# Currently supported is 3.1 and 3.5.
# There are no checks at present if a different version is sent to us.
my ( $template_data ) = return_template_data();
my ( $entry_count ) = 0;

if ( !${$template_data}{$version} ) { return %result; };

foreach my $entry ( @body_parts )
        {
	$direction="";
	next if $entry=~/xmlns/;
        $entry=~s/\<\/IPDR\>//g;
        my ( $type ) = (split(/xsi:type=\"/, (split(/\">/,$entry))[0] ))[1];
        next unless $type=~/^DOCSIS-Type/i;
        $entry = (split(/\">/,$entry))[1];

        # now we have a clean ipdr line, all attributes with opens and closes

        my %inner_keys;
        foreach my $attrib ( split(/\<\//,$entry) )
                {
                my ( $close_attrib ) = (split(/\</,$attrib))[1]; 
		next unless $close_attrib;
		my ( $name , $value ) = (split(/\>/,$close_attrib))[0,1];
                next unless $name; $inner_keys{$name}=$value;
                }

        if ( $version=~/^3.1/ )
                {
                next if scalar(keys %inner_keys)<16;
                $direction = $inner_keys{'SFdirection'}; }

        if ( $version=~/^3.5/ )
                {
                next if scalar(keys %inner_keys)<22;
                $direction = $direction_name[$inner_keys{'serviceDirection'}];
                }

        if ( $version=~/^99.99/ )
                {
                $direction = $direction_name[$inner_keys{'serviceDirection'}];
                }

	next unless $direction;

        my $subscriber = $inner_keys{ ${$template_data}{$version}{'all-CMmacAddress'} };

	foreach my $attribute ( keys %{${$template_data}{$version}} )
		{
		my ( $parent, $test ) = (split(/-/,$attribute))[0,1];
		next unless $inner_keys{ ${$template_data}{$version}{$attribute} };
		$result{$host_ip}{$entry_count}{$test} = $inner_keys{ ${$template_data}{$version}{$attribute} };
		}

#        foreach my $attribute ( keys %{${$template_data}{$version}} )
#                {
#                my ( $parent, $test ) = (split(/-/,$attribute))[0,1];
#			#next if $parent=~/direction/i;
#		next unless $inner_keys{ ${$template_data}{$version}{$attribute} };
#                        if ( $parent=~/^all/ )
#                                { $result{$subscriber}{ $test }=
#					$inner_keys{ ${$template_data}{$version}{$attribute} }; }
#                                else
#                                { $result{$subscriber}{$direction}{ $test }= 
#					$inner_keys{ ${$template_data}{$version}{$attribute} }; }
#                }


	$entry_count++;
        }

return %result;
}

sub _send_to_clear_destination
{
my ( $self ) = shift;
my ( $data ) = shift;
my ( $length_sent ) = 0;
my ( $send_size ) = 1000;

#RemoteSecure
#RemoteMulti
#print "Sending data is \n\n$data\n\n";

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
        my $child;
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
                                        { $remotespeed=10; }
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
                                if ( !$lsr )
                                        {
                                        waitpid($child,0);
                                        exit(0);
                                        }
                                $lsr->autoflush(0);
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
                return 0;
                }
        $lsr->autoflush(0);
        my $selector = new IO::Select( $lsr );
        my $timer = (1/($self->{_GLOBAL}{'RemoteSpeed'}/8) )*$send_size;
        my $chunk;
        my $print_status = 1;
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
                usleep($timer);
                }
        usleep(100000);
        $lsr->close();
        }

return 1;
}

sub return_template_data
{

my ( %templates ) =
	(
	'3.1' =>
		{ 
		'all-CMmacAddress' => 'subscriberId',
		'all-serviceTimeCreated'  => 'IPDRcreationTime',
		'all-serviceClassName'	=> 'serviceClassName',
		'direction-serviceDirection' => 'SFdirection',
		'all-CMcpeIpv4List' => 'CPEipAddress',
		'all-CMipAddress' => 'CMipAddress',
		'Upstream-servicePktsPassed' => 'pktsPassed',
		'Downstream-servicePktsPassed' => 'pktsPassed',
		'Upstream-serviceOctetsPassed' => 'octetsPassed',
		'Downstream-serviceOctetsPassed' => 'octetsPassed',
		'Upstream-serviceSlaDelayPkts' => 'SLAdelayPkts',
		'Downstream-serviceSlaDelayPkts' => 'SLAdelayPkts',
		'Upstream-serviceSlaDropPkts' => 'SLAdropPkts',
		'Downstream-serviceSlaDropPkts' => 'SLAdropPkts',
		'Upstream-serviceIdentifier' => 'SFID',
		'Downstream-serviceIdentifier' => 'SFID',
		'Upstream-serviceTimeActive' => 'serviceTimeActive',
		'Downstream-serviceTimeActive' => 'serviceTimeActive',
		'all-CMTShostname' => 'CMTShostname',
		'all-CMdocsisMode' => 'CMdocsisMode',
		'all-CMTSipAddress' => 'CMTSipAddress',
		'all-CMTSsysUpTime' => 'CMTSsysUpTime'
		}
		,
	'3.5' =>
		{
		'all-CMmacAddress' => 'CMmacAddress',
		'all-serviceClassName'  => 'serviceClassName',
		'all-serviceTimeCreated'  => 'serviceTimeCreated',
		'direction-serviceDirection' => 'serviceDirection',
		'all-CMcpeIpv4List' => 'CMCPEipAddress',
		'all-CMipAddress' => 'CMipAddress',
		'Upstream-servicePktsPassed' => 'servicePktsPassed',
		'Downstream-servicePktsPassed' => 'servicePktsPassed',
		'Upstream-serviceOctetsPassed' => 'serviceOctetsPassed',
		'Downstream-serviceOctetsPassed' => 'serviceOctetsPassed',
		'Upstream-serviceIdentifier' => 'serviceIdentifier',
		'Downstream-serviceIdentifier' => 'serviceIdentifier',
		'Upstream-serviceSlaDelayPkts' => 'serviceSlaDelayPkts',
		'Downstream-serviceSlaDelayPkts' => 'serviceSlaDelayPkts',
		'Upstream-serviceSlaDropPkts' => 'serviceSlaDropPkts',
		'Downstream-serviceSlaDropPkts' => 'serviceSlaDropPkts',
		'Upstream-serviceTimeActive' => 'serviceTimeActive',
		'Downstream-serviceTimeActive' => 'serviceTimeActive',
		'all-CMTShostName' => 'CMTShostName',
		'all-IPDRcreationTime' => 'IPDRcreationTime',
		'all-RecType' => 'RecType',
		'all-CMdocsisMode' => 'CMdocsisMode',
		'all-CMTSdownIfName' => 'CMTSdownIfName',
		'all-CMTSupIfName' => 'CMTSupIfName',
		'all-CMTSipAddress' => 'CMTSipAddress',
		'all-CMTSsysUpTime' => 'CMTSsysUpTime'
		},
	'99.99' =>
		{
		'all-CMmacAddress' => 'CMmacAddress',
		'all-serviceClassName'  => 'serviceClassName',
		'all-serviceTimeCreated'  => 'serviceTimeCreated',
		'direction-serviceDirection' => 'serviceDirection',
		'all-CMcpeIpv4List' => 'CMCPEipAddress',
		'all-CMipAddress' => 'CMipAddress',
		'Upstream-servicePktsPassed' => 'servicePktsPassed',
		'Downstream-servicePktsPassed' => 'servicePktsPassed',
		'Upstream-serviceOctetsPassed' => 'serviceOctetsPassed',
		'Downstream-serviceOctetsPassed' => 'serviceOctetsPassed',
		'Upstream-serviceIdentifier' => 'serviceIdentifier',
		'Downstream-serviceIdentifier' => 'serviceIdentifier',
		'Upstream-serviceSlaDelayPkts' => 'serviceSlaDelayPkts',
		'Downstream-serviceSlaDelayPkts' => 'serviceSlaDelayPkts',
		'Upstream-serviceSlaDropPkts' => 'serviceSlaDropPkts',
		'Downstream-serviceSlaDropPkts' => 'serviceSlaDropPkts',
		'Upstream-serviceTimeActive' => 'serviceTimeActive',
		'Downstream-serviceTimeActive' => 'serviceTimeActive',
		'all-CMTShostName' => 'CMTShostName',
		'all-IPDRcreationTime' => 'IPDRcreationTime',
		'all-RecType' => 'RecType',
		'all-CMdocsisMode' => 'CMdocsisMode',
		'all-CMTSdownIfName' => 'CMTSdownIfName',
		'all-CMTSupIfName' => 'CMTSupIfName',
		'all-CMTSipAddress' => 'CMTSipAddress',
		'all-CMTSsysUpTime' => 'CMTSsysUpTime'
		}
	);

return \%templates;
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

=head1 AUTHOR

Andrew S. Kennedy, C<< <shamrock at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-ipdr-cisco at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPDR-Collection-Cisco>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPDR::Cisco

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IPDR-Collection-Cisco>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IPDR-Collection-Cisco>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPDR-Collection-Cisco>

=item * Search CPAN

L<http://search.cpan.org/dist/IPDR-Collection-Cisco>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2011 Andrew S. Kennedy, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of IPDR::Collection::Cisco
