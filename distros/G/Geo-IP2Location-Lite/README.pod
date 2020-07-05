package Geo::IP2Location::Lite;

# Copyright (C) 2005-2014 IP2Location.com
# All Rights Reserved
#
# This library is free software: you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

$Geo::IP2Location::Lite::VERSION = '0.13';

my $UNKNOWN            = "UNKNOWN IP ADDRESS";
my $NO_IP              = "MISSING IP ADDRESS";
my $INVALID_IP_ADDRESS = "INVALID IP ADDRESS";
my $NOT_SUPPORTED      = "This parameter is unavailable in selected .BIN data file. Please upgrade data file.";
my $MAX_IPV4_RANGE     = 4294967295;

my $COUNTRYSHORT       = 1;
my $COUNTRYLONG        = 2;
my $REGION             = 3;
my $CITY               = 4;
my $ISP                = 5;
my $LATITUDE           = 6;
my $LONGITUDE          = 7;
my $DOMAIN             = 8;
my $ZIPCODE            = 9;
my $TIMEZONE           = 10;
my $NETSPEED           = 11;
my $IDDCODE            = 12;
my $AREACODE           = 13;
my $WEATHERSTATIONCODE = 14;
my $WEATHERSTATIONNAME = 15;
my $MCC                = 16;
my $MNC                = 17;
my $MOBILEBRAND        = 18;
my $ELEVATION          = 19;
my $USAGETYPE          = 20;

my $NUMBER_OF_FIELDS   = 20;
my $ALL                = 100;

my $IS_LITTLE_ENDIAN   = unpack("h*", pack("s", 1)) =~ m/^1/;

my $POSITIONS = {
	$COUNTRYSHORT       => [0,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2],
	$COUNTRYLONG        => [0,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2],
	$REGION             => [0,  0,  0,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3],
	$CITY               => [0,  0,  0,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4],
	$LATITUDE           => [0,  0,  0,  0,  0,  5,  5,  0,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5],
	$LONGITUDE          => [0,  0,  0,  0,  0,  6,  6,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6],
	$ZIPCODE            => [0,  0,  0,  0,  0,  0,  0,  0,  0,  7,  7,  7,  7,  0,  7,  7,  7,  0,  7,  0,  7,  7,  7,  0,  7],
	$TIMEZONE           => [0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8,  8,  7,  8,  8,  8,  7,  8,  0,  8,  8,  8,  0,  8],
	$ISP                => [0,  0,  3,  0,  5,  0,  7,  5,  7,  0,  8,  0,  9,  0,  9,  0,  9,  0,  9,  7,  9,  0,  9,  7,  9],
	$DOMAIN             => [0,  0,  0,  0,  0,  0,  0,  6,  8,  0,  9,  0, 10,  0, 10,  0, 10,  0, 10,  8, 10,  0, 10,  8, 10],
	$NETSPEED           => [0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8, 11,  0, 11,  8, 11,  0, 11,  0, 11,  0, 11],
	$IDDCODE            => [0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  9, 12,  0, 12,  0, 12,  9, 12,  0, 12],
	$AREACODE           => [0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 10, 13,  0, 13,  0, 13, 10, 13,  0, 13],
	$WEATHERSTATIONCODE => [0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  9, 14,  0, 14,  0, 14,  0, 14],
	$WEATHERSTATIONNAME => [0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 10, 15,  0, 15,  0, 15,  0, 15],
	$MCC                => [0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  9, 16,  0, 16,  9, 16],
	$MNC                => [0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 10, 17,  0, 17, 10, 17],
	$MOBILEBRAND        => [0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 11, 18,  0, 18, 11, 18],
	$ELEVATION          => [0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 11, 19,  0, 19],
	$USAGETYPE          => [0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 12, 20],
};

my $IPv4_re = qr/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;

sub open {
	my ($class, $db_file) = @_;
	$db_file || die "Geo::IP2Location::Lite::open() requires a database path name";
	CORE::open( my $handle,'<',"$db_file" ) or die "Geo::IP2Location::Lite::open() error opening $db_file: $!";
	binmode($handle);
	my $obj = bless {filehandle => $handle}, $class;
	return $obj->initialize;
}

sub initialize {
	my ($obj) = @_;
	$obj->{"databasetype"} = $obj->read8($obj->{filehandle}, 1);
	$obj->{"databasecolumn"} = $obj->read8($obj->{filehandle}, 2);
	$obj->{"databaseyear"} = $obj->read8($obj->{filehandle}, 3);
	$obj->{"databasemonth"} = $obj->read8($obj->{filehandle}, 4);
	$obj->{"databaseday"} = $obj->read8($obj->{filehandle}, 5);
	$obj->{"ipv4databasecount"} = $obj->read32($obj->{filehandle}, 6);
	$obj->{"ipv4databaseaddr"} = $obj->read32($obj->{filehandle}, 10);
	$obj->{"ipv4indexbaseaddr"} = $obj->read32($obj->{filehandle}, 22);
	return $obj;
}

sub get_module_version { return $Geo::IP2Location::Lite::VERSION; }

sub get_database_version {
	my $obj = shift(@_);
	return $obj->{"databaseyear"} . "." . $obj->{"databasemonth"} . "." . $obj->{"databaseday"};
}

sub _get_by_pos {
	my ( $obj,$ipaddr,$pos ) = @_;

	return $INVALID_IP_ADDRESS
		if ! $pos;

	my ( $ipv,$ipnum ) = $obj->validate_ip( $ipaddr );

	return $ipv == 4
		? $obj->get_record( $ipnum,$pos )
		: $INVALID_IP_ADDRESS;
}

sub get_country            { return ( _get_by_pos( @_,$COUNTRYSHORT ),_get_by_pos( @_,$COUNTRYLONG ) ) }
sub get_country_short      { return _get_by_pos( @_,$COUNTRYSHORT ); }
sub get_country_long       { return _get_by_pos( @_,$COUNTRYLONG ); }
sub get_region             { return _get_by_pos( @_,$REGION ); }
sub get_city               { return _get_by_pos( @_,$CITY ); }
sub get_isp                { return _get_by_pos( @_,$ISP ); }
sub get_latitude           { return _get_by_pos( @_,$LATITUDE ); }
sub get_zipcode            { return _get_by_pos( @_,$ZIPCODE ); }
sub get_longitude          { return _get_by_pos( @_,$LONGITUDE ); }
sub get_domain             { return _get_by_pos( @_,$DOMAIN ); }
sub get_timezone           { return _get_by_pos( @_,$TIMEZONE ); }
sub get_netspeed           { return _get_by_pos( @_,$NETSPEED ); }
sub get_iddcode            { return _get_by_pos( @_,$IDDCODE ); }
sub get_areacode           { return _get_by_pos( @_,$AREACODE ); }
sub get_weatherstationcode { return _get_by_pos( @_,$WEATHERSTATIONCODE ); }
sub get_weatherstationname { return _get_by_pos( @_,$WEATHERSTATIONNAME ); }
sub get_mcc                { return _get_by_pos( @_,$MCC ); }
sub get_mnc                { return _get_by_pos( @_,$MNC ); }
sub get_mobilebrand        { return _get_by_pos( @_,$MOBILEBRAND ); }
sub get_elevation          { return _get_by_pos( @_,$ELEVATION ); }
sub get_usagetype          { return _get_by_pos( @_,$USAGETYPE ); }

sub get_all {
	my @res = _get_by_pos( @_,$ALL );

	if ( $res[0] eq $INVALID_IP_ADDRESS ) {
		return ( $INVALID_IP_ADDRESS x $NUMBER_OF_FIELDS );
	}

	return @res;
}

sub get_record {
	my ( $obj,$ipnum,$mode ) = @_;
	my $dbtype= $obj->{"databasetype"};

	$mode = 0 if ! defined $mode;

	if ($ipnum eq "") {
		if ($mode == $ALL) {
			return ( $NO_IP x $NUMBER_OF_FIELDS );
		} else {
			return $NO_IP;
		}
	}

	if ( $mode != $ALL ) {
		if ( $POSITIONS->{$mode}[$dbtype] == 0 ) {
			return $NOT_SUPPORTED;
		}
	}
	
	my $realipno = $ipnum;
	my $handle = $obj->{"filehandle"};
	my $baseaddr = $obj->{"ipv4databaseaddr"};
	my $dbcount = $obj->{"ipv4databasecount"};
	my $dbcolumn = $obj->{"databasecolumn"};
	my $indexbaseaddr = $obj->{"ipv4indexbaseaddr"};

	my $ipnum1_2 = int($ipnum >> 16);
	my $indexaddr = $indexbaseaddr + ($ipnum1_2 << 3);

	my $low = 0;
	my $high = $dbcount;
	if ($indexbaseaddr > 0) {
		$low = $obj->read32($handle, $indexaddr);
		$high = $obj->read32($handle, $indexaddr + 4);
	}
	my $mid = 0;
	my $ipfrom = 0;
	my $ipto = 0;
	my $ipno = 0;

	if ($realipno == $MAX_IPV4_RANGE) {
		$ipno = $realipno - 1;
	} else {
		$ipno = $realipno;
	}

	while ($low <= $high) {
		$mid = int(($low + $high) >> 1);
		$ipfrom = $obj->read32($handle, $baseaddr + $mid * $dbcolumn * 4);
		$ipto = $obj->read32($handle, $baseaddr + ($mid + 1) * $dbcolumn * 4);

		return $UNKNOWN if ( ! defined( $ipfrom ) || ! defined( $ipto ) );
		
		if (($ipno >= $ipfrom) && ($ipno < $ipto)) {
			# read whole results string into temp string and parse results from memory
			my $raw_positions_row;
			seek($handle, ($baseaddr + $mid * $dbcolumn * 4) - 1, 0);
			read($handle, $raw_positions_row, $dbcolumn * 4);

			my @return_vals;

			foreach my $pos (
				$mode == $ALL
					? ( $COUNTRYSHORT .. $NUMBER_OF_FIELDS )
					: $mode
			) {

				if ( $POSITIONS->{$pos}[$dbtype] == 0 ) {
					push( @return_vals, $NOT_SUPPORTED );
				} else {
					if ( $pos == $LATITUDE or $pos == $LONGITUDE ) {

						push( @return_vals, sprintf( "%.6f",$obj->readFloat(
							substr($raw_positions_row, 4 * ( $POSITIONS->{$pos}[$dbtype] -1 ), 4)
						) ) ); 

					} elsif ( $pos == $COUNTRYLONG ) {

						push( @return_vals, $obj->readStr(
							$handle,
							unpack("V", substr($raw_positions_row, 4 * ( $POSITIONS->{$pos}[$dbtype] -1 ), 4 ) ) + 3
						) );

					} else {

						my $return_val = $obj->readStr(
							$handle,
							unpack("V", substr($raw_positions_row, 4 * ( $POSITIONS->{$pos}[$dbtype]-1), 4) )
						);

						if ( $pos == $COUNTRYSHORT && $return_val eq 'UK' ) {
							$return_val = 'GB';
						}

						push( @return_vals,$return_val );
					}
				}
			}

			return ( $mode == $ALL ) ? @return_vals : $return_vals[0];

		} else {
			if ($ipno < $ipfrom) {
				$high = $mid - 1;
			} else {
				$low = $mid + 1;
			}
		}
	}

	return $UNKNOWN;
}

sub read32 {
	my ($obj, $handle, $position) = @_;
	my $data = "";
	seek($handle, $position-1, 0);
	read($handle, $data, 4);
	return unpack("V", $data);
}

sub read8 {
	my ($obj, $handle, $position) = @_;
	my $data = "";
	seek($handle, $position-1, 0);
	read($handle, $data, 1);
	return unpack("C", $data);
}

sub readStr {
	my ($obj, $handle, $position) = @_;
	my $data = "";
	my $string = "";
	seek($handle, $position, 0);
	read($handle, $data, 1);
	read($handle, $string, unpack("C", $data));
	return $string;
}

sub readFloat {
	my ($obj, $data) = @_;
	return $IS_LITTLE_ENDIAN
		? unpack("f", $data)           # "LITTLE ENDIAN - x86\n";
		: unpack("f", reverse($data)); # "BIG ENDIAN - MAC\n";
}

sub validate_ip {
	my ( $obj,$ip ) = @_;
	my $ipv = -1;
	my $ipnum = -1;
	#name server lookup if domain name
	$ip = $obj->name2ip($ip);
	
	if ($obj->ip_is_ipv4($ip)) {
		#ipv4 address
		$ipv = 4;
		$ipnum = $obj->ip2no($ip);
	}
	return ($ipv, $ipnum);
}

sub ip2no {
	my ( $obj,$ip ) = @_;
	my @block = split(/\./, $ip);
	my $no = 0;
	$no = $block[3];
	$no = $no + $block[2] * 256;
	$no = $no + $block[1] * 256 * 256;
	$no = $no + $block[0] * 256 * 256 * 256;
	return $no;
}

sub name2ip {
	my ( $obj,$host ) = @_;
	return "" if ! defined($host);
  my $ip_address = "";
  if ($host =~ $IPv4_re){
    $ip_address = $host;
  } else {
	if ( my $ip = gethostbyname($host) ) {
		$ip_address = join('.', unpack('C4',($ip)[4]));
	}
  }
  return $ip_address;
}

sub ip_is_ipv4 {
	my ( $obj,$ip ) = @_;
	if ($ip =~ $IPv4_re) {
		return 1;
	} else {
		return 0;
	}
}

1;

__END__

=head1 NAME

Geo::IP2Location::Lite - Lightweight version of Geo::IP2Location with IPv4
support only

=for html
<a href='https://travis-ci.org/Humanstate/geo-ip2location-lite?branch=master'><img src='https://travis-ci.org/Humanstate/geo-ip2location-lite.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/Humanstate/geo-ip2location-lite?branch=master'><img src='https://coveralls.io/repos/Humanstate/geo-ip2location-lite/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 SYNOPSIS

	use Geo::IP2Location::Lite;

	my $obj = Geo::IP2Location::Lite->open( "/path/to/IP-COUNTRY.BIN" );

	my $countryshort = $obj->get_country_short("20.11.187.239");
	my $countrylong  = $obj->get_country_long("20.11.187.239");
	my $region       = $obj->get_region("20.11.187.239");
	...

	my ( $cos,$col,$reg ... ) = $obj->get_all("20.11.187.239");

=head1 DESCRIPTION

This module is a lightweight version of Geo::IP2Location that is compatible
with B<IPv4> BIN files only. It fixes all the current issues against the
current version of Geo::IP2Location and makes the perl more idiomatic (and
thus easier to maintain). The code is also compatible with older perls
(L<Geo::IP2Location> currently only works with 5.14 and above).

You should see the documentation for the original L<Geo::IP2Location> module
for a complete list of available methods, the documentation below includes
B<additional> methods addded by this module only.

=head1 DIFFERENCES FROM L<Geo::IP2Location>

The get_country method has been added to get both short and long in one call:

	my ( $country_short,$country_long ) = $obj->get_country( $ip );

The ISO-3166 code for United Kingdom of Great Britain and Northern Ireland has
been corrected from B<UK> to B<GB>

=head1 SEE ALSO

L<Geo::IP2Location>

http://www.ip2location.com

=head1 VERSION

0.13

=head1 AUTHOR

Forked from Geo::IP2Location by Lee Johnson C<leejo@cpan.org>. If you would
like to contribute documentation, features, bug fixes, or anything else then
please raise an issue / pull request:

    https://github.com/Humanstate/geo-ip2location-lite

=head1 LICENSE

Copyright (c) 2016 IP2Location.com

All rights reserved. This package is free software; It is licensed under the
GPL.

=cut
