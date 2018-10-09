package Ham::Resources::Utils;

use 5.006;
use Math::Trig qw(great_circle_distance deg2rad great_circle_direction rad2deg pi asin acos tan);
use Ham::Locator;
use strict;
use warnings;

=head1 NAME

Ham::Resources::Utils - Calculation of distance and course beetwen two points
on Earth (through coordinates or grid locator), and Sunrise, Sunset and Midday time for these locations (in UTC). Also sexagesimal degrees and decimal degrees convertion and grid location. For use mainly for Radio Amateurs.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

my %coordinates = (
		long_1 	=> "",
		lat_1 	=> "",
		long_2 	=> "",
		lat_2 	=> "",
);

my $locator_precision = 8;

my $self = {};

=head1 SYNOPSIS

This module calculates the distance and course between two points on the Earth.
Also Sunrise, Sunset and Midday time for both locations.

The data of the locations may be in terrestrial coordinates or through 'Maidenhead Locator System' (grid Locator) notacion.

The module offer the possibility to access to some methods that uses it, for
example conversions between sexagesimal degrees into decimal degrees or
conversion between grid locator to sexagesimal degrees.

Also access to convert decimal degrees to compass names, and more.

    use Ham::Resources::Utils;

    my $foo = Ham::Resources::Utils->new();
    ...


=head1 SUBROUTINES/METHODS

=head2 new

This is the constructor.

    my $foo = Ham::Resources::Utils->new();

=cut

sub new { bless {}, shift }


=head2 data_by_coordinates

Gets a string with the date and a hash with the coordinates in sexagesimal
values from point A and point B and returns a hash with all previous
data and Distance, course and compass values and Sunrise, Sunset and Midday
times for both locations if needed.

    my $date = "14-03-2012";
    my %coordinates = ( lat_1 => "41N23",
    			long_1 => "2E11",
    			lat_2 => "30S0",
    			long_2 => "10W45");

    my %data = $foo->data_by_coordinates{$date, %coordinates};
    print Dumper(%data);

The $date argument is necessary for the Sun time calculations (Sunrise, Sunset and Midday).

Distances are in kilometers (km) and Miles (mi). Times are in UTC (Universal Time).

An output example:

  DATA_BY_COORDINATES()
    compass: S                       # compass direction to point B or destination
    course_dec: 190.94              # direction to destination in decimal degree
    course_sexag: 190.56          # direction to destination in sexagesimal degree
    date: 14-3-2012                 # date of event (for Sun calculation porpouses)
    distance_km: 9377.83            # distance to destination in kilometers
    distance_mi: 17367.74           # distance to destination in miles
    lat_1: 41N23"              # Latitude of point A or origin in sexagesinal notation
    lat_1_dec: 41.3833333333333     # Latitude of origin in decimal notation
    lat_2: 41S54"              # Latitude of point B or destination in sexagesimal notation
    lat_2_dec: -41.9                # Latiude of destination in decimal notation
    locator_1: JN11cj               # Grid Locator of origin point
    locator_2: IE38sc               # Grid Locator of destination point
    long_1: 2E12"              # Longitude of point A or origin in sexagesimal notation
    long_1_dec: 2.2                 # Longitude of origin in decimal notation
    long_2: 12W30"             # Longitude of point B or destination in sexagesimal notation
    long_2_dec: -12.5               # Longitude of destination in decimal notation
    midday_arrive: 12h 1m           # Midday time on point B (destination) in UTC
    midday_departure: 12h 1m        # Midday time on point A (origin) in UTC
    sunrise_arrive: 6h 5m           # Sun rise time on point B (destination) in UTC
    sunrise_departure: 6h 5m        # Sun rise time on point A (origin) in UTC
    sunset_arrive: 17h 58m          # Sun set time on point B (destination) in UTC
    sunset_departure: 17h 58m       # Sun set time on point A (origin) in UTC


=cut

sub data_by_coordinates {
	my $self = shift;
	my $date = shift;
	my %coordinates = @_;
	my %data = data_constructor($self, $date, %coordinates);
}

=head2 data_by_locator

Gets a string with the date and a string with the locator of point 'A' and an
string with a locator for point 'B'. Returns a hash with the data shown it in the
previous method.

   my $date = "14-03-2012"; # date in 'dd-mm-yyyy' format
   my $locator_dep = "JN11cj";
   my $locator_arr = "IJ90ca";

   my %data = $foo->data_by_locator($date,$locator_dep,$locator_arr);
   print Dumper(%data);

=cut

sub data_by_locator {
	my $self = shift;
	my $date = shift;
	my ($locator_dep, $locator_arr) = @_;
	my ($lat_dep, $long_dep, $lat_arr, $long_arr) = undef;
	($lat_dep, $long_dep) = loc2degree($self,$locator_dep) if ($locator_dep);
	($lat_arr, $long_arr) = loc2degree($self,$locator_arr) if ($locator_arr);

	$lat_dep =~ s/\./N/ if ($lat_dep !~ /^\s\d+/);
	$lat_dep =~ s/\./S/ if ($lat_dep =~ /^\s\d+/);
	$lat_arr =~ s/\./N/ if ($lat_arr !~ /^\s\d+/);
   $lat_arr =~ s/\./S/ if ($lat_arr =~ /^\s\d+/);

	$long_dep =~ s/\./E/ if ($long_dep !~ /^\s\d+/);
   $long_dep =~ s/\./W/ if ($long_dep =~ /^\s\d+/);
   $long_arr =~ s/\./E/ if ($long_arr !~ /^\s\d+/);
   $long_arr =~ s/\./W/ if ($long_arr =~ /^\s\d+/);

	my %coordinates = (
			long_1 	=> $long_dep,
			lat_1	=> $lat_dep,
			long_2	=> $long_arr,
			lat_2	=> $lat_arr,
	);

	my %data = data_constructor($self, $date, %coordinates);
}

sub data_constructor {
	my $self = shift;
	my $date = shift;
	my %coord = @_;
	my $error = "";

	%coord = (%coord, sexag2dec($self, %coord));
	%coord = check_error(%coord);

	my @DEPARTURE = NESW( $coord{long_1_dec}, $coord{lat_1_dec} );
	my @ARRIVE = NESW( $coord{long_2_dec}, $coord{lat_2_dec} );
	my $km = great_circle_distance(@DEPARTURE, @ARRIVE, 6371); # medium value for Earth radii
	$km = sprintf("%.2f",$km);
	my $mi = $km / 1.609344; # miles conversion
	$mi = sprintf("%.2f",$mi);
	my $rad = great_circle_direction(@DEPARTURE, @ARRIVE);
	my $sexag = dec2sexag($self, rad2deg($rad));
	my $rad_round = sprintf("%.2f",(rad2deg($rad)));
	my $compass = compass($self, rad2deg($rad));

	my $locator_dep = degree2loc($self, $coord{lat_1}, $coord{long_1});
	my $locator_arr = degree2loc($self, $coord{lat_2}, $coord{long_2});


	my %sun_departure = cicle_sun($self, $coord{lat_1_dec}, $coord{long_1_dec}, $date, "_departure");
	my %sun_arrive = cicle_sun($self, $coord{lat_2_dec}, $coord{long_2_dec}, $date, "_arrive");

	%coord = (  %coord,
					distance_km 	=> $km,
					distance_mi 	=> $mi,
					course_sexag 	=> $sexag,
					course_dec		=> $rad_round,
					compass			=> $compass,
					date				=> $date,
					locator_1		=> $locator_dep,
					locator_2		=> $locator_arr,
					%sun_departure, %sun_arrive
	);
	if ($error) { return my %error = (_error => $error); }

	return %coord;
}

=head2 loc2degree

Gets a string with grid locator value and returns an array with the latitude and
longitude in sexagesimal degrees form. Grid precision only 6 digit.

=cut

sub loc2degree {
	my ($self,$loc) = @_;
	my $grid = new Ham::Locator;
	$grid->set_precision($locator_precision);
	$loc = substr($loc, 0, 6) if (length($loc) > 6);

	$grid->set_loc($loc);
	my ($latitude, $longitude) = $grid->loc2latlng;
	my $lat_sexag = dec2sexag($self, $latitude);
	my $long_sexag = dec2sexag($self, $longitude);

	$lat_sexag =~ tr/-/ / if($latitude < 0);
	$long_sexag =~ tr/S/W/ if($longitude < 0);
	$long_sexag =~ tr/N/E/ if($longitude > 0);
	$long_sexag =~ tr/-/ / if($longitude < 0);

	return ($lat_sexag, $long_sexag);
}

=head2 degree2loc

Gets a string with the latitude and a string with the longitude, in sexagesimal
notation, of a point on Earth and returns a string with the grid locator notation.
Grid precision now is 8 digit.

    my $lat = "41N23";
    my $long = "2E11";
    my $locator = $foo->degree2loc($lat, $long);

=cut

sub degree2loc {
	my ($self, $lat, $long) = @_;
	my %deg_coord = (
		lat_1  => $lat,
		long_1 => $long
	);
	my %dec_coord = sexag2dec($self, %deg_coord);
	my %check = check_error(%dec_coord);
	if ($check{_error}) { return "Error to convert degrees to locator."; }

	my $m = new Ham::Locator;
	$m->set_precision($locator_precision);
	$m->set_latlng($dec_coord{lat_1_dec}, $dec_coord{long_1_dec});
	my $loc = $m->latlng2loc;
}

=head2 compass

Gets an integer with a decimal degree and returns a string with its
equivalent value in a compass (North, East, ...). It uses a separation of 11.25
degrees for each position, 32 cardinal positions of total.
Values range must be between 0 to 360 degrees.

    my $compass = $foo->compass("-90.0"); # returns "W" (west)
    my $compass = $foo->compass("270.0"); # returns "W" (west)

=cut

sub compass {
	my $self = shift;
	my $course = shift;
	my $pattern = qr/(\+?)(-?)\d{1,3}(\.?)(\d*)$/;
	my $error_msg = "Error value must be a integer between 0 to 360";

	if ($course !~ $pattern) {
		return $error_msg;
	} else {
		if ($course < -360 or $course > 360) { return $error_msg; }
		my @rosa = ('NbE','NNE','NEbN','NE','NEbE','ENE','EbN','E','EbS','ESE','SEbE','SE','SEbS','SSE','SbE','S','SbW','SSW','SWbS','SW','SWbW','WSW','WbS','W','WbN','WNW','NWbW','NW','NWbN','NNW','NbW','N');

		my $rosa_index = int((+$course / 11.25))-1;
		return $rosa[$rosa_index];
	}
}

=head2 dec2sexag

Gets an integer with a decimal degree value and returns a string  with its
equivalence to sexagesimal degree form. Only returns degrees and minutes.

=cut

sub  dec2sexag{
	my ($self, $course) = @_;
	my @degree_part = split(/\./, $course);
	my $decimal = (('0.'.$degree_part[1]) * 60);
	my $min = int((sprintf("%.2f",$decimal)));
	my $sexag = $degree_part[0].".".$min;
}

=head2 sexag2dec

Gets a hash with sexagesimal value (maximun four) and returns a hash with its
decimal values.

Range of values are -90 to 90 for latitudes, and -180 to 180 for longitudes.

Values must be a pair, longitude and latitude. Two values for one point or
four values (two pairs) for two points.

There is not mandatory send a complete hash (4 values), but you will receive a
hash with the four.

You can use it like this:

    my %coord = (
	Long_1 => "41N23.30",
      	Lat_1  => "2E11.10"
    );
    my %sexag = $foo->sexag2dec(%coord);
    foreach my $key (sort keys %sexag) {
      say $key." = ".$sexag{$key} if ($sexag{$key});
    }

The index send it, you will receive with '_dec' suffix, ie, you send
'latitude' and receive 'latitude_dec'

=cut

sub sexag2dec {
	my $self = shift;
   my %coord = @_;

   my $error_msg_1 = "Error sexagesimal conversion. Out of range. (-90 to 90)";
   my $error_msg_2 = "Error sexagesimal conversion. Out of range. (-180 to 180)";

   my $grad_match = qr|(\d{1,3})([NSEOW+-\.])(\d{1,2})\.{0,1}(\d{0,2}){0,1}|i;
	my %coord_dec = (
			lat_1_dec		=> '',
			lat_2_dec		=> '',
			long_1_dec		=> '',
			long_2_dec		=> '',
	);
	my $secs = undef;
   foreach my $key (sort keys %coord) {
		if ($4) {$secs = $4/3600;} else {$secs = 0}
		if ($key && ($coord{$key} =~ $grad_match)) {
		   if ($2 eq 'S' || $2 eq 'W' || $2 eq '-') {
				$coord_dec{$key.'_dec'} = (-($1+(($3/60)+$secs)));
		   	if ($2 eq 'S' && $coord_dec{$key.'_dec'} < -90) { $coord_dec{$key.'_dec'} = $error_msg_1; }
		   	if ($2 eq 'W' && $coord_dec{$key.'_dec'} < -180) { $coord_dec{$key.'_dec'} = $error_msg_2; }
			} else {
				$coord_dec{$key.'_dec'} = ($1+(($3/60)+$secs));
		   	if ($2 eq 'N' && $coord_dec{$key.'_dec'} > 90) { $coord_dec{$key.'_dec'} = $error_msg_1; }
		   	if ($2 eq 'E' && $coord_dec{$key.'_dec'} > 180) { $coord_dec{$key.'_dec'} = $error_msg_2; }
			}
		}
   }
	return %coord_dec;
}

=head2 cicle_sun

Gets three strings with latitude, longitude, in decimal degrees, and date, in
'dd-mm-yyyy' format and returns a hash with Sunrise time, Sunset time and
Midday time in hours and minutes format in Universal Time (UTC).

    my %sun = $foo->cicle_sun($lat,$long,$date);

=cut

sub cicle_sun {
	my $self = shift;
	my ($Lat, $Long, $date, $origin_point) = @_;

	$origin_point = "" if (!$origin_point);
	$date = "00-00-0000" if ($date =~ /Error/);
	$Lat = 0 if ($Lat =~ /Error/);
	$Long = 0 if ($Long =~ /Error/);

	my @date_ = date_split($self, $date);
	my $day = $date_[0];
	my $month = $date_[1];
	my $year = $date_[2];
	my $UT = '0';

      if ($day =~ /Error/) {
                return my %solar_cycle = (_error => $day);
        }


	# Julian data
	my $GGG = 1;
	my $S = 1;

	if ($year <= 1585) { $GGG = 0; }
	my $JD = -1 * int(7 * (int(($month + 9) / 12 ) + $year) / 4);
	if (($month - 9) < 0) { $S = -1; }
	my $A = abs($month - 9);
	my $J1 = int($year + $S * int($A / 7));
	$J1 = -1 * int((int($J1 / 100) + 1) * 3 / 4);
	$JD = $JD + int(275 * $month / 9) + $day + ($GGG * $J1);
   $JD = $JD + 1721027 + 2 * $GGG + 367 * $year - 0.5;
   my $J2 = $JD;

	# Earth values
	my $RAD = 180 / pi;
	my $ET = 0.016718;
	my $VP = 8.22e-5;
	my $P = 4.93204;
	my $M0 = 2.12344;
	my $MN = 1.72019e-2;
	my $T0 = 2444000.5;
	$S = 2415020.5;
	$P = $P + ($J2 - $T0) * $VP / 100;
	my $AM = $M0 + $MN * ($J2 - $T0);
	$AM = $AM - 2 * pi * int($AM / (2 * pi));

	# Kepler equation for the Earth
	my $V = $AM + 2 * $ET * sin($AM) + 1.25 * $ET * $ET * sin(2 * $AM);
	if ($V < 0) {
		$V = 2 * pi + $V;
	}
	my $L = $P + $V;
	$L = $L - 2 * pi * int($L / (2 * pi));

	#AR and DEC calculus
	my $Z = ($J2 - 2415020.5) / 365.2422;
	my $OB = 23.452294 - (0.46845 * $Z + 0.00000059 * $Z * $Z) / 3600;
	$OB = $OB / $RAD;
	my $DC = asin(sin($OB) * sin($L));
	my $AR = acos(cos($L) / cos($DC));
	if ($L > pi) {
		$AR = 2 * pi - $AR;
	}
	$OB = $OB * $RAD;
	$L = $L * $RAD;
	$AR = $AR * 12 / pi;

	# HH.MM to AR conversion
	my $H = int($AR);
	my $M = int(($AR - int($AR)) * 60);
	$S=(($AR - int($AR)) * 60 - $M) * 60;
	$DC = $DC * $RAD;

	# Degrees conversion from DEC
	my $D = abs($DC);
	if ($DC > 0) {
		my $G1 = int($D);
	} else {
		my $G1 = (-1) * int($D);
	}
	my $M1 = int(($D - int($D)) * 60);
	my $S1 = (($D - int($D)) * 60 - $M1) * 60;
	if ($DC < 0) {
		$M1 = -$M1;
		$S1 = -$S1;
	}

	# Time equation
	my $MR = 0.04301;
	my $F = 13750.987;
	my $C = 2 * $ET * $F * sin($AM) + 1.25 * $ET * $ET * $F * sin(2 * $AM);
	my $R = -$MR * $F * sin(2 * ($P + $AM)) + $MR * $MR * $F * sin(4 * ($P + $AM)) / 2;
	$ET = $C + $R;

	# Semi-diurn arc calculus
	my $H0 = acos(-tan($Lat / $RAD) * tan($DC / $RAD));
	$H0 = $H0 * $RAD;

	# DEC variations
	my $VD = 0.9856 * sin($OB / $RAD) * cos($L / $RAD) / cos($DC / $RAD);

	# Sun rise calculus
	my $VDOR = $VD * (-$H0 + 180) / 360;
	my $DCOR = $DC + $VDOR;
	my $HORTO = -acos(-tan($Lat / $RAD) * tan($DCOR / $RAD));
	my $VHORTO = 5 / (6 * cos($Lat / $RAD) * cos($DCOR / $RAD) * sin($HORTO));
	$HORTO = ($HORTO * $RAD + $VHORTO) / 15;
	my $TUORTO = $HORTO + $ET / 3600 - $Long / 15 + 12;

	# Sun rise value conversion to HH.MM
	my $HOR = int($TUORTO);
	my $MOR = int(($TUORTO - $HOR) * 60 + 0.5);

	# AZ calculation
	my $TUC = 12 + $ET / 3600 - $Long / 15;

	# AZ value conversion to HH.MM
	my $HC = int($TUC);
	my $MC = int(($TUC - $HC) * 60 + 0.5);

	# Sunset calculus
	my $VDOC = $VD * ($H0 + 180) / 360;
	my $DCOC = $DC + $VDOC;
	my $HOC = acos(-tan($Lat / $RAD) * tan($DCOC / $RAD));
	my $VHOC = 5 / (6 * cos($Lat / $RAD) * cos($DCOC / $RAD) * sin($HOC));
	$HOC = ($HOC * $RAD + $VHOC) / 15;
	my $TUOC = $HOC + $ET / 3600 - $Long / 15 + 12;

	# Sunset conversion to HH.MM
	$HOC = int($TUOC);
	my $MOC = int(($TUOC - $HOC) * 60 + 0.5);

	# Altitude of AZ
	my $HCUL = 90 - $Lat + ($DCOR + $DCOC) / 2;

	# Degree conversion from altitude
	my $GCUL = int($HCUL);
	my $MCUL = int (($HCUL - $GCUL) * 60 + 0.5);

	# AZ from Sunrise and Sunset
	my $ACOC = acos(-sin($DCOC / $RAD) / cos($Lat / $RAD)) * $RAD;
	my $ACOR = 360 - acos(-sin($DCOR / $RAD) / cos($Lat / $RAD)) * $RAD;

	# AZ conversion to degrees
	my $GACOC = int($ACOC);
	my $MACOC = int(($ACOC - $GACOC) * 60 + 0.5);
	my $GACOR = int($ACOR);
	my $MACOR = int(($ACOR - $GACOR) * 60 + 0.5);

	my $sunrise = $HOR."h ".$MOR."m";
	my $sunset = $HOC."h ".$MOC."m";
	my $midday = $HC."h ".$MC."m";

	my $k_sunrise = "sunrise".$origin_point;
	my $k_sunset = "sunset".$origin_point;
	my $k_midday = "midday".$origin_point;

	my %solar_cycle = (
		$k_sunrise	=> $sunrise,
		$k_sunset	=> $sunset,
		$k_midday	=> $midday,
	);

	if ($day =~ /Error/) {
		return my %solar_cycle = (_error => $day);
	}
	if ($Lat == 0 || $Long == 0) {
		%solar_cycle = (_error => "Error sexagesimal conversion. Out of range.");
	}

	return %solar_cycle;
}

=head2 date_split

Gets a string with date in format 'dd-mm-yyyy' and check it if value is a valid date.

Returns an array with the day, month and year ... or error message.

=cut

sub date_split {
	my ($self, $date) = @_;
	my @part_of_date;
	my $check = is_date($date);
	if ($check !~ /Error/) {
		return @part_of_date = split(/-/,$date);
	} else {
		return $part_of_date[0] = $check;
	}
}

# ---------------
#  INTERNAL SUBS
# ---------------

=head1 Internals subs

=head2 data_constructor

Internal function used by data_by_coordinates() and data_by_locator() to call the others functions and create a response.

=head2 NESW

Internal function to convert degrees to radians.

=head2 check_error

Internal function to check errors in data_by_coordinates() or data_by_locator().

=head2 is_date

Internal function to check if a date is valid.

=cut

sub NESW {
	deg2rad($_[0]), deg2rad(90 - $_[1])
}

sub is_date {
	my $date = shift;
	my $pattern = qr/\d{1,2}(-)\d{1,2}(-)\d{4}/;

	if ($date !~ $pattern) {
		return "Error date format. Must be dd-mm-yyyy";
	} else {
		my @part_of_date = split(/-/,$date);

		my $intDay = ($part_of_date[0] <= 9) ? sprintf("%02d", $part_of_date[0]) : sprintf("%2d", $part_of_date[0]);
		my $intMonth = ($part_of_date[1] <= 9) ? sprintf("%02d", $part_of_date[1]) : sprintf("%2d", $part_of_date[1]);
		my $intYear = $part_of_date[2];

		my %array_month = (
			'01' => 31,
			'02' => 0,
			'03' => 31,
			'04' => 30,
			'05' => 31,
			'06' => 30,
			'07' => 31,
			'08' => 31,
			'09' => 30,
			'10' => 31,
			'11' => 30,
			'12' => 31,
		);

		if ($intMonth > 12) { return "Error in date format. This must be a valid dd-mm-yyyy." }

		if ($array_month{$intMonth} != 0 && $part_of_date[0] <= $array_month{$intMonth}) {
			return 1;
		}

		if ($intMonth == 0) {
			if ($intDay > 0 && $intDay < 29) {
				return 1;
			}
			elsif ($intDay == 29) {
				if (($intYear % 4 == 0) && ($intYear % 100 != 0) || ($intYear % 400) == 0) {
					return 1;
				}
			}
		}

		return "Error in date format. This must be a valid dd-mm-yyyy.";
	}
}

sub check_error {
	my %coord = @_;
	foreach my $key (sort keys %coord) {
		if ($coord{$key} =~ /Error/) {
			$coord{_error} = $coord{$key};
			$coord{$key} = 0;
		}
	}
	return %coord;
}


=head1 Cheking Errors

In functions that return only a string or an array, errors will detect to match /Error/ word.
In complex functions, like data_by_coordinates, that responses with a hash, you check the '_error' index, i.e:

    %data = $foo->data_by_locator($date,$locator_1,$locator_2);
    if (!$data{_error}) {
	    foreach my $key (sort keys %data) {
		    say $key.": ".$data{$key};
	    }
    } else {
	    say $data{_error};
    }

... or something like this :p

=cut


=head1 AUTHOR

CJUAN, C<< <cjuan at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ham-resources-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ham-Resources-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ham::Resources::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ham-Resources-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ham-Resources-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ham-Resources-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Ham-Resources-Utils/>

=back

=head1 TODO

=over 4

=item * Add long path course and distances from point A to B

=item * Add a function to calculate X and Y coordinates based on real coordinates for use it on a geographical projection (or Plate Carree)

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012-2018 CJUAN.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Ham::Resources::Utils
