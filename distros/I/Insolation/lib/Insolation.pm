#
# Written by Travis Kent Beste
# Mon Sep 13 10:49:23 CDT 2010

package Insolation;

use 5.008000;
use strict;
use warnings;

use Math::Trig;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Insolation ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

#----------------------------------------#
#
#----------------------------------------#
sub new {
	my $class = shift;
	my %args = @_;

	my %fields = (
		longitude  => 0,
		latitude   => 0,
		month      => 0,
		_min_month => 0,
		_max_month => 0,
		year       => 0,

		# calculated data, hold it here while they decide how to output it
		data       => {},

		# calculated variables
		SCRATCH    => {
			ECCEN         => 0, # orbital parameter
			OBLIQ         => 0, # orbital parameter
			OMEGVP        => 0, # orbital parameter
			ITZONE        => 0, # time zone
		},

		# assign constants
		CONSTANTS  => {
			PI            => 4 * atan2(1, 1),                           # compute value of PI at run time - accurately
			TWOPI         => (2 * (4 * atan2(1, 1))),                   # compute value of PI at run time - accurately
			RSUND         => .267,                                      # mean radius of Sun in degrees
			REFRAC        => .583,                                      # effective Sun disk increase
			EDAYZY        => 365.2425,                                  # actual length of a year - now
			DAYzMO        => [31,28,31, 30,31,30, 31,31,30, 31,30,31],  # days in each month - we calculate leap year below
			EARTH_WATT_M2 => 1367,                                     # amount of energy that reaches the earth - watts/(m*m)
		},
	);

	my $self = {
		%fields
	};
	bless $self, $class;

	#print Dumper $self;
	#exit;

	#--------------------#
	# validate input
	#--------------------#

	if (defined($args{'Longitude'})) {
		$self->set_longitude($args{Longitude});
	}

	if (defined($args{'Latitude'})) {
		$self->set_latitude($args{Latitude});
	}

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	if (defined($args{'Month'})) {
		$self->set_month($args{Month});
	} else {
		$self->{month} = -1; # will end up computing for all months 
		$self->{_min_month} = 1;
		$self->{_max_month}   = 12;
	}

	if (defined($args{'Year'})) {
		$self->set_year($args{Year});
	}	else {
		$self->{year} = $year + 1900; # set default year to this year
	}

	return $self;
}

#----------------------------------------#
#
#----------------------------------------#
sub DESTROY {
	my $self = shift;

	$self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}

# Preloaded methods go here.

#----------------------------------------#
#
#----------------------------------------#
sub set_year {
	my $self = shift;
	my $year = shift;

	$self->{year} = sprintf("%d", $year);
}

#----------------------------------------#
#
#----------------------------------------#
sub set_month {
	my $self  = shift;
	my $month = shift;

	if ($self->isvalid_month($month)) {
		$self->{'month'} = sprintf("%d", $month);
		$self->{_min_month} = $self->{month};
		$self->{_max_month}   = $self->{month};
	} else {
		print "error with month\n";
		exit(1);
	}
}

#----------------------------------------#
#
#----------------------------------------#
sub set_longitude {
	my $self      = shift;
	my $longitude = shift;

	if ($self->isvalid_longitude) {
		if ($self->isvalid_longitude($longitude)) {
			$self->{longitude} = $longitude;
		} else {
			print "error with longitude\n";
			exit(1);
		}
	}
}

#----------------------------------------#
#
#----------------------------------------#
sub set_latitude {
	my $self     = shift;
	my $latitude = shift;

	if ($self->isvalid_latitude($latitude)) {
		$self->{latitude} = $latitude;
	} else {
		print "error with latitude\n";
		exit(1);
	}
}

#----------------------------------------#
#
#----------------------------------------#
sub isvalid_year {
	my $self = shift;
	my $year = shift;

	if ( ($year >= 1) && ($year <= 9999) ) {
		return 1;
	} 

	return 0;
}

#----------------------------------------#
#
#----------------------------------------#
sub isvalid_month {
	my $self  = shift;
	my $month = shift;

	if ($month eq "") {
		return 0;
	}

	if ( ($month >= 1) && ($month <= 12) ) {
		return 1;
	} 

	return 0;
}

#----------------------------------------#
#
#----------------------------------------#
sub isvalid_latitude {
	my $self     = shift;
	my $latitude = shift;

	#print "$latitude\n";

	if (abs($latitude) > 90) {
		return 0
	}

	return 1;
}

#----------------------------------------#
#
#----------------------------------------#
sub isvalid_longitude {
	my $self      = shift;
	my $longitude = shift;

	#print "$lonitude\n";

	if ($self->{longitude} >  187.5) {
		$self->{longitude} = $self->{longitude} - 360;
	}
	if ($self->{longitude} < -187.5) {
		$self->{longitude} = $self->{longitude} + 360;
	}
	if (abs($self->{longitude}) > 187.5) {
		return 0;
	}

	return 1;
}

#----------------------------------------#
# calculate the data for the months given
#----------------------------------------#
sub calculate_insolation {
	my $self = shift;

	$self->{SCRATCH}->{ITZONE} = int($self->{longitude} / 15); #  Determine time zone
	$self->ORBPAR();                                           #  Determine orbital parameters

  for (my $MONTH = $self->{_min_month}; $MONTH <= $self->{_max_month}; $MONTH++) {
    my $DATMAX = $self->{CONSTANTS}->{DAYzMO}[($MONTH - 1)]; # array indexed at zero instead of 1
    if ( ($MONTH == 2) and ($self->QLEAPY($self->{year})) ) {
      $DATMAX = 29;
    }
    for (my $JDATE = 1; $JDATE <= $DATMAX; $JDATE++) {
			my $DATE   = $JDATE-1 + .5 - $self->{longitude}/360;
      my $DAY    = $self->YMDtoD($self->{year}, $MONTH, $DATE);
			#print "DAY : $DAY\n";

      my ($SIND, $COSD, $SUNDIS, $SUNLON, $SUNLAT, $EQTIME) = $self->ORBIT($DAY);
			#print "SIND : $SIND\n";
			#print "COSD : $COSD\n";
			#print "SUNDIS : $SUNDIS\n";
			#print "SUNLON : $SUNLON\n";
			#print "SUNLAT : $SUNLAT\n";
			#print "EQTIME : $EQTIME\n";

      my ($COSZT, $COSZS) = $self->COSZIJ($SIND, $COSD);
      my $RSmEzM = ($self->{CONSTANTS}->{REFRAC} + $self->{CONSTANTS}->{RSUND} / $SUNDIS) * $self->{CONSTANTS}->{TWOPI}/360;
      my $DUSK   = $self->SUNSET($SIND, $COSD, $RSmEzM);
			my $SRINC  = $self->{CONSTANTS}->{EARTH_WATT_M2} * $COSZT / $SUNDIS**2;

			my ($dawn, $dusk);
			my $date = sprintf("%04d-%02d-%02d", $self->{year}, $MONTH, $JDATE);
      if ($DUSK >= 999999) {
				#--------------------#
				# Daylight at all times at this location on this day
				#--------------------#

				$dawn = 0;
				$dusk = 0;

      } elsif ($DUSK <= -999999) {
				#--------------------#
				# Nightime at all times at this location on this day
				#--------------------#

				$dawn = 0;
				$dusk = 0;

			} else {
				#--------------------#
				# Daylight and nightime at this location on this day
				#--------------------#

				my $DAWN   = (-$DUSK-$EQTIME) * 24 / $self->{CONSTANTS}->{TWOPI} + 12 - $self->{longitude} / 15 + $self->{SCRATCH}->{ITZONE};
				$DUSK   = ( $DUSK-$EQTIME) * 24 / $self->{CONSTANTS}->{TWOPI} + 12 - $self->{longitude} / 15 + $self->{SCRATCH}->{ITZONE};
				my $IDAWNH = int($DAWN);
				my $IDUSKH = int($DUSK);
				my $IDAWNM = int( ($DAWN - $IDAWNH) * 60);
				my $IDUSKM = int( ($DUSK - $IDUSKH) * 60);
				$dawn = sprintf("%02d:%02d", $IDAWNH, $IDAWNM);
				$dusk = sprintf("%02d:%02d", $IDUSKH, $IDUSKM);

			}

			# set the data in the object's data collector - that way you can output it the way you'd like xml,csv,txt,etc
			$self->{data}->{'day'}->{$date}->{'data'} = {
				'dawn'  => $dawn,
				'dusk'  => $dusk,
				'srinc' => sprintf("%.45f", $SRINC),
				'coszs' => sprintf("%.45f", $COSZS),
			};
			#printf "%10s - %5s - %5s - %.40f - %.40f\n", $date, $dawn, $dusk, $SRINC, $COSZS;
    }
  }
}

#----------------------------------------#
# output in xml
#----------------------------------------#
sub get_xml {
	my $self = shift;

	# only require if they use this method
	my $package = 'XML::Simple';
	eval {
		(my $pkg = $package) =~ s|::|/|g; # require need a path
  	require "$pkg.pm";
		import $package;
	};
	die $@ if( $@ );

	my $xs   = XML::Simple->new(
		AttrIndent => 1,
		RootName   => 'Insolation',
		KeyAttr    => [ 'date' => 'name'],
		NoAttr     => 1,
	);

	my $xml = $xs->XMLout($self->{data});
	#print "$xml";

	return $xml;
}

#----------------------------------------#
# output in csv
#----------------------------------------#
sub get_csv {
	my $self = shift;
	my $csv;

	foreach my $date (sort keys %{$self->{data}->{day}}) {
		my $dawn  = $self->{data}->{day}->{$date}->{data}->{dawn};
		my $dusk  = $self->{data}->{day}->{$date}->{data}->{dusk};
		my $srinc = $self->{data}->{day}->{$date}->{data}->{srinc};
		my $coszs = $self->{data}->{day}->{$date}->{data}->{coszs};
		$csv .= sprintf("%s,%s,%s,%5.2f,%.4f\n", $date, $dawn, $dusk, $srinc, $coszs);
	}

	return $csv;
}

#----------------------------------------#
# get the insolation for a computed value
#----------------------------------------#
sub get_ym_insolation {
	my $self  = shift;
	my $ym    = shift;
	my $year  = substr($ym, 0, 4);
	my $month = substr($ym, 5, 2);
	my $total = 0;

	if (! defined($self->{data}->{day}->{$ym . '-01'}->{data}->{srinc})) {
		print "front of the month doesn't exist...\n";
		return 0;
	} else {
		#print "front of the month looks good...\n";
	}

	my $DATMAX = $self->{CONSTANTS}->{DAYzMO}[($month - 1)]; # array indexed at zero instead of 1
	if ( ($month == 2) and ($self->QLEAPY($year)) ) {
		$DATMAX = 29;
	}
	if (! defined($self->{data}->{day}->{$ym . '-' . $DATMAX}->{data}->{srinc})) {
		print "end of the month doesn't exist...\n";
		return 0;
	} else {
		#print "end of the month looks good...\n";
	}

	# compute the month total
	for(my $d = 1; $d <= $DATMAX; $d++) {
		$total += $self->{data}->{day}->{$ym . sprintf("-%02d", $d)}->{data}->{srinc};
	}

	return $total;
}

#----------------------------------------#
# get the insolation for a computed value
#----------------------------------------#
sub get_ymd_insolation {
	my $self = shift;
	my $ymd  = shift;

	if (! defined($self->{data}->{day}->{$ymd}->{data}->{srinc})) {
		return -1;
	}

	return $self->{data}->{day}->{$ymd}->{data}->{srinc};
}

#----------------------------------------#
# ORBPAR calculates the three orbital parameters as a function of
# YEAR.  The source of these calculations is: Andre L. Berger,
# 1978, "Long-Term Variations of Daily Insolation and Quaternary
# Climatic Changes", JAS, v.35, p.2362.  Also useful is: Andre L.
# Berger, May 1978, "A Simple Algorithm to Compute Long Term
# Variations of Daily Insolation", published by Institut
# D'Astronomie de Geophysique, Universite Catholique de Louvain,
# Louvain-la Neuve, No. 18.
# 
# Tables and equations refer to the first reference (JAS).  The
# corresponding table or equation in the second reference is
# enclosed in parentheses.  The coefficients used in this
# subroutine are slightly more precise than those used in either
# of the references.  The generated orbital parameters are precise
# within plus or minus 1000000 years from present.
# 
# Input:  YEAR   = years A.D. are positive, B.C. are negative
# Output: ECCEN  = ECCENtricity of orbital ellipse
#         OBLIQ  = latitude of Tropic of Cancer in radians
#         OMEGVP = longitude of perihelion =
#                = spatial angle from vernal equinox to perihelion
#                  in radians with sun as angle vertex
#----------------------------------------#
sub ORBPAR {
	my $self = shift;

	# Table 1 (2).  Obliquity relative to mean ecliptic of date: OBLIQD
	my @table1 = (-2462.2214466, 31.609974, 251.9025,
                -857.3232075, 32.620504, 280.8325,
                -629.3231835, 24.172203, 128.3057,
                -414.2804924, 31.983787, 292.7252,
                -311.7632587, 44.828336,  15.3747,
                 308.9408604, 30.973257, 263.7951,
                -162.5533601, 43.668246, 308.4258,
                -116.1077911, 32.246691, 240.0099,
                 101.1189923, 30.599444, 222.9725,
                 -67.6856209, 42.681324, 268.7809,
                  24.9079067, 43.836462, 316.7998,
                  22.5811241, 47.439436, 319.6024,
                 -21.1648355, 63.219948, 143.8050,
                 -15.6549876, 64.230478, 172.7351,
                  15.3936813,  1.010530,  28.9300,
                  14.6660938,  7.437771, 123.5968,
                 -11.7273029, 55.782177,  20.2082,
                  10.2742696,   .373813,  40.8226,
                   6.4914588, 13.218362, 123.4722,
                   5.8539148, 62.583231, 155.6977,
                  -5.4872205, 63.593761, 184.6277,
                  -5.4290191, 76.438310, 267.2772,
                   5.1609570, 45.815258,  55.0196,
                   5.0786314,  8.448301, 152.5268,
                  -4.0735782, 56.792707,  49.1382,
                   3.7227167, 49.747842, 204.6609,
                   3.3971932, 12.058272,  56.5233,
                  -2.8347004, 75.278220, 200.3284,
                  -2.6550721, 65.241008, 201.6651,
                  -2.5717867, 64.604291, 213.5577,
                  -2.4712188,  1.647247,  17.0374,
                   2.4625410,  7.811584, 164.4194,
                   2.2464112, 12.207832,  94.5422,
                  -2.0755511, 63.856665, 131.9124,
                  -1.9713669, 56.155990,  61.0309,
                  -1.8813061, 77.448840, 296.2073,
                  -1.8468785,  6.801054, 135.4894,
                   1.8186742, 62.209418, 114.8750,
                   1.7601888, 20.656133, 247.0691,
                  -1.5428851, 48.344406, 256.6114,
                   1.4738838, 55.145460,  32.1008,
                  -1.4593669, 69.000539, 143.6804,
                   1.4192259, 11.071350,  16.8784,
                  -1.1818980, 74.291298, 160.6835,
                   1.1756474, 11.047742,  27.5932,
                  -1.1316126,  0.636717, 348.1074,
                   1.0896928, 12.844549,  82.6496
	             );
	#print Dumper \@table1;

	# Table 4 (1).  Fundamental elements of the ecliptic: ECCEN sin(pi)
	my @table4 = ( .01860798,  4.207205,  28.620089,
                 .01627522,  7.346091, 193.788772,
                -.01300660, 17.857263, 308.307024,
                 .00988829, 17.220546, 320.199637,
                -.00336700, 16.846733, 279.376984,
                 .00333077,  5.199079,  87.195000,
                -.00235400, 18.231076, 349.129677,
                 .00140015, 26.216758, 128.443387,
                 .00100700,  6.359169, 154.143880,
                 .00085700, 16.210016, 291.269597,
                 .00064990,  3.065181, 114.860583,
                 .00059900, 16.583829, 332.092251,
                 .00037800, 18.493980, 296.414411,
                -.00033700,  6.190953, 145.769910,
                 .00027600, 18.867793, 337.237063,
                 .00018200, 17.425567, 152.092288,
                -.00017400,  6.186001, 126.839891,
                -.00012400, 18.417441, 210.667199,
                 .00001250,  0.667863,  72.108838
	            );
	#print Dumper \@table4;

	# Table 5 (3).  General precession in longitude: psi
	my @table5 = ( 7391.0225890, 31.609974, 251.9025,
                 2555.1526947, 32.620504, 280.8325,
                 2022.7629188, 24.172203, 128.3057,
                -1973.6517951,  0.636717, 348.1074,
                 1240.2321818, 31.983787, 292.7252,
                  953.8679112,  3.138886, 165.1686,
                 -931.7537108, 30.973257, 263.7951,
                  872.3795383, 44.828336,  15.3747,
                  606.3544732,  0.991874,  58.5749,
                 -496.0274038,  0.373813,  40.8226,
                  456.9608039, 43.668246, 308.4258,
                  346.9462320, 32.246691, 240.0099,
                 -305.8412902, 30.599444, 222.9725,
                  249.6173246,  2.147012, 106.5937,
                 -199.1027200, 10.511172, 114.5182,
                  191.0560889, 42.681324, 268.7809,
                 -175.2936572, 13.650058, 279.6869,
                  165.9068833,  0.986922,  39.6448,
                  161.1285917,  9.874455, 126.4108,
                  139.7878093, 13.013341, 291.5795,
                 -133.5228399,  0.262904, 307.2848,
                  117.0673811,  0.004952,  18.9300,
                  104.6907281,  1.142024, 273.7596,
                   95.3227476, 63.219948, 143.8050,
                   86.7824524,  0.205021, 191.8927,
                   86.0857729,  2.151964, 125.5237,
                   70.5893698, 64.230478, 172.7351,
                  -69.9719343, 43.836462, 316.7998,
                  -62.5817473, 47.439436, 319.6024,
                   61.5450059,  1.384343,  69.7526,
                  -57.9364011,  7.437771, 123.5968,
                   57.1899832, 18.829299, 217.6432,
                  -57.0236109,  9.500642,  85.5882,
                  -54.2119253,  0.431696, 156.2147,
                   53.2834147,  1.160090,  66.9489,
                   52.1223575, 55.782177,  20.2082,
                  -49.0059908, 12.639528, 250.7568,
                  -48.3118757,  1.155138,  48.0188,
                  -45.4191685,  0.168216,   8.3739,
                  -42.2357920,  1.647247,  17.0374,
                  -34.7971099, 10.884985, 155.3409,
                   34.4623613,  5.610937,  94.1709,
                  -33.8356643, 12.658184, 221.1120,
                   33.6689362,  1.010530,  28.9300,
                  -31.2521586,  1.983748, 117.1498,
                  -30.8798701, 14.023871, 320.5095,
                   28.4640769,  0.560178, 262.3602,
                  -27.1960802,  1.273434, 336.2148,
                   27.0860736, 12.021467, 233.0046,
                  -26.3437456, 62.583231, 155.6977,
                   24.7253740, 63.593761, 184.6277,
                   24.6732126, 76.438310, 267.2772,
                   24.4272733,  4.280910,  78.9281,
                   24.0127327, 13.218362, 123.4722,
                   21.7150294, 17.818769, 188.7132,
                  -21.5375347,  8.359495, 180.1364,
                   18.1148363, 56.792707,  49.1382,
                  -16.9603104,  8.448301, 152.5268,
                  -16.1765215,  1.978796,  98.2198,
                   15.5567653,  8.863925,  97.4808,
                   15.4846529,  0.186365, 221.5376,
                   15.2150632,  8.996212, 168.2438,
                   14.5047426,  6.771027, 161.1199,
                  -14.3873316, 45.815258,  55.0196,
                   13.1351419, 12.002811, 262.6495,
                   12.8776311, 75.278220, 200.3284,
                   11.9867234, 65.241008, 201.6651,
                   11.9385578, 18.870667, 294.6547,
                   11.7030822, 22.009553,  99.8233,
                   11.6018181, 64.604291, 213.5577,
                  -11.2617293, 11.498094, 154.1631,
                  -10.4664199,  0.578834, 232.7153,
                   10.4333970,  9.237738, 138.3034,
                  -10.2377466, 49.747842, 204.6609,
                   10.1934446,  2.147012, 106.5938,
                  -10.1280191,  1.196895, 250.4676,
                   10.0289441,  2.133898, 332.3345,
                  -10.0034259,  0.173168,  27.3039
	             );

	my $YM1950 = $self->{year} - 1950;
	#print "YM1950 : $YM1950\n";

	my $PIz180 = $self->{CONSTANTS}->{TWOPI} / 360;
	#print "PIz180 : $PIz180\n";

	#--------------------#
	# Obliquity from Table 1 (2):
	#--------------------#
	# OBLIQ  = 23.320556 (degrees)             Equation 5.5 (15)
	# OBLIQD = OBLIQ + sum[A cos(ft+delta)]   Equation 1 (5)
	my $sumc = 0;
	for (my $i = 0; $i < 47; $i++) {
		#printf "%2d => 1=%18.8f 2=%18.8f 3=%18.8f\n", $i, $table1[(($i*3)+0)], $table1[(($i*3)+1)], $table1[(($i*3)+2)];
		my $arg = $PIz180 * ($YM1950 * $table1[(($i*3)+1)] / 3600 + $table1[(($i*3)+2)]);
		$sumc = $sumc + $table1[(($i*3)+0)] * cos($arg);
		#print "$arg - $sumc\n";
	}
	my $OBLIQD = 23.320556 + $sumc/3600;
	#print "OBLIQD : $OBLIQD\n";
	$self->{SCRATCH}->{OBLIQ} = $OBLIQD * $PIz180;
	#print "OBLIQ  : " . $self->{SCRATCH}->{OBLIQ} . "\n";

	#--------------------#
	# Eccentricity from Table 4 (1):
	#--------------------#
	#  ECCEN sin(pi) = sum[M sin(gt+beta)]           Equation 4 (1)
	#  ECCEN cos(pi) = sum[M cos(gt+beta)]           Equation 4 (1)
	#  ECCEN = ECCEN sqrt[sin(pi)^2 + cos(pi)^2]
	my $ESINPI = 0;
	my $ECOSPI = 0;
	for (my $i = 0; $i < 19; $i++) {
		#printf "%2d => 1=%18.8f 2=%18.8f 3=%18.8f\n", $i, $table4[(($i*3)+0)], $table4[(($i*3)+1)], $table4[(($i*3)+2)];
		my $arg = $PIz180 * ($YM1950 * $table4[(($i*3)+1)] / 3600 + $table4[(($i*3)+2)]);
		$ESINPI = $ESINPI + $table4[(($i*3)+0)] * sin($arg);
		$ECOSPI = $ECOSPI + $table4[(($i*3)+0)] * cos($arg);
		#print "ESINPI : $ESINPI\n";
		#print "ECOSPI : $ECOSPI\n";
	}
	$self->{SCRATCH}->{ECCEN} = sqrt(($ESINPI * $ESINPI) + ($ECOSPI * $ECOSPI));
	#print "ECCEN  : " . $self->{SCRATCH}->{ECCEN} . "\n";

	#--------------------#
	# Perihelion from Equation 4,6,7 (9) and Table 4,5 (1,3):
	#--------------------#
	# PSI# = 50.439273 (seconds of degree)         Equation 7.5 (16)
	# ZETA =  3.392506 (degrees)                   Equation 7.5 (17)
	# PSI = PSI# t + ZETA + sum[F sin(ft+delta)]   Equation 7 (9)
	# PIE = atan[ECCEN sin(pi) / ECCEN cos(pi)]
	# OMEGVP = PIE + PSI + 3.14159                 Equation 6 (4.5)

	my $PIE = atan2($ESINPI, $ECOSPI);
	#print "PIE    : $PIE\n";
	my $FSINFD = 0;
	for(my $i = 0; $i < 78; $i++) {
		#printf "%2d => 1=%18.8f 2=%18.8f 3=%18.8f\n", $i, $table5[(($i*3)+0)], $table5[(($i*3)+1)], $table5[(($i*3)+2)];
		my $arg = $PIz180 * ($YM1950 * $table5[(($i*3)+1)] / 3600 + $table5[(($i*3)+2)]);
		$FSINFD = $FSINFD + $table5[(($i*3)+0)] * sin($arg);
	}
	#print "FSINFD : $FSINFD\n";
	my $PSI = $PIz180 * (3.392506 + ($YM1950 * 50.439273 + $FSINFD) / 3600);
	#print "PSI    : $PSI\n";
	my $a = ($PIE + $PSI + .5 * $self->{CONSTANTS}->{TWOPI}) ;
	my $b = $self->{CONSTANTS}->{TWOPI};
	my $c = $a / $b;
	my $d = modulo($a, $b);
	#printf "%25.20f\n", $a;
	#printf "%25.20f\n", $b;
	#printf "%25.20f\n", $c;
	#printf "%25.20f\n", $d;
	$self->{SCRATCH}->{OMEGVP} = modulo(($PIE + $PSI + .5 * $self->{CONSTANTS}->{TWOPI}), $self->{CONSTANTS}->{TWOPI});
	#print "OMEGVP : " . $self->{SCRATCH}->{OMEGVP} . "\n";
}

#----------------------------------------#
# ORBIT receives orbital parameters and time of year, and returns
# distance from Sun and Sun's position.
# Reference for following caculations is: V.M.Blanco and
# S.W.McCuskey, 1961, "Basic Physics of the Solar System", pages
# 135 - 151.  Existence of Moon and heavenly bodies other than
# Earth and Sun are ignored.  Earth is assumed to be spherical.
# 
# Program author: Gary L. Russell 2002/09/25
# Angles, longitude and latitude are measured in radians.
# 
# Input: ECCEN  = ECCENtricity of the orbital ellipse
#        OBLIQ  = latitude of Tropic of Cancer
#        OMEGVP = longitude of perihelion (sometimes Pi is added) =
#               = spatial angle from vernal equinox to perihelion
#                 with Sun as angle vertex
#        DAY    = days measured since 2000 January 1, hour 0
# 
# Constants: EDAYzY = tropical year = Earth days per year = 365.2425
#            VE200D = days from 2000 January 1, hour 0 till vernal
#                     equinox of year 2000 = 31 + 29 + 19 + 7.5/24
# 
# Intermediate quantities:
#    BSEMI = semi minor axis in units of semi major axis
#   PERIHE = perihelion in days since 2000 January 1, hour 0
#            in its annual revolution about Sun
#       TA = true anomaly = spatial angle from perihelion to
#            current location with Sun as angle vertex
#       EA = ECCENtric anomaly = spatial angle measured along
#            ECCENtric circle (that circumscribes Earth's orbit)
#            from perihelion to point above (or below) Earth's
#            absisca (where absisca is directed from center of
#            ECCENtric circle to perihelion)
#       MA = mean anomaly = temporal angle from perihelion to
#            current time in units of 2*Pi per tropical year
#   TAofVE = TA(VE) = true anomaly of vernal equinox = - OMEGVP
#   EAofVE = EA(VE) = ECCENtric anomaly of vernal equinox
#   MAofVE = MA(VE) = mean anomaly of vernal equinox
#   SLNORO = longitude of Sun in Earth's nonrotating reference frame
#   VEQLON = longitude of Greenwich Meridion in Earth's nonrotating
#            reference frame at vernal equinox
#   ROTATE = change in longitude in Earth's nonrotating reference
#            frame from point's location on vernal equinox to its
#            current location where point is fixed on rotating Earth
#   SLMEAN = longitude of fictitious mean Sun in Earth's rotating
#            reference frame (normal longitude and latitude)
#
# Output: DIST = distance to Sun in units of semi major axis
#         SIND = sine of declination angle = sin(SUNLAT)
#         COSD = cosine of the declination angle = cos(SUNLAT)
#       SUNLON = longitude of point on Earth directly beneath Sun
#       SUNLAT = latitude of point on Earth directly beneath Sun
#       EQTIME = Equation of Time = longitude of fictitious mean Sun minus SUNLON
# 
# From the above reference:
# (4-54): [1 - ECCEN*cos(EA)]*[1 + ECCEN*cos(TA)] = (1 - ECCEN^2)
# (4-55): tan(TA/2) = sqrt[(1+ECCEN)/(1-ECCEN)]*tan(EA/2)
# Yield:  tan(EA) = sin(TA)*sqrt(1-ECCEN^2) / [cos(TA) + ECCEN]
#    or:  tan(TA) = sin(EA)*sqrt(1-ECCEN^2) / [cos(EA) - ECCEN]
#
#     Use C540, Only: EDAYzY,VE200D,CONSTANTS}->{TWOPI
#      Implicit  Real*8 (A-H,M-Z)
#----------------------------------------#
sub ORBIT {
	my $self = shift;
	my $DAY  = shift;

	my $EDAYzY = 365.2425;
	my $VE200D = 79.3125;

	# Determine EAofVE from geometry: tan(EA) = b*sin(TA) / [e+cos(TA)]
	# Determine MAofVE from Kepler's equation: MA = EA - e*sin(EA)
	# Determine MA knowing time from vernal equinox to current day

	#printf "DAY    : %.10f\n", $DAY;
	#printf "ECCEN  : %.10f\n", $self->{SCRATCH}->{ECCEN};
	#printf "OMEGVP : %.10f\n", $self->{SCRATCH}->{OMEGVP};

	my $BSEMI  = sqrt(1 - ($self->{SCRATCH}->{ECCEN} * $self->{SCRATCH}->{ECCEN}));
	#printf "BSEMI  : %.10f\n", $BSEMI;

	my $TAofVE = -($self->{SCRATCH}->{OMEGVP});
	#printf "TAofVE : %.10f\n", $TAofVE;

	my $EAofVE = atan2( ($BSEMI * sin($TAofVE)), ($self->{SCRATCH}->{ECCEN} + cos($TAofVE)) );
	#printf "EAofVE : %.10f\n", $EAofVE;

	my $MAofVE = $EAofVE - $self->{SCRATCH}->{ECCEN} * sin($EAofVE);
	#printf "MAofVE : %.10f\n", $MAofVE;

	my $MA     = modulo(($self->{CONSTANTS}->{TWOPI} * ($DAY - $VE200D) / $EDAYzY + $MAofVE), $self->{CONSTANTS}->{TWOPI});
	#printf "MA     : $MA\n";

	# Numerically invert Kepler's equation: MA = EA - e*sin(EA)
	my $dEA = 1;
	my $i = 0;
	my $EA = $MA + ($self->{SCRATCH}->{ECCEN} * ( sin($MA)) + ($self->{SCRATCH}->{ECCEN} * sin( 2 * $MA ) / 2) );
	while (abs($dEA) > 0.0000000001){
		$dEA = ($MA - $EA + $self->{SCRATCH}->{ECCEN} * sin($EA)) / (1 - $self->{SCRATCH}->{ECCEN} * cos($EA));
		$EA += $dEA;
		#printf "computing $i times ($EA, $dEA - %25.20f)\n", (abs($dEA));
		$i++;
	}

	#
	# Calculate distance to Sun and true anomaly
	#
	my $SUNDIS = 1 - $self->{SCRATCH}->{ECCEN} * cos($EA);
	my $TA     = atan2( ($BSEMI * sin($EA)), (cos($EA) - $self->{SCRATCH}->{ECCEN}));

	#
	# Change reference frame to be nonrotating reference frame, angles
	# fixed according to stars, with Earth at center and positive x
	# axis be ray from Earth to Sun were Earth at vernal equinox, and
	# x-y plane be Earth's equatorial plane.  Distance from current Sun
	# to this x axis is SUNDIS sin(TA-TAofVE).  At vernal equinox, Sun
	# is located at (SUNDIS,0,0).  At other times, Sun is located at:
	#
	# SUN = (SUNDIS cos(TA-TAofVE),
	#        SUNDIS sin(TA-TAofVE) cos(OBLIQ),
	#        SUNDIS sin(TA-TAofVE) sin(OBLIQ))
	#
	my $SIND   = sin($TA - $TAofVE) * sin($self->{SCRATCH}->{OBLIQ});
	my $COSD   = sqrt(1 - ($SIND * $SIND));
	my $SUNX   = cos($TA - $TAofVE);
	my $SUNY   = sin($TA - $TAofVE) * cos($self->{SCRATCH}->{OBLIQ});
	my $SLNORO = atan2($SUNY, $SUNX);

	#
	# Determine Sun location in Earth's rotating reference frame
	# (normal longitude and latitude)
	#
	my $VEQLON = $self->{CONSTANTS}->{TWOPI} * $VE200D - $self->{CONSTANTS}->{TWOPI} / 2 + $MAofVE - $TAofVE;  # modulo 2*Pi
	my $ROTATE = $self->{CONSTANTS}->{TWOPI} * ($DAY - $VE200D) * ($EDAYzY + 1) / $EDAYzY;
	my $SUNLON = modulo(($SLNORO - $ROTATE - $VEQLON), $self->{CONSTANTS}->{TWOPI});
	if ($SUNLON > ($self->{CONSTANTS}->{TWOPI} / 2)) {
		$SUNLON = $SUNLON - $self->{CONSTANTS}->{TWOPI};
	}
	my $SUNLAT = asin(sin($TA - $TAofVE) * sin($self->{SCRATCH}->{OBLIQ}));

	#
	# Determine longitude of fictitious mean Sun
	# Calculate Equation of Time
	#
	my $SLMEAN = $self->{CONSTANTS}->{TWOPI} / 2 - $self->{CONSTANTS}->{TWOPI} * ($DAY - int($DAY));
	my $EQTIME = modulo($SLMEAN - $SUNLON, $self->{CONSTANTS}->{TWOPI});
	if ($EQTIME > $self->{CONSTANTS}->{TWOPI}/2) {
		$EQTIME = $EQTIME - $self->{CONSTANTS}->{TWOPI};
	}

	return ($SIND, $COSD, $SUNDIS, $SUNLON, $SUNLAT, $EQTIME);
}

#----------------------------------------#
# SUNSET
# Input: RLAT = latitude (degrees)
#   SIND,COSD = sine and cosine of the declination angle
#      RSmEzM = (Sun Radius - Earth Radius) / (distance to Sun)
#
# Output: DUSK = time of DUSK (temporal radians) at mean local time
#
#----------------------------------------#
sub SUNSET {
	my $self   = shift;
	my $RLAT   = $self->{latitude};;
	my $SIND   = shift;
	my $COSD   = shift;
	my $RSmEzM = shift;

	my $DUSK = 0;

	my $SINJ = sin( $self->{CONSTANTS}->{TWOPI} * $self->{latitude} / 360);
	my $COSJ = cos( $self->{CONSTANTS}->{TWOPI} * $self->{latitude} / 360);
	my $SJSD = $SINJ * $SIND;
	my $CJCD = $COSJ * $COSD;

	# Constant nightime at this latitude
	if (($SJSD + $RSmEzM + $CJCD) <= 0) {
		$DUSK = -999999;
		return $DUSK;
	} 

	# Constant daylight at this latitude
	if (($SJSD + $RSmEzM - $CJCD) >= 0) {
		$DUSK = 999999;
		return $DUSK;
	}

	#  Compute DUSK (at local time)
	my $CDUSK = -($SJSD + $RSmEzM) / $CJCD;  # cosine of DUSK
	$DUSK = acos($CDUSK);

	return $DUSK;
}

#----------------------------------------#
# For a given JYEAR (A.D.), JMONTH and DATE (between 0 and 31),
# calculate number of DAYs measured from 2000 January 1, hour 0.
#----------------------------------------#
sub YMDtoD {
	my $self   = shift;
	my $JYEAR  = shift;
	my $JMONTH = shift;
	my $DATE   = shift;

	#print "year   : $JYEAR\n";
	#print "month  : $JMONTH\n";
	#print "date   : $DATE\n";

	my $JDAY4C = 365 * 400 + 97; #  number of days in 4 centuries
	my $JDAY1C = 365 * 100 + 24; #  number of days in 1 century
	my $JDAY4Y = 365 *   4 +  1; #  number of days in 4 years
	my $JDAY1Y = 365;          #  number of days in 1 year

	my @JDSUMN = (0,31,59, 90,120,151, 181,212,243, 273,304,334);
	my @JDSUML = (0,31,60, 91,121,152, 182,213,244, 274,305,335);

	my $N4CENT = int( ($JYEAR-2000) / 400);
	my $IYR4C  = $JYEAR - 2000 - ($N4CENT * 400);
	my $N1CENT = int($IYR4C / 100);
	my $IYR1C  = $IYR4C - $N1CENT * 100;
	my $N4YEAR = int($IYR1C / 4);
	my $IYR4Y  = $IYR1C - $N4YEAR * 4;
	my $N1YEAR = $IYR4Y;
	my $DAY    = $N4CENT * $JDAY4C;

	#print "N4CENT : $N4CENT\n";
	#print "IYR4C  : $IYR4C\n";
	#print "N1CENT : $N1CENT\n";
	#print "IYR1C  : $IYR1C\n";
	#print "N4YEAR : $N4YEAR\n";
	#print "IYR4Y  : $IYR4Y\n";
	#print "N1YEAR : $N1YEAR\n";
	#print "DAY    : $DAY\n";

	if ($N1CENT > 0) {
		$DAY = $DAY + $JDAY1C + 1 + ($N1CENT - 1) * $JDAY1C;
		#print "1. $DAY\n";
		if ($N4YEAR > 0) {
			#print "2. $DAY\n";
			$DAY = $DAY + $JDAY4Y-1 + ($N4YEAR - 1) * $JDAY4Y;
			if ($N1YEAR > 0) {
				#print "3. $DAY\n";
				$DAY = $DAY + $JDAY1Y+1 + ($N1YEAR - 1) * $JDAY1Y;
				#print "4. $DAY\n";
				$DAY = $DAY + $JDSUMN[($JMONTH - 1)] + $DATE;
				#print "5. $DAY\n";
				return $DAY;
			} else {
				$DAY = $DAY + $JDSUML[($JMONTH - 1)] + $DATE;
				#print "6. $DAY\n";
				return $DAY;
			}
		} else {
			#print "day   : -> $DAY\n";
			#print "month : -> $JMONTH\n";
			#print "date  : -> $DATE\n";
			#print "index : -> " . $JDSUML[$JMONTH] . "\n";
			$DAY = $DAY + $JDSUML[($JMONTH - 1)] + $DATE;
			#print "7. - $DAY\n";
			return $DAY;
		}
	} else {

		$DAY = $DAY + ($N4YEAR * $JDAY4Y);
		#print "8. $DAY\n";

		if ($N1YEAR > 0)  {
			$DAY = $DAY + ($JDAY1Y + 1) + (($N1YEAR - 1) * $JDAY1Y);
			#print "9. $DAY\n";

			#print "JMONTH " . $JMONTH . "\n";
			#print "JDSUMN " . $JDSUMN[($JMONTH - 1)] . "\n";

			$DAY = $DAY + $JDSUMN[($JMONTH - 1)] + $DATE;
			#print "10. $DAY\n";

			return $DAY;
		} else {
			$DAY = $DAY + $JDSUML[($JMONTH - 1)] + $DATE;
			#print "11. $DAY\n";
			return $DAY;
		}
	}
}

#----------------------------------------#
# For a given DAY measured from 2000 January 1, hour 0, determine
# the JYEAR (A.D.), JMONTH and DATE (between 0 and 31).
#----------------------------------------#
sub DtoYMD {
	my $self = shift;
	my $DAY = shift;

	my $JDAY4C = 365*400 + 97; #  number of days in 4 centuries
	my $JDAY1C = 365*100 + 24; #  number of days in 1 century
	my $JDAY4Y = 365*  4 +  1, #  number of days in 4 years
	my $JDAY1Y = 365;          #  number of days in 1 year

	my @JDSUMN = (0,31,59, 90,120,151, 181,212,243, 273,304,334);
	my @JDSUML = (0,31,60, 91,121,152, 182,213,244, 274,305,335);
 
	#my $N4CENT = int($DAY / $JDAY4C);
	#my $DAY4C  = $DAY - $N4CENT * $JDAY4C;
	#my $N1CENT = ($DAY4C - 1) / $JDAY1C;

	# Second to fourth of every fourth century: 21??, 22??, 23??, etc.
	#if ($N1CENT > 0) {
  #	$DAY1C  = $DAY4C - $N1CENT * $JDAY1C - 1;
	#	$N4YEAR = ($DAY1C + 1) / $JDAY4Y;

	#	if ($N4YEAR > 0) {
	#		# Subsequent four years of every second to fourth century when
	#		# there is a leap year: 2104-2107, 2108-2111 ... 2204-2207, etc.
	#		$DAY4Y  = $DAY1C - $N4YEAR * $JDAY4Y + 1;
	#		$N1YEAR = ($DAY4Y - 1) / $JDAY1Y;
	#		if ($N1YEAR > 0)  {
	#			# Current year is not a leap frog year
  #			$DAY1Y  = $DAY4Y - $N1YEAR * $JDAY1Y - 1;
	#		}
	#}

#  First of every fourth century: 16??, 20??, 24??, etc.
	#$DAY1C  = $DAY4C;
	#$N4YEAR = $DAY1C / JDAY4Y;
	#$DAY4Y  = $DAY1C - $N4YEAR * $JDAY4Y;
	#$N1YEAR = ($DAY4Y - 1) / $JDAY1Y;
	#if (N1YEAR > 0) {
	#	# Current year is not a leap frog year
	#	$DAY1Y  = $DAY4Y - $N1YEAR * $JDAY1Y - 1;
	#}

  #    GoTo 100

#  First four years of every second to fourth century when there is
#  no leap year: 2100-2103, 2200-2203, 2300-2303, etc.
  #    DAY4Y  = DAY1C
  #    N1YEAR = DAY4Y/JDAY1Y
  #    DAY1Y  = DAY4Y - N1YEAR*JDAY1Y
  #    GoTo 210

# 
#  Current year is a leap frog year
# 
  #100 DAY1Y = DAY4Y
  #    Do 120 M=1,11
  #120 If (DAY1Y < JDSUML(M+1))  GoTo 130
#C     M=12
  #130 JYEAR  = 2000 + N4CENT*400 + N1CENT*100 + N4YEAR*4 + N1YEAR
  #    JMONTH = M
  #    DATE   = DAY1Y - JDSUML(M)
  #    Return

# 
#  Current year is not a leap frog year
# 
  #210 Do 220 M=1,11
  #220 If (DAY1Y < JDSUMN(M+1))  GoTo 230
#C     M=12
  #230 JYEAR  = 2000 + N4CENT*400 + N1CENT*100 + N4YEAR*4 + N1YEAR
  #    JMONTH = M
  #    DATE   = DAY1Y - JDSUMN(M)
  #    Return
  #    End
}

#----------------------------------------#
# For a given year, VERNAL calculates an approximate time of vernal
# equinox in days measured from 2000 January 1, hour 0.

# VERNAL assumes that vernal equinoxes from one year to the next
# are separated by exactly 365.2425 days, a tropical year
# [Explanatory Supplement to The Astronomical Ephemeris].  If the
# tropical year is 365.2422 days, as indicated by other references,
# then the time of the vernal equinox will be off by 2.88 hours in
# 400 years.

# Time of vernal equinox for year 2000 A.D. is March 20, 7:36 GMT
# [NASA Reference Publication 1349, Oct. 1994].  VERNAL assumes
# that vernal equinox for year 2000 will be on March 20, 7:30, or
# 79.3125 days from 2000 January 1, hour 0.  Vernal equinoxes for
# other years returned by VERNAL are also measured in days from
# 2000 January 1, hour 0.  79.3125 = 31 + 29 + 19 + 7.5/24.
sub vernal {
	my $self = shift;
	my $JYEAR = shift;

	my $EDAYzY = 365.2425;
	my $VE200D = 79.3125;
	my $VERNAL = $VE200D + ($JYEAR - 2000) * $EDAYzY;
}

#----------------------------------------#
# QLEAPY
# Determine whether the given JYEAR is a Leap Year or not.
#----------------------------------------#
sub QLEAPY {
	my $year = shift;

	if(!($year%4)) {
		if($year%100) {
			return(0); # if leap year
		} else {
			if(!($year%400)) {
				return(0);
			}
			return(1)
		}
	}

	return 1; # if it is not leap year
}

#----------------------------------------#
# COSZIJ calculates the daily average cosine of the zenith angle
# weighted by time and weighted by sunlight.
# 
# Input: RLAT = latitude (degrees)
#   SIND,COSD = sine and cosine of the declination angle
# 
# Output: COSZT = sum(cosZ*dT) / sum(dT)
#         COSZS = sum(cosZ*cosZ*dT) / sum(cosZ*dT)
# 
# Intern: DAWN = time of DAWN (temporal radians) at mean local time
#         DUSK = time of DUSK (temporal radians) at mean local time
#----------------------------------------#
sub COSZIJ {
	my $self   = shift;
	my $SIND   = shift;
	my $COSD   = shift;

	my $DUSK   = 0;
	my $CDUSK  = 0;
	my $SDUSK  = 0;
	my $DAWN   = 0;
	my $S2DUSK = 0;
	my $SDAWN  = 0;
	my $S2DAWN = 0;
	my $COSZT  = 0;
	my $COSZS  = 0;
	my $ECOSZ  = 0;
	my $QCOSZ  = 0;

	my $SINJ = sin($self->{CONSTANTS}->{TWOPI} * $self->{latitude} / 360);
	#print "sinj : $SINJ\n";
	my $COSJ = cos($self->{CONSTANTS}->{TWOPI} * $self->{latitude} / 360);
	#print "cosj : $COSJ\n";

	my $SJSD = $SINJ * $SIND;
	my $CJCD = $COSJ * $COSD;

	# Constant nightime at this latitude
	if ( ($SJSD + $CJCD) <= 0) {
		$DAWN  = 999999;
		$DUSK  = 999999;
		$COSZT = 0;
		$COSZS = 0;
	}

	# Constant daylight at this latitude
	if ( ($SJSD - $CJCD) >= 0) {
		$DAWN  = -999999;
		$DUSK  = -999999;
		$ECOSZ = $SJSD * $self->{CONSTANTS}->{TWOPI};
		$QCOSZ = $SJSD * $ECOSZ + .5 * $CJCD * $CJCD * $self->{CONSTANTS}->{TWOPI};
		$COSZT = $SJSD;  #  = ECOSZ/$self->{CONSTANTS}->{TWOPI}
		$COSZS = $QCOSZ / $ECOSZ;
	}

	# Compute DAWN and DUSK (at local time) and their sines
	$CDUSK  = - ($SJSD / $CJCD);
	$DUSK   = acos($CDUSK);
	$SDUSK  = sqrt( $CJCD * $CJCD - $SJSD * $SJSD) / $CJCD;
	$S2DUSK = 2 * $SDUSK * $CDUSK;
	$DAWN   = -$DUSK;
	$SDAWN  = -$SDUSK;
	$S2DAWN = -$S2DUSK;

	# Nightime at initial and final times with daylight in between
	$ECOSZ = $SJSD * ($DUSK-$DAWN) + $CJCD * ($SDUSK - $SDAWN);
	$QCOSZ = $SJSD * $ECOSZ + $CJCD * ($SJSD * ($SDUSK - $SDAWN) +.5 * $CJCD * ($DUSK - $DAWN + .5 * ($S2DUSK-$S2DAWN) ) );
	$COSZT = $ECOSZ / $self->{CONSTANTS}->{TWOPI};
	$COSZS = $QCOSZ / $ECOSZ;

	return ($COSZT, $COSZS);
}

# my own div because we're getting nowhere with '%'
# this is such a hack
# a   = 49.2
# b   = 6.23
# a/b = 7.89
# d   = 7
# e   = 89
# return 49.2 - (7 * 6.23)
sub modulo {
	my $a       = shift;
	my $b       = shift;
	my ($d, $e) = split(/\./, ($a/$b), 2);

	return ($a - ($d * $b));
}

# my own round up because the one that I found on perlmonks.org
# didn't work well
sub _roundup {
	my $a       = shift;
	my ($b, $c) = split(/\./, $a, 2);

	if (($a-$b) >= .5) {
		return ($b+1);
	}

	return $b;
}

1;

__END__

=head1 NAME

Insolation - Perl extension for calculating the amount of energy at a given point on the earth
for a given time period.

=head1 SYNOPSIS

  use Insolation;

  my $insolation = new Insolation();

  $insolation->set_latitude('44.915982');   # set latitude
  $insolation->set_longitude('-93.228340'); # set longitude
  $insolation->set_year('2010');            # set year
  $insolation->set_month('10');             # set month
  $insolation->calculate_insolation();      # calculate the insolation for the givin information

  # get xml output
  my $xml = $insolation->get_xml();

  # get csv output
  my $csv = $insolation->get_csv();

  # get culmulative energy for the month
  my $month_energy = $insolation->get_ym_insolation('2010-10');
  printf "insolation for 2010-10    : %9.2f\n", $month_energy;

  # get the energy on a specific day
  my $day_energy = $insolation->get_ymd_insolation('2010-10-01');
  printf "insolation for 2010-10-01 : %9.2f\n", $day_energy;

=head1 DESCRIPTION

This module will compute the amount of insolation at a specific location.
Passing in your longitude and latitude it'll then need your month and year.
"Insolation" means sunlight received from the Sun at top-of-atmosphere.
On a global annual basis, about 57% of insolation is incident on the Earth's
surface.  Clouds are the main cause of this decrease, but even clear sky will
have some reduction.

=head2 ERRORS

Calculation for insolation in the Atmosphere-Ocean Model has
inaccuracies that should be kept in mind.  These are roughly
ordered according to importance.

1. We assume the Earth revolves through its orbit in exactly 365 days.

2. We assume that the Vernal equinox always occurs on March 21, hour 0.

3. We calculate the Earth in its orbit only once a day.

4. Instead of integrating insolation over a GCM grid box, we integrate insolation over a single latitude line within the box.  That line is the area weighted latitude of the box.  This error causes global insolation to increase by .0001 and is accentuated at the poles.  

5. We keep the orbital parameters fixed during long runs.  

6. We keep the meridion where the sun is overhead on noon Greenwich mean time as the Greenwich meridion.  (That meridion is calculated but not used.) 

7. We treat the Sun as a point; its radius does not affect our distance to the sun.

8. We treat the Earth as a point; its radius does not affect the distance to the sun.

9. We ignore the existence of the Moon, and assume that the center of the Earth-Moon system is the center of the Earth.

10. We assume that the Earth is spherical.

11. We assume that the orbit is a perfect ellipse; other heavenly bodies do not affect it.

12. We use Berger's orbital parameters.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Idea Source link : http://aom.giss.nasa.gov/srlocat.html

Wiki link : http://en.wikipedia.org/wiki/Insolation

Web link : http://www.travisbeste.com/programming/perl/Insolation

=head1 AUTHOR

Travis Kent Beste, E<lt>travis@tencorners.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Travis Kent Beste

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
