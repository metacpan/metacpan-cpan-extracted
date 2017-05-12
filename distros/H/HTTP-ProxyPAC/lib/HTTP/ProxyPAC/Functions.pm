package HTTP::ProxyPAC::Functions;
use strict;
use IO::Socket; # inet_aton, inet_ntoa
use Sys::Hostname;

our @PACFunctions = qw(
    isPlainHostName
    dnsDomainIs
    localHostOrDomainIs
    isResolvable
    isInNet
    dnsResolve
    myIpAddress
    dnsDomainLevels
    shExpMatch
    weekDayRange
    dateRange
    timeRange
);

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

# new (vice changed) stuff
our @baseFunctions = qw(
    dnsResolve
    myIpAddress
);

sub validIP {
  return $_[0] =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/
               && $1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255;
}

#/* The following comments headed the file nsProxyAutoConfig.js used 
#   by various NetScape and Mozilla browsers.  Since HTTP::ProxyPAC
#   is also licensed under the GPL, this use is OK.  */
#
#/* ***** BEGIN LICENSE BLOCK *****
# * Version: MPL 1.1/GPL 2.0/LGPL 2.1
# *
# * The contents of this file are subject to the Mozilla Public License Version
# * 1.1 (the "License"); you may not use this file except in compliance with
# * the License. You may obtain a copy of the License at
# * http://www.mozilla.org/MPL/
# *
# * Software distributed under the License is distributed on an "AS IS" basis,
# * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# * for the specific language governing rights and limitations under the
# * License.
# *
# * The Original Code is mozilla.org code.
# *
# * The Initial Developer of the Original Code is
# * Netscape Communications Corporation.
# * Portions created by the Initial Developer are Copyright (C) 1998
# * the Initial Developer. All Rights Reserved.
# *
# * Contributor(s):
# *   Akhil Arora <akhil.arora\@sun.com>
# *   Tomi Leppikangas <Tomi.Leppikangas\@oulu.fi>
# *   Darin Fisher <darin\@meer.net>
# *
# * Alternatively, the contents of this file may be used under the terms of
# * either the GNU General Public License Version 2 or later (the "GPL"), or
# * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
# * in which case the provisions of the GPL or the LGPL are applicable instead
# * of those above. If you wish to allow use of your version of this file only
# * under the terms of either the GPL or the LGPL, and not to allow others to
# * use your version of this file under the terms of the MPL, indicate your
# * decision by deleting the provisions above and replace them with the notice
# * and other provisions required by the GPL or the LGPL. If you do not delete
# * the provisions above, a recipient may use your version of this file under
# * the terms of any one of the MPL, the GPL or the LGPL.
# *
# * ***** END LICENSE BLOCK ***** */

sub nsProxyAutoConfig {
    <<ZZZZ;
/*
   Script for Proxy Auto Config in the new world order.
       - Gagan Saksena 04/24/00 
*/

/*** code for installing the following code into a browser 
     removed 2010 by cmac for HTTP::ProxyPAC version 0.2 ***/

function dnsDomainIs(host, domain) {
    return (host.length >= domain.length &&
            host.substring(host.length - domain.length) == domain);
}
function dnsDomainLevels(host) {
    return host.split('.').length-1;
}
function convert_addr(ipchars) {
    var bytes = ipchars.split('.');
    var result = ((bytes[0] & 0xff) << 24) |
                 ((bytes[1] & 0xff) << 16) |
                 ((bytes[2] & 0xff) <<  8) |
                  (bytes[3] & 0xff);
    return result;
}
function isInNet(ipaddr, pattern, maskstr) {
    var test = /^(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\$/.exec(ipaddr);
    if (test == null) {
        ipaddr = dnsResolve(ipaddr);
        if (ipaddr == null)
            return false;
    } else if (test[1] > 255 || test[2] > 255 ||
               test[3] > 255 || test[4] > 255) {
        return false;    // not an IP address
    }
    var host = convert_addr(ipaddr);
    var pat  = convert_addr(pattern);
    var mask = convert_addr(maskstr);
    return ((host & mask) == (pat & mask));

}
function isPlainHostName(host) {
    return (host.search('\\\\.') == -1);
}
function isResolvable(host) {
    var ip = dnsResolve(host);
    return (ip != null);
}
function localHostOrDomainIs(host, hostdom) {
    return (host == hostdom) ||
           (hostdom.lastIndexOf(host + '.', 0) == 0);
}
function shExpMatch(url, pattern) {
   pattern = pattern.replace(/\\./g, '\\\\.');
   pattern = pattern.replace(/\\*/g, '.*');
   pattern = pattern.replace(/\\?/g, '.');
   var newRe = new RegExp('^'+pattern+'\$');
   return newRe.test(url);
}

var wdays = {SUN: 0, MON: 1, TUE: 2, WED: 3, THU: 4, FRI: 5, SAT: 6};
var months = {JAN: 0, FEB: 1, MAR: 2, APR: 3, MAY: 4, JUN: 5,
              JUL: 6, AUG: 7, SEP: 8, OCT: 9, NOV: 10, DEC: 11};

function weekdayRange() {
    function getDay(weekday) {
        if (weekday in wdays) {
            return wdays[weekday];
        }
        return -1;
    }
    var date = new Date();
    var argc = arguments.length;
    var wday;
    if (argc < 1)
        return false;
    if (arguments[argc - 1] == 'GMT') {
        argc--;
        wday = date.getUTCDay();
    } else {
        wday = date.getDay();
    }
    var wd1 = getDay(arguments[0]);
    var wd2 = (argc == 2) ? getDay(arguments[1]) : wd1;
    return (wd1 == -1 || wd2 == -1) ? false
                                    : (wd1 <= wday && wday <= wd2);
}
function dateRange() {
    function getMonth(name) {
        if (name in months) {
            return months[name];
        }
        return -1;
    }
    var date = new Date();
    var argc = arguments.length;
    if (argc < 1) {
        return false;
    }
    var isGMT = (arguments[argc - 1] == 'GMT');

    if (isGMT) {
        argc--;
    }
    // function will work even without explict handling of this case
    if (argc == 1) {
        var tmp = parseInt(arguments[0]);
        if (isNaN(tmp)) {
            return ((isGMT ? date.getUTCMonth()
                           : date.getMonth()) == getMonth(arguments[0]));
        } else if (tmp < 32) {
            return ((isGMT ? date.getUTCDate()
                           : date.getDate()) == tmp);
        } else {
            return ((isGMT ? date.getUTCFullYear()
                           : date.getFullYear()) == tmp);
        }
    }
    var year = date.getFullYear();
    var date1, date2;
    date1 = new Date(year,  0,  1,  0,  0,  0);
    date2 = new Date(year, 11, 31, 23, 59, 59);
    var adjustMonth = false;
    for (var i = 0; i < (argc >> 1); i++) {
        var tmp = parseInt(arguments[i]);
        if (isNaN(tmp)) {
            var mon = getMonth(arguments[i]);
            date1.setMonth(mon);
        } else if (tmp < 32) {
            adjustMonth = (argc <= 2);
            date1.setDate(tmp);
        } else {
            date1.setFullYear(tmp);
        }
    }
    for (var i = (argc >> 1); i < argc; i++) {
        var tmp = parseInt(arguments[i]);
        if (isNaN(tmp)) {
            var mon = getMonth(arguments[i]);
            date2.setMonth(mon);
        } else if (tmp < 32) {
            date2.setDate(tmp);
        } else {
            date2.setFullYear(tmp);
        }
    }
    if (adjustMonth) {
        date1.setMonth(date.getMonth());
        date2.setMonth(date.getMonth());
    }
    if (isGMT) {
    var tmp = date;
        tmp.setFullYear(date.getUTCFullYear());
        tmp.setMonth(date.getUTCMonth());
        tmp.setDate(date.getUTCDate());
        tmp.setHours(date.getUTCHours());
        tmp.setMinutes(date.getUTCMinutes());
        tmp.setSeconds(date.getUTCSeconds());
        date = tmp;
    }
    return ((date1 <= date) && (date <= date2));
}
function timeRange() {
    var argc = arguments.length;
    var date = new Date();
    var isGMT= false;

    if (argc < 1) {
        return false;
    }
    if (arguments[argc - 1] == 'GMT') {
        isGMT = true;
        argc--;
    }

    var hour = isGMT ? date.getUTCHours() : date.getHours();
    var date1, date2;
    date1 = new Date();
    date2 = new Date();

    if (argc == 1) {
        return (hour == arguments[0]);
    } else if (argc == 2) {
        return ((arguments[0] <= hour) && (hour <= arguments[1]));
    } else {
        switch (argc) {
        case 6:
            date1.setSeconds(arguments[2]);
            date2.setSeconds(arguments[5]);
        case 4:
            var middle = argc >> 1;
            date1.setHours(arguments[0]);
            date1.setMinutes(arguments[1]);
            date2.setHours(arguments[middle]);
            date2.setMinutes(arguments[middle + 1]);
            if (middle == 2) {
                date2.setSeconds(59);
            }
            break;
        default:
          throw 'timeRange: bad number of arguments'
        }
    }
    if (isGMT) {
        date.setFullYear(date.getUTCFullYear());
        date.setMonth(date.getUTCMonth());
        date.setDate(date.getUTCDate());
        date.setHours(date.getUTCHours());
        date.setMinutes(date.getUTCMinutes());
        date.setSeconds(date.getUTCSeconds());
    }
    return ((date1 <= date) && (date <= date2));
}    
ZZZZ
}
1;
