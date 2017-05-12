#!/usr/local/bin/perl

use strict;
use IPDR::Collection::CiscoSSL;

my $ipdr_client = new IPDR::Collection::CiscoSSL (
			[
			SSLKeyFile => 'pubhostkey.pem',
			SSLCertFile => 'pubhostcert.pem',
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
                print "Document id '$document_attribute' value is '${$data}{$host}{'document'}{$document_attribute}'\n";
                }

        foreach my $sequence ( keys %{${$data}{$host}} )
                {
                next if $sequence=~/^document$/i;
                foreach my $attribute ( keys %{${$data}{$host}{$sequence}} )
                        {
                        print "Sequence is '$sequence' Attribute is '$attribute' value is '${$data}{$host}{$sequence}{$attribute}'\n";
                        }
                }

        }

return 1;
}

