
package Ham::APRS::FAP;

=head1 NAME

Ham::APRS::FAP - Finnish APRS Parser (Fabulous APRS Parser)

=head1 SYNOPSIS

  use Ham::APRS::FAP qw(parseaprs);
  my $aprspacket = 'OH2RDP>BEACON,OH2RDG*,WIDE:!6028.51N/02505.68E#PHG7220/RELAY,WIDE, OH2AP Jarvenpaa';
  my %packetdata;
  my $retval = parseaprs($aprspacket, \%packetdata);
  if ($retval == 1) {
	# decoding ok, do something with the data
	while (my ($key, $value) = each(%packetdata)) {
		print "$key: $value\n";
	}
  } else {
	warn "Parsing failed: $packetdata{resultmsg} ($packetdata{resultcode})\n";
  }

=head1 ABSTRACT

This module is a fairly complete APRS parser. It parses normal,
mic-e and compressed location packets, NMEA location packets,
objects, items, messages, telemetry and most weather packets. It is
stable and fast enough to parse the APRS-IS stream in real time.

The package also contains the Ham::APRS::IS module which, in turn,
is an APRS-IS client library.

=head1 DESCRIPTION

Unless a debugging mode is enabled, all errors and warnings are reported
through the API (as opposed to printing on STDERR or STDOUT), so that
they can be reported nicely on the user interface of an application.
This parser is not known to crash on invalid packets. It is used to power
the L<http://aprs.fi/> web site.

APRS features specifically NOT handled by this module:

=over

=item * special objects (area, signpost, etc)

=item * network tunneling/third party packets

=item * direction finding

=item * station capability queries

=item * status reports (partially)

=item * user defined data formats

=back

This module is based (on those parts that are implemented)
on APRS specification 1.0.1.

This module requires a reasonably recent L<Date::Calc> module.

=head1 EXPORT

None by default.

=head1 FUNCTION REFERENCE

=cut

use strict;
use warnings;
use Date::Calc qw(check_date Today Date_to_Time Add_Delta_YM Mktime);
use Math::Trig;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Ham::APRS::FAP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
##our %EXPORT_TAGS = (
##	'all' => [ qw(
##
##	) ],
##);

our @EXPORT_OK = (
##	@{ $EXPORT_TAGS{'all'} },
	'&parseaprs',
	'&kiss_to_tnc2',
	'&tnc2_to_kiss',
	'&aprs_duplicate_parts',
	'&count_digihops',
	'&check_ax25_call',
	'&distance',
	'&direction',
	'&make_object',
	'&make_timestamp',
	'&make_position',
	'&mice_mbits_to_message',
);

##our @EXPORT = qw(
##	
##);

our $VERSION = '1.21';


# Preloaded methods go here.

# no debugging by default
my $debug = 0;

my %result_messages = (
	'unknown' => 'Unsupported packet format',
	
	'packet_no' => 'No packet given to parse',
	'packet_short' => 'Too short packet',
	'packet_nobody' => 'No body in packet',
	
	'srccall_noax25' => 'Source callsign is not a valid AX.25 call',
	'srccall_badchars' => 'Source callsign contains bad characters',
	
	'dstpath_toomany' => 'Too many destination path components to be AX.25',
	'dstcall_none' => 'No destination field in packet',
	'dstcall_noax25' => 'Destination callsign is not a valid AX.25 call',
	
	'digicall_noax25' => 'Digipeater callsign is not a valid AX.25 call',
	'digicall_badchars' => 'Digipeater callsign contains bad characters',
	
	'timestamp_inv_loc' => 'Invalid timestamp in location',
	'timestamp_inv_obj' => 'Invalid timestamp in object',
	'timestamp_inv_sta' => 'Invalid timestamp in status',
	'timestamp_inv_gpgga' => 'Invalid timestamp in GPGGA sentence',
	'timestamp_inv_gpgll' => 'Invalid timestamp in GPGLL sentence',
	
	'packet_invalid' => 'Invalid packet',
	
	'nmea_inv_cval' => 'Invalid coordinate value in NMEA sentence',
	'nmea_large_ew' => 'Too large value in NMEA sentence (east/west)',
	'nmea_large_ns' => 'Too large value in NMEA sentence (north/south)',
	'nmea_inv_sign' => 'Invalid lat/long sign in NMEA sentence',
	'nmea_inv_cksum' => 'Invalid checksum in NMEA sentence',
	
	'gprmc_fewfields' => 'Less than ten fields in GPRMC sentence ',
	'gprmc_nofix' => 'No GPS fix in GPRMC sentence',
	'gprmc_inv_time' => 'Invalid timestamp in GPRMC sentence',
	'gprmc_inv_date' => 'Invalid date in GPRMC sentence',
	'gprmc_date_out' => 'GPRMC date does not fit in an Unix timestamp',
	
	'gpgga_fewfields' => 'Less than 11 fields in GPGGA sentence',
	'gpgga_nofix' => 'No GPS fix in GPGGA sentence',
	
	'gpgll_fewfields' => 'Less than 5 fields in GPGLL sentence',
	'gpgll_nofix' => 'No GPS fix in GPGLL sentence',
	
	'nmea_unsupp' => 'Unsupported NMEA sentence type',
	
	'obj_short' => 'Too short object',
	'obj_inv' => 'Invalid object',
	'obj_dec_err' => 'Error in object location decoding',
	
	'item_short' => 'Too short item',
	'item_inv' => 'Invalid item',
	'item_dec_err' => 'Error in item location decoding',
	
	'loc_short' => 'Too short uncompressed location',
	'loc_inv' => 'Invalid uncompressed location',
	'loc_large' => 'Degree value too large',
	'loc_amb_inv' => 'Invalid position ambiguity',
	
	'mice_short' => 'Too short mic-e packet',
	'mice_inv' => 'Invalid characters in mic-e packet',
	'mice_inv_info' => 'Invalid characters in mic-e information field',
	'mice_amb_large' => 'Too much position ambiguity in mic-e packet',
	'mice_amb_inv' => 'Invalid position ambiguity in mic-e packet',
	'mice_amb_odd' => 'Odd position ambiguity in mic-e packet',
	
	'comp_inv' => 'Invalid compressed packet',
	
	'msg_inv' => 'Invalid message packet',
	
	'wx_unsupp' => 'Unsupported weather format',
	'user_unsupp' => 'Unsupported user format',
	
	'dx_inv_src' => 'Invalid DX spot source callsign',
	'dx_inf_freq' => 'Invalid DX spot frequency',
	'dx_no_dx' => 'No DX spot callsign found',
	
	'tlm_inv' => 'Invalid telemetry packet',
	'tlm_large' => 'Too large telemetry value',
	'tlm_unsupp' => 'Unsupported telemetry',
	
	'exp_unsupp' => 'Unsupported experimental',
	
	'sym_inv_table' => 'Invalid symbol table or overlay',
);

=over

=item result_messages( )

Returns a reference to a hash containing all possible
return codes as the keys and their plain english descriptions
as the values of the hash.

=back

=cut

sub result_messages()
{
	return \%result_messages;
}

# these functions are used to report warnings and parser errors
# from the module

sub _a_err($$;$)
{
	my ($rethash, $errcode, $val) = @_;
	
	$rethash->{'resultcode'} = $errcode;
	$rethash->{'resultmsg'}
		= defined $result_messages{$errcode}
		? $result_messages{$errcode} : $errcode;
	
	$rethash->{'resultmsg'} .= ': ' . $val if (defined $val);
	
	if ($debug > 0) {
		warn "Ham::APRS::FAP ERROR $errcode: " . $rethash->{'resultmsg'} . "\n";
	}
}

sub _a_warn($$;$)
{
	my ($rethash, $errcode, $val) = @_;
	
	push @{ $rethash->{'warncodes'} }, $errcode;
	
	if ($debug > 0) {
		warn "Ham::APRS::FAP WARNING $errcode: "
		    . (defined $result_messages{$errcode}
		      ? $result_messages{$errcode} : $errcode)
		    . (defined $val ? ": $val" : '')
		    . "\n";
	}
}

# message bit types for mic-e
# from left to right, bits a, b and c
# standard one bit is 1, custom one bit is 2
my %mice_messagetypes = (
	'111' => 'off duty',
	'222' => 'custom 0',
	'110' => 'en route',
	'220' => 'custom 1',
	'101' => 'in service',
	'202' => 'custom 2',
	'100' => 'returning',
	'200' => 'custom 3',
	'011' => 'committed',
	'022' => 'custom 4',
	'010' => 'special',
	'020' => 'custom 5',
	'001' => 'priority',
	'002' => 'custom 6',
	'000' => 'emergency',
);

=over

=item mice_mbits_to_message($packetdata{'mbits'})

Convert mic-e message bits (three numbers 0-2) to a textual message.
Returns the message on success, undef on failure.

=back

=cut

sub mice_mbits_to_message($) {
	my $bits = shift @_;
	if ($bits =~ /^\s*([0-2]{3})\s*$/o) {
		$bits = $1;
		if (defined($mice_messagetypes{$bits})) {
			return $mice_messagetypes{$bits};
		}
	}
	return undef;
}

# A list of mappings from GPSxyz (or SPCxyz)
# to APRS symbols. Overlay characters (z) are
# not handled here
my %dstsymbol = (
	'BB' => q(/!), 'BC' => q(/"), 'BD' => q(/#), 'BE' => q(/$),
	'BF' => q(/%), 'BG' => q(/&), 'BH' => q(/'), 'BI' => q!/(!,
	'BJ' => q!/)!, 'BK' => q(/*), 'BL' => q(/+), 'BM' => q(/,),
	'BN' => q(/-), 'BO' => q(/.), 'BP' => q(//),

	'P0' => q(/0), 'P1' => q(/1), 'P2' => q(/2), 'P3' => q(/3),
	'P4' => q(/4), 'P5' => q(/5), 'P6' => q(/6), 'P7' => q(/7),
	'P8' => q(/8), 'P9' => q(/9),

	'MR' => q(/:), 'MS' => q(/;), 'MT' => q(/<), 'MU' => q(/=),
	'MV' => q(/>), 'MW' => q(/?), 'MX' => q(/@),

	'PA' => q(/A), 'PB' => q(/B), 'PC' => q(/C), 'PD' => q(/D),
	'PE' => q(/E), 'PF' => q(/F), 'PG' => q(/G), 'PH' => q(/H),
	'PI' => q(/I), 'PJ' => q(/J), 'PK' => q(/K), 'PL' => q(/L),
	'PM' => q(/M), 'PN' => q(/N), 'PO' => q(/O), 'PP' => q(/P),
	'PQ' => q(/Q), 'PR' => q(/R), 'PS' => q(/S), 'PT' => q(/T),
	'PU' => q(/U), 'PV' => q(/V), 'PW' => q(/W), 'PX' => q(/X),
	'PY' => q(/Y), 'PZ' => q(/Z),

	'HS' => q(/[), 'HT' => q(/\\), 'HU' => q(/]), 'HV' => q(/^),
	'HW' => q(/_), 'HX' => q(/`),

	'LA' => q(/a), 'LB' => q(/b), 'LC' => q(/c), 'LD' => q(/d),
	'LE' => q(/e), 'LF' => q(/f), 'LG' => q(/g), 'LH' => q(/h),
	'LI' => q(/i), 'LJ' => q(/j), 'LK' => q(/k), 'LL' => q(/l),
	'LM' => q(/m), 'LN' => q(/n), 'LO' => q(/o), 'LP' => q(/p),
	'LQ' => q(/q), 'LR' => q(/r), 'LS' => q(/s), 'LT' => q(/t),
	'LU' => q(/u), 'LV' => q(/v), 'LW' => q(/w), 'LX' => q(/x),
	'LY' => q(/y), 'LZ' => q(/z),

	'J1' => q(/{), 'J2' => q(/|), 'J3' => q(/}), 'J4' => q(/~),

	'OB' => q(\\!), 'OC' => q(\\"), 'OD' => q(\\#), 'OE' => q(\\$),
	'OF' => q(\\%), 'OG' => q(\\&), 'OH' => q(\\'), 'OI' => q!\\(!,
	'OJ' => q!\\)!, 'OK' => q(\\*), 'OL' => q(\\+), 'OM' => q(\\,),
	'ON' => q(\\-), 'OO' => q(\\.), 'OP' => q(\\/),

	'A0' => q(\\0), 'A1' => q(\\1), 'A2' => q(\\2), 'A3' => q(\\3),
	'A4' => q(\\4), 'A5' => q(\\5), 'A6' => q(\\6), 'A7' => q(\\7),
	'A8' => q(\\8), 'A9' => q(\\9),

	'NR' => q(\\:), 'NS' => q(\\;), 'NT' => q(\\<), 'NU' => q(\\=),
	'NV' => q(\\>), 'NW' => q(\\?), 'NX' => q(\\@),

	'AA' => q(\\A), 'AB' => q(\\B), 'AC' => q(\\C), 'AD' => q(\\D),
	'AE' => q(\\E), 'AF' => q(\\F), 'AG' => q(\\G), 'AH' => q(\\H),
	'AI' => q(\\I), 'AJ' => q(\\J), 'AK' => q(\\K), 'AL' => q(\\L),
	'AM' => q(\\M), 'AN' => q(\\N), 'AO' => q(\\O), 'AP' => q(\\P),
	'AQ' => q(\\Q), 'AR' => q(\\R), 'AS' => q(\\S), 'AT' => q(\\T),
	'AU' => q(\\U), 'AV' => q(\\V), 'AW' => q(\\W), 'AX' => q(\\X),
	'AY' => q(\\Y), 'AZ' => q(\\Z),

	'DS' => q(\\[), 'DT' => q(\\\\), 'DU' => q(\\]), 'DV' => q(\\^),
	'DW' => q(\\_), 'DX' => q(\\`),

	'SA' => q(\\a), 'SB' => q(\\b), 'SC' => q(\\c), 'SD' => q(\\d),
	'SE' => q(\\e), 'SF' => q(\\f), 'SG' => q(\\g), 'SH' => q(\\h),
	'SI' => q(\\i), 'SJ' => q(\\j), 'SK' => q(\\k), 'SL' => q(\\l),
	'SM' => q(\\m), 'SN' => q(\\n), 'SO' => q(\\o), 'SP' => q(\\p),
	'SQ' => q(\\q), 'SR' => q(\\r), 'SS' => q(\\s), 'ST' => q(\\t),
	'SU' => q(\\u), 'SV' => q(\\v), 'SW' => q(\\w), 'SX' => q(\\x),
	'SY' => q(\\y), 'SZ' => q(\\z),

	'Q1' => q(\\{), 'Q2' => q(\\|), 'Q3' => q(\\}), 'Q4' => q(\\~),
);

# conversion constants
our $knot_to_kmh = 1.852; # nautical miles per hour to kilometers per hour
our $mph_to_kmh = 1.609344; # miles per hour to kilometers per hour
our $kmh_to_ms = 10 / 36; # kilometers per hour to meters per second
our $mph_to_ms = $mph_to_kmh * $kmh_to_ms; # miles per hour to meters per second
our $hinch_to_mm = 0.254; # hundredths of an inch to millimeters
our $feet_to_meters = 0.3048;

=over

=item debug($enable)

Enables (debug(1)) or disables (debug(0)) debugging.

When debugging is enabled, warnings and errors are emitted using the warn() function,
which will normally result in them being printed on STDERR. Succesfully
printed packets will be also printed on STDOUT in a human-readable
format.

When debugging is disabled, nothing will be printed on STDOUT or STDERR -
all errors and parsing results need to be collected from the returned
hash reference.

=back

=cut

sub debug($)
{
	my $dval = shift @_;
	if ($dval) {
		$debug = 1;
	} else {
		$debug = 0;
	}
}

# Return a human readable timestamp in UTC.
# If no parameter is given, use current time,
# else use the unix timestamp given in the parameter.

sub _gettime {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday);
	if (scalar(@_) >= 1) {
		my $tstamp = shift @_;
		($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime($tstamp);
	} else {
		($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime();
	}
	my $timestring = sprintf('%d-%02d-%02d %02d:%02d:%02d UTC',
		$year + 1900,
		$mon + 1,
		$mday,
		$hour,
		$min,
		$sec);
	return $timestring;
}

=over

=item distance($lon0, $lat0, $lon1, $lat1)

Returns the distance in kilometers between two locations
given in decimal degrees. Arguments are given in order as
lon0, lat0, lon1, lat1, east and north positive.
The calculation uses the great circle distance, it
is not too exact, but good enough for us.

=back

=cut

sub distance($$$$) {
	my $lon0 = shift @_;
	my $lat0 = shift @_;
	my $lon1 = shift @_;
	my $lat1 = shift @_;
	
	# decimal to radian
	$lon0 = deg2rad($lon0);
	$lon1 = deg2rad($lon1);
	$lat0 = deg2rad($lat0);
	$lat1 = deg2rad($lat1);
	
	# Use the haversine formula for distance calculation
	# http://mathforum.org/library/drmath/view/51879.html
	my $dlon = $lon1 - $lon0;
	my $dlat = $lat1 - $lat0;
	my $a = (sin($dlat/2)) ** 2 + cos($lat0) * cos($lat1) * (sin($dlon/2)) ** 2;
	my $c = 2 * atan2(sqrt($a), sqrt(1-$a));
	my $distance = $c * 6366.71; # in kilometers

	return $distance;
}

=over

=item direction($lon0, $lat0, $lon1, $lat1)

Returns the initial great circle direction in degrees
from lat0/lon0 to lat1/lon1. Locations are input
in decimal degrees, north and east positive.

=back

=cut

sub direction($$$$) {
	my $lon0 = shift @_;
	my $lat0 = shift @_;
	my $lon1 = shift @_;
	my $lat1 = shift @_;

	$lon0 = deg2rad($lon0);
	$lon1 = deg2rad($lon1);
	$lat0 = deg2rad($lat0);
	$lat1 = deg2rad($lat1);

	# direction from Aviation Formulary V1.42 by Ed Williams
	# by way of http://mathforum.org/library/drmath/view/55417.html
	my $direction = atan2(sin($lon1-$lon0)*cos($lat1),
		cos($lat0)*sin($lat1)-sin($lat0)*cos($lat1)*cos($lon1-$lon0));
	if ($direction < 0) {
		# make direction positive
		$direction += 2 * pi;
	}

	return rad2deg($direction);
}

=over

=item count_digihops($header)

Count the number of digipeated hops in a (KISS) packet and
return it. Returns -1 in case of error.
The header parameter can contain the full packet or just the header
in TNC2 format. All callsigns in the header must be AX.25 compatible
and remember that the number returned is just an educated guess, not
absolute truth.

=back

=cut

sub count_digihops($) {
	my $header = shift @_;

	# Do a rough check on the header syntax
	$header =~ tr/\r\n//d;
	$header = uc($header);
	if ($header =~ /^([^:]+):/o) {
		# remove data part of packet, if present
		$header = $1;
	}
	my $hops = undef;
	if ($header =~ /^([A-Z0-9-]+)\>([A-Z0-9-]+)$/o) {
		# check the callsigns for validity
		my $retval = check_ax25_call($1);
		if (not(defined($retval))) {
			if ($debug > 0) {
				warn "count_digihops: invalid source callsign ($1)\n";
			}
			return -1;
		}
		$retval = check_ax25_call($2);
		if (not(defined($retval))) {
			if ($debug > 0) {
				warn "count_digihops: invalid destination callsign ($2)\n";
			}
			return -1;
		}
		# no path at all, so zero hops
		return 0;

	} elsif ($header =~ /^([A-Z0-9-]+)\>([A-Z0-9-]+),([A-Z0-9,*-]+)$/o) {
		my $retval = check_ax25_call($1);
		if (not(defined($retval))) {
			if ($debug > 0) {
				warn "count_digihops: invalid source callsign ($1)\n";
			}
			return -1;
		}
		$retval = check_ax25_call($2);
		if (not(defined($retval))) {
			if ($debug > 0) {
				warn "count_digihops: invalid destination callsign ($2)\n";
			}
			return -1;
		}
		# some hops
		$hops = $3;

	} else {
		# invalid
		if ($debug > 0) {
			warn "count_digihops: invalid packet header\n";
		}
		return -1;
	}

	my $hopcount = 0;
	# split the path into parts
	my @parts = split(/,/, $hops);
	# now examine the parts one by one
	foreach my $piece (@parts) {
		# remove the possible "digistar" from the end of callsign
		# and take note of its existence
		my $wasdigied = 0;
		if ($piece =~ /^[A-Z0-9-]+\*$/o) {
			$wasdigied = 1;
			$piece =~ s/\*$//;
		}
		# check the callsign for validity and expand it
		my $call = check_ax25_call($piece);
		if (not(defined($call))) {
			if ($debug > 0) {
				warn "count_digihops: invalid callsign in path ($piece)\n";
			}
			return -1;
		}
		# check special cases, wideN-N and traceN-N for now
		if ($call =~ /^WIDE([1-7])-([0-7])$/o) {
			my $difference = $1 - $2;
			if ($difference < 0) {
				# ignore reversed N-N
				if ($debug > 0) {
					warn "count_digihops: reversed N-N in path ($call)\n";
				}
				next;
			}
			$hopcount += $difference;

		} elsif ($call =~ /^TRACE([1-7])-([0-7])$/o) {
			# skip traceN-N because the hops are already individually shown
			# before this
			next;

		} else {
			# just a normal packet. if "digistar" is there,
			# increment the digicounter by one
			if ($wasdigied == 1) {
				$hopcount++;
			}
		}
	}

	return $hopcount;
}


# Return a unix timestamp based on an
# APRS six (+ one char for type) character timestamp.
# If an invalid timestamp is given, return 0.
sub _parse_timestamp($$) {
	my($options, $stamp) = @_;
	
	# Check initial format
	return 0 if ($stamp !~ /^(\d{2})(\d{2})(\d{2})(z|h|\/)$/o);
	
	return "$1$2$3" if ($options->{'raw_timestamp'});
	
	my $stamptype = $4;
	
	if ($stamptype eq 'h') {
		# HMS format
		my $hour = $1;
		my $minute = $2;
		my $second = $3;
		
		# Check for invalid time
		if ($hour > 23 || $minute > 59 || $second > 59) {
			return 0;
		}
		
		# All calculations here are in UTC, but
		# if this is run under old MacOS (pre-OSX), then
		# Date_to_Time could be in local time..
		my $currenttime = time();
		my ($cyear, $cmonth, $cday) = Today(1);
		my $tstamp = Date_to_Time($cyear, $cmonth, $cday, $hour, $minute, $second);
		
		# If the time is more than about one hour
		# into the future, roll the timestamp
		# one day backwards.
		if ($currenttime + 3900 < $tstamp) {
			$tstamp -= 86400;
			# If the time is more than about 23 hours
			# into the past, roll the timestamp one
			# day forwards.
		} elsif ($currenttime - 82500 > $tstamp) {
			$tstamp += 86400;
		}
		return $tstamp;

	} elsif ($stamptype eq 'z' ||
		 $stamptype eq '/') {
		# Timestamp is DHM, UTC (z) or local (/).
		# Always intepret local to mean local
		# to this computer.
		my $day = $1;
		my $hour = $2;
		my $minute = $3;
		
		if ($day < 1 || $day > 31 || $hour > 23 || $minute > 59) {
			return 0;
		}
		
		# If time is under about 12 hours into
		# the future, go there.
		# Otherwise get the first matching
		# time in the past.
		my $currenttime = time();
		my ($cyear, $cmonth, $cday);
		if ($stamptype eq 'z') {
			($cyear, $cmonth, $cday) = Today(1);
		} else {
			($cyear, $cmonth, $cday) = Today(0);
		}
		# Form the possible timestamps in
		# this, the next and the previous month
		my ($fwdyear, $fwdmonth) = (Add_Delta_YM($cyear, $cmonth, $cday, 0, 1))[0,1];
		my ($backyear, $backmonth) = (Add_Delta_YM($cyear, $cmonth, $cday, 0, -1))[0,1];
		my $fwdtstamp = undef;
		my $currtstamp = undef;
		my $backtstamp = undef;
		if (check_date($cyear, $cmonth, $day)) {
			if ($stamptype eq 'z') {
				$currtstamp = Date_to_Time($cyear, $cmonth, $day, $hour, $minute, 0);
			} else {
				$currtstamp = Mktime($cyear, $cmonth, $day, $hour, $minute, 0);
			}
		}
		if (check_date($fwdyear, $fwdmonth, $day)) {
			if ($stamptype eq 'z') {
				$fwdtstamp = Date_to_Time($fwdyear, $fwdmonth, $day, $hour, $minute, 0);
			} else {
				$fwdtstamp = Mktime($cyear, $cmonth, $day, $hour, $minute, 0);
			}
		}
		if (check_date($backyear, $backmonth, $day)) {
			if ($stamptype eq 'z') {
				$backtstamp = Date_to_Time($backyear, $backmonth, $day, $hour, $minute, 0);
			} else {
				$backtstamp = Mktime($cyear, $cmonth, $day, $hour, $minute, 0);
			}
		}
		# Select the timestamp to use. Pick the timestamp
		# that is largest, but under about 12 hours from
		# current time.
		if (defined($fwdtstamp) && ($fwdtstamp - $currenttime) < 43400) {
			return $fwdtstamp;
		} elsif (defined($currtstamp) && ($currtstamp - $currenttime) < 43400) {
			return $currtstamp;
		} elsif (defined($backtstamp)) {
			return $backtstamp;
		}
	}

	# return failure if we haven't returned with
	# a success earlier
	return 0;
}

# clean up a comment string - remove control codes
# but stay UTF-8 clean
sub _cleanup_comment($)
{
	$_[0] =~ tr/[\x20-\x7e\x80-\xfe]//cd;
	$_[0] =~ s/^\s+//;
	$_[0] =~ s/\s+$//;
	
	return $_[0];
}

# Return position resolution in meters based on the number
# of minute decimal digits. Also accepts negative numbers,
# i.e. -1 for 10 minute resolution and -2 for 1 degree resolution.
# Calculation is based on latitude so it is worst case
# (resolution in longitude gets better as you get closer to the poles).
sub _get_posresolution($)
{
	return $knot_to_kmh * ($_[0] <= -2 ? 600 : 1000) * 10 ** (-1 * $_[0]);
}


# return an NMEA latitude or longitude.
# 1st parameter is the (dd)dmm.m(mmm..) string and
# 2nd is the north/south or east/west indicator
# returns undef on error. The returned value
# is decimal degrees, north and east positive.
sub _nmea_getlatlon($$$)
{
	my ($value, $sign, $rh) = @_;
	
	# upcase the sign for compatibility
	$sign = uc($sign);

	# Be leninent on what to accept, anything
	# goes as long as degrees has 1-3 digits,
	# minutes has 2 digits and there is at least
	# one decimal minute.
	if ($value =~ /^\s*(\d{1,3})([0-5][0-9])\.(\d+)\s*$/o) {
		my $minutes = $2 . '.' . $3;
		$value = $1 + ($minutes / 60);
		# capture position resolution in meters based
		# on the amount of minute decimals present
		$rh->{'posresolution'} = _get_posresolution(length($3));
	} else {
		_a_err($rh, 'nmea_inv_cval', $value);
		return undef;
	}

	if ($sign =~ /^\s*[EW]\s*$/o) {
		# make sure the value is ok
		if ($value > 179.999999) {
			_a_err($rh, 'nmea_large_ew', $value);
			return undef;
		}
		# west negative
		if ($sign =~ /^\s*W\s*$/o) {
			$value *= -1;
		}
	} elsif ($sign =~ /^\s*[NS]\s*$/o) {
		# make sure the value is ok
		if ($value > 89.999999) {
			_a_err($rh, 'nmea_large_ns', $value);
			return undef;
		}
		# south negative
		if ($sign =~ /^\s*S\s*$/o) {
			$value *= -1;
		}
	} else {
		# incorrect sign
		_a_err($rh, 'nmea_inv_sign', $sign);
		return undef;
	}

	# all ok
	return $value;
}


# return a two element array, first containing
# the symbol table id (or overlay) and second
# containing symbol id. return undef in error
sub _get_symbol_fromdst($) {
	my $dstcallsign = shift @_;

	my $table = undef;
	my $code = undef;

	if ($dstcallsign =~ /^(GPS|SPC)([A-Z0-9]{2,3})/o) {
		my $leftoverstring = $2;
		my $type = substr($leftoverstring, 0, 1);
		my $sublength = length($leftoverstring);
		if ($sublength == 3) {
			if ($type eq 'C' || $type eq 'E') {
				my $numberid = substr($leftoverstring, 1, 2);
				if ($numberid =~ /^(\d{2})$/o &&
				    $numberid > 0 &&
				    $numberid < 95) {
					$code = chr($1 + 32);
					if ($type eq 'C') {
						$table = '/';
					} else {
						$table = "\\";
					}
					return ($table, $code);
				} else {
					return undef;
				}
			} else {
				# secondary symbol table, with overlay
				# Check first that we really are in the
				# secondary symbol table
				my $dsttype = substr($leftoverstring, 0, 2);
				my $overlay = substr($leftoverstring, 2, 1);
				if (($type eq 'O' ||
				    $type eq 'A' ||
				    $type eq 'N' ||
				    $type eq 'D' ||
				    $type eq 'S' ||
				    $type eq 'Q') && $overlay =~ /^[A-Z0-9]$/o) {
					if (defined($dstsymbol{$dsttype})) {
						$code = substr($dstsymbol{$dsttype}, 1, 1);
						return ($overlay, $code);
					} else {
						return undef;
					}
				} else {
					return undef;
				}
			}
		} else {
			# primary or secondary symbol table, no overlay
			if (defined($dstsymbol{$leftoverstring})) {
				$table = substr($dstsymbol{$leftoverstring}, 0, 1);
				$code = substr($dstsymbol{$leftoverstring}, 1, 1);
				return ($table, $code);
			} else {
				return undef;
			}
		}
	} else {
		return undef;
	}

	# failsafe catch-all
	return undef;
}


# Parse an NMEA location
sub _nmea_to_decimal($$$$$) {
	#(substr($body, 1), $srccallsign, $dstcallsign, \%poshash)
	my($options, $body, $srccallsign, $dstcallsign, $rethash) = @_;

	if ($debug > 1) {
		# print packet, after stripping control chars
		my $printbody = $body;
		$printbody =~ tr/[\x00-\x1f]//d;
		warn "NMEA: from $srccallsign to $dstcallsign: $printbody\n";
	}

	# verify checksum first, if it is provided
	$body =~ s/\s+$//; # remove possible white space from the end
	if ($body =~ /^([\x20-\x7e]+)\*([0-9A-F]{2})$/io) {
		my $checksumarea = $1;
		my $checksumgiven = hex($2);
		my $checksumcalculated = 0;
		for (my $i = 0; $i < length($checksumarea); $i++) {
			$checksumcalculated ^= ord(substr($checksumarea, $i, 1));
		}
		if ($checksumgiven != $checksumcalculated) {
			# invalid checksum
			_a_err($rethash, 'nmea_inv_cksum');
			return 0;
		}
		# make a note of the existance of a checksum
		$rethash->{'checksumok'} = 1;
	}

	# checksum ok or not provided

	$rethash->{'format'} = 'nmea';
	
	# use a dot as a default symbol if one is not defined in
	# the destination callsign
	my ($symtable, $symcode) = _get_symbol_fromdst($dstcallsign);
	if (not(defined($symtable)) || not(defined($symcode))) {
		$rethash->{'symboltable'} = '/';
		$rethash->{'symbolcode'} = '/';
	} else {
		$rethash->{'symboltable'} = $symtable;
		$rethash->{'symbolcode'} = $symcode;
	}

	# Split to NMEA fields
	$body =~ s/\*[0-9A-F]{2}$//; # remove checksum from body first
	my @nmeafields = split(/,/, $body);

	# Now check the sentence type and get as much info
	# as we can (want).
	if ($nmeafields[0] eq 'GPRMC') {
		# we want at least 10 fields
		if (@nmeafields < 10) {
			_a_err($rethash, 'gprmc_fewfields', scalar(@nmeafields));
			return 0;
		}

		if ($nmeafields[2] ne 'A') {
			# invalid position
			_a_err($rethash, 'gprmc_nofix');
			return 0;
		}

		# check and save the timestamp
		my ($hour, $minute, $second);
		if ($nmeafields[1] =~ /^\s*(\d{2})(\d{2})(\d{2})(|\.\d+)\s*$/o) {
			# if seconds has a decimal part, ignore it
			# leap seconds are not taken into account...
			if ($1 > 23 || $2 > 59 || $3 > 59) {
				_a_err($rethash, 'gprmc_inv_time', $nmeafields[1]);
				return 0;
			}
			$hour = $1 + 0; # force numeric
			$minute = $2 + 0;
			$second = $3 + 0;
		} else {
			_a_err($rethash, 'gprmc_inv_time');
			return 0;
		}
		my ($year, $month, $day);
		if ($nmeafields[9] =~ /^\s*(\d{2})(\d{2})(\d{2})\s*$/o) {
			# check the date for validity. Assume
			# years 0-69 are 21st century and years
			# 70-99 are 20th century
			$year = 2000 + $3;
			if ($3 >= 70) {
				$year = 1900 + $3;
			}
			# check for invalid date
			if (not(check_date($year, $2, $1))) {
				_a_err($rethash, 'gprmc_inv_date', "$year $2 $1");
				return 0;
			}
			$month = $2 + 0; # force numeric
			$day = $1 + 0;
		} else {
			_a_err($rethash, 'gprmc_inv_date');
			return 0;
		}
		# Date_to_Time() can only handle 32-bit unix timestamps,
		# so make sure it is not used for those years that
		# are outside that range.
		if ($year >= 2038 || $year < 1970) {
			$rethash->{'timestamp'} = 0;
			_a_err($rethash, 'gprmc_date_out', $year);
			return 0;
		} else {
			$rethash->{'timestamp'} = Date_to_Time($year, $month, $day, $hour, $minute, $second);
		}

		# speed (knots) and course, make these optional
		# in the parsing sense (don't fail if speed/course
		# can't be decoded).
		if ($nmeafields[7] =~ /^\s*(\d+(|\.\d+))\s*$/o) {
			# convert to km/h
			$rethash->{'speed'} = $1 * $knot_to_kmh;
		}
		if ($nmeafields[8] =~ /^\s*(\d+(|\.\d+))\s*$/o) {
			# round to nearest integer
			my $course = int($1 + 0.5);
			# if zero, set to 360 because in APRS
			# zero means invalid course...
			if ($course == 0) {
				$course = 360;
			} elsif ($course > 360) {
				$course = 0; # invalid
			}
			$rethash->{'course'} = $course;
		} else {
			$rethash->{'course'} = 0; # unknown
		}

		# latitude and longitude
		my $latitude = _nmea_getlatlon($nmeafields[3], $nmeafields[4], $rethash);
		if (not(defined($latitude))) {
			return 0;
		}
		$rethash->{'latitude'} = $latitude;
		my $longitude = _nmea_getlatlon($nmeafields[5], $nmeafields[6], $rethash);
		if (not(defined($longitude))) {
			return 0;
		}
		$rethash->{'longitude'} = $longitude;

		# we have everything we want, return
		return 1;

	} elsif ($nmeafields[0] eq 'GPGGA') {
		# we want at least 11 fields
		if (@nmeafields < 11) {
			_a_err($rethash, 'gpgga_fewfields', scalar(@nmeafields));
			return 0;
		}

		# check for position validity
		if ($nmeafields[6] =~ /^\s*(\d+)\s*$/o) {
			if ($1 < 1) {
				_a_err($rethash, 'gpgga_nofix', $1);
				return 0;
			}
		} else {
			_a_err($rethash, 'gpgga_nofix');
			return 0;
		}

		# Use the APRS time parsing routines to check
		# the time and convert it to timestamp.
		# But before that, remove a possible decimal part
		$nmeafields[1] =~ s/\.\d+$//;
		$rethash->{'timestamp'} = _parse_timestamp($options, $nmeafields[1] . 'h');
		if ($rethash->{'timestamp'} == 0) {
			_a_err($rethash, 'timestamp_inv_gpgga');
			return 0;
		}

		# latitude and longitude
		my $latitude = _nmea_getlatlon($nmeafields[2], $nmeafields[3], $rethash);
		if (not(defined($latitude))) {
			return 0;
		}
		$rethash->{'latitude'} = $latitude;
		my $longitude = _nmea_getlatlon($nmeafields[4], $nmeafields[5], $rethash);
		if (not(defined($longitude))) {
			return 0;
		}
		$rethash->{'longitude'} = $longitude;

		# altitude, only meters are accepted
		if ($nmeafields[10] eq 'M' &&
		    $nmeafields[9] =~ /^(-?\d+(|\.\d+))$/o) {
			# force numeric interpretation
			$rethash->{'altitude'} = $1 + 0;
		}

		# ok
		return 1;

	} elsif ($nmeafields[0] eq 'GPGLL') {
		# we want at least 5 fields
		if (@nmeafields < 5) {
			_a_err($rethash, 'gpgll_fewfields', scalar(@nmeafields));
			return 0;
		}

		# latitude and longitude
		my $latitude = _nmea_getlatlon($nmeafields[1], $nmeafields[2], $rethash);
		if (not(defined($latitude))) {
			return 0;
		}
		$rethash->{'latitude'} = $latitude;
		my $longitude = _nmea_getlatlon($nmeafields[3], $nmeafields[4], $rethash);
		if (not(defined($longitude))) {
			return 0;
		}
		$rethash->{'longitude'} = $longitude;

		# Use the APRS time parsing routines to check
		# the time and convert it to timestamp.
		# But before that, remove a possible decimal part
		if (@nmeafields >= 6) {
			$nmeafields[5] =~ s/\.\d+$//;
			$rethash->{'timestamp'} = _parse_timestamp($options, $nmeafields[5] . 'h');
			if ($rethash->{'timestamp'} == 0) {
				_a_err($rethash, 'timestamp_inv_gpgll');
				return 0;
			}
		}

		if (@nmeafields >= 7) {
			# GPS fix validity supplied
			if ($nmeafields[6] ne 'A') {
				_a_err($rethash, 'gpgll_nofix');
				return 0;
			}
		}

		# ok
		return 1;

	##} elsif ($nmeafields[0] eq 'GPVTG') {
	##} elsif ($nmeafields[0] eq 'GPWPT') {
	} else {
		$nmeafields[0] =~ tr/[\x00-\x1f]//d;
		_a_err($rethash, 'nmea_unsupp', $nmeafields[0]);
		return 0;
	}

	return 0;
}


# Parse the possible APRS data extension
# as well as comment
sub _comments_to_decimal($$$) {
	my $rest = shift @_;
	my $srccallsign = shift @_;
	my $rethash = shift @_;
	
	# First check the possible APRS data extension,
	# immediately following the packet
	if (length($rest) >= 7) {
		if ($rest =~ /^([0-9. ]{3})\/([0-9. ]{3})/o) {
			my $course = $1;
			my $speed = $2;
			if ($course =~ /^\d{3}$/o &&
			    $course <= 360 &&
			    $course >= 1) {
				# force numeric interpretation
				$course += 0;
				$rethash->{'course'} = $course;
			} else {
				# course is invalid, set it to zero
				$rethash->{'course'} = 0;
			}
			if ($speed =~ /^\d{3}$/o) {
				# force numeric interpretation
				# and convert to km/h
				$rethash->{'speed'} = $speed * $knot_to_kmh;
			} else {
				# If speed is invalid, don't set it
				# (zero speed is a valid speed).
			}
			$rest = substr($rest, 7);

		} elsif ($rest =~ /^PHG(\d[\x30-\x7e]\d\d[0-9A-Z])\//o) {
			# PHGR
			$rethash->{'phg'} = $1;
			$rest = substr($rest, 8);

		} elsif ($rest =~ /^PHG(\d[\x30-\x7e]\d\d)/o) {
			# don't do anything fancy with PHG, just store it
			$rethash->{'phg'} = $1;
			$rest = substr($rest, 7);

		} elsif ($rest =~ /^RNG(\d{4})/o) {
			# radio range, in miles, so convert
			# to km
			$rethash->{'radiorange'} = $1 * $mph_to_kmh;
			$rest = substr($rest, 7);
		}
	}

	# Check for optional altitude anywhere in the comment,
	# take the first occurrence
	if ($rest =~ /^(.*?)\/A=(-\d{5}|\d{6})(.*)$/o) {
		# convert to meters as well
		$rethash->{'altitude'} = $2 * $feet_to_meters;
		$rest = $1 . $3;
	}

	# Check for new-style base-91 comment telemetry
	$rest = _comment_telemetry($rethash, $rest);
	
	# Check for !DAO!, take the last occurrence (per recommendation)
	if ($rest =~ /^(.*)\!([\x21-\x7b][\x20-\x7b]{2})\!(.*?)$/o) {
		my $daofound = _dao_parse($2, $srccallsign, $rethash);
		if ($daofound == 1) {
			$rest = $1 . $3;
		}
	}
	
	# Strip a / or a ' ' from the beginning of a comment
	# (delimiter after PHG or other data stuffed within the comment)
	$rest =~ s/^[\/\s]//;
	
	# Save the rest as a separate comment, if
	# anything is left (trim unprintable chars
	# out first and white space from both ends)
	if (length($rest) > 0) {
		$rethash->{'comment'} = _cleanup_comment($rest);
	}

	# Always succeed as these are optional
	return 1;
}

# Parse an object
sub _object_to_decimal($$$$) {
	my($options, $packet, $srccallsign, $rethash) = @_;

	# Minimum length for an object is 31 characters
	# (or 46 characters for non-compressed)
	if (length($packet) < 31) {
		_a_err($rethash, 'obj_short');
		return 0;
	}

	# Parse the object up to the location
	my $timestamp = undef;
	if ($packet =~ /^;([\x20-\x7e]{9})(\*|_)(\d{6})(z|h|\/)/o) {
		# hash member 'objectname' signals an object
		$rethash->{'objectname'} = $1;
		if ($2 eq '*') {
			$rethash->{'alive'} = 1;
		} else {
			$rethash->{'alive'} = 0;
		}
		$timestamp = $3 . $4;
	} else {
		_a_err($rethash, 'obj_inv');
		return 0;
	}

	# Check the timestamp for validity and convert
	# to UNIX epoch. If the timestamp is invalid, set it
	# to zero.
	$rethash->{'timestamp'} = _parse_timestamp($options, $timestamp);
	if ($rethash->{'timestamp'} == 0) {
		_a_warn($rethash, 'timestamp_inv_obj');
	}

	# Forward the location parsing onwards
	my $locationoffset = 18; # object location always starts here
	my $locationchar = substr($packet, $locationoffset, 1);
	my $retval = undef;
	if ($locationchar =~ /^[\/\\A-Za-j]$/o) {
		# compressed
		$retval = _compressed_to_decimal(substr($packet, $locationoffset, 13), $srccallsign, $rethash);
		$locationoffset += 13; # now points to APRS data extension/comment
	} elsif ($locationchar =~ /^\d$/io) {
		# normal
		$retval = _normalpos_to_decimal(substr($packet, $locationoffset), $srccallsign, $rethash);
		$locationoffset += 19; # now points to APRS data extension/comment
	} else {
		# error
		_a_err($rethash, 'obj_dec_err');
		return 0;
	}
	return 0 if ($retval != 1);

	# Check the APRS data extension and possible comments,
	# unless it is a weather report (we don't want erroneus
	# course/speed figures and weather in the comments..)
	if ($rethash->{'symbolcode'} ne '_') {
		_comments_to_decimal(substr($packet, $locationoffset), $srccallsign, $rethash);
	} else {
		# possibly a weather object, try to parse
		_wx_parse(substr($packet, $locationoffset), $rethash);
	}

	return 1;
}

# Parse a status report. Only timestamps
# and text report are supported. Maidenhead,
# beam headings and symbols are not.
sub _status_parse($$$$) {
	my($options, $packet, $srccallsign, $rethash) = @_;

	# Remove CRs, LFs and trailing spaces
	$packet =~ tr/\r\n//d;
	$packet =~ s/\s+$//;

	# Check for a timestamp
	if ($packet =~ /^(\d{6}z)/o) {
		$rethash->{'timestamp'} = _parse_timestamp({}, $1);
		_a_warn($rethash, 'timestamp_inv_sta') if ($rethash->{'timestamp'} == 0);
		$packet = substr($packet, 7);
	}

	# Save the rest as the report
	$rethash->{'status'} = $packet;

	return 1;
}

# Parse a station capabilities packet
sub _capabilities_parse($$$) {
	my $packet = shift @_;
	my $srccallsign = shift @_;
	my $rethash = shift @_;

	# Remove CRs, LFs and trailing spaces
	$packet =~ tr/\r\n//d;
	$packet =~ s/\s+$//;
	# Then just split the packet, we aren't too picky about the format here.
	# Also duplicates and case changes are not handled in any way,
	# so the last part will override an earlier part and different
	# cases can be present. Just remove trailing/leading spaces.
	my @caps = split(/,/, $packet);
	my %caphash = ();
	foreach my $cap (@caps) {
		if ($cap =~ /^\s*([^=]+?)\s*=\s*(.*?)\s*$/o) {
			# TOKEN=VALUE
			$caphash{$1} = $2;
		} elsif ($cap =~ /^\s*([^=]+?)\s*$/o) {
			# just TOKEN
			$caphash{$1} = undef;
		}
	}

	my $keycount = keys(%caphash);
	if ($keycount > 0) {
		# store the capabilities in the return hash
		$rethash->{'capabilities'} = \%caphash;
		return 1;
	}
	
	# at least one capability has to be defined for a capability
	# packet to be counted as valid
	return 0;
}

# Parse a message
# possible TODO: ack piggybacking
sub _message_parse($$$) {
	my $packet = shift @_;
	my $srccallsign = shift @_;
	my $rethash = shift @_;

	# Check format
	if ($packet =~ /^:([A-Za-z0-9_ -]{9}):([\x20-\x7e\x80-\xfe]+)$/o) {
		my $destination = $1;
		my $message = $2;
		# remove trailing spaces from the recipient
		$destination =~ s/\s+$//;
		$rethash->{'destination'} = $destination;
		# check whether this is an ack
		if ($message =~ /^ack([A-Za-z0-9}]{1,5})\s*$/o) {
			# trailing spaces are allowed because some
			# broken software insert them..
			$rethash->{'messageack'} = $1;
			return 1;
		}
		# check whether this is a message reject
		if ($message =~ /^rej([A-Za-z0-9}]{1,5})\s*$/o) {
			$rethash->{'messagerej'} = $1;
			return 1;
		}
		# separate message-id from the body, if present
		if ($message =~ /^([^{]*)\{([A-Za-z0-9}]{1,5})\s*$/o) {
			$rethash->{'message'} = $1;
			$rethash->{'messageid'} = $2;
		} else {
			$rethash->{'message'} = $message;
		}
		# catch telemetry messages
		if ($message =~ /^(BITS|PARM|UNIT|EQNS)\./i) {
			$rethash->{'type'} = 'telemetry-message';
		}
		return 1;
	}
	
	_a_err($rethash, 'msg_inv');
	
	return 0;
}

#
sub _comment_telemetry($$)
{
	my($rethash, $rest) = @_;
	 
	if ($rest =~ /^(.*)\|([!-{]{2})([!-{]{2})([!-{]{2}|)([!-{]{2}|)([!-{]{2}|)([!-{]{2}|)([!-{]{2}|)\|(.*)$/) {
		$rest = $1 . $9;
		$rethash->{'telemetry'} = {
			'seq' => (ord(substr($2, 0, 1)) - 33) * 91 +
				(ord(substr($2, 1, 1)) - 33),
			'vals' => [
				(ord(substr($3, 0, 1)) - 33) * 91 +
				(ord(substr($3, 1, 1)) - 33),
				$4 ne '' ? (ord(substr($4, 0, 1)) - 33) * 91 +
				(ord(substr($4, 1, 1)) - 33) : undef,
				$5 ne '' ? (ord(substr($5, 0, 1)) - 33) * 91 +
				(ord(substr($5, 1, 1)) - 33) : undef,
				$6 ne '' ? (ord(substr($6, 0, 1)) - 33) * 91 +
				(ord(substr($6, 1, 1)) - 33) : undef,
				$7 ne '' ? (ord(substr($7, 0, 1)) - 33) * 91 +
				(ord(substr($7, 1, 1)) - 33) : undef,
			]
		};
		if ($8 ne '') {
			# bits: first, decode the base-91 integer
			my $bitint = (ord(substr($8, 0, 1)) - 33) * 91 +
				(ord(substr($8, 1, 1)) - 33);
			# then, decode the 8 bits of telemetry
			$rethash->{'telemetry'}->{'bits'} = unpack('b8', pack('C', $bitint));
		}
	}
	
	return $rest;
}

# Parse an item
sub _item_to_decimal($$$) {
	my $packet = shift @_;
	my $srccallsign = shift @_;
	my $rethash = shift @_;

	# Minimum length for an item is 18 characters
	# (or 24 characters for non-compressed)
	if (length($packet) < 18) {
		_a_err($rethash, 'item_short');
		return 0;
	}

	# Parse the item up to the location
	if ($packet =~ /^\)([\x20\x22-\x5e\x60-\x7e]{3,9})(!|_)/o) {
		# hash member 'itemname' signals an item
		$rethash->{'itemname'} = $1;
		if ($2 eq '!') {
			$rethash->{'alive'} = 1;
		} else {
			$rethash->{'alive'} = 0;
		}
	} else {
		_a_err($rethash, 'item_inv');
		return 0;
	}

	# Forward the location parsing onwards
	my $locationoffset = 2 + length($rethash->{'itemname'});
	my $locationchar = substr($packet, $locationoffset, 1);
	my $retval = undef;
	if ($locationchar =~ /^[\/\\A-Za-j]$/o) {
		# compressed
		$retval = _compressed_to_decimal(substr($packet, $locationoffset, 13), $srccallsign, $rethash);
		$locationoffset += 13;
	} elsif ($locationchar =~ /^\d$/io) {
		# normal
		$retval = _normalpos_to_decimal(substr($packet, $locationoffset), $srccallsign, $rethash);
		$locationoffset += 19;
	} else {
		# error
		_a_err($rethash, 'item_dec_err');
		return 0;
	}
	return 0 if ($retval != 1);

	# Check the APRS data extension and possible comments,
	# unless it is a weather report (we don't want erroneus
	# course/speed figures and weather in the comments..)
	if ($rethash->{'symbolcode'} ne '_') {
		_comments_to_decimal(substr($packet, $locationoffset), $srccallsign, $rethash);
	}

	return 1;
}

# Parse a normal uncompressed location
sub _normalpos_to_decimal($$$) {
	my $packet = shift @_;
	my $srccallsign = shift @_;
	my $rethash = shift @_;

	# Check the length
	if (length($packet) < 19) {
		_a_err($rethash, 'loc_short');
		return 0;
	}
	
	$rethash->{'format'} = 'uncompressed';
	
	# Make a more detailed check on the format, but do the
	# actual value checks later
	my $lon_deg = undef;
	my $lat_deg = undef;
	my $lon_min = undef;
	my $lat_min = undef;
	my $issouth = 0;
	my $iswest = 0;
	my $symboltable;
	if ($packet =~ /^(\d{2})([0-7 ][0-9 ]\.[0-9 ]{2})([NnSs])(.)(\d{3})([0-7 ][0-9 ]\.[0-9 ]{2})([EeWw])([\x21-\x7b\x7d])/o) {
		my $sind = uc($3);
		my $wind = uc($7);
		$symboltable = $4;
		$rethash->{'symbolcode'} = $8;
		if ($sind eq 'S') {
			$issouth = 1;
		}
		if ($wind eq 'W') {
			$iswest = 1;
		}
		$lat_deg = $1;
		$lat_min = $2;
		$lon_deg = $5;
		$lon_min = $6;
	} else {
		_a_err($rethash, 'loc_inv');
		return 0;
	}
	
	if ($symboltable !~ /^[\/\\A-Z0-9]$/) {
		_a_err($rethash, 'sym_inv_table');
		return 0;
	}
	$rethash->{'symboltable'} = $symboltable;
	
	# Check the degree values
	if ($lat_deg > 89 || $lon_deg > 179) {
		_a_err($rethash, 'loc_large');
		return 0;
	}

	# Find out the amount of position ambiguity
	my $tmplat = $lat_min;
	$tmplat =~ s/\.//; # remove the period
	# Count the amount of spaces at the end
	if ($tmplat =~ /^(\d{0,4})( {0,4})$/io) {
		$rethash->{'posambiguity'} = length($2);
	} else {
		_a_err($rethash, 'loc_amb_inv');
		return 0;
	}

	my $latitude = undef;
	my $longitude = undef;
	if ($rethash->{'posambiguity'} == 0) {
		# No position ambiguity. Check longitude for invalid spaces
		if ($lon_min =~ / /io) {
			_a_err($rethash, 'loc_amb_inv', 'longitude 0');
			return 0;
		}
		$latitude = $lat_deg + ($lat_min/60);
		$longitude = $lon_deg + ($lon_min/60);
	} elsif ($rethash->{'posambiguity'} == 4) {
		# disregard the minutes and add 0.5 to the degree values
		$latitude = $lat_deg + 0.5;
		$longitude = $lon_deg + 0.5;
	} elsif ($rethash->{'posambiguity'} == 1) {
		# the last digit is not used
		$lat_min = substr($lat_min, 0, 4);
		$lon_min = substr($lon_min, 0, 4);
		if ($lat_min =~ / /io || $lon_min =~ / /io) {
			_a_err($rethash, 'loc_amb_inv', 'lat/lon 1');
			return 0;
		}
		$latitude = $lat_deg + (($lat_min + 0.05)/60);
		$longitude = $lon_deg + (($lon_min + 0.05)/60);
	} elsif ($rethash->{'posambiguity'} == 2) {
		# the minute decimals are not used
		$lat_min = substr($lat_min, 0, 2);
		$lon_min = substr($lon_min, 0, 2);
		if ($lat_min =~ / /io || $lon_min =~ / /io) {
			_a_err($rethash, 'loc_amb_inv', 'lat/lon 2');
			return 0;
		}
		$latitude = $lat_deg + (($lat_min + 0.5)/60);
		$longitude = $lon_deg + (($lon_min + 0.5)/60);
	} elsif ($rethash->{'posambiguity'} == 3) {
		# the single minutes are not used
		$lat_min = substr($lat_min, 0, 1) . '5';
		$lon_min = substr($lon_min, 0, 1) . '5';
		if ($lat_min =~ / /io || $lon_min =~ / /io) {
			_a_err($rethash, 'loc_amb_inv', 'lat/lon 3');
			return 0;
		}
		$latitude = $lat_deg + ($lat_min/60);
		$longitude = $lon_deg + ($lon_min/60);
	} else {
		_a_err($rethash, 'loc_amb_inv');
		return 0;
	}

	# Finally apply south/west indicators
	if ($issouth == 1) {
		$latitude = 0 - $latitude;
	}
	if ($iswest == 1) {
		$longitude = 0 - $longitude;
	}
	# Store the locations
	$rethash->{'latitude'} = $latitude;
	$rethash->{'longitude'} = $longitude;
	# Calculate position resolution based on position ambiguity
	# calculated above.
	$rethash->{'posresolution'} = _get_posresolution(2 - $rethash->{'posambiguity'});

	# Parse possible APRS data extension
	# afterwards along with comments


	return 1;
}

# convert a mic-encoder packet
sub _mice_to_decimal($$$$$) {
	my ($packet, $dstcallsign, $srccallsign, $rethash, $options) = @_;

	# We only want the base callsign
	$dstcallsign =~ s/-\d+$//;

	$rethash->{'format'} = 'mice';
	
	# Check the format
	if (length($packet) < 8 || length($dstcallsign) != 6) {
		# too short packet to be mic-e
		_a_err($rethash, 'mice_short');
		return 0;
	}
	if (not($dstcallsign =~ /^[0-9A-LP-Z]{3}[0-9LP-Z]{3}$/io)) {
		# A-K characters are not used in the last 3 characters
		# and MNO are never used
		_a_err($rethash, 'mice_inv');
		return 0;
	}
	
	# check the information field (longitude, course, speed and
	# symbol table and code are checked). Not bullet proof..
	my $mice_fixed;
	my $symboltable = substr($packet, 7, 1);
	if ($packet !~ /^[\x26-\x7f][\x26-\x61][\x1c-\x7f]{2}[\x1c-\x7d][\x1c-\x7f][\x21-\x7b\x7d][\/\\A-Z0-9]/o) {
		# If the accept_broken_mice option is given, check for a known
		# corruption in the packets and try to fix it - aprsd is
		# replacing some valid but non-printable mic-e packet
		# characters with spaces, and some other software is replacing
		# the multiple spaces with a single space. This regexp
		# replaces the single space with two spaces, so that the rest
		# of the code can still parse the position data.
		if (($options->{'accept_broken_mice'})
		    && $packet =~ s/^([\x26-\x7f][\x26-\x61][\x1c-\x7f]{2})\x20([\x21-\x7b\x7d][\/\\A-Z0-9])(.*)/$1\x20\x20$2$3/o) {
			$mice_fixed = 1;
			# Now the symbol table identifier is again in the correct spot...
			$symboltable = substr($packet, 7, 1);
			if ($symboltable !~ /^[\/\\A-Z0-9]$/) {
				_a_err($rethash, 'sym_inv_table');
				return 0;
			}
		} else {
			# Get a more precise error message for invalid symbol table
			if ($symboltable !~ /^[\/\\A-Z0-9]$/) {
				_a_err($rethash, 'sym_inv_table');
			} else {
				_a_err($rethash, 'mice_inv_info');
			}
			return 0;
		}
	}

	# First do the destination callsign
	# (latitude, message bits, N/S and W/E indicators and long. offset)

	# Translate the characters to get the latitude
	my $tmplat = $dstcallsign;
	$tmplat =~ tr/A-JP-YKLZ/0-90-9___/;
	# Find out the amount of position ambiguity
	if ($tmplat =~ /^(\d+)(_*)$/io) {
		my $amount = 6 - length($1);
		if ($amount > 4) {
			# only minutes and decimal minutes can
			# be masked out
			_a_err($rethash, 'mice_amb_large');
			return 0;
		}
		$rethash->{'posambiguity'} = $amount;
		# Calculate position resolution based on position ambiguity
		# calculated above.
		$rethash->{'posresolution'} = _get_posresolution(2 - $amount);
	} else {
		# no digits in the beginning, baaad..
		# or the ambiguity digits weren't continuous
		_a_err($rethash, 'mice_amb_inv');
		return 0;
	}

	# convert the latitude to the midvalue if position ambiguity
	# is used
	if ($rethash->{'posambiguity'} >= 4) {
		# the minute is between 0 and 60, so
		# the middle point is 30
		$tmplat =~ s/_/3/;
	} else {
		$tmplat =~ s/_/5/;  # the first is changed to digit 5
	}
	$tmplat =~ s/_/0/g; # the rest are changed to digit 0

	# get the degrees
	my $latitude = substr($tmplat, 0, 2);
	# the minutes
	my $latminutes = substr($tmplat, 2, 2) . '.' . substr($tmplat, 4, 2);
	# convert the minutes to decimal degrees and combine
	$latitude += ($latminutes/60);

	# check the north/south direction and correct the latitude
	# if necessary
	my $nschar = ord(substr($dstcallsign, 3, 1));
	if ($nschar <= 0x4c) {
		$latitude = 0 - $latitude;
	}

	# Latitude is finally complete, so store it
	$rethash->{'latitude'} = $latitude;

	# Get the message bits. 1 is standard one-bit and
	# 2 is custom one-bit. %mice_messagetypes provides
	# the mappings to message names
	my $mbitstring = substr($dstcallsign, 0, 3);
	$mbitstring =~ tr/0-9/0/;
	$mbitstring =~ tr/L/0/;
	$mbitstring =~ tr/P-Z/1/;
	$mbitstring =~ tr/A-K/2/;
	$rethash->{'mbits'} = $mbitstring;

	# Decode the longitude, the first three bytes of the
	# body after the data type indicator.
	# First longitude degrees, remember the longitude offset
	my $longitude = ord(substr($packet, 0, 1)) - 28;
	my $longoffsetchar = ord(substr($dstcallsign, 4, 1));
	if ($longoffsetchar >= 0x50) {
		$longitude += 100;
	}
	if ($longitude >= 180 && $longitude <= 189) {
		$longitude -= 80;
	} elsif ($longitude >= 190 && $longitude <= 199) {
		$longitude -= 190;
	}

	# Decode the longitude minutes
	my $longminutes = ord(substr($packet, 1, 1)) - 28;
	if ($longminutes >= 60) {
		$longminutes -= 60;
	}
	# ... and minute decimals
	$longminutes = sprintf('%02d.%02d',
		$longminutes,
		ord(substr($packet, 2, 1)) - 28);
	# apply position ambiguity to longitude
	if ($rethash->{'posambiguity'} == 4) {
		# minute is unused -> add 0.5 degrees to longitude
		$longitude += 0.5;
	} elsif ($rethash->{'posambiguity'} == 3) {
		my $lontmp = substr($longminutes, 0, 1) . '5';
		$longitude += ($lontmp/60);
	} elsif ($rethash->{'posambiguity'} == 2) {
		my $lontmp = substr($longminutes, 0, 2) . '.5';
		$longitude += ($lontmp/60);
	} elsif ($rethash->{'posambiguity'} == 1) {
		my $lontmp = substr($longminutes, 0, 4) . '5';
		$longitude += ($lontmp/60);
	} elsif ($rethash->{'posambiguity'} == 0) {
		$longitude += ($longminutes/60);
	} else {
		_a_err($rethash, 'mice_amb_odd', $rethash->{'posambiguity'});
		return 0;
	}

	# check the longitude E/W sign
	my $ewchar = ord(substr($dstcallsign, 5, 1));
	if ($ewchar >= 0x50) {
		$longitude = 0 - $longitude;
	}

	# Longitude is finally complete, so store it
	$rethash->{'longitude'} = $longitude;

	# Now onto speed and course.
	# If the packet has had a mic-e fix applied, course and speed are likely to be off.
	if (!$mice_fixed) {
		my $speed = (ord(substr($packet, 3, 1)) - 28) * 10;
		my $coursespeed = ord(substr($packet, 4, 1)) - 28;
		my $coursespeedtmp = int($coursespeed / 10);
		$speed += $coursespeedtmp;
		$coursespeed -= $coursespeedtmp * 10;
		my $course = 100 * $coursespeed;
		$course += ord(substr($packet, 5, 1)) - 28;
		# do some important adjustements
		if ($speed >= 800) {
			$speed -= 800;
		}
		if ($course >= 400) {
			$course -= 400;
		}
		# convert speed to km/h and store
		$rethash->{'speed'} = $speed * $knot_to_kmh;
		# also zero course is saved, which means unknown
		if ($course >= 0) {
			$rethash->{'course'} = $course;
		}
	}

	# save the symbol table and code
	$rethash->{'symbolcode'} = substr($packet, 6, 1);
	$rethash->{'symboltable'} = $symboltable;

	# Check for possible altitude and comment data.
	# It is base-91 coded and in format 'xxx}' where
	# x are the base-91 digits in meters, origin is 10000 meters
	# below sea.
	if (length($packet) > 8) {
		my $rest = substr($packet, 8);
		
		# check for Mic-E Telemetry Data
		if ($rest =~ /^'([0-9a-f]{2})([0-9a-f]{2})(.*)$/i) {
			# two hexadecimal values: channels 1 and 3
			$rest = $3;
			$rethash->{'telemetry'} = {
				'vals' => [ unpack('C*', pack('H*', $1 . '00' . $2)) ]
			};
		}
		if ($rest =~ /^‘([0-9a-f]{10})(.*)$/i) {
			# five channels:
			$rest = $2;
			$rethash->{'telemetry'} = {
				'vals' => [ unpack('C*', pack('H*', $1)) ]
			};
		}
		
		# check for altitude
		if ($rest =~ /^(.*?)([\x21-\x7b])([\x21-\x7b])([\x21-\x7b])\}(.*)$/o) {
			$rethash->{'altitude'} = (
				(ord($2) - 33) * 91 ** 2 +
				(ord($3) - 33) * 91 +
				(ord($4) - 33)) - 10000;
			$rest = $1 . $5;
		}

                # Check for new-style base-91 comment telemetry
                $rest = _comment_telemetry($rethash, $rest);
                
                # Check for !DAO!, take the last occurrence (per recommendation)
                if ($rest =~ /^(.*)\!([\x21-\x7b][\x20-\x7b]{2})\!(.*?)$/o) {
                        my $daofound = _dao_parse($2, $srccallsign, $rethash);
                        if ($daofound == 1) {
                                $rest = $1 . $3;
                        }
                }
                
                # If anything is left, store it as a comment
		# after removing non-printable ASCII
		# characters
		if (length($rest) > 0) {
			$rethash->{'comment'} = _cleanup_comment($rest);
		}
	}
	
	if ($mice_fixed) {
		$rethash->{'mice_mangled'} = 1;
		#warn "$srccallsign: fixed packet was parsed\n";
	}
	
	return 1;
}

# convert a compressed position to decimal degrees
sub _compressed_to_decimal($$$)
{
	my ($packet, $srccallsign, $rethash) = @_;

	# A compressed position is always 13 characters long.
	# Make sure we get at least 13 characters and that they are ok.
	# Also check the allowed base-91 characters at the same time.
	if (not($packet =~ /^[\/\\A-Za-j]{1}[\x21-\x7b]{8}[\x21-\x7b\x7d]{1}[\x20-\x7b]{3}/o)) {
		_a_err($rethash, 'comp_inv');
		return 0;
	}

	$rethash->{'format'} = 'compressed';
	
	my $symboltable = substr($packet, 0, 1);
	my $lat1 = ord(substr($packet, 1, 1)) - 33;
	my $lat2 = ord(substr($packet, 2, 1)) - 33;
	my $lat3 = ord(substr($packet, 3, 1)) - 33;
	my $lat4 = ord(substr($packet, 4, 1)) - 33;
	my $long1 = ord(substr($packet, 5, 1)) - 33;
	my $long2 = ord(substr($packet, 6, 1)) - 33;
	my $long3 = ord(substr($packet, 7, 1)) - 33;
	my $long4 = ord(substr($packet, 8, 1)) - 33;
	my $symbolcode = substr($packet, 9, 1);
	my $c1 = ord(substr($packet, 10, 1)) - 33;
	my $s1 = ord(substr($packet, 11, 1)) - 33;
	my $comptype = ord(substr($packet, 12, 1)) - 33;

	# save the symbol table and code
	$rethash->{'symbolcode'} = $symbolcode;
	# the symbol table values a..j are really 0..9
	$symboltable =~ tr/a-j/0-9/;
	$rethash->{'symboltable'} = $symboltable;

	# calculate latitude and longitude
	$rethash->{'latitude'} = 90 -
		(($lat1 * 91 ** 3 +
		$lat2 * 91 ** 2 +
		$lat3 * 91 +
		$lat4) / 380926);
	$rethash->{'longitude'} = -180 +
		(($long1 * 91 ** 3 +
		$long2 * 91 ** 2 +
		$long3 * 91 +
		$long4) / 190463);
        # save best-case position resolution in meters
        # 1852 meters * 60 minutes in a degree * 180 degrees
        # / 91 ** 4
        $rethash->{'posresolution'} = 0.291;

	# GPS fix status, only if csT is used
	if ($c1 != -1) {
		if (($comptype & 0x20) == 0x20) {
			$rethash->{'gpsfixstatus'} = 1;
		} else {
			$rethash->{'gpsfixstatus'} = 0;
		}
	}

	# check the compression type, if GPGGA, then
	# the cs bytes are altitude. Otherwise try
	# to decode it as course and speed. And
	# finally as radio range
	# if c is space, then csT is not used.
	# Also require that s is not a space.
	if ($c1 == -1 || $s1 == -1) {
		# csT not used
	} elsif (($comptype & 0x18) == 0x10) {
		# cs is altitude
		my $cs = $c1 * 91 + $s1;
		# convert directly to meters
		$rethash->{'altitude'} = (1.002 ** $cs) * $feet_to_meters;
	} elsif ($c1 >= 0 && $c1 <= 89) {
		if ($c1 == 0) {
			# special case of north, APRS spec
			# uses zero for unknown and 360 for north.
			# so remember to convert north here.
			$rethash->{'course'} = 360;
		} else {
			$rethash->{'course'} = $c1 * 4;
		}
		# convert directly to km/h
		$rethash->{'speed'} = (1.08 ** $s1 - 1) * $knot_to_kmh;
	} elsif ($c1 == 90) {
		# convert directly to km
		$rethash->{'radiorange'} = (2 * 1.08 ** $s1) * $mph_to_kmh;
	}

	return 1;
}


# Parse a possible !DAO! extension (datum and extra
# lat/lon digits). Returns 1 if a valid !DAO! extension was
# detected in the test subject (and stored in $rethash), 0 if not.
# Only the "DAO" should be passed as the candidate parameter,
# not the delimiting exclamation marks.
sub _dao_parse($$$)
{
	my ($daocandidate, $srccallsign, $rethash) = @_;

	# datum character is the first character and also
	# defines how the rest is interpreted
	my ($latoff, $lonoff) = undef;
	if ($daocandidate =~ /^([A-Z])(\d)(\d)$/o) {
		# human readable (datum byte A...Z)
		$rethash->{'daodatumbyte'} = $1;
		$rethash->{'posresolution'} = _get_posresolution(3);
		$latoff = $2 * 0.001 / 60;
		$lonoff = $3 * 0.001 / 60;

	} elsif ($daocandidate =~ /^([a-z])([\x21-\x7b])([\x21-\x7b])$/o) {
		# base-91 (datum byte a...z)
		# store the datum in upper case, still
		$rethash->{'daodatumbyte'} = uc($1);
		# close enough.. not exact:
		$rethash->{'posresolution'} = _get_posresolution(4);
		# do proper scaling of base-91 values
		$latoff = (ord($2) - 33) / 91 * 0.01 / 60;
		$lonoff = (ord($3) - 33) / 91 * 0.01 / 60;

	} elsif ($daocandidate =~ /^([\x21-\x7b])  $/o) {
		# only datum information, no lat/lon digits
		my $daodatumbyte = $1;
		if ($daodatumbyte =~ /^[a-z]$/o) {
			$daodatumbyte = uc($daodatumbyte);
		}
		$rethash->{'daodatumbyte'} = $daodatumbyte;
		return 1;

	} else {
		return 0;
	}

	# check N/S and E/W
	if ($rethash->{'latitude'} < 0) {
		$rethash->{'latitude'} -= $latoff;
	} else {
		$rethash->{'latitude'} += $latoff;
	}
	if ($rethash->{'longitude'} < 0) {
		$rethash->{'longitude'} -= $lonoff;
	} else {
		$rethash->{'longitude'} += $lonoff;
	}
	return 1;
}

=over

=item check_ax25_call($callsign)

Check the callsign for a valid AX.25 callsign format and
return cleaned up (OH2XYZ-0) callsign or undef if the callsign
is not a valid AX.25 address.

Please note that it's very common to use invalid callsigns on the APRS-IS.

=back

=cut

sub check_ax25_call($) {
	if ($_[0] =~ /^([A-Z0-9]{1,6})(-\d{1,2}|)$/o) {
		if (length($2) == 0) {
			return $1;
		} else {
			# convert SSID to positive and numeric
			my $ssid = 0 - $2;
			if ($ssid < 16) {
				# 15 is maximum in AX.25
				return $1 . '-' . $ssid;
			}
		}
	}

	# no successfull return yet, so error
	return undef;
}

# _dx_parse($sourcecall, $info, $rethash)
#
# Parses the body of a DX spot packet. Returns the following
# hash elements: dxsource (source of the info), dxfreq (frequency),
# dxcall (DX callsign) and dxinfo (info string).
#

sub _dx_parse($$$)
{
	my ($sourcecall, $info, $rh) = @_;
	
	if (!defined check_ax25_call($sourcecall)) {
		_a_err($rh, 'dx_inv_src', $sourcecall);
		return 0;
	}
	$rh->{'dxsource'} = $sourcecall;
	
	$info =~ s/^\s*(.*?)\s*$/$1/; # strip whitespace
	if ($info =~ s/\s*(\d{3,4}Z)//) {
		$rh->{'dxtime'} = $1;
	}
	_a_err($rh, 'dx_inv_freq') if ($info !~ s/^(\d+\.\d+)\s*//);
	$rh->{'dxfreq'} = $1;
	_a_err($rh, 'dx_no_dx') if ($info !~ s/^([a-zA-Z0-9-\/]+)\s*//);
	$rh->{'dxcall'} = $1;
	
	$info =~ s/\s+/ /g;
	$rh->{'dxinfo'} = $info;
	
	return 1;
}

# _wx_parse($s, $rethash)
#
# Parses a normal uncompressed weather report packet.
#

sub _fahrenheit_to_celsius($)
{
	return ($_[0] - 32) / 1.8;
}

sub _wx_parse($$)
{
	my ($s, $rh) = @_;
	
	#my $initial = $s;
	
	# 257/007g013t055r000P000p000h56b10160v31
	# 045/000t064r000p000h35b10203.open2300v1.10
	# 175/007g007p...P000r000t062h32b10224wRSW
	my %w;
	my ($wind_dir, $wind_speed, $temp, $wind_gust) = ('', '', '', '');
	if ($s =~ s/^_{0,1}([\d \.\-]{3})\/([\d \.]{3})g([\d \.]+)t(-{0,1}[\d \.]+)//
	    || $s =~ s/^_{0,1}c([\d \.\-]{3})s([\d \.]{3})g([\d \.]+)t(-{0,1}[\d \.]+)//) {
		#warn "wind $1 / $2 gust $3 temp $4\n";
		($wind_dir, $wind_speed, $wind_gust, $temp) = ($1, $2, $3, $4);
	} elsif ($s =~ s/^_{0,1}([\d \.\-]{3})\/([\d \.]{3})t(-{0,1}[\d \.]+)//) {
		#warn "$initial\nwind $1 / $2 temp $3\n";
		($wind_dir, $wind_speed, $temp) = ($1, $2, $3);
	} elsif ($s =~ s/^_{0,1}([\d \.\-]{3})\/([\d \.]{3})g([\d \.]+)//) {
		#warn "$initial\nwind $1 / $2 gust $3\n";
		($wind_dir, $wind_speed, $wind_gust) = ($1, $2, $3);
	} elsif ($s =~ s/^g(\d+)t(-{0,1}[\d \.]+)//) {
		# g000t054r000p010P010h65b10073WS 2300 {UIV32N}
		($wind_gust, $temp) = ($1, $2);
	} else {
		#warn "wx_parse: no initial match: $s\n";
		return 0;
	}
	
	if (!defined $temp && $s =~ s/t(-{0,1}\d{1,3})//) {
		$temp = $1;
	}
	
	$w{'wind_gust'} = sprintf('%.1f', $wind_gust * $mph_to_ms) if ($wind_gust =~ /^\d+$/);
	$w{'wind_direction'} = sprintf('%.0f', $wind_dir) if ($wind_dir =~ /^\d+$/);
	$w{'wind_speed'} = sprintf('%.1f', $wind_speed * $mph_to_ms) if ($wind_speed =~ /^\d+$/);
	$w{'temp'} = sprintf('%.1f', _fahrenheit_to_celsius($temp)) if ($temp =~ /^-{0,1}\d+$/);
	
	if ($s =~ s/r(\d{1,3})//) {
		$w{'rain_1h'} = sprintf('%.1f', $1*$hinch_to_mm); # during last 1h
	}
	if ($s =~ s/p(\d{1,3})//) {
		$w{'rain_24h'} = sprintf('%.1f', $1*$hinch_to_mm); # during last 24h
	}
	if ($s =~ s/P(\d{1,3})//) {
		$w{'rain_midnight'} = sprintf('%.1f', $1*$hinch_to_mm); # since midnight
	}
	
	if ($s =~ s/h(\d{1,3})//) {
		$w{'humidity'} = sprintf('%.0f', $1); # percentage
		$w{'humidity'} = 100 if ($w{'humidity'} eq 0);
		undef $w{'humidity'} if ($w{'humidity'} > 100 || $w{'humidity'} < 1);
	}
	
	if ($s =~ s/b(\d{4,5})//) {
		$w{'pressure'} = sprintf('%.1f', $1/10); # results in millibars
	}
	
	if ($s =~ s/([lL])(\d{1,3})//) {
		$w{'luminosity'} = sprintf('%.0f', $2); # watts / m2
		$w{'luminosity'} += 1000 if ($1 eq 'l');
	}
	
	if ($s =~ s/v([\-\+]{0,1}\d+)//) {
		# what ?
	}
	
	if ($s =~ s/s(\d{1,3})//) {
		# snowfall
		$w{'snow_24h'} = sprintf('%.1f', $1*$hinch_to_mm);
	}
	
	if ($s =~ s/#(\d+)//) {
		# raw rain counter
	}
	
	$s =~ s/^([rPphblLs#][\. ]{1,5})+//;
	
	$s =~ s/^\s+//;
	$s =~ s/\s+/ /;
	if ($s =~ /^[a-zA-Z0-9\-_]{3,5}$/) {
		$w{'soft'} = substr($s, 0, 16) if ($s ne '');
	} else {
		$rh->{'comment'} = _cleanup_comment($s);
	}
	
	if (defined $w{'temp'}
	    || (defined $w{'wind_speed'} && defined $w{'wind_direction'})
	    	) {
	    		#warn "ok: $initial\n$s\n";
	    		$rh->{'wx'} = \%w;
	    		return 1;
	}
	
	return 0;
}

# _wx_parse_peet_packet($s, $sourcecall, $rethash)
#
# Parses a Peet bros Ultimeter weather packet ($ULTW header).
#

sub _wx_parse_peet_packet($$$)
{
	my ($s, $sourcecall, $rh) = @_;
	
	#warn "\$ULTW: $s\n";
	# 0000000001FF000427C70002CCD30001026E003A050F00040000
	my %w;
	my $t;
	my @vals;
	while ($s =~ s/^([0-9a-f]{4}|----)//i) {
		if ($1 eq '----') {
			push @vals, undef;
		} else {
			# Signed 16-bit integers in network (big-endian) order
			# encoded in hex, high nybble first.
			# Perl 5.10 unpack supports n! for signed ints, 5.8
			# requires tricks like this:
			my $v = unpack('n', pack('H*', $1));
			
			push @vals, ($v < 32768) ? $v : $v - 65536;
		}
	}
	return 0 if (!@vals);
	
	$t = shift @vals;
	$w{'wind_gust'} = sprintf('%.1f', $t * $kmh_to_ms / 10) if (defined $t);
	$t = shift @vals;
	$w{'wind_direction'} = sprintf('%.0f', ($t& 0xff) * 1.41176) if (defined $t); # 1/255 => 1/360
	$t = shift @vals;
	$w{'temp'} = sprintf('%.1f', _fahrenheit_to_celsius($t / 10)) if (defined $t); # 1/255 => 1/360
	$t = shift @vals;
	$w{'rain_midnight'} = sprintf('%.1f', $t * $hinch_to_mm) if (defined $t);
	$t = shift @vals;
	$w{'pressure'} = sprintf('%.1f', $t / 10) if (defined $t && $t >= 10);
	shift @vals; # Barometer Delta
	shift @vals; # Barometer Corr. Factor (LSW)
	shift @vals; # Barometer Corr. Factor (MSW)
	$t = shift @vals;
	if (defined $t) {
		$w{'humidity'} = sprintf('%.0f', $t / 10); # percentage
		delete $w{'humidity'} if ($w{'humidity'} > 100 || $w{'humidity'} < 1);
	}
	shift @vals; # date
	shift @vals; # time
	$t = shift @vals;
	$w{'rain_midnight'} = sprintf('%.1f', $t * $hinch_to_mm) if (defined $t);
	$t = shift @vals;
	$w{'wind_speed'} = sprintf('%.1f', $t * $kmh_to_ms / 10) if (defined $t);
	
	if (defined $w{'temp'}
	    || (defined $w{'wind_speed'} && defined $w{'wind_direction'})
	    || (defined $w{'pressure'})
	    || (defined $w{'humidity'})
	    	) {
	    		$rh->{'wx'} = \%w;
	    		return 1;
	}
	
	return 0;
}

# _wx_parse_peet_logging($s, $sourcecall, $rethash)
# 
# Parses a Peet bros Ultimeter weather logging frame (!! header).
#

sub _wx_parse_peet_logging($$$)
{
	my ($s, $sourcecall, $rh) = @_;
	
	#warn "\!!: $s\n";
	# 0000000001FF000427C70002CCD30001026E003A050F00040000
	my %w;
	my $t;
	my @vals;
	while ($s =~ s/^([0-9a-f]{4}|----)//i) {
		if ($1 eq '----') {
			push @vals, undef;
		} else {
			# Signed 16-bit integers in network (big-endian) order
			# encoded in hex, high nybble first.
			# Perl 5.10 unpack supports n! for signed ints, 5.8
			# requires tricks like this:
			my $v = unpack('n', pack('H*', $1));
			
			push @vals, ($v < 32768) ? $v : $v - 65536;
		}
	}
	return 0 if (!@vals);
	
	$t = shift @vals; # instant wind speed
	$w{'wind_speed'} = sprintf('%.1f', $t * $kmh_to_ms / 10) if (defined $t);
	$t = shift @vals;
	$w{'wind_direction'} = sprintf('%.0f', ($t& 0xff) * 1.41176) if (defined $t); # 1/255 => 1/360
	$t = shift @vals;
	$w{'temp'} = sprintf('%.1f', _fahrenheit_to_celsius($t / 10)) if (defined $t); # 1/255 => 1/360
	$t = shift @vals;
	$w{'rain_midnight'} = sprintf('%.1f', $t * $hinch_to_mm) if (defined $t);
	$t = shift @vals;
	$w{'pressure'} = sprintf('%.1f', $t / 10) if (defined $t && $t >= 10);
	$t = shift @vals;
	$w{'temp_in'} = sprintf('%.1f', _fahrenheit_to_celsius($t / 10)) if (defined $t); # 1/255 => 1/360
	$t = shift @vals;
	if (defined $t) {
		$w{'humidity'} = sprintf('%.0f', $t / 10); # percentage
		delete $w{'humidity'} if ($w{'humidity'} > 100 || $w{'humidity'} < 1);
	}
	$t = shift @vals;
	if (defined $t) {
		$w{'humidity_in'} = sprintf('%.0f', $t / 10); # percentage
		delete $w{'humidity_in'} if ($w{'humidity_in'} > 100 || $w{'humidity_in'} < 1);
	}
	shift @vals; # date
	shift @vals; # time
	$t = shift @vals;
	$w{'rain_midnight'} = sprintf('%.1f', $t * $hinch_to_mm) if (defined $t);
	$t = shift @vals; # avg wind speed
	$w{'wind_speed'} = sprintf('%.1f', $t * $kmh_to_ms / 10) if (defined $t);
	
	# if inside temperature exists but no outside, use inside
	$w{'temp'} = $w{'temp_in'} if (defined $w{'temp_in'} && !defined $w{'temp'});
	$w{'humidity'} = $w{'humidity_in'} if (defined $w{'humidity_in'} && !defined $w{'humidity'});
	
	if (defined $w{'temp'}
	    || (defined $w{'wind_speed'} && defined $w{'wind_direction'})
	    || (defined $w{'pressure'})
	    || (defined $w{'humidity'})
	    	) {
	    		$rh->{'wx'} = \%w;
	    		return 1;
	}
	
	return 0;
}

# _telemetry_parse($s, $rethash)
#
# Parses a telemetry packet.
#

sub _telemetry_parse($$)
{
	my ($s, $rh) = @_;
	
	my $initial = $s;
	
	my ($seq, $v1, $v2, $v3, $v4, $v5, $bits);
	my %t;
	if ($s =~ s/^(\d+),(-|)(\d{1,6}|\d+\.\d+|\.\d+|),(-|)(\d{1,6}|\d+\.\d+|\.\d+|),(-|)(\d{1,6}|\d+\.\d+|\.\d+|),(-|)(\d{1,6}|\d+\.\d+|\.\d+|),(-|)(\d{1,6}|\d+\.\d+|\.\d+|),([01]{0,8})//) {
		$t{'seq'} = $1;
		my @vals = ( "$2$3", "$4$5", "$6$7", "$8$9", "$10$11" );
		for (my $i = 0; $i <= $#vals; $i++) {
			$vals[$i] = $vals[$i] eq '' ? 0 : sprintf('%.2f', $vals[$i]);
			if ($vals[$i] >= 999999 || $vals[$i] <= -999999) {
				_a_err($rh, 'tlm_large');
				return 0;
			}
		}
		$t{'vals'} = \@vals;
		$t{'bits'} = $12;
		# expand bits to 8 bits if some are missing
		if ((my $l = length($t{'bits'})) < 8) {
			$t{'bits'} .= '0' x (8-$l);
		}
	} else {
		# todo: return an error code
		_a_err($rh, 'tlm_inv');
		return 0;
	}
	
	$rh->{'telemetry'} = \%t;
	#warn 'ok: ' . Dumper(\%t);
	return 1;
}

=over

=item parseaprs($packet, $hashref, %options)

Parse an APRS packet given as a string, e.g.
"OH2XYZ>APRS,RELAY*,WIDE:!2345.56N/12345.67E-PHG0123 hi there"
Second parameter has to be a reference to a hash. That hash will
be filled with as much data as possible based on the packet
given as parameter.

Returns 1 if the decoding was successfull,
returns 0 if not. In case zero is returned, the contents of
the parameter hash should be discarded, except for the error cause
as reported via hash elements resultcode and resultmsg.


The third parameter is an optional hash containing any of the following
options:

B<isax25> - the packet should be examined in a form
that can exist on an AX.25 network (1) or whether the frame is
from the Internet (0 - default).

B<accept_broken_mice> - if the packet contains corrupted
mic-e fields, but some of the data is still recovable, decode
the packet instead of reporting an error. At least aprsd produces
these packets. 1: try to decode, 0: report an error (default).
Packets which have been successfully demangled will contain the
B<mice_mangled> flag.

B<raw_timestamp> - Timestamps within the packets are not decoded
to an UNIX timestamp, but are returned as raw strings.

Example:

my %hash;

my $ret = parseaprs("OH2XYZ>APRS,RELAY*,WIDE:!2345.56N/12345.67E-PHG0123 hi",
\%hash, 'isax25' => 0, 'accept_broken_mice' => 0);

=back

=cut

sub parseaprs($$;%) {
	my($packet, $rethash, %options) = @_;
	my $isax25 = ($options{'isax25'}) ? 1 : 0;
	
	if (!defined $packet) {
		_a_err($rethash, 'packet_no');
		return 0;
	}
	if (length($packet) < 1) {
		_a_err($rethash, 'packet_short');
		return 0;
	}
	
	# Separate the header and packet body on the first
	# colon.
	my ($header, $body) = split(/:/, $packet, 2);

	# If no body, skip
	if (!defined $body) {
		_a_err($rethash, 'packet_nobody');
		return 0;
	}

	# Save all the parts of the packet
	$rethash->{'origpacket'} = $packet;
	$rethash->{'header'} = $header;
	$rethash->{'body'} = $body;

	# Source callsign, put the rest in $rest
	my($srccallsign, $rest);
	if ($header =~ /^([A-Z0-9-]{1,9})>(.*)$/io) {
		$rest = $2;
		if ($isax25 == 0) {
			$srccallsign = $1;
		} else {
		        $srccallsign = check_ax25_call(uc($1));
		        if (not(defined($srccallsign))) {
		        	_a_err($rethash, 'srccall_noax25');
		        	return 0;
                        }
		}
	} else {
		# can't be a valid amateur radio callsign, even
		# in the extended sense of APRS-IS callsigns
		_a_err($rethash, 'srccall_badchars');
		return 0;
	}
	$rethash->{'srccallsign'} = $srccallsign;

	# Get the destination callsign and digipeaters.
	# Only TNC-2 format is supported, AEA (with digipeaters) is not.
	my @pathcomponents = split(/,/, $rest);
	# More than 9 (dst callsign + 8 digipeaters) path components
	# from AX.25 or less than 1 from anywhere is invalid.
	if ($isax25 == 1) {
		if (scalar(@pathcomponents) > 9) {
			# too many fields to be from AX.25
			_a_err($rethash, 'dstpath_toomany');
			return 0;
		}
	}
	if (scalar(@pathcomponents) < 1) {
		# no destination field
		_a_err($rethash, 'dstcall_none');
		return 0;
	}
	
	# Destination callsign. We are strict here, there
	# should be no need to use a non-AX.25 compatible
	# destination callsigns in the APRS-IS.
	my $dstcallsign = check_ax25_call(shift @pathcomponents);
	if (!defined $dstcallsign) {
		_a_err($rethash, 'dstcall_noax25');
		return 0;
	}
	$rethash->{'dstcallsign'} = $dstcallsign;

	# digipeaters
	my @digipeaters;
	if ($isax25 == 1) {
		foreach my $digi (@pathcomponents) {
			if ($digi =~ /^([A-Z0-9-]+)(\*|)$/io) {
				my $digitested = check_ax25_call(uc($1));
				if (not(defined($digitested))) {
					_a_err($rethash, 'digicall_noax25');
					return 0;
				}
				my $wasdigied = 0;
				if ($2 eq '*') {
					$wasdigied = 1;
				}
				# add it to the digipeater array
				push(@digipeaters, { 'call' => $digitested,
					'wasdigied' => $wasdigied });
			} else {
				_a_err($rethash, 'digicall_badchars');
				return 0;
			}
		}
	} else {
		my $seen_qconstr = 0;
		
		foreach my $digi (@pathcomponents) {
			# From the internet. Apply the same checks as for
			# APRS-IS packet originator. Allow long hexadecimal IPv6
			# address after the Q construct.
			if ($digi =~ /^([A-Z0-9a-z-]{1,9})(\*|)$/o) {
				push(@digipeaters, { 'call' => $1,
					'wasdigied' => ($2 eq '*') ? 1 : 0 });
				$seen_qconstr = 1 if ($1 =~ /^q..$/);
			} else {
				if ($seen_qconstr && $digi =~ /^([0-9A-F]{32})$/) {
					push(@digipeaters, { 'call' => $1, 'wasdigied' => 0 });
				} else {
					_a_err($rethash, 'digicall_badchars');
					return 0;
				}
			}
		}
	}
	$rethash->{'digipeaters'} = \@digipeaters;
	
	# So now we have source and destination callsigns and
	# digipeaters parsed and ok. Move on to the body.

	# Check the first character of the packet
	# and determine the packet type
	my $retval = -1;
	my $packettype = substr($body, 0, 1);
	my $paclen = length($body);


	# Check the packet type and proceed depending on it

	# Mic-encoder packet
	if (ord($packettype) == 0x27 || ord($packettype) == 0x60) {
		# the following are obsolete mic-e types: 0x1c 0x1d
		# mic-encoder data
		# minimum body length 9 chars
		if ($paclen >= 9) {
			$rethash->{'type'} = 'location';
			return _mice_to_decimal(substr($body, 1), $dstcallsign, $srccallsign, $rethash, \%options);
		}

	# Normal or compressed location packet, with or without
	# timestamp, with or without messaging capability
	} elsif ($packettype eq '!' ||
		 $packettype eq '=' ||
		 $packettype eq '/' ||
		 $packettype eq '@') {
		# with or without messaging
		if ($packettype eq '!' || $packettype eq '/') {
			$rethash->{'messaging'} = 0;
		} else {
			$rethash->{'messaging'} = 1;
		}
		
		if ($paclen >= 14) {
			$rethash->{'type'} = 'location';
			if ($packettype eq '/' || $packettype eq '@') {
				# With a prepended timestamp, check it and jump over.
				# If the timestamp is invalid, it will be set to zero.
				$rethash->{'timestamp'} = _parse_timestamp(\%options, substr($body, 1, 7));
				if ($rethash->{'timestamp'} == 0) {
					_a_warn($rethash, 'timestamp_inv_loc');
				}
				$body = substr($body, 7);
			}
			$body = substr($body, 1); # remove the first character
			# grab the ascii value of the first byte of body
			my $poschar = ord($body);
			if ($poschar >= 48 && $poschar <= 57) {
				# poschar is a digit... normal uncompressed position
				if (length($body) >= 19) {
					$retval = _normalpos_to_decimal($body, $srccallsign, $rethash);
					# continue parsing with possible comments, but only
					# if this is not a weather report (course/speed mixup,
					# weather as comment)
					# if the comments don't parse, don't raise an error
					if ($retval == 1 && $rethash->{'symbolcode'} ne '_') {
						_comments_to_decimal(substr($body, 19), $srccallsign, $rethash);
					} else {
						#warn "maybe a weather report?\n" . substr($body, 19) . "\n";
						_wx_parse(substr($body, 19), $rethash);
					}
				}
			} elsif ($poschar == 47 || $poschar == 92
			    || ($poschar >= 65 && $poschar <= 90) || ($poschar >= 97 && $poschar <= 106) ) {
				# $poschar =~ /^[\/\\A-Za-j]$/o
				# compressed position
				if (length($body) >= 13) {
					$retval = _compressed_to_decimal(substr($body, 0, 13), $srccallsign, $rethash);
					# continue parsing with possible comments, but only
					# if this is not a weather report (course/speed mixup,
					# weather as comment)
					# if the comments don't parse, don't raise an error
					if ($retval == 1 && $rethash->{'symbolcode'} ne '_') {
						_comments_to_decimal(substr($body, 13), $srccallsign, $rethash);
					} else {
						#warn "maybe a weather report?\n" . substr($body, 13) . "\n";
						_wx_parse(substr($body, 13), $rethash);
					}
				}
			} elsif ($poschar == 33) { # '!'
				# Weather report from Ultimeter 2000
				$rethash->{'type'} = 'wx';
				return _wx_parse_peet_logging(substr($body, 1), $srccallsign, $rethash);
			} else {
				_a_err($rethash, 'packet_invalid');
				return 0;
			}
		} else {
			_a_err($rethash, 'packet_short', 'location');
			return 0;
		}

	# Weather report
	} elsif ($packettype eq '_') {
		if ($body =~ /_(\d{8})c[\- \.\d]{1,3}s[\- \.\d]{1,3}/) {
			$rethash->{'type'} = 'wx';
			return _wx_parse(substr($body, 9), $rethash);
		} else {
			_a_err($rethash, 'wx_unsupp', 'Positionless');
			return 0;
		}
		
	# Object
	} elsif ($packettype eq ';') {
		if ($paclen >= 31) {
			$rethash->{'type'} = 'object';
			return _object_to_decimal(\%options, $body, $srccallsign, $rethash);
		}

	# NMEA data
	} elsif ($packettype eq '$') {
		# don't try to parse the weather stations, require "$GP" start
		if (substr($body, 0, 3) eq '$GP') {
			# dstcallsign can contain the APRS symbol to use,
			# so read that one too
			$rethash->{'type'} = 'location';
			return _nmea_to_decimal(\%options, substr($body, 1), $srccallsign, $dstcallsign, $rethash);
		} elsif (substr($body, 0, 5) eq '$ULTW') {
			$rethash->{'type'} = 'wx';
			return _wx_parse_peet_packet(substr($body, 5), $srccallsign, $rethash);
		}

	# Item
	} elsif ($packettype eq ')') {
		if ($paclen >= 18) {
			$rethash->{'type'} = 'item';
			return _item_to_decimal($body, $srccallsign, $rethash);
		}

	# Message, bulletin or an announcement
	} elsif ($packettype eq ':') {
		if ($paclen >= 11) {
			# all are labeled as messages for the time being
			$rethash->{'type'} = 'message';
			return _message_parse($body, $srccallsign, $rethash);
		}

	# Station capabilities
	} elsif ($packettype eq '<') {
		# at least one other character besides '<' required
		if ($paclen >= 2) {
			$rethash->{'type'} = 'capabilities';
			return _capabilities_parse(substr($body, 1), $srccallsign, $rethash);
		}

	# Status reports
	} elsif ($packettype eq '>') {
		# we can live with empty status reports
		if ($paclen >= 1) {
			$rethash->{'type'} = 'status';
			return _status_parse(\%options, substr($body, 1), $srccallsign, $rethash);
		}
	
	# Telemetry
	} elsif ($body =~ /^T#(.*?),(.*)$/) {
		$rethash->{'type'} = 'telemetry';
		return _telemetry_parse(substr($body, 2), $rethash);
		
	# DX spot
	} elsif ($body =~ /^DX\s+de\s+(.*?)\s*[:>]\s*(.*)$/i) {
		$rethash->{'type'} = 'dx';
		return _dx_parse($1, $2, $rethash);
		
	# Experimental
	} elsif ($body =~ /^\{\{/i) {
		_a_err($rethash, 'exp_unsupp');
		return 0;
		
	# When all else fails, try to look for a !-position that can
	# occur anywhere within the 40 first characters according
	# to the spec.
	} else {
		my $pos = index($body, '!');
		if ($pos >= 0 && $pos <= 39) {
			$rethash->{'type'} = 'location';
			$rethash->{'messaging'} = 0;
			my $pchar = substr($body, $pos + 1, 1);
			if ($pchar =~ /^[\/\\A-Za-j]$/o) {
				# compressed position
				if (length($body) >= $pos + 1 + 13) {
					$retval = _compressed_to_decimal(substr($body, $pos + 1, 13), $srccallsign, $rethash);
					# check the APRS data extension and comment,
					# if not weather data
					if ($retval == 1 && $rethash->{'symbolcode'} ne '_') {
						_comments_to_decimal(substr($body, $pos + 14), $srccallsign, $rethash);
					}
				}
			} elsif ($pchar =~ /^\d$/io) {
				# normal uncompressed position
				if (length($body) >= $pos + 1 + 19) {
					$retval = _normalpos_to_decimal(substr($body, $pos + 1), $srccallsign, $rethash);
					# check the APRS data extension and comment,
					# if not weather data
					if ($retval == 1 && $rethash->{'symbolcode'} ne '_') {
						_comments_to_decimal(substr($body, $pos + 20), $srccallsign, $rethash);
					}
				}
			}
		}
	}

	# Return success for an ok packet
	if ($retval == 1) {
		return 1;
	}
	
	return 0;
}


# Checks a callsign for validity and strips
# trailing spaces out and returns the string.
# Returns undef on invalid callsign
sub _kiss_checkcallsign($)
{
	if ($_[0] =~ /^([A-Z0-9]+)\s*(|-\d+)$/o) {
		if (length($2) > 0) {
			# check the SSID if given
			if ($2 < -15) {
				return undef;
			}
		}
		return $1 . $2;
	}

	# no match
	return undef;
}


=over

=item kiss_to_tnc2($kissframe)

Convert a KISS-frame into a TNC-2 compatible UI-frame.
Non-UI and non-pid-F0 frames are dropped. The KISS-frame
to be decoded should not have FEND (0xC0) characters
in the beginning or in the end. Byte unstuffing
must not be done before calling this function. Returns
a string containing the TNC-2 frame (no CR and/or LF)
or undef on error.

=back

=cut

sub kiss_to_tnc2($) {
	my $kissframe = shift @_;

	my $asciiframe = "";
	my $dstcallsign = "";
	my $callsigntmp = "";
	my $digipeatercount = 0; # max. 8 digipeaters

	# perform byte unstuffing for kiss first
	$kissframe =~ s/\xdb\xdc/\xc0/g;
	$kissframe =~ s/\xdb\xdd/\xdb/g;

	# length checking _after_ byte unstuffing
	if (length($kissframe) < 16) {
		if ($debug > 0) {
			warn "too short frame to be valid kiss\n";
		}
		return undef;
	}

	# the first byte has to be zero (kiss data)
	if (ord(substr($kissframe, 0, 1)) != 0) {
		if ($debug > 0) {
			warn "not a kiss data frame\n";
		}
		return undef;
	}

	my $addresspart = 0;
	my $addresscount = 0;
	while (length($kissframe) > 0) {
		# in the first run this removes the zero byte,
		# in subsequent runs this removes the previous byte
		$kissframe = substr($kissframe, 1);
		my $charri = substr($kissframe, 0, 1);

		if ($addresspart == 0) {
			$addresscount++;
			# we are in the address field, go on
			# decoding it
			# switch to numeric
			$charri = ord($charri);
			# check whether this is the last
			# (0-bit is one)
			if ($charri & 1) {
				if ($addresscount < 14 ||
				    ($addresscount % 7) != 0) {
					# addresses ended too soon or in the
					# wrong place
					if ($debug > 0) {
						warn "addresses ended too soon or in the wrong place in kiss frame\n";
					}
					return undef;
				}
				# move on to control field next time
				$addresspart = 1;
			}
			# check the complete callsign
			# (7 bytes)
			if (($addresscount % 7) == 0) {
				# this is SSID, get the number
				my $ssid = ($charri >> 1) & 0xf;
				if ($ssid != 0) {
					# don't print zero SSID
					$callsigntmp .= "-" . $ssid;
				}
				# check the callsign for validity
				my $chkcall = _kiss_checkcallsign($callsigntmp);
				if (not(defined($chkcall))) {
					if ($debug > 0) {
						warn "Invalid callsign in kiss frame, discarding\n";
					}
					return undef;
				}
				if ($addresscount == 7) {
					# we have a destination callsign
					$dstcallsign = $chkcall;
					$callsigntmp = "";
					next;
				} elsif ($addresscount == 14) {
					# we have a source callsign, copy
					# it to the final frame directly
					$asciiframe = $chkcall . ">" . $dstcallsign;
					$callsigntmp = "";
				} elsif ($addresscount > 14) {
					# get the H-bit as well if we
					# are in the path part
					$asciiframe .= $chkcall;
					$callsigntmp = "";
					if ($charri & 0x80) {
						$asciiframe .= "*";
					}
					$digipeatercount++;
				} else {
					if ($debug > 0) {
						warn "Internal error 1 in kiss_to_tnc2()\n";
					}
					return undef;
				}
				if ($addresspart == 0) {
					# more address fields will follow
					# check that there are a maximum
					# of eight digipeaters in the path
					if ($digipeatercount >= 8) {
						if ($debug > 0) {
							warn "Too many digipeaters in kiss packet, discarding\n";
						}
						return undef;
					}
					$asciiframe .= ",";
				} else {
					# end of address fields
					$asciiframe .= ":";
				}
				next;
			}
			# shift one bit right to get the ascii
			# character
			$charri >>= 1;
			$callsigntmp .= chr($charri);

		} elsif ($addresspart == 1) {
			# control field. we are only interested in
			# UI frames, discard others
			$charri = ord($charri);
			if ($charri != 3) {
				if ($debug > 0) {
					warn "not UI frame, skipping\n";
				}
				return undef;
			}
			#print " control $charri";
			$addresspart = 2;

		} elsif ($addresspart == 2) {
			# PID
			#printf(" PID %02x data: ", ord($charri));
			# we want PID 0xFO
			$charri = ord($charri);
			if ($charri != 0xf0) {
				if ($debug > 0) {
					warn "PID not 0xF0, skipping\n";
				}
				return undef;
			}
			$addresspart = 3;

		} else {
			# body
			$asciiframe .= $charri;
		}
	}

	# Ok, return whole frame
	return $asciiframe;
}

=over

=item tnc2_to_kiss($tnc2frame)

Convert a TNC-2 compatible UI-frame into a KISS data
frame (single port KISS TNC). The frame will be complete,
i.e. it has byte stuffing done and FEND (0xC0) characters
on both ends. If conversion fails, return undef.

=back

=cut

sub tnc2_to_kiss($) {
	my $gotframe = shift @_;

	my $kissframe = chr(0); # kiss frame starts with byte 0x00
	my $body;
	my $header;

	# separate header and body
	if ($gotframe =~ /^([A-Z0-9,*>-]+):(.+)$/o) {
		$header = $1;
		$body = $2;
	} else {
		if ($debug > 0) {
			warn "tnc2_to_kiss(): separation into header and body failed\n";
		}
		return undef;
	}

	# separate the sender, recipient and digipeaters
	my $sender;
	my $sender_ssid;
	my $receiver;
	my $receiver_ssid;
	my $digipeaters;
	if ($header =~ /^([A-Z0-9]{1,6})(-\d+|)>([A-Z0-9]{1,6})(-\d+|)(|,.*)$/o) {
		$sender = $1;
		$sender_ssid = $2;
		$receiver = $3;
		$receiver_ssid = $4;
		$digipeaters = $5;
	} else {
		if ($debug > 0) {
			warn "tnc2_to_kiss(): separation of sender and receiver from header failed\n";
		}
		return undef;
	}

	# Check SSID format and convert to number
	if (length($sender_ssid) > 0) {
		$sender_ssid = 0 - $sender_ssid;
		if ($sender_ssid > 15) {
			if ($debug > 0) {
				warn "tnc2_to_kiss(): sender SSID ($sender_ssid) is over 15\n";
			}
			return undef;
		}
	} else {
		$sender_ssid = 0;
	}
	if (length($receiver_ssid) > 0) {
		$receiver_ssid = 0 - $receiver_ssid;
		if ($receiver_ssid > 15) {
			if ($debug > 0) {
				warn "tnc2_to_kiss(): receiver SSID ($receiver_ssid) is over 15\n";
			}
			return undef;
		}
	} else {
		$receiver_ssid = 0;
	}
	# pad callsigns to 6 characters with space
	$sender .= ' ' x (6 - length($sender));
	$receiver .= ' ' x (6 - length($receiver));
	# encode destination and source
	for (my $i = 0; $i < 6; $i++) {
		$kissframe .= chr(ord(substr($receiver, $i, 1)) << 1);
	}
	$kissframe .= chr(0xe0 | ($receiver_ssid << 1));
	for (my $i = 0; $i < 6; $i++) {
		$kissframe .= chr(ord(substr($sender, $i, 1)) << 1);
	}
	if (length($digipeaters) > 0) {
		$kissframe .= chr(0x60 | ($sender_ssid << 1));
	} else {
		$kissframe .= chr(0x61 | ($sender_ssid << 1));
	}

	# if there are digipeaters, add them
	if (length($digipeaters) > 0) {
		$digipeaters =~ s/,//; # remove the first comma
		# split into parts
		my @digis = split(/,/, $digipeaters);
		my $digicount = scalar(@digis);
		if ($digicount > 8 || $digicount < 1) {
			# too many (or none?!?) digipeaters
			if ($debug > 0) {
				warn "tnc2_to_kiss(): too many (or zero) digipeaters: $digicount\n";
			}
			return undef;
		}
		for (my $i = 0; $i < $digicount; $i++) {
			# split into callsign, SSID and h-bit
			if ($digis[$i] =~ /^([A-Z0-9]{1,6})(-\d+|)(\*|)$/o) {
				my $callsign = $1 . ' ' x (6 - length($1));
				my $ssid = 0;
				my $hbit = 0x00;
				if (length($2) > 0) {
					$ssid = 0 - $2;
					if ($ssid > 15) {
						if ($debug > 0) {
							warn "tnc2_to_kiss(): digipeater nr. $i SSID ($ssid) invalid\n";
						}
						return undef;
					}
				}
				if ($3 eq '*') {
					$hbit = 0x80;
				}
				# add to kiss frame
				for (my $k = 0; $k < 6; $k++) {
					$kissframe .= chr(ord(substr($callsign, $k, 1)) << 1);
				}
				if ($i + 1 < $digicount) {
					# more digipeaters to follow
					$kissframe .= chr($hbit | 0x60 | ($ssid << 1));
				} else {
					# last digipeater
					$kissframe .= chr($hbit | 0x61 | ($ssid << 1));
				}
				
			} else {
				if ($debug > 0) {
					warn "tnc2_to_kiss(): digipeater nr. $i parsing failed\n";
				}
				return undef;
			}
		}
	}

	# add frame type (0x03) and PID (0xF0)
	$kissframe .= chr(0x03) . chr(0xf0);
	# add frame body
	$kissframe .= $body;
	# perform KISS byte stuffing
	$kissframe =~ s/\xdb/\xdb\xdd/g;
	$kissframe =~ s/\xc0/\xdb\xdc/g;
	# add FENDs
	$kissframe = chr(0xc0) . $kissframe . chr(0xc0);

	return $kissframe;
}

=over

=item aprs_duplicate_parts($packet)

Accepts a TNC-2 format frame and extracts the original
sender callsign, destination callsign (without ssid) and
payload data for duplicate detection. Returns
sender, receiver and body on success, undef on error.
In the case of third party packets, always gets this
information from the innermost data. Also removes
possible trailing spaces to improve detection
(e.g. aprsd replaces trailing CRs or LFs in a packet with a space).

=back

=cut

sub aprs_duplicate_parts($)
{
	my ($packet) = @_;

	# If this is a third party packet format,
	# strip out the outer layer and focus on the inside.
	# Do this several times in a row if necessary
	while (1) {
		if ($packet =~ /^[^:]+:\}(.*)$/io) {
			$packet = $1;
		} else {
			last;
		}
	}

	if ($packet =~ /^([A-Z0-9]{1,6})(-[A-Z0-9]{1,2}|)>([A-Z0-9]{1,6})(-\d{1,2}|)(:|,[^:]+:)(.*)$/io) {
		my $source;
		my $destination;
		my $body = $6;
		if ($2 eq "") {
			# ssid 0
			$source = $1 . "-0";
		} else {
			$source = $1 . $2;
		}
		# drop SSID for destination
		$destination = $3;
		# remove trailing spaces from body
		$body =~ s/\s+$//;
		return ($source, $destination, $body);
	}

	return undef;
}

=over

=item make_object($name, $tstamp, $lat, $lon, $symbols, $speed, $course, $altitude, $alive, $usecompression, $posambiguity, $comment)

Creates an APRS object. Returns a body of an APRS object, i.e. ";OBJECTNAM*DDHHMM/DDMM.hhN/DDDMM.hhW$CSE/SPDcomments..."
or undef on error.

Parameters:

 1st: object name, has to be valid APRS object name, does not need to be space-padded
 2nd: object timestamp as a unix timestamp, or zero to use current time
 3rd: object latitude, decimal degrees
 4th: object longitude, decimal degrees
 5th: object symbol table (or overlay) and symbol code, two bytes if the given symbole length is zero (""), use point (//)
 6th: object speed, -1 if non-moving (km/h)
 7th: object course, -1 if non-moving
 8th: object altitude, -10000 or less if not used
 9th: alive or dead object (0 == dead, 1 == alive)
 10th: compressed (1) or uncompressed (0)
 11th: position ambiguity (0..4)
 12th: object comment text


Note: Course/speed/altitude/compression is not implemented.

This function API will probably change in the near future. The long list of
parameters should be changed to hash with named parameters.

=back

=cut

sub make_object($$$$$$$$$$$$) {
# FIXME: course/speed/altitude/compression not implemented
	my $name = shift @_;
	my $tstamp = shift @_;
	my $lat = shift @_;
	my $lon = shift @_;
	my $symbols = shift @_;
	my $speed = shift @_;
	my $course = shift @_;
	my $altitude = shift @_;
	my $alive = shift @_;
	my $usecompression = shift @_;
	my $posambiguity = shift @_;
	my $comment = shift @_;

	my $packetbody = ";";

	# name
	if ($name =~ /^([\x20-\x7e]{1,9})$/o) {
		# also pad with whitespace
		$packetbody .= $1 . " " x (9 - length($1));
	} else {
		return undef;
	}

	# dead/alive
	if ($alive == 1) {
		$packetbody .= "*";
	} elsif ($alive == 0) {
		$packetbody .= "_";
	} else {
		return undef;
	}

	# timestamp, hardwired for DHM
	my $aptime = make_timestamp($tstamp, 0);
	if (not(defined($aptime))) {
		return undef;
	} else {
		$packetbody .= $aptime;
	}

	# actual position
	my $posstring = make_position($lat, $lon, $speed, $course, $altitude, $symbols, $usecompression, $posambiguity);
	if (not(defined($posstring))) {
		return undef;
	} else {
		$packetbody .= $posstring;
	}

	# add comments to the end
	$packetbody .= $comment;

	return $packetbody;
}

=over

=item make_timestamp($timestamp, $format)

Create an APRS (UTC) six digit (DHM or HMS) timestamp from a unix timestamp.
The first parameter is the unix timestamp to use, or zero to use
current time. Second parameter should be one for
HMS format, zero for DHM format.

Returns a 7-character string (e.g. "291345z") or undef on error.

=back

=cut

sub make_timestamp($$) {
	my $tstamp = shift @_;
	my $tformat = shift @_;

	if ($tstamp == 0) {
		$tstamp = time();
	}

	my ($day, $hour, $minute, $sec) = (gmtime($tstamp))[3,2,1,0];
	if (not(defined($day))) {
		return undef;
	}

	my $tstring = "";
	if ($tformat == 0) {
		$tstring = sprintf("%02d%02d%02dz", $day, $hour, $minute);
	} elsif ($tformat == 1) {
		$tstring = sprintf("%02d%02d%02dh", $hour, $minute, $sec);
	} else {
		return undef;
	}
	return $tstring;
}

=over

=item make_position($lat, $lon, $speed, $course, $altitude, $symbols, $optionref)

Creates an APRS position for position/object/item. Parameters:

 1st: latitude in decimal degrees
 2nd: longitude in decimal degrees
 3rd: speed in km/h, -1 == don't include
 4th: course in degrees, -1 == don't include. zero == unknown course, 360 == north
 5th: altitude in meters above mean sea level, -10000 or under == don't use
 6th: aprs symbol to use, first table/overlay and then code (two bytes). If string length is zero (""), uses default.
 7th: hash reference for options:
 
 "compressed": 1 for compressed format
 "ambiguity": Use amount (0..4) of position ambiguity. Note that position ambiguity and compression can't be used at the same time.
 "dao": Use !DAO! extension for improved precision

Returns a string such as "1234.56N/12345.67E/CSD/SPD" or in
compressed form "F*-X;n_Rv&{-A" or undef on error.

Please note: course/speed/altitude are not supported yet, and neither is compressed format or position ambiguity.

This function API will probably change in the near future. The long list of
parameters should be changed to hash with named parameters.

=back

=cut

sub make_position($$$$$$;$)
{
# FIXME: course/speed/altitude are not supported yet,
#        neither is compressed format or position ambiguity
	my($lat, $lon, $speed, $course, $altitude, $symbol, $options) = @_;
	
	if (!$options) {
		$options = { };
	}
	
	if ($options->{'ambiguity'}) {
		# can't be ambiguous and then add precision with !DAO!
		delete $options->{'dao'};
	}

	if ($lat < -89.99999 ||
	    $lat > 89.99999 ||
	    $lon < -179.99999 ||
	    $lon > 179.99999) {
		# invalid location
		return undef;
	}

	my $symboltable = "";
	my $symbolcode = "";
	if (length($symbol) == 0) {
		$symboltable = "/";
		$symbolcode = "/";
	} elsif ($symbol =~ /^([\/\\A-Z0-9])([\x21-\x7b\x7d])$/o) {
		$symboltable = $1;
		$symbolcode = $2;
	} else {
		return undef;
	}

	if ($options->{'compression'}) {
		my $latval = 380926 * (90 - $lat);
		my $lonval = 190463 * (180 + $lon);
		my $latstring = "";
		my $lonstring = "";
		for (my $i = 3; $i >= 0; $i--) {
			# latitude character
			my $value = int($latval / (91 ** $i));
			$latval = $latval % (91 ** $i);
			$latstring .= chr($value + 33);
			# longitude character
			$value = int($lonval / (91 ** $i));
			$lonval = $lonval % (91 ** $i);
			$lonstring .= chr($value + 33);
		}
		# encode overlay character if it is a number
		$symboltable =~ tr/0-9/a-j/;
		# FIXME: no altitude/radiorange encoding
		my $retstring = $symboltable . $latstring . $lonstring . $symbolcode;
		if ($speed >= 0 && $course > 0 && $course <= 360) {
			# In APRS spec unknown course is zero normally (and north is 360),
			# but in compressed aprs north is zero and there is no unknown course.
			# So round course to nearest 4-degree section and remember
			# to do the 360 -> 0 degree transformation.
			my $cval = int(($course + 2) / 4);
			if ($cval > 89) {
				$cval = 0;
			}
			$retstring .= chr($cval + 33);
			# speed is in knots in compressed form. round to nearest integer
			my $speednum = int((log(($speed / $knot_to_kmh) + 1) / log(1.08)) + 0.5);
			if ($speednum > 89) {
				# limit top speed
				$speednum = 89;
			}
			$retstring .= chr($speednum + 33) . "A";
		} else {
			$retstring .= "  A";
		}
		return $retstring;

	# normal position format
	} else {
		# convert to degrees and minutes
		my $isnorth = 1;
		if ($lat < 0.0) {
			$lat = 0 - $lat;
			$isnorth = 0;
		}
		my $latdeg = int($lat);
		my $latmin = ($lat - $latdeg) * 60;
		my $latmin_s;
		my $latmin_dao;
		# if we're doing DAO, round to 6 digits and grab the last 2 characters for DAO
		if ($options->{'dao'}) {
			$latmin_s = sprintf("%06.0f", $latmin * 10000);
			$latmin_dao = substr($latmin_s, 4, 2);
		} else {
			$latmin_s = sprintf("%04.0f", $latmin * 100);
		}
		my $latstring = sprintf("%02d%02d.%02d", $latdeg, substr($latmin_s, 0, 2), substr($latmin_s, 2, 2));
		my $posambiguity = $options->{'ambiguity'};
		if (defined $posambiguity && $posambiguity > 0 && $posambiguity <= 4) {
			# position ambiguity
			if ($posambiguity <= 2) {
				# only minute decimals are blanked
				$latstring = substr($latstring, 0, 7 - $posambiguity) . " " x $posambiguity;
			} elsif ($posambiguity == 3) {
				$latstring = substr($latstring, 0, 3) . " .  ";
			} elsif ($posambiguity == 4) {
				$latstring = substr($latstring, 0, 2) . "  .  ";
			}
		}
		if ($isnorth == 1) {
			$latstring .= "N";
		} else {
			$latstring .= "S";
		}
		my $iseast = 1;
		if ($lon < 0.0) {
			$lon = 0 - $lon;
			$iseast = 0;
		}
		my $londeg = int($lon);
		my $lonmin = ($lon - $londeg) * 60;
		my $lonmin_s;
		my $lonmin_dao;
		# if we're doing DAO, round to 6 digits and grab the last 2 characters for DAO
		if ($options->{'dao'}) {
			$lonmin_s = sprintf("%06.0f", $lonmin * 10000);
			$lonmin_dao = substr($lonmin_s, 4, 2);
		} else {
			$lonmin_s = sprintf("%04.0f", $lonmin * 100);
		}
		my $lonstring = sprintf("%03d%s.%s", $londeg, substr($lonmin_s, 0, 2), substr($lonmin_s, 2, 2));
		if (defined $posambiguity && $posambiguity > 0 && $posambiguity <= 4) {
			# position ambiguity
			if ($posambiguity <= 2) {
				# only minute decimals are blanked
				$lonstring = substr($lonstring, 0, 8 - $posambiguity) . " " x $posambiguity;
			} elsif ($posambiguity == 3) {
				$lonstring = substr($lonstring, 0, 4) . " .  ";
			} elsif ($posambiguity == 4) {
				$lonstring = substr($lonstring, 0, 3) . "  .  ";
			}
		}
		if ($iseast == 1) {
			$lonstring .= "E";
		} else {
			$lonstring .= "W";
		}
		
		my $retstring;
		
		if ($options->{'timestamp'}) {
			my($sec,$min,$hour) = gmtime($options->{'timestamp'});
			$retstring = sprintf('/%02d%02d%02dh', $hour, $min, $sec);
		} else {
			$retstring = '!';
		}
		$retstring .= $latstring . $symboltable . $lonstring . $symbolcode;
		
		# add course/speed, if given
		if (defined $speed && defined $course && $speed >= 0 && $course >= 0) {
			# convert speed to knots
			$speed = $speed / $knot_to_kmh;
			if ($speed > 999) {
				$speed = 999; # maximum speed
			}
			if ($course > 360) {
				$course = 0; # unknown course
			}
			$retstring .= sprintf("%03d/%03d", $course, $speed);
		}
		
		if (defined $altitude) {
			$altitude = $altitude / $feet_to_meters;
			# /A=(-\d{5}|\d{6})
			if ($altitude >= 0) {
				$retstring .= sprintf("/A=%06.0f", $altitude);
			} else {
				$retstring .= sprintf("/A=-%05.0f", $altitude * -1);
			}
		}
		
		if ($options->{'comment'}) {
			$retstring .= $options->{'comment'};
		}
		
		if ($options->{'dao'}) {
			# !DAO! extension, use Base91 format for best precision
			# /1.1 : scale from 0.99 to 0..90 for base91, int(... + 0.5): round to nearest integer
			my $dao = '!w' . chr(int($latmin_dao/1.1 + 0.5) + 33) . chr(int($lonmin_dao/1.1 + 0.5) + 33) . '!';
			$retstring .= $dao;
		}
		
		return $retstring;
	}
}


1;
__END__


=head1 SEE ALSO

APRS specification 1.0.1, L<http://www.tapr.org/aprs_working_group.html>

APRS addendums, e.g. L<http://www.aprs.org/aprs11.html>

The source code of this module - there are some undocumented features.

libfap, a C library port of this module, L<http://pakettiradio.net/libfap/>

Python bindings for libfap, L<http://github.com/kd7lxl/python-libfap>

=head1 AUTHORS

Tapio Sokura, OH2KKU E<lt>tapio.sokura@iki.fiE<gt>

Heikki Hannikainen, OH7LZB E<lt>hessu@hes.iki.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2012 by Tapio Sokura

Copyright 2007-2012 by Heikki Hannikainen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
