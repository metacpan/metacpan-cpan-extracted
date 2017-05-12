#!/usr/bin/perl -X
package Finance::Quant::Quotes;

use strict;
use warnings;
use LWP::UserAgent;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Finance::Quant::Quotes ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
get	
);

our $VERSION = '0.01';



	
	sub get {
		my ($symbol, $startdate, $enddate, $agent) = @_;
		print "fetching data...\n";
		my $dat = _fetch($symbol, $startdate, $enddate, $agent);   # csv file, 1st row = header
		
		
		return if(!$dat);
		
		my @q = split /\n/, $dat;
		my @header = split /,/, shift @q;
		my %quotes = map { $_ => [] } @header;
		for my $q (@q) {
			my @val = split ',', $q;
			unshift @{$quotes{$header[$_]}}, $val[$_] for 0..$#val;   # unshift instead of push if data listed latest 1st & oldest last
		}
#		open OUT, ">$symbol.csv";
#		print OUT $dat;
#		close OUT;
#		print "data written to $symbol.csv.\n";


		return \%quotes;
	}
	sub _fetch {
		my ($symbol, $startdate, $enddate, $interval, $agent) = @_;
		my $url = "http://chart.yahoo.com/table.csv?";
		my $freq = "g=$interval";    # d: daily, w: weekly, m: monthly
		my $stock = "s=$symbol";
		my @start = split '-', $startdate;
		my @end = split '-', $enddate;
		$startdate = "a=" . ($start[0]-1) . "&b=$start[1]&c=$start[2]";
		$enddate = "d=" . ($end[0]-1) . "&e=$end[1]&f=$end[2]";
		$url .= "$startdate&$enddate&$stock&y=0&$freq&ignore=.csv";
		my $ua = new LWP::UserAgent(agent=>$agent,timeout=>5);
		my $request = new HTTP::Request('GET',$url);
		my $response = $ua->request($request);
		if ($response->is_success) {
			return $response->content;
		} else {

#			warn "Cannot fetch $url (status ", $response->code, " ", $response->message, ")\n";
		  	return 0;
		}
	}




1;
__END__

