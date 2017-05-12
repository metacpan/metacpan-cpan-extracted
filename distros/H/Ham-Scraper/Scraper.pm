package Ham::Scraper;

use 5.008008;
use strict;
use warnings;
use diagnostics;

use FileHandle;
use HTML::TableExtract;
use HTTP::Request::Common qw(GET POST);
use LWP::Simple;
use LWP::UserAgent;
use Net::HTTP;
use XML::Element;
use XML::TreeBuilder;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = ( [ qw(FindU FindUXml APRSWorld APRSWorldXml QRZ QRZxml) ] );

our $VERSION = '0.9';

sub AppendElement
{
	my $tree = shift;
	my $elementName = shift;
	my $elementContent = shift;

	my $element = XML::Element->new($elementName);
	$element->push_content($elementContent);
	$tree->push_content($element);

	return $tree;
}

sub CreateStationXml(\%)
{
	my %argumentHash = %{(shift)};
	my @now = localtime;
	my $date = $now[4] . '/' . $now[3];
	
	my $tree = XML::Element->new('station', 'local-date' => $date);

	foreach my $elementName (keys (%argumentHash))
	{
		&AppendElement($tree, $elementName, $argumentHash{$elementName});
	}

    return $tree;
}

sub WriteRawTextToFile
{
	my %stationInfo = @_;
	my $callsign = $stationInfo{Callsign};
	my $timestamp =$stationInfo{LastHeard};
	my $position = $stationInfo{Position};
	my $status = $stationInfo{Status};
	
	my $output = new IO::File("station.txt", O_WRONLY);
	
	print $output "Callsign: $callsign\n";
	print $output "Timestamp: $timestamp\n";
	print $output "Position (Latitude & Longitude), Region: $position\n";
	print $output "Status: $status\n";
}

sub PrintXmlTree
{
	my $tree = shift;
	print STDOUT $tree->as_XML;
}

sub WriteXmlTreeToFile
{
	my $xmlTree = shift;
	my $handle = new IO::File ">station.xml" or die "Can't open station.xml for writing\n";
	print $handle $xmlTree;
}

sub FindU
{
	# Our requesting agent. Define our URL and POST.
	my $baseUrl  = 'http://www.findu.com/cgi-bin/find.cgi';
	my $post = "call=" . shift;
	
	# Here are the headers we'll send off...
	my $headers = HTTP::Headers->new(Accept => 'text/plain',
	                 'User-Agent' => 'AutoLookup/1.0');
	
	# and the final requested web page.
	my $uable = HTTP::Request->new('POST', $baseUrl, $headers, $post);
	my $userAgent = LWP::UserAgent->new; 
	my $request = $userAgent->request($uable);
	
	die $request->message unless $request->is_success;
	
	my $webPage = $request->content;
	
	$webPage =~ s/(<[^>]*>)*//isg; # Remove all HTML tags
	$webPage =~ s/&nbsp;/ /g; # As well as NBSPs
	
	my $callsign = "N/A";
	if ($webPage =~ m/Position of ([A-Z]{1,2}[0-9]{1}[A-Z]{2,3})/)
	{
		$callsign = $1;
	}
	# Write a regex that matches the following string:
	# 	1.2 miles southwest of Bolingbrook, IL
	#	(\d)*.(\d)*\s(rest of string)
	
	my $status = "N/A";
	if ($webPage =~ m/Status: ([^,]*)/g)
	{
		$status = $1;
	}
	
	my $reportReceived = "N/A";
	if ($webPage =~ m/Report received  ([^\n]*)/)
	{
		$reportReceived = $1;
	}
	
	my $rawPacket = "N/A";
	if ($webPage =~ m/Raw packet: ([^\n]*)/)
	{
		$rawPacket = $1;
	}
	
	return ( Callsign=>$callsign, LastHeard=>$reportReceived, Status=>$status );
}

sub FindUXml
{
	my $queryCallsign = shift;
	my %aprsInfo = FindU($queryCallsign);
	my $xmlTree = CreateStationXml(%aprsInfo)->as_XML;
	return $xmlTree;
}

sub APRSWorld
{
	my $queryCallsign = shift;
	my $baseUrl = "http://db.aprsworld.net/datamart/switch.php?call=$queryCallsign&table=position&maps=yes";
	
	my $webPage = get("$baseUrl") or die $!;
	
	my $tableData = new HTML::TableExtract->new(headers => [
	    "Callsign", "Date", "Latitude / Longitude", "Status"]);
	$tableData->parse($webPage);
	
	my $callsign;
	my $position;
	my $timestamp;
	my $status;
		
	foreach my $tableStates ($tableData->table_states) {
	    foreach my $row ($tableStates->rows) {

	        my $currentCallsign = @$row[0];
	        next if length $currentCallsign == 0;
	        $callsign = $currentCallsign;
	
	        $timestamp = "Timestamp not available";
	        if (defined(@$row[1])) {
	        	$timestamp = @$row[1];
	        }
	        
	        $position = "Position not available";
	        if (defined(@$row[2])) {
	        	$position = @$row[2];
	        }
	        
	        $status = "Status not available";
	        if (defined(@$row[4])) {
	        	$status = @$row[4];
	        }
	    }
	}

	return ( Callsign=>$callsign, Position=>$position, LastHeard=>$timestamp, Status=>$status );
}

sub APRSWorldXml
{
	my $queryCallsign = shift;
	my %aprsInfo = APRSWorld($queryCallsign);
	my $xmlTree = CreateStationXml(%aprsInfo)->as_XML;
	return $xmlTree;
}

sub QRZ
{
	my $queryCallsign = shift;
	my $baseUrl = "http://www.qrz.com/detail/";
	
	my $webPage = get("$baseUrl$queryCallsign") or die $!;
	$webPage =~ s/(<[^>]*>)*//isg;
	$webPage =~ s/&nbsp;/ /g;
	
	$webPage =~ m/Name:([^\n]*)/;
	my $name = $1;
	
	# This pattern currently does not match!
	$webPage =~ m/Class: (Novice|Technician|General)/;
	my $class = $1;
	
	$webPage =~ m/GMT Offset:([^\n]*)/;
	my $gmtOffset = $1;
	
	$webPage =~ m/Time Zone:([^\n]*)/;
	my $timeZone = $1;
	
	$webPage =~ m/Addr2:([^\n]*)/;
	my $cityStateZip = $1;
	
	$webPage =~ m/County:([^\n]*)/;
	my $county = $1;
	
	$webPage =~ m/Grid:([^\n]*)/;
	my $grid = $1;

	return ( Name=>$name, Class=>$class, CityStateZip => $cityStateZip, GMTOffset=>$gmtOffset, TimeZone=>$timeZone, Grid=>$grid );
}

sub QRZxml
{
	my $queryCallsign = shift;
	my %qrzInfo = QRZ($queryCallsign);
	my $xmlTree = CreateStationXml(%qrzInfo)->as_XML;
	return $xmlTree;
}

1;
__END__

=head1 NAME

Ham::Scrape - Perl extension for scraping Amateur Radio callsign info and
real-time positional information from the Internet. This module scrapes the
information from three web sites (QRZ, FindU and APRSWorld), and supports
printing of the key fields to console to file as raw ASCII or formatted in
an XML document structure.

=head1 SYNOPSIS

  use Ham::Scraper;
  
  # Retreive QRZ information for callsign
  my %qrz = Ham::Scraper::QRZ($callsign);
  my $name = $qrz{Name};
  my $location = $qrz{CityStateZip};
  my $timeZone = $qrz{TimeZone};
  my $gmtOffset = $qrz{GMTOffset};
  my $grid = $qrz{Grid};
  # Use name, location, grid, etc. in program.

  # Scrape real-time position report information (as XML) from FindU
  my $aprsXml = Ham::Scraper::FindUXml($callsign);

Whether you are looking to scrape QRZ, Findu or APRSWorld information,
you can have the results return in a hash or as simple XML document.
A subroutine returning XML is suffixed with Xml.

=head1 DESCRIPTION

This basic Perl module uses the following Web sites to scrape information
relating to real-time position and call sign detail of Amateur Radio
operators:

    http://aprsworld.net
    http://www.findu.com
    http://www.qrz.com

=head2 EXPORT

FindU
FindUXml

APRSWorld
APRSWorldXml

Qrz
QrzXml

=head1 SEE ALSO

For further information on APRS or Ham Radio, please visit the following
web wites:

    http://www.arrl.org
    http://aprsworld.net
    http://www.findu.com
    http://www.qrz.com

If you want to verify whether this module is the latest version that is
available, then please check CPAN.

=head1 AUTHOR

Kevin Wittmer, E<lt>kevinwittme7 at hotmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kevin Wittmer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
