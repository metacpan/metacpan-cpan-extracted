# Copyright (C) 2002-2019 IP2Location.com
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

package Geo::IP2Proxy;

use strict;
use vars qw(@ISA $VERSION @EXPORT);
use Math::BigInt;

$VERSION = '2.11';

require Exporter;
@ISA = qw(Exporter);

use constant UNKNOWN => "UNKNOWN IP ADDRESS";
use constant IPV6_ADDRESS_IN_IPV4_BIN => "IPV6 ADDRESS MISSING IN IPV4 BIN";
use constant NO_IP => "MISSING IP ADDRESS";
use constant INVALID_IPV6_ADDRESS => "INVALID IPV6 ADDRESS";
use constant INVALID_IPV4_ADDRESS => "INVALID IPV4 ADDRESS";
use constant INVALID_IP_ADDRESS => "INVALID IP ADDRESS";
use constant NOT_SUPPORTED => "NOT SUPPORTED";
use constant MAX_IPV4_RANGE => 4294967295;
use constant MAX_IPV6_RANGE => 340282366920938463463374607431768211455;

use constant COUNTRYSHORT => 1;
use constant COUNTRYLONG => 2;
use constant REGION => 3;
use constant CITY => 4;
use constant ISP => 5;
use constant PROXYTYPE => 6;
use constant ISPROXY => 7;
use constant DOMAIN => 8;
use constant USAGETYPE => 9;
use constant ASN => 10;
use constant AS => 11;
use constant LASTSEEN => 12;

use constant ALL => 100;
use constant IPV4 => 0;
use constant IPV6 => 1;

my @IPV4_COUNTRY_POSITION =             (0,  2,  3,  3,  3,  3,  3,  3,  3);
my @IPV4_REGION_POSITION =              (0,  0,  0,  4,  4,  4,  4,  4,  4);
my @IPV4_CITY_POSITION =                (0,  0,  0,  5,  5,  5,  5,  5,  5);
my @IPV4_ISP_POSITION =                 (0,  0,  0,  0,  6,  6,  6,  6,  6);
my @IPV4_PROXYTYPE_POSITION =           (0,  0,  2,  2,  2,  2,  2,  2,  2);
my @IPV4_DOMAIN_POSITION =              (0,  0,  0,  0,  0,  7,  7,  7,  7);
my @IPV4_USAGETYPE_POSITION =           (0,  0,  0,  0,  0,  0,  8,  8,  8);
my @IPV4_ASN_POSITION =                 (0,  0,  0,  0,  0,  0,  0,  9,  9);
my @IPV4_AS_POSITION =                  (0,  0,  0,  0,  0,  0,  0, 10, 10);
my @IPV4_LASTSEEN_POSITION =            (0,  0,  0,  0,  0,  0,  0,  0, 11);

my @IPV6_COUNTRY_POSITION =             (0,  2,  3,  3,  3,  3,  3,  3,  3);
my @IPV6_REGION_POSITION =              (0,  0,  0,  4,  4,  4,  4,  4,  4);
my @IPV6_CITY_POSITION =                (0,  0,  0,  5,  5,  5,  5,  5,  5);
my @IPV6_ISP_POSITION =                 (0,  0,  0,  0,  6,  6,  6,  6,  6);
my @IPV6_PROXYTYPE_POSITION =           (0,  0,  2,  2,  2,  2,  2,  2,  2);
my @IPV6_DOMAIN_POSITION =              (0,  0,  0,  0,  0,  7,  7,  7,  7);
my @IPV6_USAGETYPE_POSITION =           (0,  0,  0,  0,  0,  0,  8,  8,  8);
my @IPV6_ASN_POSITION =                 (0,  0,  0,  0,  0,  0,  0,  9,  9);
my @IPV6_AS_POSITION =                  (0,  0,  0,  0,  0,  0,  0, 10, 10);
my @IPV6_LASTSEEN_POSITION =            (0,  0,  0,  0,  0,  0,  0,  0, 11);

my $IPv6_re = qr/:(?::[0-9a-fA-F]{1,4}){0,5}(?:(?::[0-9a-fA-F]{1,4}){1,2}|:(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})))|[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}|:)|(?::(?:[0-9a-fA-F]{1,4})?|(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))))|:(?:(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|[0-9a-fA-F]{1,4}(?::[0-9a-fA-F]{1,4})?|))|(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|:[0-9a-fA-F]{1,4}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){0,2})|:))|(?:(?::[0-9a-fA-F]{1,4}){0,2}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){1,2})|:))|(?:(?::[0-9a-fA-F]{1,4}){0,3}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){1,2})|:))|(?:(?::[0-9a-fA-F]{1,4}){0,4}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){1,2})|:))/;
my $IPv4_re = qr/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/;

sub open {
  die "Geo::IP2Proxy::open() requires a database path name" unless( (@_ > 1) && ($_[1]) );
  my ($class, $dbFile) = @_;
  my $handle;
  my $obj;
  CORE::open $handle, "$dbFile" or die "Geo::IP2Proxy::open() error opening $dbFile";
	binmode($handle);
	$obj = bless {filehandle => $handle}, $class;
	$obj->initialize();
	return $obj;
}

sub close {
  my ($class) = @_;
  if (CORE::close($class->{filehandle})) {
  	return 0;
  } else {
  	return 1;
  }
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
	$obj->{"ipv6databasecount"} = $obj->read32($obj->{filehandle}, 14);
	$obj->{"ipv6databaseaddr"} = $obj->read32($obj->{filehandle}, 18);
	$obj->{"ipv4indexbaseaddr"} = $obj->read32($obj->{filehandle}, 22);
	$obj->{"ipv6indexbaseaddr"} = $obj->read32($obj->{filehandle}, 26);
	return $obj;
}

sub getModuleVersion {
	my $obj = shift(@_);
	return $VERSION;
}

sub getPackageVersion {
	my $obj = shift(@_);
	return $obj->{"databasetype"};
}

sub getDatabaseVersion {
	my $obj = shift(@_);
	my $databaseyear = 2000 + $obj->{"databaseyear"};
	return $databaseyear . "." . $obj->{"databasemonth"} . "." . $obj->{"databaseday"};
}

sub getCountryShort {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validateIP($ipaddr);
	if ($ipv == 4) {
		return $obj->getIPv4Record($ipnum, COUNTRYSHORT);
	} else {
		if ($ipv == 6) {
			return $obj->getIPv6Record($ipnum, COUNTRYSHORT);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub getCountryLong {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validateIP($ipaddr);
	if ($ipv == 4) {
		return $obj->getIPv4Record($ipnum, COUNTRYLONG);
	} else {
		if ($ipv == 6) {
			return $obj->getIPv6Record($ipnum, COUNTRYLONG);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub getRegion {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validateIP($ipaddr);
	if ($ipv == 4) {
		return $obj->getIPv4Record($ipnum, REGION);
	} else {
		if ($ipv == 6) {
			return $obj->getIPv6Record($ipnum, REGION);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}	
}

sub getCity {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validateIP($ipaddr);
	if ($ipv == 4) {
		return $obj->getIPv4Record($ipnum, CITY);
	} else {
		if ($ipv == 6) {
			return $obj->getIPv6Record($ipnum, CITY);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub getISP {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validateIP($ipaddr);
	if ($ipv == 4) {
		return $obj->getIPv4Record($ipnum, ISP);
	} else {
		if ($ipv == 6) {
			return $obj->getIPv6Record($ipnum, ISP);
		} else {
			return INVALID_IP_ADDRESS;
		}
	}	
}

sub getProxyType {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validateIP($ipaddr);
	if ($ipv == 4) {
		return $obj->getIPv4Record($ipnum, PROXYTYPE);
	} else {
		if ($ipv == 6) {
			return $obj->getIPv6Record($ipnum, PROXYTYPE);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}	
}

sub isProxy {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validateIP($ipaddr);
	if ($ipv == 4) {
		return $obj->getIPv4Record($ipnum, ISPROXY);
	} else {
		if ($ipv == 6) {
			return $obj->getIPv6Record($ipnum, ISPROXY);	
		} else {
			return -1;
		}
	}	
}

sub getDomain {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validateIP($ipaddr);
	if ($ipv == 4) {
		return $obj->getIPv4Record($ipnum, DOMAIN);
	} else {
		if ($ipv == 6) {
			return $obj->getIPv6Record($ipnum, DOMAIN);
		} else {
			return INVALID_IP_ADDRESS;
		}
	}	
}

sub getUsageType {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validateIP($ipaddr);
	if ($ipv == 4) {
		return $obj->getIPv4Record($ipnum, USAGETYPE);
	} else {
		if ($ipv == 6) {
			return $obj->getIPv6Record($ipnum, USAGETYPE);
		} else {
			return INVALID_IP_ADDRESS;
		}
	}	
}

sub getASN {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validateIP($ipaddr);
	if ($ipv == 4) {
		return $obj->getIPv4Record($ipnum, ASN);
	} else {
		if ($ipv == 6) {
			return $obj->getIPv6Record($ipnum, ASN);
		} else {
			return INVALID_IP_ADDRESS;
		}
	}	
}

sub getAS {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validateIP($ipaddr);
	if ($ipv == 4) {
		return $obj->getIPv4Record($ipnum, AS);
	} else {
		if ($ipv == 6) {
			return $obj->getIPv6Record($ipnum, AS);
		} else {
			return INVALID_IP_ADDRESS;
		}
	}	
}

sub getLastSeen {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validateIP($ipaddr);
	if ($ipv == 4) {
		return $obj->getIPv4Record($ipnum, LASTSEEN);
	} else {
		if ($ipv == 6) {
			return $obj->getIPv6Record($ipnum, LASTSEEN);
		} else {
			return INVALID_IP_ADDRESS;
		}
	}	
}

sub getAll {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validateIP($ipaddr);
	if ($ipv == 4) {
		return $obj->getIPv4Record($ipnum, ALL);
	} else {
		if ($ipv == 6) {
			return $obj->getIPv6Record($ipnum, ALL);	
		} else {
			return (-1, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS);
		}
	}
}

sub getIPv6Record {
	my $obj = shift(@_);
	my $ipnum = shift(@_);
	my $mode = shift(@_);
	my $dbtype = $obj->{"databasetype"};

	if ($ipnum eq "") {
		if ($mode == ALL) {
			return (-1, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP);
		} else {
			if ($mode == ISPROXY) {
				return -1;
			} else {
				return NO_IP;
			}
		}
	}

	if (($mode == COUNTRYSHORT) && ($IPV6_COUNTRY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == COUNTRYLONG) && ($IPV6_COUNTRY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == REGION) && ($IPV6_REGION_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == CITY) && ($IPV6_CITY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ISP) && ($IPV6_ISP_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == PROXYTYPE) && ($IPV6_PROXYTYPE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == DOMAIN) && ($IPV6_DOMAIN_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == USAGETYPE) && ($IPV6_USAGETYPE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ASN) && ($IPV6_ASN_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == AS) && ($IPV6_AS_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == LASTSEEN) && ($IPV6_LASTSEEN_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}

	my $realipno = Math::BigInt->new($ipnum);
	my $handle = $obj->{"filehandle"};
	my $baseaddr = $obj->{"ipv6databaseaddr"};
	my $dbcount = $obj->{"ipv6databasecount"};
	my $dbcolumn = $obj->{"databasecolumn"};
	my $indexbaseaddr = $obj->{"ipv6indexbaseaddr"};

	if ($dbcount == 0) {
		if ($mode == ALL) {
			return (IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN);
		} else {
			return IPV6_ADDRESS_IN_IPV4_BIN;
		}
	}

	my $ipnum1_2 = new Math::BigInt($ipnum);
	my $remainder = 0;
	($ipnum1_2, $remainder) = $ipnum1_2->bdiv(2**112);
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

	$ipno = $realipno;
	if ($realipno == "340282366920938463463374607431768211455") {
		$ipno = $ipno->bsub(1);
	}

	while ($low <= $high) {
		$mid = int(($low + $high)/2);
		$ipfrom = $obj->read128($handle, $baseaddr + $mid * (($dbcolumn * 4) + 12));
		$ipto = $obj->read128($handle, $baseaddr + ($mid + 1) * (($dbcolumn * 4) + 12));
		if (($ipno >= $ipfrom) && ($ipno < $ipto)) {
			my $row_pointer = $baseaddr + $mid * (($dbcolumn * 4) + 12);
			if ($mode == ALL) {
				my $countryshort = NOT_SUPPORTED;
				my $countrylong = NOT_SUPPORTED;
				my $region = NOT_SUPPORTED;
				my $city = NOT_SUPPORTED;
				my $isp = NOT_SUPPORTED;
				my $proxytype = NOT_SUPPORTED;
				my $domain = NOT_SUPPORTED;
				my $usagetype = NOT_SUPPORTED;
				my $asn = NOT_SUPPORTED;
				my $as = NOT_SUPPORTED;
				my $lastseen = NOT_SUPPORTED;
				my $isproxy  = -1;
				
				if ($IPV6_COUNTRY_POSITION[$dbtype] != 0) {
					my $pos = $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_COUNTRY_POSITION[$dbtype]));
					$countryshort = $obj->readStr($handle, $pos);
					$countrylong = $obj->readStr($handle, $pos + 3);
				}
				if ($IPV6_REGION_POSITION[$dbtype] != 0) {
					$region = $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_REGION_POSITION[$dbtype])));
				}
				if ($IPV6_CITY_POSITION[$dbtype] != 0) {
					$city = $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_CITY_POSITION[$dbtype])));
				}
				if ($IPV6_ISP_POSITION[$dbtype] != 0) {
					$isp = $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_ISP_POSITION[$dbtype])));
				}
				if ($IPV6_PROXYTYPE_POSITION[$dbtype] != 0) {
					$proxytype = $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_PROXYTYPE_POSITION[$dbtype])));
				}
				if ($IPV6_DOMAIN_POSITION[$dbtype] != 0) {
					$domain = $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_DOMAIN_POSITION[$dbtype])));
				}
				if ($IPV6_USAGETYPE_POSITION[$dbtype] != 0) {
					$usagetype = $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_USAGETYPE_POSITION[$dbtype])));
				}
				if ($IPV6_ASN_POSITION[$dbtype] != 0) {
					$asn = $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_ASN_POSITION[$dbtype])));
				}
				if ($IPV6_AS_POSITION[$dbtype] != 0) {
					$as = $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_AS_POSITION[$dbtype])));
				}
				if ($IPV6_LASTSEEN_POSITION[$dbtype] != 0) {
					$lastseen = $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_LASTSEEN_POSITION[$dbtype])));
				}
				if (($countryshort eq "-") || ($proxytype eq "-")) {
					$isproxy = 0;
				} else {
					if (($proxytype eq "DCH") || ($proxytype eq "SES")) {
						$isproxy = 2;
					} else {
						$isproxy = 1;
					}
				}
				return ($isproxy, $proxytype, $countryshort, $countrylong, $region, $city, $isp, $domain, $usagetype, $asn, $as, $lastseen);
			}
			if ($mode == COUNTRYSHORT) {
				return $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_COUNTRY_POSITION[$dbtype])));
			}
			if ($mode == COUNTRYLONG) {
				return $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_COUNTRY_POSITION[$dbtype])) + 3);
			}
			if ($mode == REGION) {
				return $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_REGION_POSITION[$dbtype])));
			}
			if ($mode == CITY) {
				return $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_CITY_POSITION[$dbtype])));
			}
			if ($mode == ISP) {
				return $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_ISP_POSITION[$dbtype])));
			}
			if ($mode == PROXYTYPE) {
				return $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_PROXYTYPE_POSITION[$dbtype])));
			}
			if ($mode == DOMAIN) {
				return $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_DOMAIN_POSITION[$dbtype])));
			}
			if ($mode == USAGETYPE) {
				return $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_USAGETYPE_POSITION[$dbtype])));
			}
			if ($mode == ASN) {
				return $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_ASN_POSITION[$dbtype])));
			}
			if ($mode == AS) {
				return $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_AS_POSITION[$dbtype])));
			}
			if ($mode == LASTSEEN) {
				return $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_LASTSEEN_POSITION[$dbtype])));
			}
			if ($mode == ISPROXY) {
				my $countryshort = NOT_SUPPORTED;
				my $proxytype = NOT_SUPPORTED;
				my $isproxy = NOT_SUPPORTED;
				if ($IPV6_PROXYTYPE_POSITION[$dbtype] == 0) {
					# PX1, use country as detection
					$countryshort = $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_COUNTRY_POSITION[$dbtype])));
				} else {
					$proxytype = $obj->readStr($handle, $obj->read32($handle, $row_pointer + 8 + 4 * ($IPV6_PROXYTYPE_POSITION[$dbtype])));
				}
				if (($countryshort eq "-") || ($proxytype eq "-")) {
					$isproxy = 0;
				} else {
					if (($proxytype eq "DCH") || ($proxytype eq "SES")) {
						$isproxy = 2;
					} else {
						$isproxy = 1;
					}
				}
				return $isproxy;
			}
		} else {
			if ($ipno < $ipfrom) {
				$high = $mid - 1;
			} else {
				$low = $mid + 1;
			}
		}
	}
	if ($mode == ALL) {
		return (-1, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN);
	} else {
		if ($mode == ISPROXY) {
			return -1;
		} else {
			return UNKNOWN;
		}		
	}
}

sub getIPv4Record {
	my $obj = shift(@_);
	my $ipnum = shift(@_);
	my $mode = shift(@_);
	my $dbtype= $obj->{"databasetype"};

	if ($ipnum eq "") {
		if ($mode == ALL) {
			return (-1, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP);
		} else {
			if ($mode == ISPROXY) {
				return -1;
			} else {
				return NO_IP;
			}
		}
	}
	
	if (($mode == COUNTRYSHORT) && ($IPV4_COUNTRY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == COUNTRYLONG) && ($IPV4_COUNTRY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == REGION) && ($IPV4_REGION_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == CITY) && ($IPV4_CITY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ISP) && ($IPV4_ISP_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == PROXYTYPE) && ($IPV4_PROXYTYPE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == DOMAIN) && ($IPV4_DOMAIN_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == USAGETYPE) && ($IPV4_USAGETYPE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ASN) && ($IPV4_ASN_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == AS) && ($IPV4_AS_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == LASTSEEN) && ($IPV4_LASTSEEN_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
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

	if ($realipno == MAX_IPV4_RANGE) {
		$ipno = $realipno - 1;
	} else {
		$ipno = $realipno;
	}

	while ($low <= $high) {
		$mid = int(($low + $high) >> 1);
		$ipfrom = $obj->read32($handle, $baseaddr + $mid * $dbcolumn * 4);
		$ipto = $obj->read32($handle, $baseaddr + ($mid + 1) * $dbcolumn * 4);
		if (($ipno >= $ipfrom) && ($ipno < $ipto)) {
			if ($mode == ALL) {
				my $countryshort = NOT_SUPPORTED;
				my $countrylong = NOT_SUPPORTED;
				my $region = NOT_SUPPORTED;
				my $city = NOT_SUPPORTED;
				my $isp = NOT_SUPPORTED;
				my $proxytype = NOT_SUPPORTED;
				my $domain = NOT_SUPPORTED;
				my $usagetype = NOT_SUPPORTED;
				my $asn = NOT_SUPPORTED;
				my $as = NOT_SUPPORTED;
				my $lastseen = NOT_SUPPORTED;
				my $isproxy  = -1;

				if ($IPV4_COUNTRY_POSITION[$dbtype] != 0) {
					my $pos = $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_COUNTRY_POSITION[$dbtype]-1));
					$countryshort = $obj->readStr($handle, $pos);
					$countrylong = $obj->readStr($handle, $pos + 3);
				}
				if ($IPV4_REGION_POSITION[$dbtype] != 0) {
					$region = $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_REGION_POSITION[$dbtype]-1)));
				}
				if ($IPV4_CITY_POSITION[$dbtype] != 0) {
					$city = $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_CITY_POSITION[$dbtype]-1)));
				}
				if ($IPV4_ISP_POSITION[$dbtype] != 0) {
					$isp = $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_ISP_POSITION[$dbtype]-1)));
				}
				if ($IPV4_PROXYTYPE_POSITION[$dbtype] != 0) {
					$proxytype = $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_PROXYTYPE_POSITION[$dbtype]-1)));
				}
				if ($IPV4_DOMAIN_POSITION[$dbtype] != 0) {
					$domain = $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_DOMAIN_POSITION[$dbtype]-1)));
				}
				if ($IPV4_USAGETYPE_POSITION[$dbtype] != 0) {
					$usagetype = $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_USAGETYPE_POSITION[$dbtype]-1)));
				}
				if ($IPV4_ASN_POSITION[$dbtype] != 0) {
					$asn = $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_ASN_POSITION[$dbtype]-1)));
				}
				if ($IPV4_AS_POSITION[$dbtype] != 0) {
					$as = $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_AS_POSITION[$dbtype]-1)));
				}
				if ($IPV4_LASTSEEN_POSITION[$dbtype] != 0) {
					$lastseen = $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_LASTSEEN_POSITION[$dbtype]-1)));
				}
				if ($countryshort eq "-") {
					$isproxy = 0;
				} else {
					if (($proxytype eq "DCH") || ($proxytype eq "SES")) {
						$isproxy = 2;
					} else {
						$isproxy = 1;
					}
				}
				return ($isproxy, $proxytype, $countryshort, $countrylong, $region, $city, $isp, $domain, $usagetype, $asn, $as, $lastseen);
			}
			if ($mode == COUNTRYSHORT) {
				return $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_COUNTRY_POSITION[$dbtype]-1)));
			}
			if ($mode == COUNTRYLONG) {
				return $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_COUNTRY_POSITION[$dbtype]-1))+3);
			}
			if ($mode == REGION) {
				return $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_REGION_POSITION[$dbtype]-1)));
			}
			if ($mode == CITY) {
				return $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_CITY_POSITION[$dbtype]-1)));
			}
			if ($mode == ISP) {
				return $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_ISP_POSITION[$dbtype]-1)));
			}
			if ($mode == PROXYTYPE) {
				return $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_PROXYTYPE_POSITION[$dbtype]-1)));
			}
			if ($mode == DOMAIN) {
				return $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_DOMAIN_POSITION[$dbtype]-1)));
			}
			if ($mode == USAGETYPE) {
				return $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_USAGETYPE_POSITION[$dbtype]-1)));
			}
			if ($mode == ASN) {
				return $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_ASN_POSITION[$dbtype]-1)));
			}
			if ($mode == AS) {
				return $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_AS_POSITION[$dbtype]-1)));
			}
			if ($mode == LASTSEEN) {
				return $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_LASTSEEN_POSITION[$dbtype]-1)));
			}
			if ($mode == ISPROXY) {
				my $countryshort = NOT_SUPPORTED;
				my $proxytype = NOT_SUPPORTED;
				my $isproxy = NOT_SUPPORTED;
				if ($IPV4_PROXYTYPE_POSITION[$dbtype] == 0) {
					# PX1, use country as detection
					$countryshort = $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_COUNTRY_POSITION[$dbtype]-1)));
				} else {
					$proxytype = $obj->readStr($handle, $obj->read32($handle, $baseaddr + ($mid * $dbcolumn * 4) + 4 * ($IPV4_PROXYTYPE_POSITION[$dbtype]-1)));
				}
				if (($countryshort eq "-") || ($proxytype eq "-")) {
					$isproxy = 0;
				} else {
					if (($proxytype eq "DCH") || ($proxytype eq "SES")) {
						$isproxy = 2;
					} else {
						$isproxy = 1;
					}
				}
				return $isproxy;
			}
		} else {
			if ($ipno < $ipfrom) {
				$high = $mid - 1;
			} else {
				$low = $mid + 1;
			}
		}
	}
	if ($mode == ALL) {
		return (-1, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN);
	} else {
		if ($mode == ISPROXY) {
			return -1;
		} else {
			return UNKNOWN;
		}
	}
}

sub read128 {
	my ($obj, $handle, $position) = @_;
	my $data = "";
	seek($handle, $position-1, 0);
	read($handle, $data, 16);
	return &bytesInt($data);
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
	my ($obj, $handle, $position) = @_;
	my $data = "";
	seek($handle, $position-1, 0);
	read($handle, $data, 4);

	my $is_little_endian = unpack("h*", pack("s", 1));
	if ($is_little_endian =~ m/^1/) {
		# "LITTLE ENDIAN - x86\n";
		return unpack("f", $data);
	} else {
		# "BIG ENDIAN - MAC\n";
		return unpack("f", reverse($data));
	}
}

sub bytesInt {
	my $binip = shift(@_);
	my @array = split(//, $binip);
	return 0 if ($#array != 15);
	my $ip96_127 = unpack("V", $array[0] . $array[1] . $array[2] . $array[3]);
	my $ip64_95 = unpack("V", $array[4] . $array[5] . $array[6] . $array[7]);
	my $ip32_63 = unpack("V", $array[8] . $array[9] . $array[10] . $array[11]);
	my $ip1_31 = unpack("V", $array[12] . $array[13] . $array[14] . $array[15]);

	my $big1 = Math::BigInt->new("$ip96_127");
	my $big2 = Math::BigInt->new("$ip64_95")->blsft(32);
	my $big3 = Math::BigInt->new("$ip32_63")->blsft(64);
	my $big4 = Math::BigInt->new("$ip1_31")->blsft(96);
	$big1 = $big1->badd($big2)->badd($big3)->badd($big4);
	
	return $big1->bstr();
}

sub validateIP {
	my $obj = shift(@_);
	my $ip = shift(@_);
	my $ipv = -1;
	my $ipnum = -1;
	#name server lookup if domain name
	$ip = $obj->nameIP($ip);
	
	if ($obj->isIPv4($ip)) {
		#ipv4 address
		$ipv = 4;
		$ipnum = $obj->ipNo($ip);
	} else {
		#expand ipv6 address
		$ip = $obj->expandIPv6Address($ip);
		if ($obj->isIPv6($ip)) {
			#ipv6 address
			$ipv = 6;
			$ipnum = $obj->hexInt($ip);
			
			#reformat ipv4 address in ipv6 
			if (($ipnum >= 281470681743360) && ($ipnum <= 281474976710655)) {
				$ipv = 4;
				$ipnum = $ipnum - 281470681743360;
			}
			#reformat 6to4 address to ipv4 address 2002:: to 2002:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF
			if (($ipnum >= 42545680458834377588178886921629466624) && ($ipnum <= 42550872755692912415807417417958686719)) {
				$ipv = 4;
				#bitshift right 80 bits
				$ipnum->brsft(80);
				#bitwise modulus to get the last 32 bit
				$ipnum->bmod(4294967296); 
			}
			#reformat Teredo address to ipv4 address 2001:0000:: to 2001:0000:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:
			if (($ipnum >= 42540488161975842760550356425300246528) && ($ipnum <= 42540488241204005274814694018844196863)) {
				$ipv = 4;
				$ipnum = Math::BigInt->new($ipnum);
				#bitwise not to invert binary
				$ipnum->bnot();
				#bitwise modulus to get the last 32 bit
				$ipnum->bmod(4294967296); 
			}
		} else {
			#not IPv4 and IPv6
		}
	}
	return ($ipv, $ipnum);
}

sub expandIPv6Address {
	my $obj = shift(@_);
	my $ip = shift(@_);
	$ip =~ s/\:\:/\:Z\:/;
	my @ip = split(/\:/, $ip);
	my $num = scalar(@ip);

	my $l = 8;
	if ($ip[$#ip] =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
		my $a = sprintf("%x", ($1*256 + $2));
		my $b = sprintf("%x", ($3*256 + $4));
		$ip[$#ip] = $a;
		$ip[$#ip+1] = $b;
		$l--;
	}

	if ($#ip == 8) {
		shift(@ip);
		$l++;
	}

	foreach (0..(scalar(@ip)-1)) {
		$ip[$_] = ('0'x(4-length ($ip[$_]))).$ip[$_];
	}

	foreach (0..(scalar(@ip)-1)) {
		next unless ($ip[$_] eq '000Z');
		my @empty = map { $_ = '0'x4 } (0..7);
		$ip[$_] = join(':', @empty[0..$l-$num]);
		last;
	}

	return (uc(join ':', @ip));
}

sub hexInt {
	my $obj = shift(@_);
	my $hexip = shift(@_);

	$hexip =~ s/\://g;

	unless (length($hexip) == 32) {
		return 0;
	};

	my $binip = unpack('B128', pack('H32', $hexip));
	my ($n, $dec) = (Math::BigInt->new(1), Math::BigInt->new(0));

	foreach (reverse (split('', $binip))) {
		$_ && ($dec += $n);
		$n *= 2;
	}

	$dec =~ s/^\+//;
	return $dec;
}

sub ipNo {
	my $obj = shift(@_);
	my $ip = shift(@_);
	my @block = split(/\./, $ip);
	my $no = 0;
	$no = $block[3];
	$no = $no + $block[2] * 256;
	$no = $no + $block[1] * 256 * 256;
	$no = $no + $block[0] * 256 * 256 * 256;
	return $no;
}

sub nameIP {
  my $obj = shift(@_);
  my $host = shift(@_);
  my $ip_address = "";
  if (($host =~ m/^$IPv4_re$/) || ($host =~ m/^$IPv6_re$/) || ($host =~ m/^\:\:$/)) {
    $ip_address = $host;
  } else {
  	# TO_DO: Can we return IPv6 address too?
    $ip_address = join('.', unpack('C4',(gethostbyname($host))[4]));
  }
  return $ip_address;
}

sub isIPv4 {
	my $obj = shift(@_);
	my $ip = shift(@_);
	if ($ip =~ m/^$IPv4_re$/) {
		my @octet = split(/\./, $ip);
		foreach my $i (0 .. $#octet) {
			return 0 if (($octet[$i] > 255) || ($octet[$i] < 0));
		}
		return 1;
	} else {
		return 0;
	}
}

sub isIPv6 {
	my $obj = shift(@_);
	my $ip = shift(@_);
	if (($ip =~ m/^$IPv6_re$/) || ($ip =~ m/^$IPv4_re$/)) {
		return 1;
	} else {
		return 0;
	}
}

1;
__END__

=head1 NAME

Geo::IP2Proxy - Reverse search of IP address to detect VPN servers, open proxies, web proxies, Tor exit nodes, search engine robots and data center ranges using IP2Proxy BIN database. Other information available includes proxy type, country, state, city,  ISP, domain name, usage type, AS number, AS name and last seen date.

This pure Perl module uses a file based IP2Proxy .BIN database available at L<IP2Proxy Proxy Detection|https://www.ip2location.com/database/ip2proxy> upon subscription. It supports both IPv4 and IPv6 addressing.

=head1 SYNOPSIS

	use Geo::IP2Proxy;
	my $obj = Geo::IP2Proxy->open("IP2PROXY-IP-PROXYTYPE-COUNTRY-REGION-CITY-ISP-DOMAIN-USAGETYPE-ASN-LASTSEEN.BIN");

	my $packageversion = $obj->getPackageVersion();
	my $dbversion = $obj->getDatabaseVersion();
	my $moduleversion = $obj->getModuleVersion();
	my $countryshort = $obj->getCountryShort("2001:0000:0000:0000:0000:0000:0000:0000");
	my $countrylong = $obj->getCountryLong("1.2.3.4");
	my $region = $obj->getRegion("1.2.3.4");
	my $city = $obj->getCity("1.2.3.4");
	my $isp = $obj->getISP("1.2.3.4");
	my $domain = $obj->getDomain("1.2.3.4");
	my $usagetype = $obj->getUsageType("1.2.3.4");
	my $asn = $obj->getASN("1.2.3.4");
	my $as = $obj->getAS("1.2.3.4");
	my $lastseen = $obj->getLastSeen("1.2.3.4");
	my $proxytype = $obj->getProxyType("1.2.3.4");
	my $isproxy = $obj->isProxy("1.2.3.4");

	($isproxy, $proxytype, $coshort, $colong, $region, $city, $isp, $domain, $usagetype, $asn, $as, $lastseen) = $obj->getAll("1.2.3.4");
	($isproxy, $proxytype, $coshort, $colong, $region, $city, $isp, $domain, $usagetype, $asn, $as, $lastseen) = $obj->getAll("2001:0000:0000:0000:0000:0000:0000:0000");

	$obj->close();

=head1 DESCRIPTION

This Perl module provides fast reverse lookup of IP address to detect VPN servers, open proxies, web proxies, Tor exit nodes, search engine robots and data center ranges using IP2Proxy BIN database. Other information available includes proxy type, country, state, city,  ISP, domain name, usage type, AS number, AS name and last seen date.

This pure Perl module uses a file based IP2Proxy .BIN database available at L<IP2Proxy Product Page|https://www.ip2location.com/database/ip2proxy> upon subscription. You can visit L<Libraries|https://www.ip2location.com/development-libraries> to download BIN sample files. It supports both IPv4 and IPv6 addressing.


=head1 IP2PROXY DATABASES

The complete IPv4 and IPv6 proxy database are available at L<IP2Proxy product page|https://www.ip2location.com/database/ip2proxy>

Meanwhile, sample databases are available at L<IP2Proxy development libraries|https://www.ip2location.com/development-libraries>


The IP2Proxy database is being updated in daily basis for greater accuracy.

Free creative-common monthly database with open proxies data only is available at L<IP2Proxy LITE|https://lite.ip2location.com>


=head1 CLASS METHODS

=over 4

=item $obj = Geo::IP2Proxy->open($database_file);

Constructs a new Geo::IP2Proxy object with the database located at $database_file.

=back

=head1 OBJECT METHODS

=over 4

=item $isproxy = $obj->isProxy( $ip );

Returns 0 if IP address is not a proxy. Returns 1 if it is proxy excluding data center range. Returns 2 if is is data center range. Returns -1 if error.

=item $proxytype = $obj->getProxyType( $ip );

Returns the proxy type of proxy's IP address or domain name. Returns "-" if not a proxy.

  VPN   Anonymizing VPN services.
  TOR   Tor Exit Nodes.
  PUB   Public Proxies.
  WEB   Web Proxies.
  DCH   Hosting Providers/Data Center.
  SES   Search Engine Robots.

=item $countryshort = $obj->getCountryShort( $ip );

Returns the ISO 3166 country code of proxy's IP address or domain name. Returns "-" if not a proxy.

=item $countrylong = $obj->getCountryLong( $ip );

Returns the full country name of proxy's IP address or domain name. Returns "-" if not a proxy.

=item $region = $obj->getRegion( $ip );

Returns the region of proxy's IP address or domain name. Returns "-" if not a proxy.

=item $city = $obj->getCity( $ip );

Returns the city of IP address or domain name. Returns "-" if not a proxy.

=item $isp = $obj->getISP( $ip );

Returns the ISP name of proxy's IP address or domain name. Returns "-" if not a proxy.

=item $domain = $obj->getDomain( $ip );

Returns the domain name of proxy's IP address or domain name. Returns "-" if not a proxy.

=item $usagetype = $obj->getUsageType( $ip );

Returns the ISP's usage type of proxy's IP address or domain name. Returns "-" if not a proxy.

  COM   Commercial
  ORG   Organization
  GOV   Government
  MIL   Military
  EDU   University/College/School
  LIB   Library
  CDN   Content Delivery Network
  ISP   Fixed Line ISP
  MOB   Mobile ISP
  DCH   Data Center/Web Hosting/Transit
  SES   Search Engine Spider
  RSV   Reserved

=item $asn = $obj->getASN( $ip );

Returns the autonomous system number (ASN) of proxy's IP address or domain name. Returns "-" if not a proxy.

=item $as = $obj->getAS( $ip );

Returns the autonomous system (AS) name of proxy's IP address or domain name. Returns "-" if not a proxy.

=item $lastseen = $obj->getLastSeen( $ip );

Returns the last seen days ago value of proxy's IP address or domain name. Returns "-" if not a proxy.

=item ($isproxy, $proxytype, $coshort, $colong, $region, $city, $isp, $domain, $usagetype, $asn, $as, $lastseen) = $obj->getAll( $ip );

Returns an array of proxy status, proxy type, country short and long name, region, city, ISP, domain name, usage type, AS number, AS name and last seen days of proxy's IP address or domain name. Returns "-" in most field if not a proxy.

=item $packageversion = $obj->getPackageVersion();

Returns the package number of IP2Proxy database.

=item $dbversion = $obj->getDatabaseVersion();

Returns the version number of IP2Proxy database.

=item $moduleversion = $obj->getModuleVersion();

Returns the version number of Geo::IP2Proxy Perl module.

=back

=head1 SEE ALSO

L<IP2Proxy Product|https://www.ip2location.com/database/ip2proxy>

=head1 VERSION

2.11

=head1 AUTHOR

Copyright (c) 2019 IP2Location.com

All rights reserved. This package is free software; It is licensed under the GPL.

=cut
