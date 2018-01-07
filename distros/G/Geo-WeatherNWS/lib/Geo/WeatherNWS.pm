package Geo::WeatherNWS;

#------------------------------------------------------------------------------
#
# Package Name:  Get Observations from NWS (Geo::WeatherNWS)
#
# Last Modified:  18 December 2001 - Prepared for CPAN - Marc Slagle
#                 24 February 2002 - Adding server/error code - Marc
#                 10 August 2011   - changed FTP server name, added tests,
#                                    docs, some restructuring. - Bob Ernst
#                 14 November 2012 - removed unneeded /d after tr,
#                                    make network tests optional,
#                                    check status of opens - Bob
#                 26 November 2012 - Address bug 14632 (METAR Decoding) from dstroma
#                 		     Address bug 27513 (Geo-WeatherNWS returns wrong station code)
#                 		     from Guenter Knauf
#                                    Fix issues with undefined values,
#                                    Change some conversion constants,
#                                    Round instead of truncate results,
#                                    Only calculate windchill for proper range,
#                                    "ptemerature" is now spelled "ptemperature"
#				     Fixed handling of condition text
#                                    Relax ICAO naming rules
#				     Change ICAO website
#				     Change http web site from weather.noaa.gov
#                                    to www.aviationweather.gov, and change parsing to match.
#                                    Add report_date and report_time items.
#                                    - Bob
#                 27 November 2012 - Add POD documentation for new functions.
#                 1 January 2017 - Switched from POSIX module to File::Temp
#
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# We need these
#------------------------------------------------------------------------------

require 5.005_62;
use strict;
use warnings;
use Net::FTP;
use IO::Handle;
use File::Temp;
use Carp;

#------------------------------------------------------------------------------
# Version
#------------------------------------------------------------------------------

our $VERSION = '1.054';

#------------------------------------------------------------------------------
# Round function
# Using Math::Round would add another dependency
#------------------------------------------------------------------------------

sub round {
    my $float = shift;
    my $rounded;

    if ( defined $float ) {
        $rounded = sprintf "%.0f", $float;
    }
    return $rounded;
}

#------------------------------------------------------------------------------
# Temperature conversion
# If the temperature we are converting from is undefined,
# then the temperature we are converting to is also undefined.
#------------------------------------------------------------------------------

sub convert_f_to_c {
    my $fahrenheit = shift;
    my $celsius;

    if (defined $fahrenheit) {
        $celsius = (5.0/9.0) * ($fahrenheit - 32.0);
    }    
    return $celsius;
}

sub convert_c_to_f {
    my $celsius = shift;
    my $fahrenheit;

    if (defined $celsius)  {
        $fahrenheit = ((9.0/5.0) * $celsius) + 32.0;
    }
    return $fahrenheit;
}

#------------------------------------------------------------------------------
# Windchill
#------------------------------------------------------------------------------

sub windchill {
    my $F = shift;
    my $wind_speed_mph = shift;
    my $windchill;

    # This is the North American wind chill index.
    # Windchill temperature is only defined for:
    # *  temperatures at or below 50 F
    # *  wind speed above 3 mph
    # Bright sunshine may increase the wind chill temperature by
    # 10 to 18 degress F.

    if (defined $F && defined $wind_speed_mph) {
        # Old Formula
        # my $Windc=int(
	#    0.0817*
	#    (3.71*$Self->{windspeedmph}**0.5 + 5.81 - 0.25*$Self->{windspeedmph})*
	#    ($F - 91.4) + 91.4);

        # New Formula
	if ($F <= 50 && $wind_speed_mph > 3) {
            $windchill =
                35.74 +
                ( 0.6215 * $F ) -
                ( 35.75 * ( $wind_speed_mph**0.16 ) ) +
                ( ( 0.4275 * $F ) * ( $wind_speed_mph**0.16 ) );
	}
    }
    return $windchill;
}

#------------------------------------------------------------------------------
# Heat Index
#------------------------------------------------------------------------------

sub heat_index {
    my $F = shift;
    my $rh = shift;
    my $heat_index;

    if (defined $F && defined $rh) {
        $heat_index =
            -42.379 +
            2.04901523 * $F +
            10.14333127 * $rh -
            0.22475541 * $F * $rh -
            6.83783e-03 * $F**2 -
            5.481717e-02 * $rh**2 +
            1.22874e-03 * $F**2 * $rh +
            8.5282e-04 * $F * $rh**2 -
            1.99e-06 * $F**2 * $rh**2;
    }
    return $heat_index;
}

#------------------------------------------------------------------------------
# Convert wind speed from nautical miles per hour to miles per hour
#------------------------------------------------------------------------------

sub convert_kts_to_mph {
    my $knots = shift;
    my $mph;

    if (defined $knots) {
        $mph = $knots * 1.150779;
    }
    return $mph;
}

#------------------------------------------------------------------------------
# Convert wind speed from nautical miles per hour to kilometers per hour
#------------------------------------------------------------------------------

sub convert_kts_to_kmh {
    my $knots = shift;
    my $kmh;

    if (defined $knots) {
        $kmh = $knots * 1.852;
    }
    return $kmh;
}

#------------------------------------------------------------------------------
# Convert miles to kilometers
#------------------------------------------------------------------------------

sub convert_miles_to_km {
    my $miles = shift;
    my $km;

    if (defined $miles) {
        $km = $miles * 1.609344;
    }
    return $km;
}

#------------------------------------------------------------------------------
# Translate Weather into readable Conditions Text
#
# Reference is WMO Code Table 4678
#------------------------------------------------------------------------------

sub translate_weather {
    my $coded = shift;
    my $old_conditionstext = shift;
    my $old_conditions1 = shift;
    my $old_conditions2 = shift;
    my ($conditionstext, $conditions1, $conditions2, $intensity);

    # We use %Converter to translate 2-letter codes into text

    my %Converter = (
        BR => 'Mist',
        TS => 'Thunderstorm',
        MI => 'Shallow',
        PR => 'Partial',
        BC => 'Patches',
        DR => 'Low Drifting',
        BL => 'Blowing',
        SH => 'Shower',
        FZ => 'Freezing',
        DZ => 'Drizzle',
        RA => 'Rain',
        SN => 'Snow',
        SG => 'Snow Grains',
        IC => 'Ice Crystals',
        PE => 'Ice Pellets',
        PL => 'Ice Pellets',
        GR => 'Hail',
        GS => 'Small Hail/Snow',
        UP => 'Unknown Precipitation',
        FG => 'Fog',
        FU => 'Smoke',
        VA => 'Volcanic Ash',
        DU => 'Widespread Dust',
        SA => 'Sand',
        HZ => 'Haze',
        PY => 'Spray',
        PO => 'Dust Devils',
        SQ => 'Squalls',
        FC => 'Tornado',
        SS => 'Sandstorm'
    );

    if ( $coded =~ /^[-+]/ ) {
	# Heavy(+) or Light(-) condition

        if ( !$old_conditions1 ) {
            my ( $Block1, $Block2 );
            my $Modifier = substr( $coded, 0, 1 ); # +/-
            my $Block1t  = substr( $coded, 1, 2 ); # e.g. TS
            my $Block2t  = substr( $coded, 3, 4 ); # e.g. RA

            $Block1 = $Converter{$Block1t};        # e.g. Thunderstorm
            $conditions1 = $Block1;                # e.g. Thunderstorm

            if ($Block2t) {
                $Block2 = $Converter{$Block2t};    # e.g. Rain
                $conditions2 = $Block2;            # e.g. Rain
            }

            if ( $Modifier =~ /^\-/ ) {
                $Block1 = "Light $Block1";         # e.g. Light Thunderstorm
                $intensity = "Light";
            }
            elsif ( $Modifier =~ /^\+/ ) {
                $Block1 = "Heavy $Block1";         # e.g. Heavy Thunderstorm
                $intensity = "Heavy";
            }

            if ($Block2) {
                $Block1 = "$Block1 $Block2";       # e.g. Light Thunderstorm Rain
            }

            if ($old_conditionstext) {
                if ( $Block1 eq "SH" ) {
                    $conditionstext = "$Block2 of $Block1";
                    $conditions1    = "Showers of";
                }
                else {
                    $conditionstext = "$old_conditionstext and $Block1";
                }
            }
            else {
                $conditionstext = $Block1;
            }
        }
    }
    else {
	# Moderate condition

        if ( !$old_conditions1 ) {
            my ( $Block1, $Block2 );
            my $Block1t = substr( $coded, 0, 2 ); # e.g. TS
            my $Block2t = substr( $coded, 2, 4 ); # e.g. RA

            $Block1 = $Converter{$Block1t};       # e.g. Thunderstorm
            $conditions1 = $Block1;               # e.g. Thunderstorm

            if ($Block2t) {
                $Block2      = $Converter{$Block2t};
                $conditions2 = $Block2;
		$Block1      = "$Block1 $Block2";
            }

            if ($old_conditionstext) {
                if ( $Block1 eq "SH" ) {
                    $conditionstext = "$Block2 of $Block1";
                    $conditions1    = "Showers of";
                 }
                 else {
                    $conditionstext = "$old_conditionstext and $Block1";
                 }
            }
            else {
                $conditionstext = $Block1;
            }
        }
    }
    return ($conditionstext, $conditions1, $conditions2, $intensity);
}

#------------------------------------------------------------------------------
# Lets create a new self
#------------------------------------------------------------------------------

sub new {
    my $Proto = shift;
    my $Class = ref($Proto) || $Proto || __PACKAGE__;
    my $Self  = {};

    $Self->{servername} = "tgftp.nws.noaa.gov";
    $Self->{username}   = "anonymous";
    $Self->{password}   = 'weather@cpan.org';
    $Self->{directory}  = "/data/observations/metar/stations";
    $Self->{timeout}    = 120;

    bless $Self, $Class;
    return $Self;
}

#------------------------------------------------------------------------------
# Adding ability to edit server/user/directory at runtime...
#------------------------------------------------------------------------------

sub setservername {
    my $Self       = shift;
    my $Servername = shift;
    $Self->{servername} = $Servername;
    return $Self;
}

sub setusername {
    my $Self = shift;
    my $User = shift;
    $Self->{username} = $User;
    return $Self;
}

sub setpassword {
    my $Self = shift;
    my $Pass = shift;
    $Self->{password} = $Pass;
    return $Self;
}

sub setdirectory {
    my $Self = shift;
    my $Dir  = shift;
    $Self->{directory} = $Dir;
    return $Self;
}

sub settemplatefile {
    my $Self  = shift;
    my $Tfile = shift;
    $Self->{tfile} = $Tfile;
    return $Self;
}

sub settimeout {
    my $Self    = shift;
    my $Seconds = shift;
    $Self->{timeout} = $Seconds;
    return $Self;
}

#------------------------------------------------------------------------------
# Here we get to FTP to the NWS and get the data
#------------------------------------------------------------------------------

sub getreporthttp {
    my $Self = shift;
    my $Code = shift;
    # The old site was: http://weather.noaa.gov/cgi-bin/mgetmetar.pl?cccc=$Code
    $Self->{http} = 
        'http://www.aviationweather.gov/adds/metars/?station_ids=' . $Code . '&chk_metars=on&hoursStr=most+recent+only';
    my $Ret = &getreport( $Self, $Code );
    return $Ret;
}

sub getreport {
    my $Self    = shift;
    my $Station = shift;

    $Self->{error} = "0";

    my $Tmphandle = File::Temp->new();
    my $Tmpfile = $Tmphandle->filename;
    close $Tmphandle;

    my $Code    = uc($Station);

    if ( !$Code ) {
        $Self->{error}     = "1";
        $Self->{errortext} = "No Station Code Entered\n";
        return $Self;
    }

    if ( $Self->{http} ) {
        use LWP::UserAgent;
        my $Ua = LWP::UserAgent->new();
        $Ua->agent("Geo::WeatherNWS $VERSION");

        my $Req = HTTP::Request->new( GET => $Self->{http} );
        $Req->content_type('application/x-www-form-urlencoded');
        my $Res = $Ua->request($Req);

        if ( $Res->is_success ) {
            my @Lines = split( /\n/, $Res->content );
            foreach my $Line (@Lines) {
		if ( $Line =~ /<(TITLE|H1|H2)>/ ) {
			# ignore
		}
		else {
		    # Remove HTML elements.
		    # (This isn't very robust, but it gets the job done for now.)
		    $Line =~ s/<[^>]*>//g;

		    # If the line starts with an ICAO, then the line is an observation (we hope)
                    if ( $Line =~ /^[A-Z][A-Z0-9]{3}\s/ ) {
                        $Self->{obs} = $Line;
                        last;
                    }
                }
            }
        }
    }
    else {

        # Some users needed this for firewalls...
        my $Ftp = Net::FTP->new(
            $Self->{servername},
            Debug   => 0,
            Passive => 1,
            Timeout => $Self->{timeout}
        );

        # my $Ftp=Net::FTP->new($Self->{servername}, Debug => 0);
        if ( !defined $Ftp ) {
            $Self->{error}     = 1;
            $Self->{errortext} = "Cannot connect to $Self->{servername}: $@";
            return $Self;
        }
        $Ftp->login( $Self->{username}, $Self->{password} );
        my $Rcode   = $Ftp->code();
        my $Message = $Ftp->message();

        if ( $Rcode =~ /^[45]/ ) {
            $Self->{error}     = $Rcode;
            $Self->{errortext} = $Message;
            return $Self;
        }

        $Ftp->cwd( $Self->{directory} );
        $Rcode   = $Ftp->code();
        $Message = $Ftp->message();

        if ( $Rcode =~ /^[45]/ ) {
            $Self->{error}     = $Rcode;
            $Self->{errortext} = $Message;
            return $Self;
        }

        $Rcode   = $Ftp->get( "$Code.TXT", $Tmpfile );
        $Rcode   = $Ftp->code();
        $Message = $Ftp->message();
        $Ftp->quit;

        if ( $Rcode =~ /^[45]/ ) {
            $Self->{error}     = $Rcode;
            $Self->{errortext} = $Message;
            return $Self;
        }

        local $/;    # enable slurp mode
        open my $F, '<', $Tmpfile or
		croak "error opening temp input $Tmpfile: $!";
        my $Data = <$F>;
        close($F);
        unlink($Tmpfile);

        $Data =~ tr/\n/ /;
        $Self->{obs} = $Data;
    }

    $Self->decode();
    return $Self;
}

#------------------------------------------------------------------------------
# Decodeobs takes the obs in a string format and decodes them
#------------------------------------------------------------------------------

sub decodeobs {
    my $Self = shift;
    my $Obs  = shift;
    $Self->{obs} = $Obs;
    $Self->decode();
    return $Self;
}

#------------------------------------------------------------------------------
# Decode does the work, and is only called internally
#------------------------------------------------------------------------------

sub decode {
    my $Self = shift;
    my @Cloudlevels;

    my @Splitter = split( /\s+/, $Self->{obs} );

 #------------------------------------------------------------------------------
 # Break the METAR observations down and decode
 #------------------------------------------------------------------------------

    my $have_icao_code = 0;
    my $column = 0;

    foreach my $Line (@Splitter) {
        $column++;


 #------------------------------------------------------------------------------
 # Report date and time
 # These aren't always present (for example, from the http interface)
 #------------------------------------------------------------------------------

        if ( $column == 1 && $Line =~ /^\d{4}\/\d{2}\/\d{2}$/) {
            $Self->{report_date} = $Line;
	}

        if ( $column == 2 && $Line =~ /^\d{2}:\d{2}$/) {
            $Self->{report_time} = $Line;
	}

 #------------------------------------------------------------------------------
 # ICAO station code
 #------------------------------------------------------------------------------

        if ( ( $Line =~ /^([A-Z][A-Z0-9]{3})/ ) &&
	     ( !$have_icao_code ) ) {
	    # Use the first value that looks like the ICAO code.
	    # This should either be the first item, or
	    # the third item if there is a leading date and time.
	    # (Before we checked have_icao_code, we'd get values
	    # like TSRA or FZFG later in the observation being treated
	    # as the ICAO code.)
	    # We also allow the last three characters to be digits.

	    # There was a check for "AUTO" above before, for now
	    # we'll add an extra check for that value. (AUTO should
	    # show up in the fifth column.)
            croak "Unexpected value AUTO for ICAO code" if $Line eq "AUTO";

            $Self->{code} = $Line;
	    $have_icao_code = 1;
        }

 #------------------------------------------------------------------------------
 # Report Time
 #------------------------------------------------------------------------------

        elsif ( $Line =~ /([0-9]Z)$/ ) {
            my $Timez = substr( $Line, 2, 4 );
            $Self->{time} = $Timez;
            $Self->{day} = substr( $Line, 0, 2 );
        }

 #------------------------------------------------------------------------------
 # Wind speed and direction
 #------------------------------------------------------------------------------

        elsif ( $Line =~ /([0-9]KT)$/ ) {
            my $Newline;
            my $Variable;

            if ( $Line =~ /VRB/ ) {
                $Newline = substr( $Line, 3 );
                $Variable = "1";
            }
            else {
                $Newline = $Line;
            }

            my $Winddir = substr( $Newline, 0, 3 );
            $Winddir =~ tr/[A-Z]/ /d;
            $Winddir = $Winddir - 0;
            my $Winddirtxt;

            if ($Variable) {
                $Winddirtxt = "Variable";
            }
            elsif ( ( $Winddir <= 22.5 ) || ( $Winddir >= 337.5 ) ) {
                $Winddirtxt = "North";
            }
            elsif ( ( $Winddir <= 67.5 ) && ( $Winddir >= 22.5 ) ) {
                $Winddirtxt = "Northeast";
            }
            elsif ( ( $Winddir <= 112.5 ) && ( $Winddir >= 67.5 ) ) {
                $Winddirtxt = "East";
            }
            elsif ( ( $Winddir <= 157.5 ) && ( $Winddir >= 112.5 ) ) {
                $Winddirtxt = "Southeast";
            }
            elsif ( ( $Winddir <= 202.5 ) && ( $Winddir >= 157.5 ) ) {
                $Winddirtxt = "South";
            }
            elsif ( ( $Winddir <= 247.5 ) && ( $Winddir >= 202.5 ) ) {
                $Winddirtxt = "Southwest";
            }
            elsif ( ( $Winddir <= 292.5 ) && ( $Winddir >= 247.5 ) ) {
                $Winddirtxt = "West";
            }
            elsif ( ( $Winddir <= 337.5 ) && ( $Winddir >= 292.5 ) ) {
                $Winddirtxt = "Northwest";
            }

            my $Windspeedkts = substr( $Line, 3 );
            my $Windgustkts = 0;

            if ( $Windspeedkts =~ /G/ ) {
                my @Splitter = split( /G/, $Windspeedkts );

                $Windspeedkts = $Splitter[0];
                $Windgustkts  = $Splitter[1];
            }

            $Windspeedkts =~ tr/[A-Z]//d;
            $Windgustkts  =~ tr/[A-Z]//d;

            if ( $Windspeedkts == 0 ) {
                $Winddirtxt = "Calm";
            }

            my $MPH  = round( convert_kts_to_mph($Windspeedkts) );
            my $GMPH = round( convert_kts_to_mph($Windgustkts) );
            my $KMH  = round( convert_kts_to_kmh($Windspeedkts) );
            my $GKMH = round( convert_kts_to_kmh($Windgustkts) );

            $Self->{windspeedkts} = $Windspeedkts;
            $Self->{windgustkts}  = $Windgustkts;
            $Self->{windspeedkts} = $Self->{windspeedkts} - 0;
            $Self->{windspeedmph} = $MPH;
            $Self->{windspeedkmh} = $KMH;
            $Self->{windgustmph}  = $GMPH;
            $Self->{windgustkmh}  = $GKMH;
            $Self->{winddirtext}  = $Winddirtxt;
            $Self->{winddir}      = $Winddir;
            $Self->{winddir}      = $Self->{winddir} - 0;
        }

 #------------------------------------------------------------------------------
 # Current Visibility
 #------------------------------------------------------------------------------

        elsif ( $Line =~ /([0-9]SM)$/ ) {
            $Line =~ tr/[A-Z]//d;

 #------------------------------------------------------------------------------
 # Some stations were reporting fractions for this value
 #------------------------------------------------------------------------------

            if ( $Line =~ /\// ) {
                my @Splitter = split( /\//, $Line );
                $Line = $Splitter[0] / $Splitter[1];
            }

            my $Viskm = convert_miles_to_km( $Line );
            $Self->{visibility_mi} = round($Line);
            $Self->{visibility_km} = round($Viskm);
        }

 #------------------------------------------------------------------------------
 # Current Conditions
 #------------------------------------------------------------------------------

        elsif (
            ( $Line =~ /
                (BR|TS|MI|PR|BC|DR|BL|SH|FZ|DZ|RA|SN|SG|IC|PE|PL|GR|GS|UP|FG|FU|VA|DU|SA|HZ|PY|PO|SQ|FC|SS)
	        ([A-Z])*
	        /x)
            || ( $Line =~ /^VC([A-Z])*/ )
            || ( $Line =~ /[\+\-]VC([A-Z])*/ ) )
        {
            my ($conditionstext, $conditions1, $conditions2, $intensity) = 
	        translate_weather($Line, $Self->{conditionstext}, $Self->{conditions1},$Self->{conditions2});
            $Self->{conditionstext} = $conditionstext if defined $conditionstext;
	    $Self->{conditions1} = $conditions1 if defined $conditions1;
	    $Self->{conditions2} = $conditions2 if defined $conditions2;
	    $Self->{intensity} = $intensity if defined $intensity;
        }

 #------------------------------------------------------------------------------
 # Cloud Cover
 #------------------------------------------------------------------------------

        elsif (( $Line =~ /^(VV[0-9])/ )
            || ( $Line =~ /^(SKC[0-9])/ )
            || ( $Line =~ /^(CLR)/ )
            || ( $Line =~ /^(FEW)/ )
            || ( $Line =~ /^(SCT[0-9])/ )
            || ( $Line =~ /^(BKN[0-9])/ )
            || ( $Line =~ /^(OVC[0-9])/ ) )
        {

            push( @Cloudlevels, $Line );

            if ( $Line =~ /^(CLR)/ ) {
                $Self->{cloudcover} = "Clear";
            }
            elsif ( $Line =~ /^(FEW)/ ) {
                $Self->{cloudcover} = "Fair";
            }
            elsif ( $Line =~ /^(SCT[0-9])/ ) {
                $Self->{cloudcover} = "Partly Cloudy";
            }
            elsif ( $Line =~ /^(BKN[0-9])/ ) {
                $Self->{cloudcover} = "Mostly Cloudy";
            }
            elsif ( $Line =~ /^(OVC[0-9])/ ) {
                $Self->{cloudcover} = "Cloudy";
            }

            if ( !$Self->{conditionstext} ) {
                $Self->{conditionstext} = $Self->{cloudcover};
            }
        }

 #------------------------------------------------------------------------------
 # Get the temperature/dewpoint and calculate windchill/heat index
 #------------------------------------------------------------------------------

        elsif (( $Line =~ /^([0-9][0-9]\/[0-9][0-9])/ )
            || ( $Line =~ /^(M[0-9][0-9]\/)/ )
            || ( $Line =~ /^(M[0-9][0-9]\/M[0-9][0-9])/ )
            || ( $Line =~ /^([0-9][0-9]\/M[0-9][0-9])/ ) )
        {
            my @Splitter    = split( /\//, $Line );
            my $Temperature = $Splitter[0];
            my $Dewpoint    = $Splitter[1];

            if ( $Temperature =~ /M/ ) {
                $Temperature =~ tr/[A-Z]//d;
                $Temperature = ( $Temperature - ( $Temperature * 2 ) );
            }

            if ( $Dewpoint =~ /M/ ) {
                $Dewpoint =~ tr/[A-Z]//d;
                $Dewpoint = ( $Dewpoint - ( $Dewpoint * 2 ) );
            }

            my $Tempf = convert_c_to_f( $Temperature );
            my $Dewf  = convert_c_to_f( $Dewpoint );

            my $Es =
              6.11 * 10.0**( 7.5 * $Temperature / ( 237.7 + $Temperature ) );
            my $E = 6.11 * 10.0**( 7.5 * $Dewpoint / ( 237.7 + $Dewpoint ) );
            my $rh = round( ( $E / $Es ) * 100 );

            my $F = $Tempf;

	    my $Heati = heat_index( $F, $rh );
            my $Heatic = convert_f_to_c( $Heati );

            $Tempf = round($Tempf);
            $Dewf = round($Dewf);
            $Heati = round($Heati);
            $Heatic = round($Heatic);

	    my $Windc = windchill( $F, $Self->{windspeedmph} );
            my $Windcc = convert_f_to_c( $Windc );
	    $Windc = round($Windc);
	    $Windcc = round($Windcc);

            $Self->{temperature_c}     = $Temperature;
            $Self->{temperature_f}     = $Tempf;
            $Self->{dewpoint_c}        = $Dewpoint;
            $Self->{dewpoint_f}        = $Dewf;
            $Self->{relative_humidity} = $rh;
            $Self->{heat_index_c}      = $Heatic;
            $Self->{heat_index_f}      = $Heati;
            $Self->{windchill_c}       = $Windcc;
            $Self->{windchill_f}       = $Windc;
        }

 #------------------------------------------------------------------------------
 # Calculate the atmospheric pressure in different formats.
 # Based on report (inches of mercury)
 #------------------------------------------------------------------------------

        elsif ( $Line =~ /^(A[0-9]{4})/ ) {
            $Line =~ tr/[A-Z]//d;
            my $Part1 = substr( $Line, 0, 2 );
            my $Part2 = substr( $Line, 2, 4 );
            $Self->{pressure_inhg} = "$Part1.$Part2";

            my $mb   = $Self->{pressure_inhg} * 33.8639;
            my $mmHg = $Self->{pressure_inhg} * 25.4;
            my $lbin = ( $Self->{pressure_inhg} * 0.491154 );
            my $kgcm = ( $Self->{pressure_inhg} * 0.0345316 );
            $mb = round($mb);
            $mmHg = round($mmHg);

            $Self->{pressure_mb}   = $mb;
            $Self->{pressure_mmhg} = $mmHg;
            $Self->{pressure_lbin} = $lbin;
            $Self->{pressure_kgcm} = $kgcm;
        }

 #------------------------------------------------------------------------------
 # Calculate the atmospheric pressure in different formats.
 # Based on report (millibars)
 #------------------------------------------------------------------------------

        elsif ( $Line =~ /^(Q[0-9]{4})/ ) {
            $Line =~ tr/[A-Z]//d;
            $Self->{pressure_mb} = $Line;

            my $inhg = ( $Self->{pressure_mb} * 0.02953 );
            $Self->{pressure_inhg} = sprintf( "%.2f", $inhg );
            my $mmHg = $Self->{pressure_inhg} * 25.4;
            my $lbin = ( $Self->{pressure_inhg} * 0.491154 );
            my $kgcm = ( $Self->{pressure_inhg} * 0.0345316 );
            $mmHg = round($mmHg);

            $Self->{pressure_mmhg} = $mmHg;
            $Self->{pressure_lbin} = $lbin;
            $Self->{pressure_kgcm} = $kgcm;
        }

 #------------------------------------------------------------------------------
 # If the remarks section is starting, we are done
 #------------------------------------------------------------------------------

        elsif ( $Line =~ /^(RMK)/ ) {
            last;
        }
    }

 #------------------------------------------------------------------------------
 # Read the remarks into an array for later processing
 #------------------------------------------------------------------------------

    my $Remarks = 0;
    my @Remarkarray;

    foreach my $Line (@Splitter) {
        if ( $Line =~ /^(RMK)/ ) {
            $Remarks = 1;
        }

        if ($Remarks) {
            push( @Remarkarray, $Line );
        }
    }

 #------------------------------------------------------------------------------
 # Delete the temp file
 #------------------------------------------------------------------------------

    $Self->{cloudlevel_arrayref} = \@Cloudlevels;
    $Self->{station_type}        = "Manual";

 #------------------------------------------------------------------------------
 # Now we process remarks.  These aren't all going to be in the report,
 # and usually aren't.  This has made it hard to develop.  This section
 # is basically incomplete, but you can get some of the data out
 #------------------------------------------------------------------------------

    foreach my $Remark (@Remarkarray) {
        if ($Remark) {
            my $Line = $Remark;

            if ( $Remark =~ /^AO[1-2]/ ) {
                $Self->{station_type} = "Automated";
            }
            elsif ( $Remark =~ /^SLP/ ) {
                $Remark =~ tr/[A-Z]//d;

		if ( !defined $Remark || $Remark eq "") {
			$Remark = 0;
		}

                if ( ($Remark) && ( $Remark >= 800 ) ) {
                    $Remark = $Remark * .1;
                    $Remark = $Remark + 900;
                }
                else {
                    $Remark = $Remark * .1;
                    $Remark = $Remark + 1000;
                }

                $Self->{slp_inhg} = ( $Remark * 0.0295300 );
                $Self->{slp_inhg} = substr( $Self->{slp_inhg}, 0, 5 );
                $Self->{slp_mmhg} = round( $Remark * 0.750062 );
                $Self->{slp_lbin} = ( $Remark * 0.0145038 );
                $Self->{slp_kgcm} = ( $Remark * 0.00101972 );
                $Self->{slp_mb}   = round($Remark);
	    }

 #------------------------------------------------------------------------------
 # Thunderstorm info
 #------------------------------------------------------------------------------

            elsif ( $Remark =~ /^TS/ ) {
                $Self->{storm} = $Remark;
            }

 #------------------------------------------------------------------------------
 # Three hour pressure tendency
 #------------------------------------------------------------------------------

            elsif ( $Remark =~ /^5[0-9]/ ) {
                $Self->{thpressure} = $Remark;
            }

 #------------------------------------------------------------------------------
 # Automated station needs maintenance
 #------------------------------------------------------------------------------

            elsif ( $Remark =~ /\$/ ) {
                $Self->{maintenance} = $Remark;
            }

 #------------------------------------------------------------------------------
 # Precipitation since last report (100ths of an inch)
 #------------------------------------------------------------------------------

            elsif ( $Remark =~ /^P[0-9]/ ) {
                $Self->{precipslr} = $Remark;
            }

 #------------------------------------------------------------------------------
 # Event beginning or ending
 #------------------------------------------------------------------------------

            elsif ( $Line =~ /^(BRB|TSB|MIB|PRB|BCB|DRB|BLB|SHB|FZB|DZB|RAB|SNB|SGB|ICB|PEB|GRB|GSB|UPB|FGB|FUB|VAB|DUB|SAB|HZB|PYB|POB|SQB|FCB|SSB)/ )
            {
                $Self->{eventbe} = $Remark;
            }

 #------------------------------------------------------------------------------
 # Precise temperature reading
 #------------------------------------------------------------------------------

            elsif ( $Remark =~ /^T[0-9]/ ) {
                $Self->{ptemperature} = $Remark;
            }
        }
    }

    my $Templatefile = $Self->{tfile};

    if ($Templatefile) {
        local $/;    # enable slurp mode
        open my $F, '<', $Templatefile or
		croak "error opening template file $Templatefile: $!";
        my $tout = <$F>;
        close($F);

        $tout =~ s{ %% ( .*? ) %% }
                        { exists( $Self->{$1} )
                                ? $Self->{$1}
                                : ""
                        }gsex;

        $Self->{templateout} = $tout;
    }

    $Self->{remark_arrayref} = \@Remarkarray;
    return $Self;
}

1;
__END__

=head1 NAME

Geo::WeatherNWS - A simple way to get current weather data from the NWS.

=head1 SYNOPSIS

  use Geo::WeatherNWS;

  my $Report=Geo::WeatherNWS::new();

  # Optionally set the server/user/directory of the reports

  $Report->setservername("tgftp.nws.noaa.gov")
  $Report->setusername("anonymous");
  $Report->setpassword('emailaddress@yourdomain.com');
  $Report->setdirectory("/data/observations/metar/stations");

  # Optionally set a template file for generating HTML

  $Report->settemplatefile(/"path/to/template/file.tmpl");

  # Get the report

  $Report->getreport('kcvg');      # kcvg is the station code for
                                   # Cincinnati, OH

  $Report->getreporthttp('kcvg');  # same as before, but use the
                                   # http method to the script at
				   # http://www.aviationweather.gov/adds/metars/
				   # (used to be weather.noaa.gov)

  # Check for errors

  if ($Report->{error})
  {
    print "$Report->{errortext}\n";
  }

  # If you have the report in a string, you can now just decode it

  my $Obs="2002/02/25 12:00 NSFA 251200Z 00000KT 50KM FEW024 SCT150 27/25 Q1010";
  $Report->decodeobs($Obs);

=head1 DESCRIPTION

  New for version 1.03:  the getreporthttp call now calls the script
  on the weather.noaa.gov site for those who can't FTP through
  firewalls.

  This module is an early release of what will hopefully be a robust
  way for Perl Programmers to get current weather data from the
  National Weather Service.  Some new functions have been added since
  the 0.18 release.

  Instead of having to use the built-in server/user/password/directory
  that the module used to use, you can provide your own.  This way if
  you have access to a mirror server of the data, you can specify the
  servername, account information and directory where the files exist.
  If you don't have access to a mirror, then you don't have to specify
  anything.  The old server, etc., are still automagically selected.

  Also new in this release is that the getreport function now returns
  an error code and the FTP error message if anything goes wrong.
  Before this was added, if the server was busy or the stations text
  file was missing you couldn't tell what happened.

  Another new feature is the template system.  You can specify a file
  with the settemplatefile function.  This file is read in and all of
  the places in the file where the code sees %%name%% will be replaced
  with the proper values. An example template has been included.
  The template uses the same names as the hashref returned by the
  getreport function.

  And, same as previous releases, the getreport function retrieves
  the most current METAR formatted station report and decodes it into
  a hash that you can use.

  Some users had reported that they wanted to re-decode the raw
  observations later.  If you store the "obs" value as a string, and
  you want to re-decode it later, you can now use the decodeobs
  function.

  I thought this would be a useful module, considering that a lot of
  sites today seem to get their weather data directly through other
  sites via http. When the site you are getting your weather data
  from changes format, then you end up having to re-code your parsing
  program.  With the weather module, all you need is a four-letter
  station code to get the most recent weather observations.

  If you do not know what the station code is for your area,
  these sites might help your search:

    http://en.wikipedia.org/wiki/List_of_airports_by_ICAO_code

    http://www.aircharterguide.com/Airports 
                 		     
  Since this module uses the NWS METAR Observations, you can get
  weather reports from anywhere in the world that has a four-letter
  station code.

  This module uses the Net::FTP module, so make sure it is available.

  To begin:

  use Geo::WeatherNWS;
  my $Report=Geo::WeatherNWS::new();

  If you want to change the server and user information, do it now.
  This step is not required.  If you don't call these functions, the
  module uses the defaults.

  $Report->setservername("weather.noaa.gov");
  $Report->setusername("anonymous");
  $Report->setpassword('emailaddress@yourdomain.com');
  $Report->setdirectory("/data/observations/metar/stations");
  $Report->settimeout(240);

  If you want to specify a template file, use this:

  $Report->settemplatefile("/path/to/template/file.tmpl");

  After setting the above, you can get the data.

  $Report->getreport('station');

  Now you can check to see if there was an error, and what the text
  of the error message was.

  if ($Report->{error})
  {
    print "$Report->{errortext}";
  }

  If you have the report in a string, you can now just decode it

  my $Obs="2002/02/25 12:00 NSFA 251200Z 00000KT 50KM FEW024 SCT150 27/25 Q1010";
  $Report->decodeobs($Obs);

  Assuming there was no error, you can now use the $Report hashref
  to display the information.  Some of the returned info is about
  the report itself, such as:

  $Report->{day}                # Report day of month
  $Report->{time}               # Report Time
  $Report->{station_type}       # Station Type (auto or manual)
  $Report->{obs}                # The Observation Text (encoded)
  $Report->{code}               # The Station Code

  These values might also be available.
  (The values {day} and {time} above should always be available.)  
  $Report->{report_date}        # Report Date
  $Report->{report_time}        # Report Time

  This is the template output:

  $Report->{templateout}

  These are the returned values specific to the conditions:

  $Report->{conditionstext}     # Conditions text
  $Report->{conditions1}        # First Part
  $Report->{conditions2}        # Second Part

  These are the returned values specific to wind:

  $Report->{windspeedmph}       # Wind Speed (in mph)
  $Report->{windspeedkts}       # Wind Speed (in knots)
  $Report->{windspeedkmh}       # Wind Speed (in km/h)
  $Report->{winddir}            # Wind Direction (in degrees)
  $Report->{winddirtext}        # Wind Direction (text version)
  $Report->{windgustmph}        # Wind Gusts (mph)
  $Report->{windgustkts}        # Wind Gusts (knots)
  $Report->{windgustkmh}        # Wind Gusts (km/h)

  These are the returned values specific to temperature and
  humidity:

  $Report->{temperature_f}      # Temperature (degrees f)
  $Report->{temperature_c}      # Temperature (degrees c)
  $Report->{dewpoint_f}         # Dewpoint (degrees f)
  $Report->{dewpoint_c}         # Dewpoint (degrees c)
  $Report->{relative_humidity}  # Relative Humidity (in percent)
  $Report->{windchill_f}        # Wind Chill (degrees f)
  $Report->{windchill_c}        # Wind Chill (degrees c)
  $Report->{heat_index_f}       # Heat Index (degrees f)
  $Report->{heat_index_c}       # Heat Index (degrees c)

  Note: Due to the formulas used to get the heat index and windchill,
  sometimes these values are a little strange.  A check to see if the
  heat index is above the temperature before displaying it would be
  a good thing for you to do.  You probably don't want to display
  the windchill unless its cold either.

  These are the return values for clouds and visibility:

  $Report->{cloudcover}           # Cloudcover (text)
  $Report->{cloudlevel_arrayref}  # Arrayref holding all cloud levels
  $Report->{visibility_mi}        # Visibility (miles)
  $Report->{visibility_km}        # Visibility (kilometers)

  These are the return values for air pressure:

  $Report->{pressure_inhg}    # Air Pressure (in mercury)
  $Report->{pressure_mmhg}    # Air Pressure (in mm mercury)
  $Report->{pressure_kgcm}    # Air Pressure (kg per cm)
  $Report->{pressure_mb}      # Air Pressure (mb)
  $Report->{pressure_lbin}    # Air Pressure (psi)

  Other values MAY be returned, but only if there are remarks
  appended to the observations.  This section of the code is more
  experimental, and these names could change in future releases.

  $Report->{remark_arrayref} # Arrayref holding all remarks
  $Report->{ptemperature}     # Precise Temperature Reading
  $Report->{storm}           # Thunderstorm stats
  $Report->{slp_inhg}        # Air Pressure at Sea Level (in mercury)
  $Report->{slp_mmhg}        # Air Pressure at Sea Level (mm mercury)
  $Report->{slp_kgcm}        # Air Pressure at Sea Level (kg per cm)
  $Report->{slp_lbin}        # Air Pressure at Sea Level (psi)
  $Report->{slp_mb}          # Air Pressure at Sea Level (mb)

  Another note:  Do not be surprised if sometimes the values come
  back empty. The weather stations are not required to place all of
  the information in the reports.

=head1 CONSTRUCTOR

=over

=item new ( )

Creates an object for the NWS METAR weather report.

=back

=head1 METHODS

=over

=item setservername( $Servername )

Set the server name for FTP access.

=item setusername( $User )

Set the username for FTP access.

=item setpassword( $Pass )

Set the password for FTP access.

=item setdirectory( $Dir )

Set the directory for the weather data on the FTP server.

=item settemplatefile( $Tfile )

Set the template file for the HTML report.

=item settimeout( $Seconds )

Set the timeout in seconds for FTP actions.

=item getreporthttp( $Code )

Get the METAR report for a station using HTTP.

=item getreport( $Station )

Get the report for a station using HTTP or FTP.

=item decodeobs( $Obs )

Decodeobs takes the obs in a string format and decodes them.

=item convert_c_to_f ( $celsius )

Convert a temperature in Celsius to Fahrenheit. 

=item convert_f_to_c ( $fahrenheit )

Convert a temperature in Fahrenheit to Celsius.

=item convert_kts_to_kmh ( $knots )

Convert a speed in knots to kilometers per hour.

=item convert_kts_to_mph ( $knots )

Convert a speed in knots to miles per hour.

=item convert_miles_to_km ( $miles )

Convert a distance in miles to kilometers.

=item heat_index ( $fahrenheit, $rh )

Calculate the heat index based on the temperature (in Fahrenheit) and the
relative humidity.

=item windchill ( $fahrenheit, $wind_speed_mph )

Calculate the windchill based on the temperature (in Fahrenheit) and
the wind speed (in MPH).

Windchill isn't defined when the temperture is above 50 F,
or for wind speeds under 4 MPH.

=item round ( $float )

Convert a floating point number to an integer by rounding.

=item translate_weather ( $coded, $old_conditionstext, $old_conditons1, $old_conditions2 )

Translate Weather into readable conditions text, per WMO Code Table 4678.
This is only called internally.

=item decode( )

Decode does the work, and is only called internally.

=back

=head1 EXAMPLE

  use Geo::WeatherNWS;

  my $Report=Geo::WeatherNWS::new();
  $Report->getreport('khao');        # For Hamilton, OH

  print "Temperature is $Report->{temperature_f} degrees\n";
  print "Air Pressure is $Report->{pressure_inhg} inches\n";

  # If it isn't raining, etc. - just print cloud cover

  if ($Report->{conditionstext})
  {
      print "Conditions: $Report->{conditionstext}\n";
  }
  else
  {
      print "Conditions: $Report->{cloudcover}\n";
  }

=head1 AUTHORS

  Marc Slagle - marc.slagle@online-rewards.com
  Bob Ernst - bobernst@cpan.org

=cut
