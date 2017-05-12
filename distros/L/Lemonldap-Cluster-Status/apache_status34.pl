#!/usr/bin/perl -w

#====================================================================
# Script designed for Cacti http://www.raxnet.net/products/cacti/
# Returns informations from the server status page of Apache
#
# You need to configure Apache to enable server-status :
#
# ExtendedStatus	On
# <Location /server-status>
# 	SetHandler server-status
# 	Order deny,allow
# 	Deny from all
# 	Allow from IPCACTI/255.255.255.255
# </Location>        
#
# 2005 (c) Clement OUDOT - LINAGORA
#
# GPL license
#====================================================================

#====================================================================
# Packages
#====================================================================
use strict;
use LWP;
use Getopt::Std;

#====================================================================
# Global parameters
#====================================================================
my ( $host, $port, $path, $timeout ) = &options ;

#====================================================================
# Create an User Agent
#====================================================================	
my $ua = LWP::UserAgent->new;
$ua->agent("CactiScript/1.0");
$ua->timeout($timeout);

#====================================================================
# HTTP Request
#====================================================================
my $request = HTTP::Request->new(GET => "http://${host}:${port}${path}");

#====================================================================
# HTTP Response
#====================================================================

my $response = $ua->request($request);

if ( $response->is_error ) {
	print "Unable to get $path\n";
	my $m = $response->message ;
	print "pb = $m \n";
	exit 1;
}

my $content = $response->content ;
#print $content ;

#====================================================================
# Parse response
#====================================================================
my ($total_accesses) = ( $content =~ /Total accesses: (\d*)/i ) ;
my ($total_traffic) = ( $content =~ /Total traffic: (\d*\.?\d*)/i ) ;
# 3/01/2006 : modif pour pouvoir parser cluster-status => 1 ou 2 espaces avant "requests currently..
my ($current_requests) = ( $content =~ /(\d*) {1,2}requests currently being processed/i ) ;
my ($idle_servers) = ( $content =~ /(\d*) idle servers/i ) ;

#====================================================================
# Print results for Cacti
#====================================================================
print "total_accesses:$total_accesses total_traffic:$total_traffic current_requests:$current_requests idle_servers:$idle_servers";

exit 0 ;

#====================================================================
# Local functions
#====================================================================
sub options {
	# Get and check args
	my %opts ;
	getopt('hpPt',\%opts) ;
	&usage unless (exists($opts{"h"})) ;
	$opts{"p"} = 80 unless (exists($opts{"p"})) ;
	$opts{"P"} = "/server-status/" unless (exists($opts{"P"})) ;
	$opts{"t"} = 25 unless (exists($opts{"t"})) ; # defaut = 5 (augmenté a 25 le 16/1/06)
	return ( $opts{"h"}, $opts{"p"}, $opts{"P"}, $opts{"t"} ) ;
}

sub usage {
	# Print Help/Error message
	print STDERR "Usage: $0 -h hostname (-p port -P path -t timeout)\n" ;
	exit 1 ;
}
