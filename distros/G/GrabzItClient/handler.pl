#!/usr/bin/perl

use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser); 
use Config::IniFiles;
use File::Spec;
use GrabzIt::GrabzItClient;

# This Perl file handles the GrabzIt callback

print "HTTP/1.0 200 OK";
print "Content-type: text/html\r\n\r\n";

$cgi = new CGI;

my $ConfigFile = 'config.ini';
tie my %ini, 'Config::IniFiles', (-file => $ConfigFile);
my %Config = %{$ini{"GrabzIt"}};

$message = $cgi->param("message");
$customId = $cgi->param("customid");
$id = $cgi->param("id");
$filename = $cgi->param("filename");
$format = $cgi->param("format");
$targetError = $cgi->param("targeterror");

# Custom id can be used to store user ids or whatever is needed for the later processing of the
# resulting screenshot

$grabzIt = new GrabzItClient($Config{applicationKey}, $Config{applicationSecret});
$result = $grabzIt->GetResult($id);

if ($result)
{
	# Ensure that the application has the correct rights for this directory.
	open FILE, ">".File::Spec->catfile("results",$filename) or die $!; 
	binmode FILE;
	print FILE $result; 
	close FILE;
}
1;