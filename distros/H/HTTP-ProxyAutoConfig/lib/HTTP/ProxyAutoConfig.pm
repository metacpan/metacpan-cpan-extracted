package HTTP::ProxyAutoConfig;

=head1 NAME

HTTP::ProxyAutoConfig - use a .pac or wpad.dat file to get proxy information

=head1 SYNOPSIS

  use HTTP::ProxyAutoConfig;

  my $pac = HTTP::ProxyAutoConfig->new("http://foo.bar/auto-proxy.pac");
  my $pac = new HTTP::ProxyAutoConfig('/Documents and Settings/me/proxy.pac');
  my $pac = HTTP::ProxyAutoConfig->new();

  my $proxy = $pac->FindProxy('http://www.yahoo.com');

=head1 DESCRIPTION

I<HTTP::ProxyAutoConfig> allows perl scripts that need to access the
Internet to determine whether to do so via a proxy server.  To do this,
it uses proxy settings provided by an IT department, either on the Web
or in a browser's I<.pac> file on disk.

It provides means to find the proxy server (or lack of one) for
a given URL.  If your application has located either a I<wpad.dat>
file or a I<.pac> file, I<HTTP::ProxyAutoConfig> processes it
to determine how to handle a particular destination URL.
If it's not given a I<wpad.dat> or I<.pac> file, I<HTTP::ProxyAutoConfig>
tests environment variables to determine whether there's a proxy server.

A I<wpad.dat> or I<.pac> file contains a JavaScript function called
I<FindProxyForURL>.  This module allows you to call the function to
learn how to access various URLs.

Mapping from a URL to the proxy information is provided by a
I<FindProxyForURL(url, host)> or I<FindProxy(url)> function call.
Both functions return a string that tells your application what to do,
namely a direct connection to the Internet or a connection via a proxy
server.

The Proxy Auto Config format and rules were originally developed at
Netscape.  The Netscape documentation is archived at
L<http://linuxmafia.com/faq/Web/autoproxy.html>

More recent references include:

=over 4

=item L<http://en.wikipedia.org/wiki/Proxy_auto-config>

=item L<http://en.wikipedia.org/wiki/Web_Proxy_Autodiscovery_Protocol>

=item L<http://www.craigjconsulting.com/proxypac.html>

=item L<http://www.returnproxy.com/proxypac/>

=back

=head1 METHODS

=head2 new( url_or_file )

This call creates the I<FindProxyForURL> function and the object through
which it can be called. The I<url_or_file> argument is optional, and
points to the auto-proxy file provided on your network or a file used
by your browser.  If there is no argument, I<HTTP::ProxyAutoConfig>
will check the I<http_auto_proxy> environment variable, followed by the
I<http_proxy>, I<https_proxy>, and I<ftp_proxy> variables.

As shown above, you can use either the I<HTTP::ProxyAutoConfig-E<gt>new()>
or the I<new HTTP::ProxyAutoConfig()> form, but don't use the
I<HTTP::ProxyAutoConfig::new()> form.

=head2 FindProxyForURL( url, host )

This takes the url, and the host (minus port) from the URL, and
determines the action you should take to contact that host.
It returns one of three strings:

  DIRECT           - connect directly
  PROXY host:port  - connect via the proxy
  SOCKS host:port  - connect via SOCKS

This result can be used to configure a net-access module like LWP.

=head2 FindProxy( url )

Same as the previous call, except you don't have to extract the host
from the URL.

=head1 AUTHORS

  By Ryan Eatmon in May of 2001
  0.2 by Craig MacKenna, March 2010

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2001, Ryan Eatmon
  Copyright (C) 2010, Craig MacKenna

This module is free software; you may redistribute it and/or
modify it under the same terms as Perl 5.10.1.  For more details,
see the full text of the licenses at
L<http://www.perlfoundation.org/artistic_license_1_0> and
L<http://www.gnu.org/licenses/gpl-2.0.html>

This program is distributed in the hope that it will be useful, but
it is provided 'as is' and without any express or implied warranties.
For details, see the full text of the licenses at the above URLs.

=cut

use strict;
use warnings;
use Carp;
use Sys::Hostname;
use IO::Socket;

our $VERSION = "0.3";

sub new {
  my $proto = shift;
  my $self = { };

  bless($self,$proto);

  $self->{URL} = shift if ($#_ > -1);
  $self->Reload();
  return $self;
}


##############################################################################
#
# FindProxy - wrapper for FindProxyForURL function so that you don't have to
#             figure out the host.
#
##############################################################################
sub FindProxy {
  my $self = shift;
  my ($url) = @_;
  my $host;
  (undef, $host) = ($url =~ m'^([a-z]+://)?([^/]+)');

  foreach my $proxy (split(/\s*\;\s*/, $self->FindProxyForURL($url, $host))) {

    return $proxy if ($proxy eq "DIRECT");

    my ($host, $port) = ($proxy =~ /^PROXY\s*(\S+):(\d+)$/);

    return $proxy if (new IO::Socket::INET(PeerAddr=>$host,
                                           PeerPort=>$port,
                                           Proto=>"tcp"));
  }
  return undef;
}


##############################################################################
#
# Reload - grok the environment variables and define the FindProxyForURL
#          function.
#
##############################################################################
sub Reload  {
  my $self = shift;

  my $url = (exists($self->{URL}) ? $self->{URL} : $ENV{"http_auto_proxy"});

  if (defined($url) && ($url ne "")) {

    ########## accept file path as well as URL
    ########## added to version 0.2 cmac march 2010
    my $function = ""; # used to be further down
    my ($rsize, $f);
    if ($url !~ m'^[a-z]+://'
     && -e $url) {

      # looks like $url is a path to a file
      open($f, "<$url") or die "Can't open $url for read: $!";
      my $size = -s $url or die "$url seems to be empty";
      ($rsize = read($f, $function, $size)) && $rsize == $size
        or die "$url contains $size bytes, but 'read' read $rsize bytes";
      close($f) or die "Can't close $url: $!";
    } else {
    ########## end addition

      my ($host, $port, $path) = ($url =~ /^http:\/\/([^\/:]+):?(\d*)\/?(.*)$/);

      $port = 80 if ($port eq "");

      my $sock = new IO::Socket::INET(PeerAddr=>$host,
                                      PeerPort=>$port,
                                      Proto=>"tcp");

      die("Cannot create normal socket: $!") unless defined($sock);

      my $send = "GET /$path HTTP/1.1\r\nCache-Control: no-cache\r\nHost: $host:$port\r\n\r\n";

      $sock->syswrite($send, length($send), 0);
      # modified 25 Mar 2010: it took minutes for a timeout on a 0-length buffer
      # what's a reasonable max for HTTP headers plus a GetProxyFromURL function?
      $sock->sysread($function, 1<<20);

      my $chunked = ($function =~ /chunked/);

      $function =~ s/^.+?\r?\n\r?\n//s;
      if ($chunked == 1) {
        $function =~ s/\n\r\n\S+\s*\r\n/\n/g;
        $function =~ s/^\S+\s*\r\n//;
      }
    } # end of get $function from internet
    $function = $self->JavaScript2Perl($function);
    {
      no warnings 'redefine';
      eval($function);
    }
    ########## added to version 0.2 cmac march 2010
    if ($@) {die "Bad JavaScript->perl translation.\n"
               . "Please notify the co-maintainer of HTTP::ProxyAutoConfig:\n$@"}
  } else {
    my $http_host;
    my $http_port;
    my $function = "sub FindProxyForURL { my (\$self,\$url,\$host) = \@_; ";
    $function .= "if (isResolvable(\$host)) { return \"DIRECT\"; }  ";
    if (exists($ENV{http_proxy})) {
      ($http_host,$http_port) = ($ENV{"http_proxy"} =~ /^(\S+)\:(\d+)$/);
      $http_host =~ s/^http\:\/\///;
      $function .= "if (shExpMatch(\$url,\"http://*\")) { return \"PROXY $http_host\:$http_port\"; }  ";
    }
    if (exists($ENV{https_proxy})) {
      my($host,$port) = ($ENV{"https_proxy"} =~ /^(\S+)\:(\d+)$/);
      $host =~ s/^https?\:\/\///;
      $function .= "if (shExpMatch(\$url,\"https://*\")) { return \"PROXY $host\:$port\"; }  ";
    }
    if (exists($ENV{ftp_proxy})) {
      my($host,$port) = ($ENV{"ftp_proxy"} =~ /^(\S+)\:(\d+)$/);
      $host =~ s/^ftp\:\/\///;
      $function .= "if (shExpMatch(\$url,\"ftp://*\")) { return \"PROXY $host\:$port\"; }  ";
    }
    if (defined($http_host) && defined($http_port)) {
      $function .= "  return \"PROXY $http_host\:$http_port\"; }";
    } else {
      $function .= "  return \"DIRECT\"; }";
    }
    {
      no warnings 'redefine';
      eval($function);
    }
    if ($@) {die $@}
  }
}

##############################################################################
#
# JavaScript2Perl - function to convert JavaScript code into Perl code.
#
##############################################################################
sub JavaScript2Perl {
  my $self = shift;
  my ($function) = @_;

  my $quoted = 0;
  my $blockComment = 0;
  my $lineComment = 0;
  my $newFunction = "";

  my %vars;
  my $variable;

  # remove comments, substitute . for +, index variable names
  foreach my $piece (split(/(\s)/,$function)) {
    foreach my $subpiece (split(/([\"\'\=])/,$piece)) {
      next if ($subpiece eq "");
      if ($subpiece eq "=" && $variable =~ /^\w/) {
        $vars{$variable} = 1;
      }
      $variable = $subpiece unless ($subpiece eq " ");

      $subpiece = "." if (($quoted == 0) && ($subpiece eq "+"));

      $lineComment = 0 if ($subpiece eq "\n");
      $quoted ^= 1 if (($blockComment == 0) &&
               ($lineComment == 0) &&
               ($subpiece =~ /(\"|\')/));
      if (($quoted == 0) && ($subpiece =~ /\/\*/)) {
    $blockComment = 1;
      } elsif (($quoted == 0) && ($subpiece =~ /\/\//)) {
    $lineComment = 1;
      } elsif (($blockComment == 1) && ($subpiece =~ /\*\//)) {
    $blockComment = 0;
      } else {
    $newFunction .= $subpiece
      unless (($blockComment == 1) || ($lineComment == 1));
      }
    }
  }

  $newFunction =~ s/^\s*function\s*(\S+)\s*\(\s*([^\,]+)\s*\,\s*([^\)]+)\s*\)\s*\{/sub $1 \{\n  my \(\$self, $2 ,$3\) = \@_\;\n  my(\$stub);\n/;
  $vars{$2} = 2;
  $vars{$3} = 2;

  $quoted = 0;
  my $finalFunction = "";

  foreach my $piece (split(/(\s)/,$newFunction)) {
    if ($piece eq "my(\$stub);") {
      $piece = "my(\$stub";
      foreach my $var (keys(%vars)) {
    next if ($vars{$var} == 2);
    $piece .= ",\$".$var;
      }
      $piece .= ");";
    }
    foreach my $subpiece (split(/([\"\'\=\,\+\x29\x28])/,$piece)) {
      next if ($subpiece eq "");
      $quoted ^= 1 if (($blockComment == 0) &&
               ($lineComment == 0) &&
               ($subpiece =~ /(\"|\')/));
      $subpiece = "\$".$subpiece
      if (($quoted == 0) && exists($vars{$subpiece}));
      $finalFunction .= $subpiece;
    }
  }
  ######### added to ProxyAutoConfig 0.2 by cmac, March 2010
  # the preceding code has taken comments out, which makes life simpler

  # since most comparisons will be strings, change JS relational operators
  #  to perl's string operators
  my %opers = ('===' => 'eq', '==' => 'eq', '!=' => 'ne', '>=' => 'ge', 
                '<=' => 'le',  '>' => 'gt',  '<' => 'lt');

  my $search = '(\'|")|(' . join('|', sort {length($b) <=> length($a)} keys(%opers)) . ')';
  while ($finalFunction =~ /$search/mg) {
    if ($1) {
      $finalFunction =~ /(\A|[^\\])$1/mg or last;
    } else {
      my $pos = pos($finalFunction) - length($2);
      substr ($finalFunction, $pos, length($2), " $opers{$2} ");
      pos($finalFunction) = $pos + 4;
    }
    my $zzz=0;
  }
  # collapse 'else if' into 'elsif'
  $finalFunction =~ s/\belse\s+if\b/elsif/mg;

  # javascript allows if/for/while/else/do without {} around a subsequent
  #   single statement, but perl doesn't so put {} around such statements

  while ($finalFunction =~ /('|"|\b(if|for|while|elsif|(else|do))\b)\s*/mg) {
    my $posLP = pos($finalFunction);
    if ($1 eq "'" || $1 eq '"') {
      $finalFunction =~ /(\A|[^\\])$1/mg or last;
    } elsif ($3
          || slide_lp_thru_rp($finalFunction)) {
      my $posRP = pos($finalFunction);
      if ($finalFunction =~ s/\G([^\x7B])/\x7B$1/) {
        place_ending_rb($finalFunction, $posRP+1);
      }
      pos($finalFunction) = $posLP;
  } }
  return $finalFunction;
}
# slide through (expression) after if/for/while/elsif
sub slide_lp_thru_rp {
  my $parenCt = 0;
  while ($_[0] =~ /(\x28|\x29|'|")/mg) {
    if ($1 eq '(') {
      $parenCt++;
    } elsif ($1 eq ')' && --$parenCt <= 0) {
      $_[0] =~ /\s+/mg; # slide to what's after the )
      return 1;
    } elsif ($1 eq '"' || $1 eq "'")  {
      $_[0] =~ /(\A|[^\\])$1/mg or last;
} } }
# add } at end of single statement after if/for/while/else/do
sub place_ending_rb {
  pos($_[0]) = $_[1];
  # scan to ; or end of line
  while ($_[0] =~ /(;|$|'|")/mg) {
    if ($1 eq ';') {pos($_[0])--}
    if (!$1 || $1 eq ';') {
      # put in the }
      $_[0] =~ s/\G;?/\x7D/;
      return;
    } elsif ($1 eq '"' || $1 eq "'")  {
      $_[0] =~ /(\A|[^\\])$1/mg or last;
} } }

sub validIP {
  return $_[0] =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/
      && $1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255;
}

##############################################################################
#
# isPlainHostName - PAC command that tells if this is a plain host name
#                   (no dots)
#
##############################################################################
sub isPlainHostName {
  my ($host) = @_;

  return $host !~ /\./;
}

##############################################################################
#
# dnsDomainIs - PAC command to tell if the host is in the domain.
#
##############################################################################
sub dnsDomainIs {
  my ($host, $domain) = @_;

  my $lh = length($host);
  my $ld = length($domain);
  return $lh >= $ld
      && substr($host, $lh - $ld) eq $domain;
}

##############################################################################
#
# localHostOrDomainIs - PAC command to tell if the host matches, or if it is
#                       unqualified and in the domain.
#
##############################################################################
sub localHostOrDomainIs {
  my ($host, $hostdom) = @_;

  return $host eq $hostdom
      || rindex($hostdom, "$host.") == 0;
}

##############################################################################
#
# isResolvable - PAC command to see if the host can be resolved via DNS.
#
##############################################################################
sub isResolvable {
  return defined(gethostbyname($_[0]));
}

##############################################################################
#
# isInNet - PAC command to see if the IP address is in this network based on
#           the mask and pattern.
#
##############################################################################
sub isInNet {
  my ($ipaddr, $pattern, $maskstr) = @_;

  if (!validIP($ipaddr)) {
    $ipaddr = dnsResolve($ipaddr);
    if (!$ipaddr) {return ''}
  }
  if (!validIP($pattern) || !validIP($maskstr)) {return ''}

  my $host = inet_aton($ipaddr);
  my $pat  = inet_aton($pattern);
  my $mask = inet_aton($maskstr);
  return ($host & $mask) eq ($pat & $mask);
}

##############################################################################
#
# dnsResolve - PAC command to get the IP from the host name.
#
##############################################################################
sub dnsResolve {
  my $ipad = inet_aton($_[0]);
  if ($ipad) {return inet_ntoa($ipad)}
  return;
}

##############################################################################
#
# myIpAddress - PAC command to get your IP.
#
##############################################################################
my $myIpAddress;
BEGIN {
  my $hostname = hostname();
  my $ipad = inet_aton($hostname);
  $myIpAddress = $ipad ? inet_ntoa($ipad) : '127.0.0.1';
}
sub myIpAddress {
  return $myIpAddress;
}

##############################################################################
#
# dnsDomainLevels - PAC command to tell how many domain levels there are in
#                   the host name (number of dots).
#
##############################################################################
sub dnsDomainLevels {
  my @parts = split /\./, $_[0];
  return @parts-1;
}

##############################################################################
#
# shExpMatch - PAC command to see if a URL/path matches the shell expression.
#              Shell expressions are like  */foo/*  or http://*.
#
##############################################################################
sub shExpMatch {
  my ($str, $shellExp) = @_;

  # this escapes the perl regexp characters that need it except ? and *
  # it also escapes /
  $shellExp =~ s#([\\|\x28\x29\x5B\x7B^\$+./])#\\$1#g;

  # there are two wildcards in "shell expressions": * and ?
  $shellExp =~ s/\?/./g;
  $shellExp =~ s/\*/.*?/g;

  return $str =~ /^$shellExp$/;
}

##############################################################################
#
# weekDayRange - PAC command to see if the current weekday falls within a
#                range.
#
##############################################################################
sub weekDayRange {
  my $wd1 = shift;
  my $wd2 = "";
  $wd2 = shift if ($_[0] ne "GMT");
  my $gmt = "";
  $gmt = shift if ($_[0] eq "GMT");

  my %wd = ( SUN=>0, MON=>1, TUE=>2, WED=>3, THU=>4, FRI=>5, SAT=>6);
  my $dow = (($gmt eq "GMT") ? (gmtime)[6] : (localtime)[6]);

  if ($wd2 eq "") {
    return $dow eq $wd{$wd1};
  } else {
    my @range;
    if ($wd{$wd1} < $wd{$wd2}) {
      @range = ($wd{$wd1}..$wd{$wd2});
    } else {
      @range = ($wd{$wd1}..6,0..$wd{$wd2});
    }
    foreach my $tdow (@range) {
      return $dow eq $tdow;
  } }
  return '';
}

##############################################################################
#
# dateRange - PAC command to see if the current date falls within a range.
#
##############################################################################
sub dateRange {
  my %mon = ( JAN=>0,FEB=>1,MAR=>2,APR=>3,MAY=>4,JUN=>5,JUL=>6,AUG=>7,SEP=>8,OCT=>9,NOV=>10,DEC=>11);

  my %args;
  my $dayCount = 1;
  my $monCount = 1;
  my $yearCount = 1;

  while ($#_ > -1) {
    if ($_[0] eq "GMT") {
      $args{gmt} = shift;
    } elsif (exists($mon{$_[0]})) {
      my $month = shift;
      $args{"mon$monCount"} = $mon{$month};
      $monCount++;
    } elsif ($_[0] > 31) {
      $args{"year$yearCount"} = shift;
      $yearCount++;
    } else {
      $args{"day$dayCount"} = shift;
      $dayCount++;
    }
  }

  my $mday = (exists($args{gmt}) ? (gmtime)[3] : (localtime)[3]);
  my $mon = (exists($args{gmt}) ? (gmtime)[4] : (localtime)[4]);
  my $year = 1900+(exists($args{gmt}) ? (gmtime)[5] : (localtime)[5]);

  if (exists($args{day1}) && exists($args{mon1}) && exists($args{year1}) &&
      exists($args{day2}) && exists($args{mon2}) && exists($args{year2})) {

    if (($args{year1} < $year) && ($args{year2} > $year)) {
      return 1;
    } elsif (($args{year1} == $year) && ($args{mon1} <= $mon)) {
      return 1;
    } elsif (($args{year2} == $year) && ($args{mon2} >= $mon)) {
      return 1;
    }
    return 0;

  } elsif (exists($args{mon1}) && exists($args{year1}) &&
       exists($args{mon2}) && exists($args{year2})) {
    if (($args{year1} < $year) && ($args{year2} > $year)) {
      return 1;
    } elsif (($args{year1} == $year) && ($args{mon1} < $mon)) {
      return 1;
    } elsif (($args{year2} == $year) && ($args{mon2} > $mon)) {
      return 1;
    } elsif (($args{year1} == $year) && ($args{mon1} == $mon) &&
         ($args{day1} <= $mday)) {
      return 1;
    } elsif (($args{year2} == $year) && ($args{mon2} == $mon) &&
         ($args{day2} >= $mday)) {
      return 1;
    }
    return 0;
  } elsif (exists($args{day1}) && exists($args{mon1}) &&
       exists($args{day2}) && exists($args{mon2})) {
    if (($args{mon1} < $mon) && ($args{mon2} > $mon)) {
      return 1;
    } elsif (($args{mon1} == $mon) && ($args{day1} <= $mday)) {
      return 1;
    } elsif (($args{mon2} == $mon) && ($args{day2} >= $mday)) {
      return 1;
    }
    return 0;
  } elsif (exists($args{year1}) && exists($args{year2})) {
    foreach my $tyear ($args{year1}..$args{year2}) {
      return 1 if ($tyear == $year);
    }
    return 0;
  } elsif (exists($args{mon1}) && exists($args{mon2})) {
    foreach my $tmon ($args{mon1}..$args{mon2}) {
      return 1 if ($tmon == $mon);
    }
    return 0;
  } elsif (exists($args{day1}) && exists($args{day2})) {
    foreach my $tmday ($args{day1}..$args{day2}) {
      return 1 if ($tmday == $mday);
    }
    return 0;
  } elsif (exists($args{year1})) {
    return (($args{year1} == $year) ? 1 : 0);
  } elsif (exists($args{mon1})) {
    return (($args{mon1} == $mon) ? 1 : 0);
  } elsif (exists($args{day1})) {
    return (($args{day1} == $mday) ? 1 : 0);
  }
  return 0;
}

##############################################################################
#
# timeRange - PAC command to see if the current time falls within a range.
#
##############################################################################
sub timeRange {
  my %args;
  my $dayCount = 1;
  my $monCount = 1;
  my $yearCount = 1;

  $args{gmt} = pop(@_) if ($_[$#_] eq "GMT");

  if ($#_ == 0) {
    $args{hour1} = shift;
  } elsif ($#_ == 1) {
    $args{hour1} = shift;
    $args{hour2} = shift;
  } elsif ($#_ == 3) {
    $args{hour1} = shift;
    $args{min1} = shift;
    $args{hour2} = shift;
    $args{min2} = shift;
  } elsif ($#_ == 5) {
    $args{hour1} = shift;
    $args{min1} = shift;
    $args{sec1} = shift;
    $args{hour2} = shift;
    $args{min2} = shift;
    $args{sec2} = shift;
  }

  my $sec = (exists($args{gmt}) ? (gmtime)[0] : (localtime)[0]);
  my $min = (exists($args{gmt}) ? (gmtime)[1] : (localtime)[1]);
  my $hour = (exists($args{gmt}) ? (gmtime)[2] : (localtime)[2]);

  if (exists($args{sec1}) && exists($args{min1}) && exists($args{hour1}) &&
      exists($args{sec2}) && exists($args{min2}) && exists($args{hour2})) {

    if (($args{hour1} < $hour) && ($args{hour2} > $hour)) {
      return 1;
    } elsif (($args{hour1} == $hour) && ($args{min1} <= $min)) {
      return 1;
    } elsif (($args{hour2} == $hour) && ($args{min2} >= $min)) {
      return 1;
    }
    return 0;

  } elsif (exists($args{min1}) && exists($args{hour1}) &&
       exists($args{min2}) && exists($args{hour2})) {
    if (($args{hour1} < $hour) && ($args{hour2} > $hour)) {
      return 1;
    } elsif (($args{hour1} == $hour) && ($args{min1} < $min)) {
      return 1;
    } elsif (($args{hour2} == $hour) && ($args{min2} > $min)) {
      return 1;
    } elsif (($args{hour1} == $hour) && ($args{min1} == $min) &&
         ($args{sec1} <= $sec)) {
      return 1;
    } elsif (($args{hour2} == $hour) && ($args{min2} == $min) &&
         ($args{sec2} >= $sec)) {
      return 1;
    }
    return 0;
  } elsif (exists($args{sec1}) && exists($args{min1}) &&
       exists($args{sec2}) && exists($args{min2})) {
    if (($args{min1} < $min) && ($args{min2} > $min)) {
      return 1;
    } elsif (($args{min1} == $min) && ($args{sec1} <= $sec)) {
      return 1;
    } elsif (($args{min2} == $min) && ($args{sec2} >= $sec)) {
      return 1;
    }
    return 0;
  } elsif (exists($args{hour1}) && exists($args{hour2})) {
    foreach my $thour ($args{hour1}..$args{hour2}) {
      return 1 if ($thour == $hour);
    }
    return 0;
  } elsif (exists($args{min1}) && exists($args{min2})) {
    foreach my $tmin ($args{min1}..$args{min2}) {
      return 1 if ($tmin == $min);
    }
    return 0;
  } elsif (exists($args{sec1}) && exists($args{sec2})) {
    foreach my $tsec ($args{sec1}..$args{sec2}) {
      return 1 if ($tsec == $sec);
    }
    return 0;
  } elsif (exists($args{hour1})) {
    return (($args{hour1} == $hour) ? 1 : 0);
  } elsif (exists($args{min1})) {
    return (($args{min1} == $min) ? 1 : 0);
  } elsif (exists($args{sec1})) {
    return (($args{sec1} == $sec) ? 1 : 0);
  }
  return 0;
}
1;
