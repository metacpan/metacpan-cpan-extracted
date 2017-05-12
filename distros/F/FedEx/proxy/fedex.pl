#!f:\perl\bin\perl.exe

#--/-fedex.pl - part of Business::FedEx -/------------------#
#--/-By: Patrick Tully-/------------------------------------#


use FedEx::ShipAPI;
use CGI;
use strict;

my $query = new CGI;
my @keys = $query->keywords();
my $buf = $query->param('buf');

my $q = new CGI;

#my $buf = '0"2"';
my $fedex = "FedEx::ShipAPI"->new(username=>'davanita', password=>'zxcpoi');
print "Content-type: text/plain\n\n";

$buf = $buf.'99,""';
$buf =~ s/\'//g;
$fedex->connect();
my $response = $fedex->transaction($buf);
$fedex->disconnect();
##TESTMODE##my $response = "test mode";
print "$response";

