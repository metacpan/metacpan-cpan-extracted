##@file
# Functions shared in Safe jail

##@class
# Functions shared in Safe jail
package Lemonldap::NG::Common::Safelib;

use strict;
use Encode;
use MIME::Base64;
use Lemonldap::NG::Common::IPv6;
use JSON::XS;
use Date::Parse;

our $VERSION = '2.0.15';

# Set here all the names of functions that must be available in Safe objects.
# Note that only functions, not methods, can be written here
our $functions =
  [
    qw(&checkLogonHours &date &dateToTime &checkDate &basic &unicode2iso &unicode2isoSafe &iso2unicode &iso2unicodeSafe &groupMatch &isInNet6 &varIsInUri &has2f_internal)
  ];

## @function boolean checkLogonHours(string logon_hours, string syntax, string time_correction, boolean default_access)
# Function to check logon hours
# @param $logon_hours string representing allowed logon hours (GMT)
# @param $syntax optional hexadecimal (default) or octetstring
# @param $time_correction optional hours to add or to subtract
# @param $default_access optional what result to return for users without logons hours
# @return 1 if access allowed, 0 else
sub checkLogonHours {
    my ( $logon_hours, $syntax, $time_correction, $default_access ) = @_;

    # Active Directory - logonHours: $attr_src_syntax = octetstring
    # Samba - sambaLogonHours: ???
    # LL::NG - ssoLogonHours: $attr_src_syntax = hexadecimal
    $syntax ||= "hexadecimal";

    # Default access if no value
    $default_access ||= "0";
    return $default_access unless $logon_hours;

    # Get the base2 value of logon_hours
    # Each byte represent an hour of the week
    # Begin with sunday at 0h00
    my $base2_logon_hours;
    if ( $syntax eq "octetstring" ) {
        $base2_logon_hours = unpack( "B*", $logon_hours );
    }
    if ( $syntax eq "hexadecimal" ) {

        # Remove white spaces
        $logon_hours =~ s/ //g;
        $base2_logon_hours = unpack( "B*", pack( "H*", $logon_hours ) );
    }

    # Get the present day and hour
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      gmtime(time);

    # Get the hour position
    my $hourpos = $wday * 24 + $hour;

    # Use time_correction
    if ($time_correction) {
        my ( $sign, $time ) = ( $time_correction =~ /([+|-]?)(\d+)/ );
        if   ( $sign =~ /-/ ) { $hourpos -= $time; }
        else                  { $hourpos += $time; }
    }

    # Get the corresponding byte
    return substr( $base2_logon_hours, $hourpos, 1 );
}

## @function integer listMatch
# Test if a value is found in a collection
# @param $list Can be a hash, array or string including the separator
# @param $value string The value to search for
# @param $ignorecase boolean Be case insensitive
# @return 1 if the value was found, 0 else
# NOTE: this function is not exported directly in this module because we don't
# want the usr to have to worry about separator. Is is wrapped in a closure in
# Jail.pm
sub listMatch {
    my ( $sep, $list, $value, $ignorecase ) = @_;
    my $flags = $ignorecase ? 'i' : '';
    my @a;
    if ( ref($list) eq "ARRAY" ) {
        @a = @{$list};
    }
    elsif ( ref($list) eq "HASH" ) {
        @a = keys %{$list};
    }
    else {
        @a = split $sep, $list;
    }
    if ( grep /(?$flags)^\Q$value\E$/, @a ) {
        return 1;
    }
    else {
        return 0;
    }
}

## @function integer date
# Get current local date
# @param $gmt optional boolean To return GMT date (default is local date)
# @return current date on format YYYYMMDDHHMMSS
sub date {
    my $gmt = shift;
    my ( $sec, $min, $hour, $mday, $mon, $year ) = $gmt ? gmtime : localtime;

    $year += 1900;
    $mon  += 1;
    $mon  = "0" . $mon  if ( $mon < 10 );
    $mday = "0" . $mday if ( $mday < 10 );
    $hour = "0" . $hour if ( $hour < 10 );
    $min  = "0" . $min  if ( $min < 10 );
    $sec  = "0" . $sec  if ( $sec < 10 );

    return $year . $mon . $mday . $hour . $min . $sec;
}

## @function integer dateToTime(string date)
# Converts a LDAP date into epoch time or returns undef upon failure.
# @param $date string Date in YYYYMMDDHHMMSS[+/-0000] format. It may contain a differential timezone, otherwise default TZ is GMT
# @return Date converted to time
sub dateToTime {
    my $date = shift;
    return undef unless ($date);

    # Parse date
    my ( $year, $month, $day, $hour, $min, $sec, $zone ) =
      ( $date =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})([-+\w]*)/ );

 # Convert date to epoch time with GMT as default timezone if date contains none
    return str2time(
        $year . "-"
          . $month . "-"
          . $day . "T"
          . $hour . ":"
          . $min . ":"
          . $sec
          . $zone,
        "GMT"
    );
}

## @function boolean checkDate(string start, string end, boolean default_access)
# Function to check a date
# @param $start string Start date in YYYYMMDDHHMMSS[+/-0000] format. It may contain a differential timezone, otherwise default TZ is GMT
# @param $end string End date in YYYYMMDDHHMMSS[+/-0000] format. It may contain a differential timezone, otherwise default TZ is GMT
# @param $default_access optional what result to return for users without start and end dates
# @return 1 if access allowed, 0 else
sub checkDate {
    my ( $start, $end, $default_access ) = @_;

    # Default access if no value
    $default_access ||= "0";
    return $default_access unless ( $start or $end );

    # If no start, set start to 01 01 1970
    $start ||= "19700101000000";

    # If no end, set end to the end of the world
    $end ||= "99991231235959";

    # Convert dates to epoch time
    my $starttime = &dateToTime($start);
    my $endtime   = &dateToTime($end);

    # Convert current GMT date to epoch time
    my $datetime = &dateToTime( &date(1) );

    return 1 if ( ( $datetime >= $starttime ) and ( $datetime <= $endtime ) );
    return 0;

}

## @function string basic(string login, string password)
# Return string that can be used for HTTP-BASIC authentication
# @param login User login
# @param password User password
# @return Authorization header content
sub basic {
    my ( $login, $password ) = @_;

    # UTF-8 strings should be ISO encoded
    $login    = &unicode2iso($login);
    $password = &unicode2iso($password);

    return "Basic " . encode_base64( $login . ":" . $password, '' );
}

## @function string unicode2iso(string string)
# Convert UTF-8 in ISO-8859-1
# @param string UTF-8 string
# @return ISO string
sub unicode2iso {
    my ($string) = @_;

    return encode( "iso-8859-1", decode( "utf-8", $string ) );
}

## @function string unicode2isoSafe(string string)
## This function is compliant with the Safe jail
## but not as portable as the original one
# Convert UTF-8 in ISO-8859-1
# @param string UTF-8 string
# @return ISO string
sub unicode2isoSafe {
    my ($string) = @_;

    my $res = $string;
    utf8::decode($res);
    utf8::downgrade($res);
    return $res;
}

## @function string iso2unicode(string string)
# Convert ISO-8859-1 in UTF-8
# @param string ISO string
# @return UTF-8 string
sub iso2unicode {
    my ($string) = @_;

    return encode( "utf-8", decode( "iso-8859-1", $string ) );
}

## @function string iso2unicodeSafe(string string)
## This function is compliant with the Safe jail
## but not as portable as the original one
# Convert ISO-8859-1 in UTF-8
# @param string ISO string
# @return UTF-8 string
sub iso2unicodeSafe {
    my ($string) = @_;

    my $res = $string;
    utf8::encode($res);
    return $res;
}

## @function int groupMatch(hashref groups, string attribute, string value)
# Check in hGroups structure if a group attribute contains a value
# @param groups The $hGroups variable
# @param attribute Name of the attribute
# @param value Value to check
# @return int Number of values that match
sub groupMatch {
    my ( $groups, $attribute, $value ) = @_;
    my $match = 0;

    foreach my $group ( keys %$groups ) {
        if ( ref( $groups->{$group}->{$attribute} ) eq "ARRAY" ) {
            foreach ( @{ $groups->{$group}->{$attribute} } ) {
                $match++ if ( $_ =~ /$value/ );
            }
        }
        else {
            $match++ if ( $groups->{$group}->{$attribute} =~ /$value/ );
        }
    }

    return $match;
}

sub isInNet6 {
    my ( $ip, $net ) = @_;
    $net =~ s#/(\d+)##;
    my $bits = $1;

    return net6( $ip, $bits ) eq net6( $net, $bits ) ? 1 : 0;
}

sub varIsInUri {
    my ( $uri, $wanteduri, $attribute, $restricted ) = @_;
    return $restricted
      ? $uri =~ /$wanteduri$attribute$/o
      : $uri =~ /$wanteduri$attribute/o;
}

my $json = JSON::XS->new;

sub has2f_internal {
    my ( $session, $type ) = @_;
    return 0 unless $session->{_2fDevices};

    my $_2fDevices = eval { $json->decode( $session->{_2fDevices} ); };
    return 0 if ( $@ or ref($_2fDevices) ne "ARRAY" );

    # Empty array
    return 0 unless scalar @{$_2fDevices};

    # Array has one value and we did not specify a type, succeed
    if ($type) {
        my @found = grep { lc( $_->{type} ) eq lc($type) } @{$_2fDevices};
        return @found ? 1 : 0;
    }

    return 1;
}

1;
