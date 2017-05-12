# $Id: METAR.pm,v 1.11 2008/01/02 13:47:00 koos Exp $

# KH: fix the parser
# should be a finite state machine
# - metar has rules what comes after what. but codes can be missing.
# (measurement not done) or //// (measurement broken at the moment)
# so given a state counter, it can stay the same or go up one or more states,
# but it can never go down
#
# info on the last bit which is actually a forecast: (German)
# http://www.wetterklima.de/flug/metar/Metarvorhersage.htm
#
# more info here (dutch, and txt 707 is not standard metar)
# http://www.vwkweb.nl/index.html?http://www.vwkweb.nl/weerinfo/weerinfo_teletekst707.html
# and also (dutch)
# http://www.gids.nl/weather/eheh/metari.html
#
# 'METAR decoding in Europe'
# http://users.hol.gr/~chatos/VATSIM/TM/metar.html
#
# english explanation
# http://booty.org.uk/booty.weather/metinfo/codes/METAR_decode.htm
#
# canadian explanation
# http://meteocentre.com/doc/metar.html
#
# 'METAR decoding, TAF decoding'
# http://stoivane.kapsi.fi/metar/
#

# This module is used for decoding NWS METAR code.

# Example METARs
#
# Findlay, Ohio
# KFDY 251450Z 21012G21KT 8SM OVC065 04/M01 A3010 RMK SLP201 57014
#
# Toledo, Ohio
# KTOL 251451Z 23016G22KT 8SM CLR 04/00 A3006 RMK AO2 SLP185 T00440000 56016 
#
# Cleveland, Ohio
# KCLE 251554Z 20015KT 10SM FEW055 OVC070 03/M02 A3011 RMK AO2 SLP205 T00331017
#
# Houston, Texas
# KHST 251455Z 06017G22KT 7SM FEW040 BKN330 25/18 A3016 RMK SLP213 8/508
# 9/205 51007
#
# LA
#
# KLAX 251450Z 07004KT 7SM SCT100 BKN200 14/11 A3005 RMK AO2 SLP173
# T01390111 56005
#
# Soesterberg
#
# EHSB 181325Z 24009KT 8000 -RA BR FEW011 SCT022 OVC030 07/06 Q1011 WHT WHT TEMPO GRN

# For METAR info, please see
# http://tgsv5.nws.noaa.gov/oso/oso1/oso12/metar.htm
# moved
# http://metar.noaa.gov/
#
# in scary detail (metar coding)
#
# http://metar.noaa.gov/table_master.jsp?sub_menu=yes&show=fmh1ch12.htm&dir=./handbook/&title=title_handbook
#


# The METAR specification is dictated in the Federal Meteorological Handbook
# which is available on-line at:
# http://tgsv5.nws.noaa.gov/oso/oso1/oso12/fmh1.htm

# General Structure is:
# TYPE, SITE, DATE/TIME, WIND, VISIBILITY, CLOUDS, TEMPERATURE, PRESSURE, REMARKS

# Specifically:

# TYPE (optional)
# METAR or SPECI
# METAR: regular report
# SPECI: special report

# SITE (required, only once)
#
# 4-Char site identifier (KLAX for LA, KHST for Houston)

# DATE/TIME (required, only once)
#
# 6-digit time followed by "Z", indicating UTC

# REPORT MODIFIER (optional)
# AUTO or COR
# AUTO = Automatic report (no human intervention)
# COR = Corrected METAR or SPECI

# WIND (group)
#
# Wind direction (\d\d\d) and speed (\d?\d\d) and optionaling gusting
# information denoted by "G" and speed (\d?\d\d) followed by "KT", for knots.
#
# Wind direction MAY be "VRB" (variable) instead of a compass direction.
#
# Variable Wind Direction (Speeds greater than 6 knots).  Variable wind
# direction with wind speed greater than 6 knots shall be coded in the
# format, dndndnVdxdxdx
#
# Calm wind is recorded as 00000KT.

# VISIBILITY (group)
#
# Visibility (\d+) followed by "SM" for statute miles or no 'SM' for meters
# (european)
#
# May be 1/(\d)SM for a fraction.
#
# May be M1/\d)SM for less than a given fraction. (M="-")
#
# \d\d\d\d according to KNMI
# lowest horizontal visibility (looking around)
# round down
# 0000 - 0500m in steps of 0050m
# 0500 - 5000m in steps of 0100m
# 5000 - 9999m in steps of 1000m
# 10km or more is 9999

# RUNWAY Visual Range (Group)
#
# R(\d\d\d)(L|C|R)?/((M|P)?\d\d\d\d){1,2}FT
#
# Where:
#  $1 is the runway number.
#  $2 is the runway (Left/Center/Right) for parallel runways.
#  $3 is the reported visibility in feet.
#  $4 is the MAXIMUM reported visibility, making $3 the MINIMUM.
#
#  "M" beginning a value means less than the reportable value of \d\d\d\d.
#  "P" beginning a value means more than the reportable value of \d\d\d\d.
#
#  new
#
#  R(\d\d\d[LCR]?)/([MP]?\d\d\d\d)(V[MP]?\d\d\d\d)?FT
#
# $1 runway number + Left/Center/Right
# $2 visibility feet
# $3 Varying feet
# M = less than
# P = more than

# WEATHER (Present Weather Group)
#
# See table in Chapter 12 of FMH-1.

# CLOUDS (Sky Condition Group)
#
# A space-separated grouping of cloud conditions which will contain at least
# one cloud report. Examples: "CLR", "BKN330", "SCT100", "FEW055", "OVC070"
# The three-letter codes represent the condition (Clear, Broken, Scattered,
# Few, Overcast) and the numbers (\d\d\d) represent altitlude/100.
#
# The report may have a trailing CB (cumulonimbus) or TCU (towering
# cumulus) appended. ([A-Z]{2,3})?(\d\d\d)(CB|TCU)?

# Vertical visibility (VV)
#
# VV
# This group is reported when the sky is obscured. VV is the group indicator,
# and hshshs is the vertical visibility in units of 30 metres
# (hundreds of feet).
#  
#  hshshs - Examples of Encoding
#  HEIGHT 		METAR CODE
#  100 ft 	(30 metres) 	001
#  450 ft 	(135 metres) 	004
#  2,700 ft 	(810 metres) 	027
#  12,600 ft 	(3,780 metres) 	1300
#
# source http://meteocentre.com/doc/metar.html
# 
# TEMPERATURE and DEW POINT
#
# (M?\d\d)/(M?\d\d) where $1 is the current temperature in degrees celcius,
# and $2 is the current dewpoint in degrees celcius.
#
# The "M" signifies a negative temperature, so converting the "M" to a
# "-" ought to suffice.

# PRESSURE
#
# The pressure, or altimeter setting, at the reporting site recorded in
# inches of mercury (Hg) minus the decimal point. It should always look
# like (A\d\d\d\d).
#
# KNMI: Q\d\d\d\d pressure in hPa calculated for sea level

# REMARKS
#
# Remarks contain additional information. They are optional but often
# informative of special conditions.
#
# Remarks begin with the "RMK" keyword and continue to the end of the line.
#
# trend group
#
# color codes BLU WHT GRN YLO AMB RED
# BLACK: vliegveld dicht
# future trend 
# NOSIG no significant change
# TEMPO temporary change
# WHT WHT TEMPO GRN = current white, prediction white temporary green
# NSW no significant weather
# AT at a given time
# PROB30 probability 30%
# BECMG becoming
# BECMG (weather) FM \d\d\d\d TL \d\d\d\d = from until utc times
# BECMG (weather) AT \d\d\d\d = at utc time
# BECMG (weather) TL \d\d\d\d = change until utc time
# BECMG 2000 visibility
# BECMG NSW weather type
# etc etc
# FCST CANCEL (2 tokens!) Forecast cancel: no further forecasts for a while

### Package Definition

package Geo::METAR;

## Required Modules

use 5.005;
use strict;
use vars qw($AUTOLOAD $VERSION);
use Carp 'cluck';

$VERSION = '1.15';

##
## Lookup tables
##

my %_weather_types = (
    MI => 'shallow',
    PI => 'partial',
    BC => 'patches',
    DR => 'drizzle',
    BL => 'blowing',
    SH => 'shower(s)',
    TS => 'thunderstorm',
    FZ => 'freezing',

    DZ => 'drizzle',
    RA => 'rain',
    SN => 'snow',
    SG => 'snow grains',
    IC => 'ice crystals',
    PE => 'ice pellets',
    GR => 'hail',
    GS => 'small hail/snow pellets',
    UP => 'unknown precip',

    BR => 'mist',
    FG => 'fog',
    PRFG => 'fog banks',  # officially PR is a modifier of FG
    FU => 'smoke',
    VA => 'volcanic ash',
    DU => 'dust',
    SA => 'sand',
    HZ => 'haze',
    PY => 'spray',

    PO => 'dust/sand whirls',
    SQ => 'squalls',
    FC => 'funnel cloud(tornado/waterspout)',
    SS => 'sand storm',
    DS => 'dust storm',
);

my $_weather_types_pat = join("|", keys(%_weather_types));

my %_sky_types = (
    SKC => "Sky Clear",
    CLR => "Sky Clear",
    SCT => "Scattered",
    BKN => "Broken",
    FEW => "Few",
    OVC => "Solid Overcast",
    NSC => "No significant clouds",
    NCD => "No cloud detected",
);

my %_trend_types = (
    BLU => "8 km view",
    WHT => "5 km view",
    GRN => "3.7 km view",
    YLO => "1.6 km view",
    AMB => "0.8 km view",
    RED => "< 0.8 km view",
    BLACK => "airport closed",
    NOSIG => "No significant change",
    TEMPO => "Temporary change",
    NSW => "No significant weather",
    PROB => "Probability",
    BECMG => "Becoming",
    LAST => "Last",
);

my $_trend_types_pat = join("|", keys(%_trend_types));

##
## Constructor.
##

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};

    ##
    ## UPPERCASE items have documented accssor functions (methods) or
    ## use AUTOLOAD, while lowercase items are reserved for internal
    ## use.
    ##

    $self->{VERSION}       = $VERSION;          # version number
    $self->{METAR}         = undef;             # the actual, raw METAR
    $self->{TYPE}          = undef;             # the type of report
    $self->{SITE}          = undef;             # site code
    $self->{DATE}          = undef;             # when it was issued
    $self->{TIME}          = undef;             # time it was issued
    $self->{MOD}           = undef;             # modifier (AUTO/COR)
    $self->{WIND_DIR_DEG}  = undef;             # wind dir in degrees
    $self->{WIND_DIR_ENG}  = undef;             # wind dir in english (Northwest/Southeast)
    $self->{WIND_DIR_ABB}  = undef;             # wind dir in abbreviated english (NW/SE)
    $self->{WIND_KTS}      = undef;             # wind speed (knots)
    $self->{WIND_GUST_KTS} = undef;             # wind gusts (knots)
    $self->{WIND_MPH}      = undef;             # wind speed (MPH)
    $self->{WIND_GUST_MPH} = undef;             # wind gusts (MPH)
    $self->{WIND_VAR}      = undef;             # wind variation (text)
    $self->{WIND_VAR_1}    = undef;             # wind variation (direction 1)
    $self->{WIND_VAR_2}    = undef;             # wind variation (direction 2)
    $self->{VISIBILITY}    = undef;             # visibility info
    $self->{RUNWAY}        = [ ];               # runway vis.
    $self->{WEATHER}       = [ ];               # current weather
    $self->{WEATHER_LOG}   = [ ];               # weather log
    $self->{SKY}           = [ ];               # current sky (cloudcover)
    $self->{TEMP_F}        = undef;             # current temp, celcius
    $self->{TEMP_C}        = undef;             # converted to fahrenheit
    $self->{DEW_F}         = undef;             # dew point, celcius
    $self->{DEW_C}         = undef;             # dew point, fahrenheit
    $self->{HOURLY_TEMP_F} = undef;             # hourly current temp, celcius
    $self->{HOURLY_TEMP_C} = undef;             # hourly converted to fahrenheit
    $self->{HOURLY_DEW_F}  = undef;             # hourly dew point, celcius
    $self->{HOURLY_DEW_C}  = undef;             # hourly dew point, fahrenheit
    $self->{HOURLY_PRECIP} = undef;             # hourly precipitation
    $self->{ALT}           = undef;             # altimeter setting
    $self->{SLP}           = undef;             # sea level pressure
    $self->{REMARKS}       = undef;             # remarks

    $self->{tokens}        = [ ];               # the "token" list
    $self->{type}          = "METAR";           # the report type (METAR/SPECI)
                                                # default=METAR
    $self->{site}          = undef;             # the site code (4 chars)
    $self->{date_time}     = undef;             # date/time
    $self->{modifier}      = "AUTO";            # the AUTO/COR modifier (if
                                                # any) default=AUTO
    $self->{wind}          = undef;             # the wind information
    $self->{windtype}      = undef;             # the wind speed type (knots/meterpersecond/kilometersperhour)
    $self->{windvar}       = undef;             # the wind variation
    $self->{visibility}    = undef;             # visibility information
    $self->{runway}        = undef;             # runway visibility
    $self->{weather}       = [ ];               # current weather conditions
    $self->{sky}           = [ ];               # sky conditions (cloud cover)
    $self->{temp_dew}      = undef;             # temp and dew pt.
    $self->{alt}           = undef;             # altimeter setting
    $self->{pressure}      = undef;             # pressure (HPa)
    $self->{slp}           = undef;             # sea level pressure
    $self->{remarks}       = [ ];               # remarks

    $self->{debug}         = undef;             # enable debug trace

    bless $self, $class;
    return $self;
}

##
## Autoload for access methods to stuff in %fields hash. We should
## probably disallow access to the lower-case items as stated above,
## but I don't feel like being a Nazi about it. Besides, I haven't
## checked to see what that might break.
##

sub AUTOLOAD
{
    my $self = shift;

    if (not ref $self)
    {
	cluck "bad AUTOLOAD for obj [$self]";
    }

    if ($AUTOLOAD =~ /.*::(.*)/)
    {
        my $key = $1;


        ## Backward compatible temps...

        my %compat = (
                      F_TEMP    =>  'TEMP_F',
                      C_TEMP    =>  'TEMP_C',
                      F_DEW     =>  'DEW_F',
                      C_DEW     =>  'DEW_C',
                     );

        if ($compat{$key})
        {
            $key = $compat{$key};
        }

        ## Check for the items...

        if (exists $self->{$key})
        {
            return $self->{$key};
        }
        else
        {
            return undef;
        }
    }
    else
    {
        warn "strange AUTOLOAD problem!";
        return undef;
    }
}

##
## Get current version number.
##

sub version
{
    my $self = shift;
    print "version() called.\n" if $self->{debug};
    return $self->{VERSION};
}

##
## Take a METAR, tokenize, and process it.
##

sub metar
{
    my $self = shift;

    if (@_)
    {
        $self->{METAR} = shift;
        $self->{METAR} =~ s/\n//g;    ## nuke any newlines
        _tokenize($self);
        _process($self);
    }
    return $self->{METAR};
}

##
## Break {METAR} into parts. Stuff into @tokens.
##

sub _tokenize
{
    my $self = shift;
    my $tok;
    my @toks;

    # Split tokens on whitespace.
    @toks = split(/\s+/, $self->{METAR});
    $self->{tokens} = \@toks;
}

## Process @tokens to populate METAR values.
##
## This is a long and involved subroutine. It basically copies the
## @tokens array and treats it as a stack, popping off items,
## examining them, and see what they look like.  Based on their
## "apppearance" it takes care populating the proper fields
## internally.

sub _process
{
    my $self = shift;

    my @toks = @{$self->{tokens}};      # copy tokens array...

    my $tok;

    ## This is a semi-brute-force way of doing things, but the amount
    ## of data is relatively small, so it shouldn't be a big deal.
    ##
    ## Ideally, I'd have it skip checks for items which have been
    ## found, but that would make this more "linear" and I'd remove
    ## the pretty while loop.
	#
	# KH: modified to maintain state to not get lost in remarks and stuff
	# and be a lot better at parsing
	
	# states

	my $expect_type = 0;
	my $expect_site = 1;
	my $expect_datetime = 2;
	my $expect_modifier = 3;
	my $expect_wind = 4;
	my $expect_visibility = 5;
	my $expect_runwayvisual = 6;
	my $expect_presentweather = 7;
	my $expect_clouds = 8;
	my $expect_temperature = 9;
	my $expect_pressure = 10;
	my $expect_recentweather = 11;
	my $expect_remarks = 12;
	my $expect_usremarks = 13;

	my $parsestate = $expect_type;

	# windtypes
	
	my $wt_knots = 1;
	my $wt_mps = 2;
	my $wt_kph = 3;

    ## Assume standard report by default

    $self->{type} = "METAR";
    $self->{TYPE} = "Routine Weather Report";

    while (defined($tok = shift(@toks))) ## as long as there are tokens
    {
        print "trying to match [$tok] state is $parsestate\n" if $self->{debug};

        ##
        ## is it a report type?
        ##

        if (($parsestate == $expect_type) and ($tok =~ /(METAR|SPECI)/i))
        {
            $self->{type} = $tok;

            if ($self->{type} eq "METAR")
            {
                $self->{TYPE} = "Routine Weather Report";
            }
            elsif ($self->{type} eq "SPECI")
            {
                $self->{TYPE} = "Special Weather Report";
            }
            print "[$tok] is a report type.\n" if $self->{debug};
			$parsestate = $expect_site;
            next;
        }

        ##
        ## is is a site ID?
        ##

        elsif (($parsestate <= $expect_site) and ($tok =~ /([A-Z]{4}|K[A-Z0-9]{3})/))
        {
            $self->{site} = $tok;
            print "[$tok] is a site ID.\n" if $self->{debug};
			$parsestate = $expect_datetime;
            next;
        }

        ##
        ## is it a date/time?
        ##

        elsif (($parsestate == $expect_datetime) and ($tok =~ /\d{6,6}Z/i))
        {
            $self->{date_time} = $tok;
            print "[$tok] is a date/time.\n" if $self->{debug};
			$parsestate = $expect_modifier;
            next;


        }

        ##
        ## is it a report modifier?
        ##

        elsif (($parsestate == $expect_modifier) and ($tok =~ /AUTO|COR|CC[A-Z]/i))
        {
            $self->{modifier} = $tok;
            print "[$tok] is a report modifier.\n" if $self->{debug};
			$parsestate = $expect_wind;
            next;
        }

        ##
        ## is it wind information in knots?
        #
		# eew: KT seems to be optional
		# but making it optional fails on other stuff
		# sortafix: wind needs to be \d\d\d\d\d or VRB\d\d
		#      optional \d\d\d\d\dG\d\d\d (gust direction)

        elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_visibility) and ($tok =~ /(\d{3}|VRB)\d{2}(G\d{1,3})?(KT)?$/i))
        {
            $self->{wind} = $tok;
			$self->{windtype} = $wt_knots;
            print "[$tok] is wind information in knots.\n" if $self->{debug};
			$parsestate = $expect_wind; # stay in wind, it can have variation
            next;
        }

		##
		## is it wind information in meters per second?
		##
		## can be variable too

        elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_visibility) and ($tok =~ /^(\d{3}|VRB)\d{2}(G\d{2,3})?MPS$/))
        {
            $self->{wind} = $tok;
            print "[$tok] is wind information.\n" if $self->{debug};
			$self->{windtype} = $wt_mps;
			$parsestate = $expect_wind; # stay in wind, it can have variation
            next;
        }

		##
		## is it wind variation information?
		##

		elsif (($parsestate >= $expect_wind) and ($parsestate < $expect_visibility) and ($tok =~ /^\d{3}V\d{3}$/))
		{
			$self->{windvar} = $tok;
			print "[$tok] is wind variation information.\n" if $self->{debug};
			$parsestate = $expect_visibility;
			next;
		}

		##
		## wind information missing at the moment?
		##

		elsif (($parsestate >= $expect_wind) and ($parsestate < $expect_visibility) and ($tok =~ /^\/\/\/\/\/(KT|MPS)$/)){
			print "[$tok] is missing wind information.\n" if $self->{debug};
			$parsestate = $expect_visibility;
			next;
		}

		##
		## is it visibility information in meters?
		##
	
		elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_runwayvisual) and ($tok =~ /^\d{4}$/))
		{
			$self->{visibility} = $tok;
            print "[$tok] is numerical visibility information.\n" if $self->{debug};
			$parsestate = $expect_visibility;
            next;
        }

		## auto visibility information in meters?

		elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_runwayvisual) and ($tok =~ /^\d{4}NDV$/))
		{
			$self->{visibility} = $tok;
            print "[$tok] is automatic numerical visibility information.\n" if $self->{debug};
			$parsestate = $expect_visibility;
            next;
        }

        ##
        ## is it visibility information in statute miles?
        ##

        elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_runwayvisual) and ($tok =~ /.*?SM$/i))
        {
            $self->{visibility} = $tok;
            print "[$tok] is statute miles visibility information.\n" if $self->{debug};
			$parsestate = $expect_visibility;
            next;
        }

        ##
        ## is it visibility information with a leading digit?
		##
		## sample:
		## KERV 132345Z AUTO 07008KT 1 1/4SM HZ 34/11 A3000 RMK AO2
		##                           ^^^^^^^
        ##

        elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_runwayvisual) and  ($tok =~ /^\d$/))
        {
            $tok .= " " . shift(@toks);
            $self->{visibility} = $tok;
            print "[$tok] is multi-part visibility information.\n" if $self->{debug};
			$parsestate = $expect_visibility;
            next;
        }

		## visibility modifier

		elsif (($parsestate == $expect_visibility) and ($tok =~ /^\d{4}(N|S|E|W|NE|NW|SE|SW)$/))
		{
            print "[$tok] is a visibility modifier.\n" if $self->{debug};
            next;
		}

        ##
        ## is it runway visibility info?
        ##
		# KH: I've seen runway visibility with 'U' units
		# EHSB 121425Z 22010KT 1200 R27/1600U -DZ BKN003 OVC007 07/07 Q1016 AMB FCST CANCEL
		# U= going up, D= going down, N= no change
		# tendency of visual range, http://stoivane.kapsi.fi/metar/

        elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_presentweather) and ($tok =~ /R\d+(L|R|C)?\/P?\d+(VP?\d+)?(FT|D|U|N|\/)?$/i))
        {
            push (@{$self->{RUNWAY}},$tok);
            print "[$tok] is runway visual information.\n" if $self->{debug};
			$parsestate = $expect_runwayvisual;
			# there can be multiple runways, so stay at this state
            next;
        }

        ##
        ## is it current weather info?
        ##

        elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_clouds) and ($tok =~ /^(-|\+)?(VC)?($_weather_types_pat)+/i))
        {
            my $engl = "";
            my $qual = $1;
            my $addlqual = $2;

            ## qualifier

            if (defined $qual)
            {
                if ( $qual eq "-" ) {
                    $engl = "light";
                } elsif ( $qual eq "+" ) {
                    $engl = "heavy";
                } else {
                    $engl = ""; ## moderate
                }
            }
            else
            {
                $engl = ""; ## moderate
            }

            while ( $tok =~ /($_weather_types_pat)/gi )
            {
                $engl .= " " . $_weather_types{$1}; ## figure out weather
            }

            ## addl qualifier

            if (defined $addlqual)
            {
                if ( $addlqual eq "VC" )
                {
                    $engl .= " in vicinity";
                }
            }

            $engl =~ s/^\s//gio;
            $engl =~ s/\s\s/ /gio;

            push(@{$self->{WEATHER}},$engl);
            push(@{$self->{weather}},$tok);
            print "[$tok] is current weather.\n" if $self->{debug};
			$parsestate = $expect_presentweather;
			# there can be multiple current weather types, so stay at this state
            next;
        }

		##
		## special case: CAVOK
		##
		
		elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_temperature) and ( $tok eq 'CAVOK' ))
		{
            push(@{$self->{sky}},$tok);
            push(@{$self->{SKY}}, "Sky Clear");
            push(@{$self->{weather}},$tok);
            push(@{$self->{WEATHER}},"No significant weather");
			$self->{visibility} = '9999';
			$parsestate = $expect_temperature;
			next;
		}

        ##
        ## is it sky conditions (clear)?
        ##

        elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_temperature) and ( $tok =~ /SKC|CLR/ ))
        {
            push(@{$self->{sky}},$tok);
            push(@{$self->{SKY}}, "Sky Clear");
            print "[$tok] is a sky condition.\n" if $self->{debug};
			$parsestate = $expect_clouds;
			next;
        }

        ##
        ## is it sky conditions (clouds)?
        ##
		## sky conditions can end with ///

        elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_temperature) and ( $tok =~ /^(FEW|SCT|BKN|OVC)(\d\d\d)?(CB|TCU)?\/*$/i))
        {
            push(@{$self->{sky}},$tok);
            my $engl = "";

            $engl = $_sky_types{$1};

            if (defined $3)
            {
                if ($3 eq "TCU")
                {
                    $engl .= " Towering Cumulus";
                }
                elsif ($3 eq "CB")
                {
                    $engl .= " Cumulonimbus";
                }
            }

            if ($2 ne "")
            {
                my $agl = int($2)*100;
                $engl .= " at $agl" . "ft";
            }

            push(@{$self->{SKY}}, $engl);
            print "[$tok] is a sky condition.\n" if $self->{debug};
			$parsestate = $expect_clouds;
			# clouds DO repeat. a lot ;)
            next;
        }

		##
		## auto detected cloud conditions
		##

        elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_temperature) and ( $tok =~ /^(NSC|NCD)$/ )){
            my $engl = "";

            $engl = $_sky_types{$tok};
            push(@{$self->{SKY}}, $engl);
			print "[$tok] is an automatic sky condition.\n" if $self->{debug};
			$parsestate = $expect_temperature;
			next;
		}

		##
		## Vertical visibility
		##

        elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_temperature) and ( $tok =~ /^VV\d+$/ )){
			print "[$tok] is vertical visibility.\n" if $self->{debug};
			$parsestate = $expect_temperature;
			next;
		}

        ##
        ## is it temperature and dew point info?
        ##

        elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_pressure) and ($tok =~ /^(M?\d\d)\/(M?\d{0,2})/i))
        {
            next if $self->{temp_dew};
            $self->{temp_dew} = $tok;

            $self->{TEMP_C} = $1;
            $self->{DEW_C} = $2;
            $self->{TEMP_C} =~ s/^M/-/;
            $self->{DEW_C} =~ s/^M/-/;

            print "[$tok] is temperature/dew point information.\n" if $self->{debug};
			$parsestate = $expect_pressure;
            next;
        }

        ##
        ## is it an altimeter setting?
        ##

        elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_remarks) and ($tok =~ /^A(\d\d)(\d\d)$/i))
        {
            $self->{alt} = $tok;
            $self->{ALT} = "$1.$2";

			# inches Hg pressure. How imperial can you get
			# conversion using 'units'

			$self->{pressure} = 33.863886 * $self->{ALT};

            print "[$tok] is an altimeter setting.\n" if $self->{debug};
			$parsestate = $expect_recentweather;
            next;
        }

		##
		## is it a pressure?
		##

		elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_remarks) and ($tok =~ /^Q(\d\d\d\d)$/i))
		{
			$self->{pressure} = $1;

			$self->{ALT} = 0.029529983*$self->{pressure};
			print "[$tok] is an air pressure.\n" if $self->{debug};
			$parsestate = $expect_recentweather;
			next;
		}

		##
		## recent weather?
		##

		elsif (($parsestate >= $expect_modifier) and ($parsestate < $expect_remarks) and ($tok =~ /^RE($_weather_types_pat)$/)){
			print "[$tok] is recent significant weather.\n" if $self->{debug};
			$parsestate = $expect_remarks;
			next;
		}

		##
		## euro type trend?
		##

		elsif (($parsestate >= $expect_modifier) and ($tok =~ /^$_trend_types_pat/)){
			print "[$tok] is a trend.\n" if $self->{debug};
			$parsestate = $expect_remarks;
			next;
		}

        ##
        ## us type remarks? .. can happen quite early in the process already
        ##

        elsif (($parsestate >= $expect_modifier) and ($tok =~ /^RMK$/i))
        {
            push(@{$self->{remarks}},$tok);
            print "[$tok] is a (US type) remark.\n" if $self->{debug};
			$parsestate  = $expect_usremarks;
            next;
        }

        ##
        ## automatic station type?
        ##

        elsif (($parsestate == $expect_usremarks) and ($tok =~ /^A(O\d)$/i))
        {
            $self->{autostationtype} = $tok;
            $self->{AUTO_STATIONTYPE} = $1;
            print "[$tok] is an automatic station type remark.\n" if $self->{debug};
            next;
        }

        ##
        ## sea level pressure
        ##

        elsif (($parsestate == $expect_usremarks) and ($tok =~ /^SLP(\d+)/i))
        {
            $self->{slp} = $tok;
            $self->{SLP} = "$1 mb";
            print "[$tok] is a sea level pressure.\n" if $self->{debug};
            next;
        }

        ##
        ## sea level pressure not available
        ##

        elsif (($parsestate == $expect_usremarks) and ($tok eq "SLPNO"))
        {
            $self->{slp} = "SLPNO";
            $self->{SLP} = "not available";
            print "[$tok] is a sea level pressure.\n" if $self->{debug};
            next;
        }

        ##
        ## hourly precipitation
        ##

        elsif (($parsestate == $expect_usremarks) and ($tok =~ /^P(\d\d\d\d)$/i))
        {
            $self->{hourlyprecip} = $tok;

            if ( $1 eq "0000" ) {
                $self->{HOURLY_PRECIP} = "Trace";
            } else {
                $self->{HOURLY_PRECIP} = $1;
            }
        }

        ##
        ## weather begin/end times
        ##

        elsif (($parsestate == $expect_usremarks) and ($tok =~ /^($_weather_types_pat)([BE\d]+)$/i))
        {
            my $engl = "";
            my $times = $2;

            $self->{weatherlog} = $tok;

            $engl = $_weather_types{$1};

            while ( $times =~ /(B|E)(\d\d)/g )
            {
                if ( $1 eq "B" ) {
                    $engl .= " began :$2";
                } else {
                    $engl .= " ended :$2";
                }
            }

            push(@{$self->{WEATHER_LOG}}, $engl);
            print "[$tok] is a weather log.\n" if $self->{debug};
            next;
        }

        ##
        ## remarks for significant cloud types
        ##

        elsif (($parsestate >= $expect_recentweather) and ($tok eq "CB" || $tok eq "TCU"))
        {
            push(@{$self->{sigclouds}}, $tok);

            if ( $tok eq "CB" ) {
                push(@{$self->{SIGCLOUDS}}, "Cumulonimbus");
            } elsif ( $tok eq "TCU" ) {
                push(@{$self->{SIGCLOUDS}}, "Towering Cumulus");
            }
			$parsestate = $expect_usremarks;
        }

        ##
        ## hourly temp/dewpoint
        ##

        elsif (($parsestate == $expect_usremarks) and ($tok =~ /^T(\d)(\d\d)(\d)(\d)(\d\d)(\d)$/i))
        {
            $self->{hourlytempdew} = $tok;
            if ( $1 == 1 ) {
                $self->{HOURLY_TEMP_C} = "-";
            }
            $self->{HOURLY_TEMP_C} .= "$2.$3";

            $self->{HOURLY_DEW_C} = "";
            if ( $4 == 1 ) {
                $self->{HOURLY_DEW_C} = "-";
            }
            $self->{HOURLY_DEW_C} .= "$5.$6";

            print "[$tok] is a hourly temp and dewpoint.\n" if $self->{debug};
            next;
        }

        ##
        ## unknown, not in remarks yet
        ##

        elsif ($parsestate < $expect_remarks)
        {
            push(@{$self->{unknown}},$tok);
            push(@{$self->{UNKNOWN}},$tok);
            print "[$tok] is unexpected at this state.\n" if $self->{debug};
            next;
        }

        ##
        ## unknown. assume remarks
        ##

        else
        {
            push(@{$self->{remarks}},$tok);
            push(@{$self->{REMARKS}},$tok);
            print "[$tok] is unknown remark.\n" if $self->{debug};
            next;
        }

    }

    ##
    ## Now that the internal stuff is set, let's do the external
    ## stuff.
    ##

    $self->{SITE} = $self->{site};
    $self->{DATE} = substr($self->{date_time},0,2);
    $self->{TIME} = substr($self->{date_time},2,4) . " UTC";
    $self->{TIME} =~ s/(\d\d)(\d\d)/$1:$2/o;
    $self->{MOD}  = $self->{modifier};

    ##
    ## Okay, wind finally gets interesting.
    ##

    if ( defined $self->{wind} )
	{
        my $wind = $self->{wind};
        my $dir_deg  = substr($wind,0,3);
        my $dir_eng = "";
		my $dir_abb = "";

        # Check for wind direction
        if ($dir_deg =~ /VRB/i) {
            $dir_deg = "Variable";
        } else {
            if      ($dir_deg < 15) {
                $dir_eng = "North";
				$dir_abb = "N";
            } elsif ($dir_deg < 30) {
                $dir_eng = "North/Northeast";
				$dir_abb = "NNE";
            } elsif ($dir_deg < 60) {
                $dir_eng = "Northeast";
				$dir_abb = "NE";
            } elsif ($dir_deg < 75) {
                $dir_eng = "East/Northeast";
				$dir_abb = "ENE";
            } elsif ($dir_deg < 105) {
                $dir_eng = "East";
				$dir_abb = "E";
            } elsif ($dir_deg < 120) {
                $dir_eng = "East/Southeast";
				$dir_abb = "ESE";
            } elsif ($dir_deg < 150) {
                $dir_eng = "Southeast";
				$dir_abb = "SE";
            } elsif ($dir_deg < 165) {
                $dir_eng = "South/Southeast";
				$dir_abb = "SSE";
            } elsif ($dir_deg < 195) {
                $dir_eng = "South";
				$dir_abb = "S";
            } elsif ($dir_deg < 210) {
                $dir_eng = "South/Southwest";
				$dir_abb = "SSW";
            } elsif ($dir_deg < 240) {
                $dir_eng = "Southwest";
				$dir_abb = "SW";
            } elsif ($dir_deg < 265) {
                $dir_eng = "West/Southwest";
				$dir_abb = "WSW";
            } elsif ($dir_deg < 285) {
                $dir_eng = "West";
				$dir_abb = "W";
            } elsif ($dir_deg < 300) {
                $dir_eng = "West/Northwest";
				$dir_abb = "WNW";
            } elsif ($dir_deg < 330) {
                $dir_eng = "Northwest";
				$dir_abb = "NW";
            } elsif ($dir_deg < 345) {
                $dir_eng = "North/Northwest";
				$dir_abb = "NNW";
            } else {
                $dir_eng = "North";
				$dir_abb = "N";
            }
        }

		my $kts_speed = undef;
		my $mph_speed = undef;

		my $kts_gust = "";
		my $mph_gust = "";

		# parse knots

		if ($self->{windtype} == $wt_knots){
			$wind =~ /...(\d\d\d?)/o;
			$kts_speed = $1;
			$mph_speed = $kts_speed * 1.1508;


			if ($wind =~ /.{5,6}G(\d\d\d?)/o) {
				$kts_gust = $1;
				$mph_gust = $kts_gust * 1.1508;
			}
		# else: parse meters/second
		} elsif ($self->{windtype} == $wt_mps){
			$wind=~ /...(\d\d\d?)/o;
			my $mps_speed = $1;
			$kts_speed = $mps_speed * 1.9438445; # units
			$mph_speed = $mps_speed * 2.2369363;
			if ($wind =~ /\d{5,6}G(\d\d\d?)/o) {
				my $mps_gust = $1;
				$kts_gust = $mps_gust * 1.9438445;
				$mph_gust = $mps_gust * 2.2369363;
			}
		} else {
			warn "Geo::METAR Parser error: unknown windtype\n";
		}

        $self->{WIND_KTS} = $kts_speed;
        $self->{WIND_MPH} = $mph_speed;

        $self->{WIND_GUST_KTS} = $kts_gust;
        $self->{WIND_GUST_MPH} = $mph_gust;

        $self->{WIND_DIR_DEG} = $dir_deg;
        $self->{WIND_DIR_ENG} = $dir_eng;
        $self->{WIND_DIR_ABB} = $dir_abb;

    }

	##
	## wind variation
	##

	if (defined $self->{windvar})
	{
		if ($self->{windvar} =~ /^(\d\d\d)V(\d\d\d)$/){
			$self->{WIND_VAR} = "Varying between $1 and $2";
			$self->{WIND_VAR_1} = $1;
			$self->{WIND_VAR_2} = $2;
		}
	}

    ##
    ## Visibility.
    ##

    {
        my $vis = $self->{visibility};
		# test for statute miles
		if ($vis =~ /SM$/){
			$vis =~ s/SM$//oi;                              # nuke the "SM"
			if ($vis =~ /M(\d\/\d)/o) {
				$self->{VISIBILITY} = "Less than $1 statute miles";
			} else {
				$self->{VISIBILITY} = $vis . " Statute Miles";
			} # end if
		# auto metars can have non-directional visibility reports
		} elsif (($self->{MOD} eq 'AUTO') and ($vis =~ /(\d+)NDV$/)){
			$self->{VISIBILITY} = "$1 meters non-directional visibility";
		} else {
			$self->{VISIBILITY} = $vis . " meters";
		}
    }

    ##
    ## Calculate F temps for all C temps
    ##

    foreach my $key ( keys(%$self) )
    {
        if ( uc($key) eq $key && $key =~ /^(.*)_C$/ )
        {
            my $fkey = $1 . "_F";

            next unless defined $self->{$key} && $self->{$key};

            $self->{$fkey} = sprintf("%.1f", (($self->{$key} * (9/5)) + 32));
        }
    }

	# join the runway group
	
	$self->{runway} = join(', ' , @{$self->{RUNWAY}});
	
}

##
## Print the tokens--usually when debugging.
##

sub print_tokens
{
    my $self = shift;
    my $tok;
    foreach $tok (@{$self->{tokens}}) {
        print "> $tok\n";
    }
}

##
## Turn debugging on/off.
##

sub debug
{
    my $self = shift;
    my $flag = shift;
    return $self->{debug} unless defined $flag;

    if (($flag eq "Y") or ($flag eq "y") or ($flag == 1)) {
        $self->{debug} = 1;
    } elsif (($flag eq "N") or ($flag eq "n") or ($flag == 0)) {
        $self->{debug} = 0;
    }

    return $self->{debug};
}

##
## Dump internal data structure. Useful for debugging and such.
##

sub dump
{
    my $self = shift;

    print "Modified METAR dump follows.\n\n";

    print "type: $self->{type}\n";
    print "site: $self->{site}\n";
    print "date_time: $self->{date_time}\n";
    print "modifier: $self->{modifier}\n";
    print "wind: $self->{wind}\n";
    print "visibility: $self->{visibility}\n";
    print "runway: $self->{runway}\n";
    print "weather: " . join(', ', @{$self->{weather}}) . "\n";
    print "sky: " . join(', ', @{$self->{sky}}) . "\n";
    print "temp_dew: $self->{temp_dew}\n";
    print "alt: $self->{ALT}\n";
    print "slp: $self->{slp}\n";
    print "remarks: " . join (', ', @{$self->{remarks}}) . "\n";
    print "\n";

    foreach my $var ( sort(keys(%$self)) )
    {
        next if ( uc($var) ne $var );

        if ( ref($self->{$var}) eq "ARRAY" )
        {
            print "$var: ", join(", ", @{$self->{$var}}), "\n";
        }
        else
        {
            print "$var: ", $self->{$var}, "\n";
        }
    }
}

1;

__END__

=head1 NAME

Geo::METAR - Process aviation weather reports in the METAR format.

=head1 SYNOPSIS

  use Geo::METAR;
  use strict;

  my $m = new Geo::METAR;
  $m->metar("KFDY 251450Z 21012G21KT 8SM OVC065 04/M01 A3010 RMK 57014");
  print $m->dump;

  exit;

=head1 DESCRIPTION

METAR reports are available on-line, thanks to the National Weather Service.
Since reading the METAR format isn't easy for non-pilots, these reports are
relatively useles to the common man who just wants a quick glace at the
weather. This module tries to parse the METAR reports so the data can be
used to create readable weather reports and/or process the data in
applications.

=head1 USAGE

=head2 How you might use this

Here is how you I<might> use the Geo::METAR module.

One use that I have had for this module is to query the NWS METAR page
(using the LWP modules) at
http://weather.noaa.gov/cgi-bin/mgetmetar.pl?cccc=EHSB to get an
up-to-date METAR. Then, I scan thru the output, looking for what looks
like a METAR string (that's not hard in Perl). Oh, EHSB can be any site
location code where there is a reporting station.

I then pass the METAR into this module and get the info I want. I can
then update my webcam page with the current temperature, sky conditions, or
whatnot. See for yourself at http://webcam.idefix.net/

See the BUGS section for a remark about multiple passes with the same
Geo::METAR object.

=head2 Functions

The following functions are defined in the METAR module. Most of
them are I<public>, meaning that you're supposed to use
them. Some are I<private>, meaning that you're not supposed to use
them -- but I won't stop you. Assume that functions are I<public>
unless otherwise documented.

=over

=item metar()

metar() is the function to whwich you should pass a METAR string.  It
will take care of decomposing it into its component parts converting
the units and so on.

Example: C<$m-E<gt>metar("KFDY 251450Z 21012G21KT 8SM OVC065 04/M01 A3010 RMK 57014");>

=item debug()

debug() toggles debugging messages. By default, debugging is turned
B<off>. Turn it on if you are developing METAR or having trouble with
it.

debug() understands all of the folloing:

        Enable       Disable
        ------       -------
          1             0
        'yes'         'no'
        'on'          'off'

If you contact me for help, I'll likely ask you for some debugging
output.

Example: C<$m-E<gt>debug(1);>

=item dump()

dump() will dump the internal data structure for the METAR in a
semi-human readable format.

Example: C<$m-E<gt>dump;>

=item version()

version() will print out the current version.

Example: C<print $m-E<gt>version;>

=item _tokenize()

B<PRIVATE>

Called internally to break the METAR into its component tokens.

=item _process()

B<PRIVATE>

Used to make sense of the tokens found in B<_tokenize()>.

=back

=head2 Variables

After you've called B<metar()>, you'd probably like to get at
the individual values for things like temperature, dew point,
and so on. You do that by accessing individual variables via
the METAR object.

This section lists those variables and what they represent.

If you call B<dump()>, you'll find that it spits all of these
out.

=over

=item VERSION

The version of METAR.pm that you're using.

=item METAR

The actual, raw METAR.

=item TYPE

Report type in English ("Routine Weather Report" or "Special Weather Report")

=item SITE

4-letter site code.

=item DATE

The date (just the day of the month) on which the report was issued.

=item TIME

The time at which the report was issued.

=item MOD

Modifier (AUTO/COR) if any.

=item WIND_DIR_ENG

The current wind direction in english (Southwest, East, North, etc.)

=item WIND_DIR_ABB

The current wind direction in abbreviated english (S, E, N, etc.)

=item WIND_DIR_DEG

The current wind direction in degrees.

=item WIND_KTS

The current wind speed in Knots.

=item WIND_MPH

The current wind speed in Miles Per Hour.

=item WIND_GUST_KTS

The current wind gusting speed in Knots.

=item WIND_GUST_MPH

The current wind gusting speed in Miles Per Hour.

=item WIND_VAR

The wind variation in English

=item WIND_VAR_1

The first wind variation direction

=item WIND_VAR_2

The second wind variation direction

=item VISIBILITY

Visibility information.

=item WIND

Wind information.

=item RUNWAY

Runway information.

=item WEATHER

Current weather (array)

=item WEATHER_LOG

Current weather log (array)

=item SKY

Current cloud cover (array)

=item TEMP_C

Temperature in Celsius.

=item TEMP_F

Temperature in Fahrenheit.

=item DEW_C

Dew point in Celsius.

=item DEW_F

Dew point in Fahrenheit.

=item HOURLY_TEMP_F

Hourly current temperature, fahrenheit

=item HOURLY_TEMP_C

Hourly current temperature, celcius

=item HOURLY_DEW_F

Hourly dewpoint, fahrenheit

=item HOURLY_DEW_C

Hourly dewpoint, celcius

=item ALT

Altimeter setting (barometric pressure).

=item REMARKS

Any remarks in the report.

=back

=head1 NOTES

Test suite is small and incomplete. Needs work yet.

Older versions of this module were installed as "METAR" instaed of
"Geo::METAR"

=head1 BUGS

The Geo::METAR is only initialized once, which means you'll get left-over
crud in variables when you call the metar() function twice.

What is an invalid METAR in one country is a standard one in the next.
The standard is interpreted and used by meteorologists all over the world,
with local variations. This means there will always be METARs that will
trip the parser.

=head1 TODO

There is a TODO file included in the Geo::METAR distribution listing
the outstanding tasks that I or others have devised. Please check that
list before you submit a bug report or request a new feture. It might
already be on the TODO list.

=head1 AUTHORS AND COPYRIGHT

Copyright 1997-2000, Jeremy D. Zawodny <Jeremy [at] Zawodny.com>

Copyright 2007, Koos van den Hout <koos@kzdoos.xs4all.nl>

Geo::METAR is covered under the GNU Public License (GPL) version 2 or
later.

The Geo::METAR Web site is located at:

  http://idefix.net/~koos/perl/Geo-METAR/

=head1 CREDITS

In addition to our work on Geo::METAR, We've received ideas, help, and
patches from the following folks:

  * Ethan Dicks <ethan.dicks [at] gmail.com>

    Testing of Geo::METAR at the South Pole. Corrections and pointers
	to interesting cases to test.

  * Otterboy <jong [at] watchguard.com>

    Random script fixes and initial debugging help

  * Remi Lefebvre <remi [at] solaria.dhis.org>

    Debian packaging as libgeo-metar-perl.deb.

  * Mike Engelhart <mengelhart [at] earthtrip.com>

    Wind direction naming corrections.

  * Michael Starling <mstarling [at] logic.bm>

    Wind direction naming corrections.

  * Hans Einar Nielssen <hans.einar [at] nielssen.com>

    Wind direction naming corrections.

  * Nathan Neulinger <nneul [at] umr.edu>

    Lots of enhancements and corrections. Too many to list here.

=head1 RELATED PROJECTS

B<lcdproc> at http://www.lcdproc.org/ uses Geo::METAR in lcdmetar.pl to
display weather data on an lcd.

=cut


# vim:expandtab:sw=4 ts=4
