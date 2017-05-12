#!/usr/bin/perl
#
# html_report.plx
#
my $version = '2.04';	# 10-29-03, michael@bizsystems.com
# GPL'd, see Copyright notice in the package README file
#
use strict;
#use diagnostics;
use LaBrea::Tarpit::Report qw(
	generate 
	gen_short
	syslog2_cache
	short_report
	make_buttons
	make_image_cache
);
use LaBrea::Tarpit::Util qw(
	cache_is_valid
	update_cache
	http_date
	labrea_whoami
);

#########################################################
######## READ THIS FILE FOR CONFIGURATION ###############
#########################################################

# ALTER this to the path for "localTrojans.pl"

use lib qw( ./ );
require 'localTrojans.pl';

# SET for your system
#
my $config = {
#  'file'	=> '/path/to/cache',	# used for test, overides host:port
#  'd_port'	=> '8686',		# defaults to 8686
#  'd_host'	=> 'localhost',		# defaults to 'localhost'
#  'd_timeout'	=> default 180,		# seconds to wait for host response
  'cache'	=> '/var/tmp/labrea.cache',
#  'umask'	=> '',			# use default 033 cache_file umask
#  'cull'	=> default 600,	# seconds to keep old threads
  'scanners'	=> 100,			# keep this many dead threads
#  'port_timer'	=> default 86400,	# seconds per collection period
  'port_intvls'	=> 30,			# keep #nintvls of port stats
  };

# SET THESE for your system

my $look_n_feel = {	# defaults shown
    'face'	=> 'VERDANA,ARIAL,HELVETICA,SANS-SERIF',
    'color'	=> '#ffffcc',  
    'bakgnd'	=> '#000000',  
  # below are all for port_intervals
    'images'	=> './',		# REQUIRED, path to images
#    'height'	=> 72,			# default 
#    'width'	=> 7,			# default 
#    'legend'	=> 'text for graph',	# optional
    'threshold'	=> 5,	# ignore below this count
#    'trojans'	=> \%trojans,		# optional
    'trojans'	=> $LaBrea::Tarpit::Report::localTrojans::trojans,
	#	 where %trojans is of the form
	#	(	# info not in /etc/services
	#	# port          text
	#	  555   => 'phAse zero',
	#	  1243  => 'Sub-7',
	#	# etc....
	#	);
  # below are for html file caching
  # the directory for the cache file MUST be writable by the web server
    'html_cache_file'	=> './tmp/html_report.cache',	# required
    'html_expire'	=> '60',			# cache expiration, secs
  
  # optional other_sites stats cache location
    'other_sites'	=> './tmp/site_stats',
};

# comment ANY of these out to eliminate that section of the report
# comment out the corresponding section in @buttons below as well
my $out = {
	'guests'		=> undef,
	'guests_by_IP'		=> undef,
	'capture_summary'	=> 5,
	'got_away'		=> undef,
	'my_IPs',		=> undef,
	'port_intervals'	=> 30,
	'versions'		=> 'Created by:',
	'other_sites'		=> undef,
  };

my $html_report = sub {
  my ($input,$report,$look_n_feel,$out,$suppress) = @_;

  my $para =  "<p>\n";

  @_ = split('\.', $0);
  $_ = pop @_;   
  my @buttons = (
	'HOME'		=> 'http://www.bizsystems.net',
#	'TOP'		=> '#top',
	'SUMMARY'	=> '#CAPTURE SUMMARY',
	"SOURCE IP's"	=> '#attackers',
	'HELD SINCE'	=> '#captured',
	'ESCAPED'	=> '#escaped',
	"DEST IP's"	=> '#local-ips',
	'TRENDS'	=> '#trends',
	'OTHER SITES'	=> '#others',
#	'MULTI PAGE'	=> './paged_report.'.$_,
	);

#########################################################
############ no more user setable parameters ############
#########################################################

  $_ = $LaBrea::Tarpit::Report::localTrojans::trojans;	# silence strict warning

  my $butsub = sub {
    my $name = $_[0] || '';
    @_ = ($look_n_feel,'',$name,\@buttons);
    goto &make_buttons;
 };

  $$report = ($_ = generate($input,$look_n_feel,$out))
	? qq|<html><body><center><b>LaBrea</b> daemon not running, try again later.
<p>
The server said....
<p>
$_
</center></body></html>
|
	:

#######
####### actually generate the page here, lots of ways to do this
#######

	q|<html><head>| .
 	make_image_cache($look_n_feel->{images}) . q
|<style>
A.NU {
  color: | . $look_n_feel->{color} . q|;
  background: transparent;
  font-family: | . $look_n_feel->{face} . q|;
  font-weight: bold;
  font-size: 10pt;  
  text-decoration: none;
}
</style>
</head>
<body bgcolor="#6699cc" text="#ffffcc" vlink="#ffffcc" link="#ffffcc"><center> 
<table cellspacing=2 cellpadding=2 border=2>
<tr><td valign=top bgcolor="| . $look_n_feel->{bakgnd} . q|">
<font face="| . $look_n_feel->{face} . q|" color="| . $look_n_feel->{color} . q|" size=3>Page last updated | . $out->{date} . q|
<p>
These reports show the scans / hack attempts against the
<br>
local IP block. The data is provided by the log output from
<br>
Tom Liston's LaBrea scanner/worm disruptor. For more 
<br>
information on LaBrea see: <a href="http://www.hackbusters.net/">www.hackbusters.net</a>
<br>
To download these scripts see:<br>
&nbsp;&nbsp;<a href="http://search.cpan.org/search?query=LaBrea::Tarpit&mode=all">CPAN.org</a><br>
To download Tom Liston's <b>labrea daemon</b> see:<br>
&nbsp;&nbsp;<a href="http://sourceforge.net/projects/labrea/">sourceforge.net/labrea/</a></font></td>
<td valign=top>
| . $out->{capture_summary} . q|</td></tr>
<tr><td colspan=2  bgcolor="| . $look_n_feel->{bakgnd} . q|"><font face="| . 
$look_n_feel->{face} . q|" color="| . $look_n_feel->{color} . q|" size=3>
Briefly:
<br>
LaBrea is a program that creates a tarpit or, as some have called it a "sticky honeypot". 
<br>
LaBrea takes over unused IP addresses on a network and creates "virtual  machines"  that 
<br>
answer to connection attempts. LaBrea answers those connection attempts in a way that
<br>
causes the machine at the other end to get "stuck", sometimes  for  a very long time.
<p></font>
  <table cellspacing=0 cellpadding=0 border=0 width=100%>
  <tr><td><font face="| .
$look_n_feel->{face} . q|" color="| . $look_n_feel->{color} . q|" size=3>
For a description of port attacks see: <br><a
href="http://www.robertgraham.com/pubs/firewall-seen.html">www.robertgraham.com/pubs/firewall-seen.html</a>
<br><a
href="http://www.simovits.com/nyheter9902.html">www.simovits.com/nyheter9902.html</a>
<br><a
href="http://www.networkice.com/Advice/Exploits/Ports/default.htm">www.networkice.com/Advice/Exploits/Ports/default.htm</a>
</font></td>
  <td>| . $out->{versions} . q|</td></tr>
  </table>
</td></tr></table>
<p>
|;
  
  $$report .= &$butsub('attackers') . $para . $out->{guests_by_IP} . $para if $out->{guests_by_IP};
  $$report .= &$butsub('captured') . $para . $out->{guests} . $para if $out->{guests};
  $$report .= &$butsub('escaped') . $para . $out->{got_away} . $para if $out->{got_away};
  $$report .= &$butsub('local-ips') . $para . $out->{my_IPs} . $para if $out->{my_IPs};
  $$report .= &$butsub('trends') . $para . $out->{port_intervals} . $para if $out->{port_intervals};
  if ( $out->{other_sites} ) {
# insert comments
    my $comments = q|<tr>
<td colspan=6 bgcolor="| . $look_n_feel->{bakgnd} . q|"><font size=3 face="| .
	$look_n_feel->{face} . q|" color="| . $look_n_feel->{color} . 
	q|">This is the recent <b>Hacktivity</b> at other sites running<br>
LaBrea::Tarpit. To include your site in this list send an email
<blockquote>
    To: <a
href="mailto:michael@bizsystems.com?Subject=LaBrea::Tarpit%20site">Michael@BizSystems.com</a><br>
    Subject: LaBrea::Tarpit site 
<p>
    <i>containing the exact URL of your report script - i.e.</i>
<p>
    http://www.foo.com/html_report.cgi
</blockquote>
To get the most recent list of sites using LaBrea::Tarpit, see:
<blockquote>
<a href="http://scans.bizsystems.net/other_sites.txt">scans.bizsystems.net/other_sites.txt</a><br>
&nbsp;&nbsp;&nbsp;&nbsp;or<br>
<a href="http://www.bizsystems.net/downloads/">www.bizsystems.net/downloads</a><br>
</blockquote></td></tr>
|;
    $out->{other_sites} =~ s/<!-- INSERT MARKER -->/$comments/o;
    $$report .= &$butsub('others') . $para .
	$out->{other_sites} . $para;
  }
    $$report .= &$butsub() . q|
</center>
</body>  
</html>  
|;
1;
# ALWAYS RETURNS TRUE, but small
}; # end of report generation

#####################################################
#####################################################

my $html_txt;

if ( ! exists $ENV{GATEWAY_INTERFACE} && @ARGV ) {	# IF SYSLOG ANALYSIS !!!
  my %lnf = %$look_n_feel;
  $lnf{'html_expire'}		= 1;	# minimal
  syslog2_cache($ARGV[0],$config);
  &$html_report($config,\$html_txt,\%lnf,$out);
  update_cache(\%lnf,\$html_txt);

} else {	# WEB SERVER CALL

  my ($mtime,$size,$use_cache,$short,$sflag);
  local(*HTML);

# generate new report unless there is a valid cache file

  my $hp = \$html_txt;
  my $textp = $hp;
  my $shortflag = 0;

  if ($ENV{QUERY_STRING} && $ENV{QUERY_STRING} =~ /short/) {	# only requesting short report
    undef $hp;
    $textp = \$short;
    $shortflag = 1;
    $out = {};			# start with empty output, need only minimum
  }

  if (	($use_cache = cache_is_valid(*HTML,$look_n_feel,$shortflag)) ||	# cache is valid
        (do {  if ($hp) {
		&$html_report($config,$hp,$look_n_feel,$out);	# else create html
	    } else {
		! gen_short($config,$out);
	    }
	} &&
		short_report(\$short,$out) &&
		update_cache($look_n_feel,$hp,\$short) &&		# do update
		($use_cache = cache_is_valid(*HTML,$look_n_feel))	# valid now??
	)
     ) {

# At this point, $use_cache contains the file 'size' or false
    $mtime = (stat(HTML))[9];
    $size = $use_cache;
  } else {				# no cache available
    $mtime = time;
    $size = length($$textp);
  }

  my $ctype = ($hp) ? 'text/html' : 'text/plain';

  my $xhead = 'X-LaBrea';
  my $xhv = labrea_whoami;

####################################################

  my $r;
  eval { require Apache;
	 $r = Apache->request;
  };

  unless ($@) {		# unless error, it's Apache
    $r->status(200);
    $r->content_type($ctype);
    $r->header_out("Content-length","$size");
    $r->header_out("Last-modified",http_date($mtime));
    $r->header_out("Expires",http_date($mtime + $look_n_feel->{html_expire}));
    $r->header_out($xhead,$xhv);
    $r->send_http_header;
    if ( $use_cache ) {
      $r->send_fd(*HTML);
      close HTML;
    } else {
      $r->print ($$textp);
    }
    return 200;			# HTTP_OK

  } else {	# sigh... no mod_perl

    if ($use_cache) {
      undef $/;
      $$textp = <HTML>;	# slurp file
      close HTML;
      $/ = "\n";
    }
    print q
|Content-type: |, $ctype, q|
Content-length: |, $size, q|
Last-modified: |, http_date($mtime), q|
Connection: close
Expires: |, http_date($mtime + $look_n_feel->{html_expire}), qq|
$xhead: $xhv

$$textp|;
  }
}
1;
