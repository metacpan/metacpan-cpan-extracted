#!/usr/bin/perl
#
# whois.plx
#
my $version = '1.05';	# 9-5-04, michael@bizsystems.com
# GPL'd, see Copyright notice in the package README file
#
use strict;
#use diagnostics;
use Net::DNS::ToolKit::Utilities qw(
	rlook_send
	rlook_rcv 
);

my $ptr_timeout = 15;	# PTR record lookup timeout in seconds

# fix up the whois routine to get the stuff we want
BEGIN {
  use vars qw($old_d_q $lastresp);
  use Net::Whois::IP qw(whoisip_query);
  $old_d_q = \&Net::Whois::IP::_do_query;
}

sub Net::Whois::IP::_do_query {
  my @rv = &$old_d_q(@_);
  $lastresp = $rv[0];
  return @rv;
}

#########################################################

$ENV{SCRIPT_NAME} =~ /whois\.([a-zA-Z_-]+)/;
my $action = 'whois.'. $1;
my $IP = ($ENV{QUERY_STRING} =~ /query=(\d+\.\d+\.\d+\.\d+)/)
	? $1 : '';

my $html = q|<html>
<head><title>Whois for IP addresses</title>
</head>
<body bgcolor="#ffffcc">
<center>
<table border=0>
<tr><td align=center><font size=4><b>Whois for IP address</b></font></td></tr>
<tr><td><font size="-1"> 
<a href="#top" onMouseover="status='Close Window';return true"
onMouseout="status='';return true;"
onClick="self.close();return false;">&gt;&gt;Close Window&lt;&lt;</a>
</font></td></tr>
<tr><td align=center>|. $IP;

my $body = q|
<form action="|. $action .q|" method=GET>
<input type=text name=query><p>
<input type=submit value="Whois >>"></td></tr>
<tr><td>|;

if ($IP) {
  if ($ENV{HTTP_REFERER} !~ /$ENV{SERVER_NAME}/i) {
    $body .= qq|
Due to the excessive load placed on our system, we have disabled the ability
for third party sites to query the Whois Proxy through the web
interface. Please enter your request manually.
<!-- referrer #$ENV{HTTP_REFERER}# refused by #$ENV{SERVER_NAME}# -->
|;
  }
  else {
    my $socket = rlook_send($IP,$ptr_timeout);
    $lastresp = '';

    eval {whoisip_query($IP)};

    my $hostname = rlook_rcv($socket,$ptr_timeout);
    if ($hostname) {
      $html .= "&nbsp;--&nbsp;$hostname";
    }
    
    if ($lastresp && ! $@) {
      $body .= q|<pre>|. join('',@$lastresp) . q|
</pre>
|;
    } else {
     $body .= q|<pre>
could not connect to whois server, try again later
</pre>
|;
    }
  }
}
$html .= $body . q|
</td></tr>
<tr><td><font size="-1">
<a href="#top" onMouseover="status='Close Window';return true" onMouseout="status='';return true;"
onClick="self.close();return false;">&gt;&gt;Close Window&lt;&lt;</a>
</font></td></tr>
</table>
</body>
</html>
|;

my $size = length($html);

my $r;
eval { require Apache;
	 $r = Apache->request;
};

unless ($@) {		# unless error, it's Apache
  $r->status(200);
  $r->content_type('text/html');
  $r->header_out("Content-length","$size");
  $r->send_http_header;
  $r->print($html);
  return 200;			# HTTP_OK

} else {	# sigh... no mod_perl

  print q
|Content-type: text/html
Content-length: |, $size, q|
Connection: close

|,$html;
}
1;
