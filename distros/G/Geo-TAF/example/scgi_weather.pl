#!/usr/bin/perl -w
#
# fetch a metar, taf or short taf from http://weather.noaa.gov
#
# This is a module which shows me doing my own thing using the
# normalised input. It does essentially the same job as 
# cgi_weather.pl, it's just a lot more complicated but returns
# a much shorter string that is a bit more cryptic.
#
# It also is designed really to just get the forecast and 
# actual weather.
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
#
#    break=1   insert a "<br /><br />" between each result
#    onediv=1  make a multiple one div (not one div per thing)
#    raw=1     will display the raw weather string
#    debug=1   will display the objects
#    force=1   always fetch the data (don't use any cached stuff)
#    
# $Id: scgi_weather.pl,v 1.1.2.2 2003/02/03 17:26:37 minima Exp $
# 
# Copyright (c) 2003 Dirk Koopman G1TLH
#
use strict;

package main;

use CGI;
use Geo::TAF;
use LWP::UserAgent;

my $q = new CGI;
my $site_code = uc $q->param('icao');
my @sort = qw(metar staf);
my $debug = $q->param('debug');
my $raw = $q->param('raw');
my $force = $q->param('force');
my $dobrk = "<br /><br />" if $q->param('break') && @sort > 1;
my $onediv = $q->param('onediv') && @sort > 1;


my %st = (
		  VV => 'vert. viz',
		  SKC => "no cloud",
		  CLR => "no cloud no sig wthr",
		  BKN => "5-7okt",
		  SCT => "3-4okt",
		  FEW => "0-2okt",
		  OVC => "8okt",
		  CAVOK => "CAVOK(no cloud >10Km viz no sig wthr)",
		  CB => 'CuNim',
          TCU => 'tower Cu',
		  NSC => 'no sig cloud',
		  BLU => '3okt 2500ft 8Km viz',
		  WHT => '3okt 1500ft 5Km viz',
		  GRN => '3okt 700ft 3700m viz',
		  YLO => '3okt 300ft 1600m viz',
		  AMB => '3okt 200ft 800m viz',
		  RED => '3okt <200ft <800m viz',
		  NIL => 'no weather',
		  '///' => 'some',
		 );

my %wt = (
		  '+' => 'heavy',
          '-' => 'light',
          'VC' => 'in the vicinity',

		  MI => 'shallow',
		  PI => 'partial',
		  BC => 'patches of',
		  DR => 'low drifting',
		  BL => 'blowing',
		  SH => 'showers',
		  TS => 'thunderstorms containing',
		  FZ => 'freezing',
		  RE => 'recent',
		  
		  DZ => 'drizzle',
		  RA => 'rain',
		  SN => 'snow',
		  SG => 'snow grains',
		  IC => 'ice crystals',
		  PE => 'ice pellets',
		  GR => 'hail',
		  GS => 'small hail/snow pellets',
		  UP => 'unknown precip',
		  
		  BR => 'mist',
		  FG => 'fog',
		  FU => 'smoke',
		  VA => 'volcanic ash',
		  DU => 'dust',
		  SA => 'sand',
		  HZ => 'haze',
		  PY => 'spray',
		  
		  PO => 'dust/sand whirls',
		  SQ => 'squalls',
		  FC => 'tornado',
		  SS => 'sand storm',
		  DS => 'dust storm',
		  '+FC' => 'water spouts',
		  WS => 'wind shear',
		  'BKN' => 'broken',

		  'NOSIG' => 'no significant weather',
		  
		 );

start();

error("No ICAO (valid) site code ($site_code) specified") unless $site_code && $site_code =~ /^[A-Z]{4}$/;

my $base = "/tmp";
my ($sort, $fn, $started);

print "<div class=\"weather\">$site_code ";

while ($sort = shift @sort) { 
	$fn = "$base/${sort}_$site_code";

	if (!$force && -e $fn) {
		my ($mt, $size) = (stat $fn)[9,7] ;
		$mt ||= 0;
		$size ||= 0;
		if ($mt + 30*60 < time || $size == 0) {
			my $s = fetch_icao($sort);
			store($s);
			print $s;
		} else {
			my $s = retrieve($fn);
			print $s;
		}
	} else {
		my $s = fetch_icao($sort);
		store($s);
		print $s;
	}

	if (@sort > 0) {
		print $onediv ? ' ' : '</div>';
		print $dobrk if $dobrk;
		print '<div class="weather">' unless $onediv; 
	}
}	

finish();
exit(0);

sub retrieve
{
	my $fn = shift;
	open IN, "$fn" or die "cannot open $fn $!\n";
	my $s = <IN>;
	close IN;
	return $s;
}

sub fetch_thing
{
	my $sort = shift;
	
	my $ua = new LWP::UserAgent;
	my $req = new HTTP::Request GET =>
  	"http://weather.noaa.gov/cgi-bin/mget$sort.pl?cccc=$site_code";

	my $response = $ua->request($req);

	my $metar;
	if (!$response->is_success) {
		error("METAR Fetch $site_code Error", $response->error_as_HTML);
	} else {

    	my $data = $response->as_string; 
    	($metar) = $data =~ /($site_code\s+\d+Z?[^<]*)/;       # find the METAR string

    	# Sanity check
    	if (length $metar < 10) {
			error("METAR ($metar) is too short");
    	}
	}
	return $metar;
}

sub fetch_icao
{
	my $sort = shift;
	my $metar = fetch_thing($sort);
	
	# pass the data to the METAR module.
	my $m = new Geo::TAF;
	if ($sort =~ /taf$/) {
		$m->taf($metar);
	} else {
		$m->metar($metar);
	}

	my @in;
	my $s;
	$s .= join "<br />", $m->raw, "<br />" if $raw;
	$s .= join "<br />", $m->as_chunk_strings, "<br />" if $debug;
	foreach my $c ($m->chunks) {
		my ($sub) = (ref $c) =~ /::([A-Z]+)$/;
		no strict 'refs';
		if ($sub eq 'HEAD') {
			$sub = $sort =~ /taf$/ ? "taf$sub" : "metar$sub";
		}
		push @in, &$sub($c);
	}
	$s .= join ' ', @in;
	return $s;
}

sub start
{
	return if $started;
	print $q->header(-type=>'text/html', -expires=>'+60m');
    print $q->start_html(-title=>"Weather for $site_code", -style=>{'src'=>'/style.css'},);
	$started = 1;
}

sub finish
{
	print "</div>";
	print  $q->end_html, "\n";
}

sub store
{
	my $s = shift;
	open OUT, ">$fn" or die "cannot open $fn $!\n";
	print OUT $s;
	close OUT;
}

sub error
{
	my $err = shift;
	my $more = shift;
	print $q->h3($err);
	print $more if $more;
	print "</div>", $q->end_html;
	warn($err);

    exit(0);
}

sub tafHEAD
{
	my @in = @{$_[0]};
	return "FORECAST Issued $in[3] on " . Geo::TAF::EN::day($in[2]);
}

sub metarHEAD
{
	my @in = @{$_[0]};
	return "CURRENT Issued $in[3] on " . Geo::TAF::EN::day($in[2]);
}

sub VALID
{
	my @in = @{$_[0]};
	return "Valid $in[1]-\>$in[2] on " . Geo::TAF::EN::day($in[0]);
}

sub WIND
{
	my @in = @{$_[0]};
	my $out = "Wind";
	$out .= $in[0] eq 'VRB' ? " variable" : " $in[0]";
    $out .= " varying $in[4]-\>$in[5]" if defined $in[4];
	$out .= ($in[0] eq 'VRB' ? '' : "deg") . " $in[1]";
	$out .= " gust $in[2]" if defined $in[2];
	$out .= $in[3];
	return $out;
}

sub PRESS
{
	my @in = @{$_[0]};
	return "QNH $in[0]";
}

sub TEMP
{
	my @in = @{$_[0]};
	my $out = "Temp $in[0]C";
	$out .= " Dewp $in[1]C" if defined $in[1];

	return $out;
}

sub CLOUD
{
	my @in = @{$_[0]};
	
	return $st{$in[0]} if @in == 1;
	return "Cloud $st{$in[0]} \@ $in[1]ft" if $in[0] eq 'VV';
	my $out = "Cloud $st{$in[0]} \@ $in[1]ft";
	$out .= " $st{$in[2]}" if defined $in[2];
	return $out;
}

#sub WEATHER
#{
#	goto &Geo::TAF::EN::WEATHER::as_string;
#}


sub WEATHER
{
	my @in = @{$_[0]};
	my @out;

	my ($vic, $shower);
	my $one = $in[0];

	while (@in) {
		my $t = shift @in;

		if (!defined $t) {
			next;
		} elsif ($t eq 'VC') {
			$vic++;
			next;
		} elsif ($t eq 'SH') {
			$shower++;
			next;
		} elsif ($t eq '+' && $one eq 'FC') {
			push @out, $wt{'+FC'};
			shift;
			next;
		}
		
		push @out, $wt{$t};
		
		if (@out && $shower) {
			$shower = 0;
			push @out, $wt{'SH'};
		}
	}
	push @out, $wt{'VC'} if $vic;

	return join ' ', @out;
}

sub RVR
{
	my @in = @{$_[0]};
	my $out = "RVR R$in[0] $in[1]$in[3]";
	$out .= " vary $in[2]$in[3]" if defined $in[2];
	if (defined $in[4]) {
		$out .= " decr" if $in[4] eq 'D';
		$out .= " incr" if $in[4] eq 'U';
	}
	return $out;
}

sub RWY
{
	return "";
}

sub PROB
{
	my @in = @{$_[0]};
    
	my $out = "Prob $in[0]%";
	$out .= " $in[1]-\>$in[2]" if defined $in[1];
	return $out;
}

sub TEMPO
{
	my @in = @{$_[0]};
	my $out = "Temporary";
	$out .= " $in[0]-\>$in[1]" if defined $in[0];

	return $out;
}

sub BECMG
{
	my @in = @{$_[0]};
	my $out = "Becoming";
	$out .= " $in[0]-\>$in[1]" if defined $in[0];

	return $out;
}

sub VIZ
{
    my @in = @{$_[0]};

    return "Viz $in[0]$in[1]";
}

sub FROM
{
    my @in = @{$_[0]};

    return "From $in[0]";
}

sub TIL
{
    my @in = @{$_[0]};

    return "Until $in[0]";
}

1;
