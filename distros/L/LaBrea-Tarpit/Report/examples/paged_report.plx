#!/usr/bin/perl
#
# paged_report.plx
#
my $version = '1.16';	# 11-7-04, michael@bizsystems.com
# GPL'd, see Copyright notice in the package README file
#
use strict;
#use diagnostics;
use LaBrea::Tarpit qw(
	prep_report
	restore_tarpit
);
use LaBrea::Tarpit::Report qw(
	gen_short
	short_report
	time2local
	capture_summary
	guests_by_IP
	guests
	got_away
	my_IPs
	port_stats
	other_sites
	get_config
	get_versions
	make_buttons
	make_image_cache
);
use LaBrea::Tarpit::Util qw(
	http_date
	daemon2_cache
	script_name
	upd_cache
	page_is_current
	labrea_whoami
);

#########################################################
######## READ THIS FILE FOR CONFIGURATION ###############
#########################################################

# ALTER this to the path for "localTrojans.pl"

use lib qw( ./ );
require 'localTrojans.pl';
my $trojans = $LaBrea::Tarpit::Report::localTrojans::trojans
	if $LaBrea::Tarpit::Report::localTrojans::trojans;

# SET for your system
#
my $config = {
#  'file'	=> '/path/to/cache',	# used for test, overides host:port
#  'd_port'	=> '8686',		# defaults to 8686
  'd_host'	=> 'localhost',		# defaults to 'localhost'
#  'd_timeout'	=> 180,		# default 180, seconds to wait for host response
# THE REST USED TO ANALYZE syslog files
  'cache'	=> '/var/tmp/labrea.cache',
#  'umask'	=> '',			# use default 033 cache_file umask
#  'cull'	=> 600,		# default 600, seconds to keep old threads
  'scanners'	=> 100,			# keep this many dead threads
#  'port_timer'	=> 86400,	# default 86400, seconds per collection period
  'port_intvls'	=> 30,			# keep #nintvls of port stats
  };

# SET THESE for your system

my $look_n_feel = {	# defaults shown
    'face'	=> 'VERDANA,ARIAL,HELVETICA,SANS-SERIF',
    'color'	=> '#ffffcc',  
    'bakgnd'	=> '#000000',  
  # below are all for port_intervals
    'images'	=> './',		# REQUIRED, path to images
#    'height'	=> 72,			# default 72
#    'width'	=> 7,			# default  7
#    'legend'	=> 'text for graph',	# optional
    'threshold'	=> 5,	# ignore below this count
#    'trojans'	=> \%trojans,		# optional
    'trojans'	=> $trojans,
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
    'html_expire'	=> 60,				# cache expiration, secs
  # optional other_sites stats cache location
    'other_sites'	=> './tmp/site_stats',
};

#	button text		URL
#	comment out or modify as needed for your site
my @buttons = (
	'HOME'		=> 'http://www.bizsystems.net',
	'SUMMARY'	=> 'summary onClick="return(please_wait(this));"',
	"SOURCE IP's"	=> 'attackers onClick="return(please_wait(this));"',
	'HELD SINCE'	=> 'captured onClick="return(please_wait(this));"',
	'ESCAPED'	=> 'escaped onClick="return(please_wait(this));"',
	"DEST IP's"	=> 'local-ips onClick="return(please_wait(this))";',
	'TRENDS'	=> 'trends onClick="return(please_wait(this));"',
);

push(@buttons,	'OTHER SITES'	=> 'others onClick="return(please_wait(this));"')
	if -e $look_n_feel->{other_sites};

my @extras		= ();
my $first_page 		= 'summary';	# from above
my $summary_days	= 5;		# number of days to show in capture summary
my $buttwidth		= 120;		# should not need to be changed
my $logo_text = q|
&nbsp;<img src="|. $look_n_feel->{images} . q|tarpot.gif" height=108 width=108 alt="Tarpot">
|;

=pod

# example: mine looks like this

my $logo_text = q|
<img src="| . $look_n_feel->{images} . q|cloud5.jpg" height=67 width=299
alt='BizSystems Internet Services' border=0><br>
<img src="| . $look_n_feel->{images} . q|homebk01.jpg" alt="" height=29 width=100 border=0>
|;

@_ = split('\.', $0);
$_ = pop @_;   
@extras = (					# extra buttons
	''		=> '',			# button space
	'SINGLE PAGE'	=> './html_report.'.$_.' onClick="return(please_wait(this));"',
	'DOWNLOAD'	=> 'http://search.cpan.org/search?query=LaBrea::Tarpit&mode=all',
);

=cut

#########################################################
############ no more user setable parameters ############
#########################################################

my ($image_cache,$use_cache,$error,$rpt,$sht,$html,$report,$short,$out);
my $tarpit = {};

# make keys of the commands or hrefs
@_ = (
	'short'	=> 'short',
	'ERROR'	=> 'error',
);
for (my $i=0; $i<=$#buttons;$i+=2) {
  $buttons[$i+1] =~ /(\S+)/;
  push @_,$buttons[$i],$1;
}

my %buttext = reverse @_;

# get proposed action
my $page = $ENV{QUERY_STRING};

$page = $first_page unless exists $buttext{$page};

my ($mtime,$upd);
if ( $page eq 'short' ) {	# skip the main cache check
  $mtime = time - $look_n_feel->{html_expire};
  $use_cache = page_is_current($mtime,
	$look_n_feel->{html_cache_file}.'.'.$page);
} else {
# first thing, check the cache age
  ($mtime,$upd) = daemon2_cache(
	$look_n_feel->{html_cache_file}.'.mem',
	$config,
	$look_n_feel->{html_expire},
 );

  $error = $@;
  if ($error) {		# was there a timeout error
    $page = 'error';	# falls through elsif's
# note that $upd & $use_cache will be false
  }
  else {
    restore_tarpit($tarpit,$look_n_feel->{html_cache_file}.'.mem')
	unless ($use_cache = page_is_current($mtime,			 # always set $use_cache
	$look_n_feel->{html_cache_file}.'.'.$page)) || $page eq 'other'; # but skip restore if tarpit not needed
  }
}

##############
if (! $upd && $use_cache) {
  # skip the updates
}
##############
elsif ( $page eq 'summary' ) {
  # print STDERR "summary\n";
  my (@csdate,@csctd);
  $out = {
	'capture_summary'	=> undef,
	'versions'		=> 'Created by: ',
# capture statistics		# all fields B<REQUIRED>
	'cs_days'		=> $summary_days,
	'cs_date'		=> \@csdate, #  epoch midnight of capt date
	'cs_ctd'		=> \@csctd,  # captured this date
  };

  prep_report($tarpit,$out);
  get_versions($out,$look_n_feel,$out);
  capture_summary($out,$look_n_feel,$out);

  $report = q|<table cellspacing=2 cellpadding=2 border=2>
<tr><td valign=top bgcolor="| . $look_n_feel->{bakgnd} . q|">
<font face="| . $look_n_feel->{face} . q|" color="| . $look_n_feel->{color} . q|" size=3>Page last updated | . 
  &time2local($out->{now}, $out->{tz}) . q|
<p>
These reports show the scans / hack attempts against the
local IP block. The data is provided by the log output from
Tom Liston's LaBrea scanner/worm disruptor. For more 
information on LaBrea see: <a href="http://www.hackbusters.net/">www.hackbusters.net</a>
<p>
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
LaBrea takes over unused IP addresses on a network and creates "virtual  machines"  that 
answer to connection attempts. LaBrea answers those connection attempts in a way that
causes the machine at the other end to get "stuck", sometimes  for  a very long time.
<p></font>
  <table cellspacing=0 cellpadding=0 border=0 width=100%>
  <tr><td><font face="| .
$look_n_feel->{face} . q|" color="| . $look_n_feel->{color} . q|" size=3>
For a description of port attacks see: <br><a
href="http://www.doshelp.com/trojanports.htm">Trojan & Worm Ports Information Center</a>
<br><a
href="http://www.simovits.com/trojans/trojans.html">www.simovits.com/trojans/trojans.html</a>
<br><a
href="http://www.jlathamsite.com/dslr/suspectports.htm">Jerry Latham's Trojan Ports List</a>
<br><a
href="http://www.neohapsis.com/neolabs/neo-ports/neo-ports.html">Neohapsis &quot;Entire List&quot;</a>
</font></td>
  <td>| . $out->{versions} . q|</td></tr>
  </table>
</td></tr></table>
|;  
  $rpt = \$report;
}
##############
elsif ( $page eq 'attackers' ) {
  # print STDERR "attackers\n";
  my (@thsip,@thnum);
  $out = {
# threads per teergrubed host
	'guests_by_IP'	=> undef,
	'th_srcIP'	=> \@thsip,
	'th_numTH'	=> \@thnum,	# number threads this IP
  };
  prep_report($tarpit,$out);
  guests_by_IP($out,$look_n_feel,$out);
  $rpt = \$out->{guests_by_IP};
}
##############
elsif ( $page eq 'captured' ) {
  # print STDERR "captured\n";
  my (@tgsip,@tgsp,@tgdp,@tgcap,@tglst,@tgpst);
  $out = {
#	teergrubed hosts
	'guests'	=> undef,
	'tg_srcIP'	=> \@tgsip,	# B<REQUIRED>
	'tg_sPORT'	=> \@tgsp,	# B<REQUIRED>
	'tg_dPORT'	=> \@tgdp,
	'tg_captr'	=> \@tgcap,	# capture epoch time
	'tg_last' 	=> \@tglst,	# last contact
	'tg_prst'	=> \@tgpst,	# persistent [true|false]
  };
  prep_report($tarpit,$out);
  guests($out,$look_n_feel,$out);
  $rpt = \$out->{guests};
}
##############
elsif ( $page eq 'escaped' ) {
  # print STDERR "escaped\n";
  my (@scsip,@scdp,@scpst,@sclst);
  $out = {
#	scanning hosts lost
	'got_away'	=> undef,
	'sc_srcIP'	=> \@scsip,	# B<REQUIRED>
	'sc_dPORT'	=> \@scdp,	# attacked port
	'sc_prst'	=> \@scpst,	# persistent [true|false]
	'sc_last'	=> \@sclst,	# last contact
  };
  prep_report($tarpit,$out);
  got_away($out,$look_n_feel,$out);
  $rpt = \$out->{got_away};
}
##############
elsif ( $page eq 'local-ips' &&
	! ($error = get_config($config,$look_n_feel)) ) {	# get config file
  # print STDERR "local-ips\n";
  my (@phdip,@phpst);
  $out = {
#	phantom IP's used (from our IP block)
	'my_IPs'	=> undef,
	'ph_dstIP'	=> \@phdip,	# B<REQUIRED>
	'ph_prst'	=> \@phpst,	# persistent [true|false]
  };
  prep_report($tarpit,$out);
  my_IPs($out,$look_n_feel,$out);
  $rpt = \$out->{my_IPs};
}
##############
elsif ( $page eq 'trends' ) {
  # print STDERR "trends\n";
  my (@ports,@portstats,);
  $out = {
#	port statistics
	'port_intervals' => $config->{port_intvls},
	'port_intvls'	 => $config->{port_intvls},
	'ports'		 => \@ports,	# scanned port list
	'portstats'	 => \@portstats,
  };
  prep_report($tarpit,$out);
  port_stats($out,$look_n_feel,$out);
  $rpt = \$out->{port_intervals};
  $image_cache = make_image_cache($look_n_feel->{images});
}
##############
elsif ( $page eq 'others' ) {
  # print STDERR "others\n";
  $out = {
	'other_sites'	=> undef,
  };
    $report = q|<tr>
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

  other_sites($out,$look_n_feel,$out);
  $_ = 'onClick="return(please_wait(this));"';
  $out->{other_sites} =~ s|(http:[^\"]+\")|$1 $_|g;
  $out->{other_sites} =~ s/<!-- INSERT MARKER -->/$report/o;
  $rpt = \$out->{other_sites};
}
##############
elsif ( $page eq 'short' ) {
  # print STDERR "short\n";		# prep short
  $out = {};
  gen_short($config,$out);
  $error = $@;
  $sht = \$short;		# flag and pointer
  short_report($sht,$out) unless $error;
  undef $rpt;
}

$tarpit = {};				# destroy tarpit cache
if ( $error ) {
  $upd = 1;		# unconditional
  undef $sht;
  $page = 'error';
  $report = qq|error, try again later.
<p>
The server said....
<p>
$error
|;
  $rpt = \$report;
}
#elsif ( $upd && ! $sht ) {		# new short report if update needed
#  $sht = \$short;
#  short_report($sht,$out);
#}

if ( $rpt ) {		# if cache update needed
  $logo_text = '&nbsp;' unless $logo_text;

## MAKE STANDARD TOP AND BUTTON BAR

  $html = qq|<html><head>
<META NAME="ROBOTS" CONTENT=NOINDEX, NOFOLLOW">
<title>LaBrea::Tarpit $page</title>| .
  ($image_cache || '') . q|<style>   
A.NU {
  color: | . $look_n_feel->{color} . q|;
  background: transparent;
  font-family: | . $look_n_feel->{face} . q|;
  font-weight: bold;
  text-decoration: none;
}
</style>
<script language=javascript>  
var pop_whois = null;
function popclose() {
  if (pop_whois == null) return;
  if (pop_whois.closed) return;
  pop_whois.close();
}
var pwait = new Image();
pwait.src = "|. $look_n_feel->{images} . q|pwait01.gif";
var ref_url;
function please_wait(button) {
  document.working.src = pwait.src;
  ref_url = button.href;
// kludgy work around to get MSIE to display "please wait"
  setTimeout("next_page()", 250);
  return false;   
}
function next_page() {
  document.location.href = ref_url;
}
</script>
</head>
<body bgcolor="#6699cc" text="#ffffcc" vlink="#ffffcc" link="#ffffcc" onUnLoad="popclose();"><center> 
<table border=0><tr><td valign=middle>| . $logo_text . qq|</td>
<td align=center valign=middle width=100%><font face="$look_n_feel->{face}" size=6>LaBrea::Tarpit $buttext{$page}</font></td></tr>
</table>
|;
# make a two column page
  @_ = (@buttons,@extras);
  $html .= q|<table cellspacing=0 cellpadding=5 border=0><tr><td valign=top>
| . make_buttons($look_n_feel,script_name,$page,\@_,$buttwidth) . q|<br>
&nbsp;
<center>
<img name=working src="|. $look_n_feel->{images} . q|cleardot.gif" width=93 height=36 alt="">
</center></td><td valign=top align=center width=100%>
| . $$rpt . q|</td></tr>
<tr><td>&nbsp;</td><td align=center>
| . make_buttons($look_n_feel,script_name,$page,\@buttons) . q|</td></tr>
</table>
</body></html>
|;
  $rpt = \$html;
}

## UPDATE CACHED PAGES
upd_cache($look_n_feel->{html_cache_file},$page,$rpt,$sht);

# the file
$_ = $look_n_feel->{html_cache_file} .'.'. $page;

$mtime = (stat($_))[9];		# file last modified

## SERVICE WEB REQUEST
local(*FH);
open(FH,$_);
my $size = (stat FH)[7];
my $ctype = ($page ne 'short') ?  'text/html' : 'text/plain';

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
  $r->send_fd(*FH);
  close FH;
  return 200;			# HTTP_OK

} else {	# sigh... no mod_perl

  undef $/;
  my $textp = <FH>;	# slurp file
  close FH;
  $/ = "\n";
  print q
|Content-type: |, $ctype, q|
Content-length: |, $size, q|
Last-modified: |, http_date($mtime), q|
Connection: close
Expires: |, http_date($mtime + $look_n_feel->{html_expire}), qq|
$xhead: $xhv

$textp|;
}

# free memory resources for re-use
undef $rpt;
undef $sht;
undef $html;
undef $report;
undef $short;
undef $out;

1;
