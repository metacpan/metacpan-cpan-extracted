#!/usr/local/bin/perl

use strict;
use IPDR::Collection::Client;

my $ipdr_client = new IPDR::Collection::Client (
			[
			VendorID => 'IPDR Client',
			ServerIP => '192.168.1.1',
			ServerPort => '6000',
			KeepAlive => 60,
			Capabilities => 0x01,
			DataHandler => \&display_data,
			Warning64BitOff =>1,
			InitiatorID => '10.1.1.1',
			DEBUG => 5,
			Timeout => 2,
			]
			);

while (1)
	{

# We send a connect message to the IPDR server
# if we connect start talking IPDR.
if ( $ipdr_client->connect() )
	{
	$ipdr_client->check_data_available();
	}

# If we get here, wait an amount of time, say 10 seconds

sleep(10);

	}

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
		print "Sequence '$sequence' attribute '$attribute' value '${$data}{$sequence}{$attribute}'\n";
		}
	}

}


