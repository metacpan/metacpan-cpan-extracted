#!/usr/bin/perl -w
#
# fetch a metar, taf or short taf from http://weather.noaa.gov
# 
# This is designed to be used in a IFRAME and returns HTML.
# It will only query the website once every 30 minutes, the rest
# of the time it will cache the result in an 'easily guessable'
# place in /tmp (consider that as a warning).
#
# Call it from a web page like this:-
#
# <iframe src="cgi-bin/fetch_weather.pl?icao=EGSH&metar=1" 
#  name="METAR for EGSH" frameborder="1" width="90%" height="50">
# [Your user agent does not support frames or is currently configured
#  not to display frames. However, you may visit
#  <A href="cgi-bin/fetch_weather.pl?icao=EGSH&metar=1">METAR for EGSH</A>]
# </iframe>
#
# You can set as many of these as you like:-
#    metar=1   for a metar (default, if no options)
#    staf=1    for a short form (usually more uptodate) TAF
#    taf=1     for a full 18 hour TAF
#    break=1   insert a "<br /><br />" between each result
#    
# $Id: cgi_weather.pl,v 1.1.2.1 2003/02/02 00:39:52 minima Exp $
# 
# Copyright (c) 2003 Dirk Koopman G1TLH
#
use strict;
use CGI;
use Geo::TAF;
use LWP::UserAgent;

my $q = new CGI;
my $site_code = uc $q->param('icao');
my @sort;
push @sort, 'taf' if $q->param('taf');
push @sort, 'staf' if $q->param('staf');
push @sort, 'metar' if $q->param('metar') || @sort == 0;
my $dobrk = $q->param('break');

error("No ICAO (valid) site code ($site_code) specified") unless $site_code && $site_code =~ /^[A-Z]{4}$/;

my $base = "/tmp";
my ($sort, $fn, $started);

while ($sort = shift @sort) { 
	$fn = "$base/${sort}_$site_code";

	my ($mt, $size) = (stat $fn)[9,7];
	$mt ||= 0;
	$size ||= 0;

	my $brk = "<br /></br />" unless @sort;

	if ($mt + 30*60 < time || $size == 0) {
		fetch_icao($brk);
	} else {
    	my $s = retrieve();
		send_metar($s, $brk);
	}
}	

sub retrieve
{
	open IN, "$fn" or die "cannot open $fn $!\n";
	my $s = <IN>;
	close IN;
	return $s;
}

sub fetch_icao
{
	my $brk = shift || "";
	my $ua = new LWP::UserAgent;

	my $req = new HTTP::Request GET =>
  	"http://weather.noaa.gov/cgi-bin/mget$sort.pl?cccc=$site_code";

	my $response = $ua->request($req);

	if (!$response->is_success) {
		error("METAR Fetch $site_code Error", $response->error_as_HTML);
	} else {

    	# Yep, get the data and find the METAR.

    	my $m = new Geo::TAF;
    	my $data;
    	$data = $response->as_string;               # grap response
    	$data =~ s/\n//go;                          # remove newlines
    	$data =~ m/($site_code\s\d+Z.*?)</go;       # find the METAR string
    	my $metar = $1;                             # keep it

    	# Sanity check
    	if (length($metar)<10) {
			error("METAR ($metar) is too short");
    	}

    	# pass the data to the METAR module.
		if ($sort =~ /taf/) {
			$m->taf($metar);
		} else {
			$m->metar($metar);
		}
		my $s = $m->as_string;
    	send_metar($s, $brk);
		store($s);
	}
}

finish();

sub start
{
	return if $started;
	print $q->header(-type=>'text/html', -expires=>'+60m');
    print $q->start_html(-title=>"Weather for $site_code", -style=>{'src'=>'/style.css'},);
	$started = 1;
}

sub finish
{
	print $q->end_html;
}

sub store
{
	my $s = shift;
	open OUT, ">$fn" or die "cannot open $fn $!\n";
	print OUT $s;
	close OUT;
}

sub send_metar
{
	my $s = shift;
	my $brk = shift || "";

	start();
    print "<div class=frame>$s</div>$brk";
}

sub error
{
	my $err = shift;
	my $more = shift;
	print $q->header(-type=>'text/html', -expires=>'+60m');
    print $q->start_html($err);
	print $q->h3($err);
	print $more if $more;
	print $q->end_html;
	warn($err);

    exit(0);
}

