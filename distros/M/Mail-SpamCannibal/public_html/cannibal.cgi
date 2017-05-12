#!/usr/bin/perl
#
package Mail::SpamCannibal::PageIndex;
#
# cannibal.cgi or cannibal.plx
# link admin.cgi or admin.plx
#
# version 2.23, 6-12-15
#
# Copyright 2003 - 2015, Michael Robinton <michael@bizsystems.com>
#   
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
use strict;
#use diagnostics;
use vars qw(%ftxt $timeout);

$timeout = 15;	# 15 second timeout for internal UDP PTR lookup

use Mail::SpamCannibal;				# just for version number
use IPTables::IPv4::DBTarpit;			# just for version number
use Mail::SpamCannibal::IP2ccFlag;
use Mail::SpamCannibal::ScriptSupport qw(
	doINCLUDE
	lookupIP
	validIP
	valid127
	is_GENERIC
);
use Net::DNS::Codes qw(:all);

use Net::DNS::ToolKit qw(
	newhead
	gethead
	get_ns
	inet_aton
	inet_ntoa
	ttlAlpha2Num
);
use Net::DNS::ToolKit::Utilities qw(
	id
	query
	question
	rlook_send
	rlook_rcv 
);
use Mail::SpamCannibal::BDBclient qw(
	dataquery
	retrieve
	INADDR_NONE
);

#########################################################################
# Individual pages are put together by calling the html_cat routine.	#
# See: Mail::SpamCannibal::WebService &html_cat				#
#########################################################################

use Mail::SpamCannibal::WebService qw(
	sendhtml
	html_cat
	cookie_date
	get_query
	make_jsPOP_win
);
use Mail::SpamCannibal::Session qw(
	decode
	sesswrap
);

my $CONFIG = doINCLUDE '../config/sc_web.conf';

die "could not load config file"
	unless $CONFIG;

my $OverRide = 0;					# override mod perl output
my ($admin,$sess,%extraheaders);
my $expire	= $CONFIG->{expire} || 300;		# default expiration 5 minutes
my $log_expire	= $CONFIG->{log_expire} || 180;		# default expiration 3 minutes
my %query	= get_query();

# allow dashes (-) in ip address
if ($query{lookup} && $query{lookup} =~ /(\d+[\.-]\d+[\.-]\d+[\.-]\d+)/) {
  ($query{lookup} = $1) =~ s/\-/\./g;
}

# check for query from LaBrea client & convert if necessary
if ($query{query} && $query{query} =~ /(\d+\.\d+\.\d+\.\d+)/) {
  $query{page} = 'lookup';
  $query{lookup} = $1;
}

# return session on success, undef otherwise
#
sub is_cookie() {
  return($ENV{HTTP_COOKIE} && 
	 $ENV{HTTP_COOKIE} =~ /SpamCannibal=([\w-]+\.[\w-]+\.\d+\.\d+\.[\w-]+)/)
		? $1 : undef;
}  

my $admses = 0;
my $user;
my $passexp = 0;
if ($ENV{SCRIPT_FILENAME} && $ENV{SCRIPT_FILENAME} =~ m|/admin\..+$|) {
  $extraheaders{'Set-Cookie'} = 'SpamCannibal=on; path=/; expires='. cookie_date(1);
  if (($admin = $CONFIG->{wrapper}) &&
      -e $admin && -x $admin &&
      do {			# return true if good session instantiated
	if (	$query{user} &&
		($_ = sesswrap("$admin newtick $query{user}")) &&
		$_ =~ /^OK\s+([\w-]+\.[\w-]+\.\d+\.\d+\.[\w-]+)/) {
	  $sess = $1;
	  $query{page} = 'passwd';
	}
	elsif (	defined $query{passwd} &&
		($sess = is_cookie) &&
		($_ = sesswrap("$admin login $sess $log_expire $query{passwd} $CONFIG->{maxretry}")) &&
		($query{page} = '2realAH') &&
		($_ =~ /^OK\s*([^\s]+)/ || ($_ =~ /^NOT OK\s*([^\s]+)/ && ($query{page} = 'passwd'))) &&
		($user = $1)) {
	  1;
	}
	elsif (	($sess = is_cookie) &&
		($_ = sesswrap("$admin chksess $sess $expire")) &&
		$_ =~ /^OK\s*([^\s]+)/ &&
		($user = $1)) {
	  1;
	}
	else {
	  0;
	}
      }
    ) {
    $extraheaders{'Set-Cookie'} = 'SpamCannibal='. $sess . 
	'; path=/; expires='. cookie_date(time + $expire);
    $extraheaders{'Set-Cookie'} .= '; secure'
	if $CONFIG->{secure};
    $query{page} = 'ahome'
	unless $query{page};
    $admses = $expire - 60;					# this is an admin session
    $admses = 0 if $admses < 0;
    $admses *= 1000;						# session web page timeout
  }
  else {
    $query{page} = 'login'
	unless $query{page} eq '2realAH';			# reset to login indirectly if password expire
  }

  push @{$CONFIG->{static}}, @{$CONFIG->{admin}};
  if ($CONFIG->{secure} && ! $ENV{SSL_SERVER_CN}) {	# bail if not secure connection
    $query{page} = 'sorry';
  }
}
else {
  $query{page} = 'home'
	unless $query{page};
}

# %ftxt will contain a like hash of cached text and will already
# exist if there is a previous instantiation of this script

%ftxt = () unless %ftxt;
my $bgcolor = ($CONFIG->{bgcolor} && $CONFIG->{bgcolor} =~ /^#[0-9a-fA-F]{6}$/)
	? $CONFIG->{bgcolor}
	:'#ffffff';
$ftxt{bgcolor} = qq| bgcolor="$bgcolor" |;
$ftxt{versions} = q|<!--|.
	q| MSC:|. $Mail::SpamCannibal::VERSION .
	q| NDC:|. $Net::DNS::Codes::VERSION .
	q| NDT:|. $Net::DNS::ToolKit::VERSION .
	q| IID:|. $IPTables::IPv4::DBTarpit::VERSION .
	q| -->
<script language=javascript1.1>
  bgcolor="|. $bgcolor .q|";
</script>
|;

my $html = '';
my $pagerror = '';

PageGen:
while (1) {

# for static pages, just issue them
  my ($name,$nav);

  if ($admin) {		# use nav2 for admin
    $nav = ($query{page} =~ /sorry|login|passwd/)	# no nav bar for listed pages
	? '' : 'nav2';
    $ftxt{versions} .= make_jsPOP_win('passwd',300,200)
	if $query{page} eq 'login';
  } else {
    $nav = 'nav';
  }

######	STATIC pages except 'home'
  foreach $name (@{$CONFIG->{static}}) {
    if ($query{page} =~ /^$name/) {
      foreach (qw(
		top
		bgcolor
		top2
		versions
		logo2
		stats
		),
		$nav,
		$name,
	) {
        html_cat(\$html,$_,$CONFIG,\%ftxt);
      }
      $html .= $pagerror;
      last PageGen;
    }
  }

######	HOME

  if ($query{page} =~ /^home/) {
    foreach (qw(
	top
	bgcolor
	top2
	versions
	logo1
	stats
	),
	'nav',
	'home',
        ) {
      html_cat(\$html,$_,$CONFIG,\%ftxt);
    }
    $html .= (exists $CONFIG->{reason} && $CONFIG->{reason})
	? $CONFIG->{reason}
	: q
|SpamCannibal does not block email access except for IP addresses and
generic netblocks that have sent or relayed what we believe to be spam or 
other unsolicited email directly to our email servers.  Spam originating 
IP addresses are blocked ONLY for access to our mail servers, however, 
the database we use for that purpose is freely available for anyone to 
look at and use as they see fit.
|;
    $html .= "<hr>\n";
    last PageGen;
  }

######	WHOIS

  if ($query{page} =~ /^whois/) {
    my $IP = ($query{whois} && $query{whois} =~ /(\d+\.\d+\.\d+\.\d+)/)
	? $1 : '';
    foreach (qw(
	top
	bgcolor
	top2
	versions
	logo2
	stats
	),
	$nav,
	'whois',
        ) {
      html_cat(\$html,$_,$CONFIG,\%ftxt);
    }
    if ($IP) {
      if ($ENV{HTTP_REFERER} !~ /$ENV{SERVER_NAME}/i || $ENV{HTTP_REFERER} =~ m|/\?|) {
	$html .= qq|
Due to the excessive load placed on our system, we have disabled the ability
for third party sites to query the Whois Proxy through the web
interface. Please enter your request manually.
<script language=javascript1.1>
document.whois.whois.value = '$IP';
</script>
|;
      } else {

	my $cc = (@_ = Mail::SpamCannibal::IP2ccFlag::get($IP))
		? qq|&nbsp;&nbsp;$_[0]</td><td><img src="$_[1]" alt="$_[0]" height=22 border=1>| : '';
	require Mail::SpamCannibal::WhoisIP;

	my $lkup = qq|<a href="#top"
onClick="document.whois.lookup.value = '$IP';document.whois.page.value = 'lookup';document.whois.submit();return false;"
onMouseOver="return(show('lookup |. $IP .qq|'));" onMouseOut="return(off());">$IP</a>|;

	$html .= "<table cellspacing=5 cellpadding=0 border=0><tr valign=middle><td>Whois response for: ${lkup}$cc</td></tr></table>";

	my $socket = rlook_send($IP,$timeout);
	my $wtxt = &Mail::SpamCannibal::WhoisIP::whoisIP($IP);
	my @hostname = rlook_rcv($socket,$timeout);
	foreach (@hostname) {
	  $html .= "\n&nbsp;&nbsp;" . $_ . "<br>";
	};
	$html .= "<pre>". $wtxt ."</pre>\n";
      }
    }
    last PageGen;
  }

######  CONTACT

  if ($query{page} =~ /^contact/) {
    die "email contact not configured" unless $CONFIG->{email};
    foreach (qw(
        top
	bgcolor
	top2
	versions
        logo2
	stats
        ),
        $nav,
        ) {
      html_cat(\$html,$_,$CONFIG,\%ftxt);
    }
    $html .= q|
<blockquote>
<b>
|. ($ENV{REMOTE_HOST} || '') .' '. ($ENV{REMOTE_ADDR} || '') .q|<br>
</b>
</blockquote>
|;
    $html .= $pagerror if $pagerror;
    html_cat(\$html,'contact',$CONFIG,\%ftxt);
    last PageGen;
  }

######  SENDMSG

  if ($query{page} =~ /^sendmsg/) {
    die "email contact not configured" unless $CONFIG->{email};
    my($sc,$bc,$socket,@hostname);
    my $IP = ($query{IP} && $query{IP} =~ /(\d+\.\d+\.\d+\.\d+)/)
	? $1 : '';

    if ($IP) {
      require Mail::SpamCannibal::SiteConfig;
      $sc = $CONFIG->{SiteConfig} || do { 
	require Mail::SpamCannibal::SiteConfig;
	new Mail::SpamCannibal::SiteConfig;
      };
      $bc = $sc->{SPMCNBL_CONFIG_DIR} . '/sc_BlackList.conf';
      $bc = doINCLUDE($bc) || die "could not load blacklist config file... $bc";
      $bc = ($bc->{GENERIC} && $bc->{GENERIC}->{blockcontact})
	? $bc->{GENERIC} : 0;				# $bc points to GENERIC hash
    }

    foreach (qw(
        top
	bgcolor
	top2
	versions
        logo2 
	stats
        ),
        $nav,
        ) {
      html_cat(\$html,$_,$CONFIG,\%ftxt);
    }
    if ($ENV{HTTP_REFERER} !~ /$ENV{SERVER_NAME}/i) {
      $html .= q|
Automated send not allowed.
|;
    } elsif ( ! $IP) {
      $html .= q|
Invalid IP address.
| . $query{IP} .q|
|;
    } elsif ( $bc && do {
	$socket = rlook_send($IP,$timeout);
	@hostname = rlook_rcv($socket,$timeout);
	is_GENERIC($bc,@hostname)} )
    {
      $pagerror = $IP .q| not eligible for removal: GENERIC PTR
<blockquote>
|;
      foreach (@hostname) {
	$pagerror .= $_ . q|<br>
|;
      }
      $pagerror .= q|</blockquote>
|;
      $query{page} = 'contact';
      $html = '';
      next PageGen;
    } elsif ($CONFIG->{userdelOK}) {
      ;	# some stuff to check lookup? and do a delete
    } else {
      require Mail::SpamCannibal::SMTPsend;
      if ($CONFIG->{altMXhosts}) {
	*Mail::SpamCannibal::SMTPsend::getMXhosts = sub {
	  return @{$CONFIG->{altMXhosts}};
	$_ = \*Mail::SpamCannibal::SMTPsend::getMXhosts; # suppress warning message
	}
      }
      $html .= q|
Message sent.
|;
      my $webmsg = qq|Subject: spamcannibal web contact

Remote Host:	$ENV{REMOTE_HOST}
Remote Addr:	$ENV{REMOTE_ADDR}

Email addr:	$query{email}
IP address:	$query{IP}

|;
      $_ = Mail::SpamCannibal::SMTPsend::sendmessage($webmsg . $query{message},$CONFIG->{email});
    }
    last PageGen;
  }

######	LOOKUP

  if ($query{page} =~ /^lookup/) {
    my $IP = validIP($query{lookup});
    foreach (qw(
	top
	bgcolor
	top2
	versions
	logo2
	stats
	),
	$nav,
	'lookup',
	) {
      html_cat(\$html,$_,$CONFIG,\%ftxt);
    }
    $html .= $query{pagerror};
    if ($IP) {
      if ($ENV{HTTP_REFERER} !~ /$ENV{SERVER_NAME}/i || $ENV{HTTP_REFERER} =~ m|/\?|) {
	$html .= qq|
Automated lookups not allowed, click LOOKUP IP to continue.
<script language=javascript1.1>
document.lookup.lookup.value = '$IP';
</script>
|;
      } else {
	require Mail::SpamCannibal::SiteConfig;
	my $sc = $CONFIG->{SiteConfig} || do { 
		require Mail::SpamCannibal::SiteConfig;
		new Mail::SpamCannibal::SiteConfig;
	};
	unless (exists $CONFIG->{bdbDAEMON}) {
	  $CONFIG->{bdbDAEMON} = $sc->{SPMCNBL_ENVIRONMENT} .'/bdbread';
	}

	my @ccs;
	my $cc = (@ccs = Mail::SpamCannibal::IP2ccFlag::get($IP))
		? qq|&nbsp;&nbsp;$ccs[0]</td><td><img src="$ccs[1]" alt="$_[0]" height=22 border=1>| : '';
	my $substr = qq|<a href="#top" onClick="return(wIP('$IP'));" onMouseover="return(show('whois $IP'));" onMouseOut="return(off());">$IP</a>|;
	$html .= q|<script language=javascript1.1>
function wIP(ip) {
  document.LookUP.whois.value = ip;
  document.LookUP.action = location.pathname;
  document.LookUP.submit();
  return false;
}
</script>
<form name="LookUP" action="" method=POST>
<input type=hidden name=whois value="">
<input type=hidden name=page value=whois>
<table border=0><tr valign=middle><td>Click for WhoisIP: |. $substr . $cc;

	my $ipTtag = '';

	if ($admin) {
	  $html .= q
|</td><td width=10>&nbsp;</td><td><table cellspacing=0 cellpadding=2 border=1>
<tr><td class=hot><a href="#top" class=hot onMouseOver="return(show('delete |. $IP .q|'));" onMouseOut="return(off());"
  onClick="return(wDelete());">X</a></td></tr></table></td><td>delete</td>
    <td><table cellspacing=0 cellpadding=2 border=1><tr>
      <td class=hot nowrap><a href="#top" class=hot onMouseOver="return(show('delete CIDR/24 |. $IP .q|'));" onMouseOut="return(off());"
  onClick="if (confirm('do you really want to delete a 256 address block?')) { self.location = location.pathname + '?page=delBLK&remove=' + '|.
	  $IP .q|'; } return false;">X CIDR/24</a></td></tr></table>|;
	}
	my $socket = rlook_send($IP,$timeout);
	my ($second,$text,$results);
	if(ref $CONFIG->{bdbDAEMON}) {	# remote?
	  ($second,$text) = lookupIP($sc,$IP,@{$CONFIG->{bdbDAEMON}});
	} else {
	  ($second,$text) = lookupIP($sc,$IP,$CONFIG->{bdbDAEMON},0);
	}
	if($second) {		# if secondary db 'blcontrib'
	  $text =~ s|(http://([\w\.\-\?#&=/]+))|\<a href="$1"\>$2\</a\>|;
	  $results = "\n<p>\n". $text;
	} else {
	  $text =~ s/</&lt;/g;		# unmask html <
	  $text =~ s/>/&gt;/g;		# unmask html >
	  $text =~ s/$IP(\D)/$substr$1/g;
	  $results = "\n<pre>\n". $text ."\n</pre>";
	}
	my $ip_found = 1;
	if ($admin && $text =~ /^not\s+in\s+\w+\s+database/) {
	  $ip_found = 0;
	  $IP =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
	  my $revip = "$4.$3.$2.$1";
	  $html .= q|
<td width=20>&nbsp;</td><td><table cellspacing=0 cellpadding=2 border=1><tr>
    <td class=cold><a href="#top" class=cold onMouseOver="return(show('tarpit |. $IP .q|'));" onMouseOut="return(off());"
  onClick="self.location = location.pathname + '?page=spamlst&host=' + '|. $IP .q|'; return false;">&#164;</a></td></tr></table></td><td>+ tarpit&nbsp;&nbsp;</td><td><table cellspacing=0 cellpadding=2 border=1><tr>
<td class=hot><a href="#top" class=hot onClick="document.forms['lookup']['lookup'].value = '|. $revip .q|';return false;" title="rev IP">&gt;&lt;</a></td></tr></table>|;
	}
	my @hostname = rlook_rcv($socket,$timeout);
	$html .= '</td></tr></table>';
	if (@hostname) {
	  my $hostname = '';
	  foreach(@hostname) {
	    $hostname .= $_ . "<br>\n";
	  }
	  $html .= q|<table cellspacing=0 cellpadding=0 border=0><tr><td width=10>&nbsp;</td><td>|. $hostname;
	}
	else {
	  $html .= q|<table cellspacing=0 cellpadding=0 border=0><tr><td width=10>&nbsp;|;
	}
	if ($admin) {
	  $html .= q|<td width=10>&nbsp;</td><td valign=top><table cellspacing=0 cellpadding=1 border=1><tr><td class=hot><a
href="#top" class=hot onMouseOver="return(show('PTR records'));" onMouseOut="return(off());"
onClick="document.rdnsblk.lookup.value='|. $IP .q|'; document.rdnsblk.submit(); return
false;">&nbsp;PTR's&nbsp;</a></td>
</tr></table>
|;
	}
	$html .= q|</td><td width=20>&nbsp;</td><td valign=middle>|. $ccs[2] .q|</td><td width=20>&nbsp;</td><td><span id=ipttag></span></td></tr></table>
|. $results .q|
</form>
|;

	if ($admin) {
	  $html .= q|
<form name="rdnsblk" target="_blank" action="" method=POST>
<input type=hidden name=lookup value="">
<input type=hidden name=page value=rdnsblk>
</form>
<script language=javascript1.1>
function wDelete() {
  if (document.bulkremove) {
    var tmp;
    var checked = 0;
    if (tmp = document.bulkremove.rm.length) {    // is an array
      for (i = 0;i < tmp;i++) {
        if (document.bulkremove.rm[i].checked)
          checked++;
      }
    } else if (document.bulkremove.rm.checked)
      checked = 1;
    if (checked > 0) {
      checked += |. $ip_found .q|;
      if (checked > 1)
        tmp = 'addresses?';
      else
        tmp = 'address?';
      document.bulkremove.action = location.pathname;
      if (confirm('do you really want to delete ' + checked + ' IP ' + tmp))
        document.bulkremove.submit();
      return false;
    }
  }
  self.location = location.pathname + '?page=delete&remove=' + '|. $IP .q|';
  return false;
}
</script>
|;
	  use integer;
	  my $found = 0;
	  my $related = '';
	  $IP =~ /(\d+\.\d+\.\d+\.)/;
	  my $cidr = $1;
# get CIDR differential data and recover minus's
	  ($_ = sesswrap("$admin getC24 $sess $expire $IP")) =~ s/;/:-/g;
	  if ($_ =~ /^OK\s+(.+)/) {
	    my($vec,@vals) =  split(':',$1);	# differential values to @vals
	    @_ = split('',$vec);
	    my $timetag = 0;
	    my $lastime = 0;
	    my $lastim2 = 0;
	    foreach(0..$#_) {
	      next unless $_[$_];
	      $timetag += shift @vals;
	      my $addr = "${cidr}$_";
	      if ($addr eq $IP) {	# put time tag in top of page
		$ipTtag = scalar localtime($timetag);
		next;
	      }
#	      next if $addr eq $IP;
	      $found += 1;
	      my $font = '';
	      my $nfont = '';
	      if ($lastime && ($lastime != $timetag && $timetag != $lastim2)) {
		$font = '<font color="#FF0000">';
		$nfont = '</font>';
	      }
	      $lastim2 = $lastime;
	      $lastime = $timetag;
	      $related .= q|<tr><td><a href="#top" onMouseOver="return(show('lookup |. $addr .q|'));" onMouseOut="return(off());"
  onClick="lookup.lookup.value='|. $addr .q|';lookup.submit();return false;">|. $addr .q|</a></td><td>|. $font .
	      scalar localtime($timetag) . $nfont .q|</td><td align=center><input name=rm type=checkbox value="|. $addr .q|"></td></tr>
|;
	    }
	  } else {	# response was NOT OK
	    $html .= '<font size="+1" color=red><pre>' . $_ . '</pre></font><br>'
	  }
	  if ($found) {
	    $html .= q|<form name=bulkremove action='' method=POST><blockquote>
<b>|. $found .q| record|. (($found > 1) ? 's' : '') .q| in the same netblock</b>
<p>
<table cellspacing=0 cellpadding=2 border=1>
  <tr><td align=center>host address</td><td align=center>last contact</td><td>delete<input
type=hidden name=page value=delete><input type=hidden name=remove value='|. $IP .q|'></td></tr>|.
	    $related .q|
</table>|;
	    if ($ipTtag) {
	      $html .= q|<script language=javascript>
document.getElementById('ipttag').innerHTML = "|. $ipTtag .q|";
</script>
|;
	    }
	    $html .= q|</blockquote></form>
<div id="gotop"><a id="atop" href="#top">TOP</a></div>
|;
	  }
	}
      }
    }
    last PageGen;
  }

######  LOGOUT

  if ($admin && $query{page} =~ /^logout/) {
    $_ = sesswrap("$admin rmvsess $sess");
    $query{page} = 'login';
    $extraheaders{'Set-Cookie'} = 'SpamCannibal=expired; path=/; expires='. cookie_date(1);
    next PageGen;
  }

######  USRUPD

  if ($admin && $query{page} =~ /^usrupd/) {
    $query{passwd} = '' unless $query{passwd};
    $query{passwd2} = '' unless $query{passwd2};
    $pagerror .= '<font size="+1" color=red>blank user name</font><br>'
	unless $query{newuser};
    $pagerror .= '<font size="+1" color=red>new passwords do not match</font><br>'
	if $query{passwd} ne $query{passwd2};
    unless ($pagerror) {
      $_ = sesswrap("$admin updpass $sess $expire $query{newuser} $query{passwd} $query{oldpasswd}");
      $pagerror .= '<font size="+1" color=red>' . $_ . '</font><br>'
	unless $_ =~ /^OK/;
    }
    if ($pagerror) {
# NOTE: see javascript entry at bottom of this page near </body> tag
      $query{page} = 'updpass';
    } else {
      $query{page} = 'ahome';
    }
    next PageGen;
  }

###### 2REALAH

  if ($admin && $query{page} =~ '2realAH') {
    $html = q|<!DOCTYPE html>
<html>
<head><title>SpamCannibal</title>
<link rel="shortcut icon" type="image/ico" href="/favicon.ico" />
<script language=javascript1.1>
if (!(opener == (void 0) |. '||'. q| !opener ))
  opener.cleanPath();
self.close();
</script>
</head><body>
|;
  }

######  AHOME

  if ($admin && $query{page} =~ 'ahome') {
    foreach (qw(
	top
	bgcolor
	top2
	versions
	logo2
	stats
	),
	$nav,
	) {
      html_cat(\$html,$_,$CONFIG,\%ftxt);
    }
    $sess =~ /^([\w-]+)/;
    $user = $1;
    $html .= q|<center>
<table border=0>
<tr><td class=bld colspan=2>Access granted for:</td></tr>
<tr><td class=wht>User:</td><td class=bld>|. decode($user) .q|</td></tr>
<tr><td class=wht>Host:</td><td class=bld>|. ($ENV{REMOTE_HOST} || '<i>unknown</i>') .q|</td></tr>
<tr><td class=wht>IP:</td><td class=bld>|. ($ENV{REMOTE_ADDR} || '') .q|</td></tr>
<tr><td class=bld colspan=2>|. ($ENV{HTTP_USER_AGENT} || '<i>unknown</i>') .q|</td></tr>
</table>
</center>
|;
    last PageGen;
  }

######  SPAMADD

  if ($admin && $query{page} =~ /^spamadd/) {
    require Mail::SpamCannibal::ParseMessage;
    import Mail::SpamCannibal::ParseMessage qw(
	array2string
	string2array
    );
    my $host = validIP($query{host});
    $pagerror .= $query{host} .' <font size="+1" color=red>invalid host IP address</font><br>'
	unless $host;
    my @spam;
    $pagerror .= ' <font size="+1" color=red>no SPAM evidence entered</font><br>'
	unless $query{spam} =~ /\S+/ && string2array($query{spam},\@spam);

    if ($pagerror) {
      $query{page} = 'spamlst';
      next PageGen;
    }

    require Mail::SpamCannibal::SiteConfig;
    my $sc = $CONFIG->{SiteConfig} || do { 
      require Mail::SpamCannibal::SiteConfig;
      new Mail::SpamCannibal::SiteConfig;
    };
    unless (exists $CONFIG->{bdbDAEMON}) {
      $CONFIG->{bdbDAEMON} = $sc->{SPMCNBL_ENVIRONMENT} .'/bdbread';
    }

# is this a CIDR insertion request for CIDR/24 - CIDR/31
    my $action = ($query{submit} =~ /^(\d+)$/ && $1 < 32 && $1 >23) ? 'insEBLK'.$1 : 'insEVD';

    foreach(0..$#spam) {
      $spam[$_] = '>'. $spam[$_]
	if $spam[$_] eq '.' && $_ != $#spam;
    }
    push @spam, '.'
	if $spam[$#spam] ne '.';
    my $spam = array2string(\@spam);

    $_ = sesswrap("$admin $action $sess $expire $host",$spam);

    if ($_ =~ /^OK/) {
      $query{page} = 'lookup';
      $query{lookup} = $host;
    } else {
      $query{page} = 'spamlst';
      $pagerror = '<font size="+1" color=red>'. $_ .'</font><br>';
    }
    next PageGen;
  }

######  BLKADD

  if ($admin && $query{page} =~ /^blkadd/) {
    my $host = validIP($query{host});
    my $response = valid127($query{response});
    my $remote = validIP($query{remote});
    my $seconds = $query{expire} || 0;
    $seconds = ttlAlpha2Num($seconds) + time;
    $pagerror .= $query{host} .' <font size="+1" color=red>invalid host IP address</font><br>'
	unless $host;
    $pagerror .= $query{response} .' <font size="+1" color=red>invalid local DNSBL response IP</font><br>'
	unless $response && $response eq $query{response};
    $pagerror .= '<font size="+1" color=red>no TXT record string found</font><br>'
	unless $query{error};
    $pagerror .= $query{remote} .' <font size="+1" color=red>invalid remote DNSBL response IP</font><br>'
	unless $remote;
    $pagerror .= '<font size="+1" color=red> missing zone</font><br>'
	unless $query{zone};
    $pagerror .= $query{zone} .' <font size="+1" color=red>no NS records for this zone</font><br>'
	unless !$query{zone} || do {
		my $querybuf = question($query{zone},T_A());
		my $resp = query(\$querybuf);
		if ($resp) {		# got answer
		  my ($off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
			$qdcount,$ancount,$nscount,$arcount)
			= gethead(\$resp);
		  $ancount;
		} else {
		  0;
		}
	};

    if ($pagerror) {
      $query{page} = 'blklist';
    } else {
      $_ = sesswrap(qq|$admin insBL $sess $expire $host $response "$query{error}" $remote $seconds $query{zone}|);
      if ($_ =~ /^OK/) {
	$query{page} = 'lookup';
	$query{lookup} = $host;
      } else {
	$query{page} = 'blklist';
	$pagerror = '<font size="+1" color=red>'. $_ .'</font><br>';
      }
    }
    next PageGen;
  }

######  DELETE

  if ($admin && 
      (	$query{page} =~ /^delete/ ||
	$query{page} =~ /^delBLK/ )) {
    my $action = ($query{page} =~ /^delBLK/) ? 'delBLK' : 'delete';
    $_ = sesswrap("$admin $action $sess $expire $query{remove}");
    unless ($_ =~ /^OK/) {
      $query{pagerror} = '<font size="+1" color=red>'. $_ .'</font><br>';
    } 
    if ($action eq 'delete' && exists $query{rm}) {
      my @zap = split("\0",$query{rm});
      foreach my $ip (@zap) {
	$_ = sesswrap("$admin $action $sess $expire $ip");
	$query{pagerror} .= '<font size="+1" color=red>'. $_ .'</font><br>'
		unless $_ =~ /^OK/;
      }
    }
    $query{page} = 'lookup';
    $query{lookup} = $query{remove};
    next PageGen;
  }

######  DELETE LIST

  if ($admin && $query{page} =~ /^delist/ ) {
    foreach (qw(
	top
	bgcolor
	top2
	versions
	logo2
	stats
	),
	$nav,
	'delist',
	) {
	html_cat(\$html,$_,$CONFIG,\%ftxt);
    }   

    if (exists $query{remove}) {
      my @zap = split(/\n/,$query{remove});
      my $cnt = 0;
      foreach (@zap) {
	next unless $_ =~ /^\s*(\d+\.\d+\.\d+\.\d+)/;
	my $ip = $1;
	next if $_ =~ /\stimeout\s/;				# skip if this is a timeout
	$_ =  sesswrap("$admin delete $sess $expire $ip");
	unless ($_ =~ /^OK/) { 
	  $query{pagerror} = '<font size="+1" color=red>'. $_ .'</font><br>';
	}
        $cnt++;
      }
      unless ($cnt) {
	$pagerror = '<font size="+1" color=red>no valid IP addresses</font><br>';
      }
      $html .= $pagerror;
    }
    last PageGen;
  }

######  RDNSBLK

  if ($admin && $query{page} =~ /^rdnsblk/ ) {
    my $IP = validIP($query{lookup});
    my $regexp = $query{regexp} || '';
    foreach (qw(
	top
	bgcolor
	top2
	versions
	logo2
	stats
	),
	$nav,
	'rdnsblk',
	) {
	html_cat(\$html,$_,$CONFIG,\%ftxt);
    }
    if ($IP && $IP =~ /(\d+)\.(\d+)\.(\d+)/) {
      my $revip = "${3}.${2}.${1}.in-addr.arpa";
      my $match = "${&}.";
      my $sock = IO::Socket::INET->new(
	PeerAddr	=> inet_ntoa(scalar get_ns()),
	PeerPort	=> 53,
	Proto		=> 'udp',
	Type		=> IO::Socket::INET::SOCK_DGRAM,
      ) or print STDERR "could not open socket for rdns lookup\n";
      my($buffer,$response);
      (my $rgx = $regexp) =~ s/\\/\\\\/g;
      $html .= q|<script language=javascript1.1>
document.rdnsblk.lookup.value='|. $IP .q|';
document.rdnsblk.regexp.value='|. $rgx .q|';
</script>
<blockquote>
<table cellspacing=0 cellpadding=2 border=1>
|;
      $OverRide = 1;
      local $| = 1;		# flush buffer on each print statement
      print q
|Content-type: text/html
|;
      if (keys %extraheaders) {
	foreach(keys %extraheaders) {
	  print $_,':: ',$extraheaders{"$_"};
	}
      }
      print q|

|, $html;

      $html = '';
      my($get,$put,$parse) = new Net::DNS::ToolKit::RR;
      foreach (0..255) {
	my $name = join('.',$_,$revip);
	my $ip = $match . $_;
	my $bp = \$buffer;
	my $offset = newhead($bp,
		id(),
		BITS_QUERY | RD,
		1,0,0,0,
	);
	$offset = $put->Question(\$buffer,$offset,$name,T_PTR,C_IN);
	eval {
		local $SIG{ALRM} = sub {die "timeout"};
		alarm 5;			# 5 second timeout
		my $wrote = syswrite $sock, $buffer, $offset;
		my $urcv;
		die "failed to get UDP message" unless
			defined ($urcv = sysread($sock, $response, NS_PACKETSZ));
		alarm 0;
	};
	if ($@) {
	  print "<tr><td>$ip</td><td>timeout ${timeout}s</td></tr>\n";
	  next;
	}
	$bp = \$response;
	my ($newoff,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
		$qdcount,$ancount,$nscount,$arcount)
		= gethead($bp);
	next if ($rcode != NOERROR);
	my($type,$class,$ttl,$rdlength,@rdata);
	foreach(0..$qdcount -1) {
	  ($newoff,$name,$type,$class) = $get->Question($bp,$newoff);
	  my $line = '';
	  foreach(0..$ancount -1) {
	    ($newoff, $name,$type,$class,$ttl,$rdlength,@rdata) = $get->next($bp,$newoff);
	    $line .= qq|<tr><td>$ip</td><td>$rdata[0]</td></tr>\n|;
	    $ip = '&nbsp;';
	  }
	  next if $regexp && $line =~ /$regexp/i;
	  print $line;
	}
      }
      close $sock;
      $html .= q|</table>
</blockquote>
|;
    }
    last PageGen;
  }


######  VIEW DB

  if ($admin && $query{page} =~ /^viewdb/) {
    foreach (qw(
	top
	bgcolor
	top2
	versions
	logo2
	stats
	),
	$nav,
	) {
      html_cat(\$html,$_,$CONFIG,\%ftxt);
    }
    my $sc = $CONFIG->{SiteConfig} || do {
	require Mail::SpamCannibal::SiteConfig;
	new Mail::SpamCannibal::SiteConfig;
    };
    unless (exists $CONFIG->{bdbDAEMON}) {
	$CONFIG->{bdbDAEMON} = $sc->{SPMCNBL_ENVIRONMENT} .'/bdbread';
    }

    $html =~ s/onLoad/onUnLoad=\"popadclose();\" onLoad/;
    $html .= make_jsPOP_win('alookup',580,400);
    $html .= q|<script language=javascript1.1>
function dbvs(db,rn) {
  document.dbsel.action = location.pathname
  document.dbsel.datab.value = db;
  document.dbsel.recno.value = rn;
  document.dbsel.submit();
  return false;
}
var alookup = null;
function popadclose() {
  if (alookup == null) return;
  if (alookup.closed == null) return;
  alookup.close();
}
function lIP(ip) {
  popwin('|. $bgcolor .q|');
  document.ViewDB.lookup.value = ip;
  document.ViewDB.action = location.pathname;
  document.ViewDB.submit();
  return false;
}
</script>
<form name=dbsel action="" method=POST onSubmit="return false;">
<input type=hidden name=page value=viewdb>
<input type=hidden name=datab value="">
<table cellspacing=0 cellpadding=10 border=0>
</script>
<tr align=center><td colspan=4 class=bld><font size="-1">Select DATABASE to view</font></td></tr>
<tr align=center>
|;
    
    my %records;
    foreach(	$sc->{SPMCNBL_DB_TARPIT},
		$sc->{SPMCNBL_DB_ARCHIVE},
		$sc->{SPMCNBL_DB_CONTRIB},
		$sc->{SPMCNBL_DB_EVIDENCE},
	) {
      $html .= q|<td class=bld>|;

      my($key,$val);
      if(ref $CONFIG->{bdbDAEMON}) {	# remote?
	($key,$val) =  dataquery(1,0,$_,@{$CONFIG->{bdbDAEMON}});
      } else {
	($key,$val) =  dataquery(1,0,$_,$CONFIG->{bdbDAEMON},0);
      }

      if (!$key || $key eq &INADDR_NONE()) {
	$val = '<font color=red>OFFLINE</font>';
	$records{$_} = 0;
      } else {
	$records{$_} = $val;		# save record count
      }

      $html .= $val .q| recs<br>
  <a href="#top" onClick="return(dbvs('|. $_ .q|','1'));" onMouseOver="return(show('|. (uc $_) .q|'));" onMouseOut="return(off());">|. $_ .q|</a></td>
|;
    }
    $html .= q|</tr>
</table>
|;

    my $ip = '';
    unless ((my $db = $query{datab}) && 
	(my $rectop = $records{"$query{datab}"})) {	# no database view requested
      $html .= q|<input type=hidden name=recno value="">
</form>
|;
      last PageGen;

    } else {						# database view requested

      my($count,@IPs);
      my $recno = $query{recno} || 1;

      if ($recno =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ||
	  $recno =~ /(\d{1,3}\.\d{1,3}\.\d{1,3})/ ||
	  $recno =~ /(\d{1,3}\.\d{1,3})/ ||
	  $recno =~ /(\d{1,3})\./
      ) {					# search for IP
	$ip = $1;
	$count = $ip =~ tr/\.//;		# rationalize IP address
	while($count < 3) {
	  $count++;
	  $ip .= '.0';
	}
	my $naddr = inet_aton($ip);
	my $rmax = $rectop;
	my $rmin = 1;

	while (1) {
	  $recno = int(($rmax + $rmin)/2);
	  if(ref $CONFIG->{bdbDAEMON}) {	# remote?
	    $count = retrieve(2,$recno,$db,\@IPs,@{$CONFIG->{bdbDAEMON}});
	  } else {
	    $count = retrieve(2,$recno,$db,\@IPs,$CONFIG->{bdbDAEMON},0);
	  }
	  unless ($count) {			# database is empty
	    $html .= q|<input type=hidden name=recno value="">
</form>
|;
	    last PageGen;
	  }
# check if found
	  last if $count == 1;
	  last if $naddr eq $IPs[0];
	  if ($naddr eq $IPs[1]) {
	    $recno -= 1
		if $recno > 1;
	    last;
	  }
# not found, bracketed?
	  last if $naddr gt $IPs[0] && $naddr lt $IPs[1];		 
# try again
	  if ($naddr lt $IPs[0]) {		# move toward rmin
	    $rmax = $recno -1;
	  } else {				# move toard rmax
	    $rmin = $recno +1;
	  }
	  last unless $rmax > $rmin && $rmin > 0 && $rmax <= $rectop;
	}
      }
      elsif ($recno =~ /\D/) {			# contains invalid character
	$recno = 1;
      }

# bound record number
      $recno = $rectop - 254
	if $recno > $rectop - 254;
      $recno = 1
	if $recno < 1;

      if(ref $CONFIG->{bdbDAEMON}) {	# remote?
	$count = retrieve(255,$recno,$db,\@IPs,@{$CONFIG->{bdbDAEMON}});
      } else {
	$count = retrieve(255,$recno,$db,\@IPs,$CONFIG->{bdbDAEMON},0);
      }

      unless ($count) {		# if database empty
	$html .= q|<input type=hidden name=recno value="">
</form>
|;
	last PageGen;
      }

      $html .= q|<table border=0><tr valign=middle><td>&nbsp;</td>
<td class=bld align=center colspan=4>database: |. $db .q|</td>
<td align=center><font size=-1>rec# or dd<b>.[</b>dd<b>.</b>dd<b>.</b>dd]</font></td></tr>
<tr>
<td><table cellspacing=0 cellpadding=2 border=1><tr><td align=center class=gry><a href="#top"
      onClick="return(dbvs('|. $db .q|','1'));"
      onMouseOver="return(show('BEGIN'));" onMouseOut="return(off());">BEGIN</a></td></tr></table></td>
<td><table cellspacing=0 cellpadding=2 border=1><tr><td align=center class=gry>&lt;&lt;<a href="#top"
      onClick="return(dbvs('|. $db .q|','|. ($recno - 255) .q|'));"
      onMouseOver="return(show('PREVIOUS'));" onMouseOut="return(off());">PREVIOUS</a></td></tr></table></td>
<td><table cellspacing=0 cellpadding=2 border=1><tr><td align=center class=gry><a href="#top"
      onClick="return(dbvs('|. $db .q|','|. ($recno + 255) .q|'));"
      onMouseOver="return(show('NEXT'));" onMouseOut="return(off());">NEXT</a>&gt;&gt;</td></tr></table></td>
<td><table cellspacing=0 cellpadding=2 border=1><tr><td align=center class=gry><a href="#top"
      onClick="return(dbvs('|. $db .q|','|. ($rectop - 254) .q|'));"
      onMouseOver="return(show('END'));" onMouseOut="return(off());">END</a></td></tr></table></td>
<td><table cellspacing=0 cellpadding=2 border=1><tr><td nowrap align=center class=gry>&nbsp;&nbsp;<a href="#top"
      onClick="return(dbvs('|. $db .q|',document.dbsel.recno.value));"
      onMouseOver="return(show('GOTO'));" onMouseOut="return(off());">GOTO</a> &gt;</td></tr></table></td>
<td><input type=text name=recno></td>
</tr></table>
</form>
&nbsp;<font size="-1">record number |. $recno;

      if ($ip) {
	$html .= '&nbsp;&nbsp;&nbsp;IP '. $ip;
      }
      $html .= q|</font>
<form name=ViewDB action="" method=POST target=alookup>
<input type=hidden name=page value=lookup>
<input type=hidden name=lookup value="">
<table cellspacing=0 cellpadding=3 border=1>
|;

      for(my $i=0;$i <= $#IPs;$i += 5) {
	$html .= '<tr>';
	foreach(0..4) {
	  my $cell = '&nbsp;';
	  if ($IPs[$i+$_]) {
	    my $ip = inet_ntoa($IPs[$i+$_]);
	    $cell = ($ip =~ /^127\./) ? $ip :		# no link for internal addresses
	  	q|<a href="#top" onClick="return(lIP('|. $ip .q|'));" onMouseOver="return(show('|. $ip .q|'));" onMouseOut="return(off());">|. $ip .q|</a>|;
	  }
	  $html .= q|  <td>|. $cell . qq|</td>\n|;
	}
	$html .= qq|</tr>\n|;
      }
      $html .= q|</table>
</form>
|;
    }
    last PageGen;
  }

######  END page search
  $html .= q|<font size=6><b>Not Found</b></font>
<p>
The URL requested was not found on this server
|;
  last PageGen;	# oops!
}

# Special handling items
#	updpass
#	spamlst
#
$html .= q|
<script language=javascript1.1>
document.UpdPass.newuser.value = '|. $user .q|';
</script>
| if $query{page} =~ /^updpass/;

$query{spam} =~ s/\r//g;
$query{spam} =~ s/\n/\\n/g;
$html .= q|
<script language=javascript1.1>
document.SpamAdd.host.value = '|. $query{host} .q|';
document.SpamAdd.spam.value = "|. $query{spam} .q|";
</script>
| if $query{page} =~ /^spamlst/ &&
	validIP($query{host});

# if this is an admin session, insert page timer

$html .= q|<script language=javascript1.1>
function warnAdmin() {
  var timeout = new Date();
  alert("Your session will expire in 60 seconds.\n\nClick OK to continue\n");
  var delay = new Date();
  if (timeout.getTime() + 60000 > delay.getTime()) {
    location.reload(1);
  } else {
    location = location.pathname + '?page=logout';
  }
}

setTimeout("warnAdmin()",| . $admses .q|);
</script>
| if $admses && $query{page} !~ /login|passwd|2realAH/;

$html .= q|</body>
</html>
|;

if ($OverRide) {
  $OverRide = 0;
   print $html;
} else {
  sendhtml(\$html,\%extraheaders);
}

1;
