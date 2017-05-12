# Copyrights 2009 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.06.
use warnings;
use strict;

package Geo::Format::Landsat::MTL;
use vars '$VERSION';
$VERSION = '0.03';

use base 'Exporter';

our @EXPORT = qw/
  landsat_mtl_from_file
  landsat_meta_from_filename
  /;

use constant METADATA_RECORD => 65536;
use constant METERS2FEET     => 3.2808399;

use Geo::Point     ();
use File::Basename qw/basename/;

use POSIX          qw/mktime strftime tzset/;
$ENV{TZ} = 'UTC'; tzset;

sub _process_group($);

sub _cleanup_mtl($);
sub _cleanup_product_parameters($);
sub _cleanup_product_metadata($$);
sub _cleanup_metadata_file_info($);
sub _cleanup_min_max_radiance($);
sub _cleanup_min_max_pixel_value($);
sub _cleanup_projection_parameters($);
sub _cleanup_corrections_applied($);
sub _get_map_proj($);


sub landsat_meta_from_filename($)
{   my $filename = basename shift;
    $filename =~ m/^L([57])(\d\d\d)(\d\d\d)_(\d\d\d)(\d\d\d\d)(\d\d)(\d\d)/
       or return;

   +{ SPACECRAFT_ID    => "Landsat$1"
    , WRS_PATH         => $2
    , STARTING_ROW     => $3
    , ENDING_ROW       => 4
    , ACQUISITION_DATE => "$5-$6-$7"
    };
}


sub landsat_mtl_from_file($)
{   my $f = shift;

    my $text;
    if(UNIVERSAL::isa($f, 'GLOB') || UNIVERSAL::isa($f, 'IO::Handle'))
    {   sysread $f, $text, METADATA_RECORD;
    }
    else
    {   open F, '<', $f
            or die "ERROR: cannot read from $f: $!\n";
        sysread F, $text, METADATA_RECORD;
        close F;
    }

    $text =~ s/\0+\z//;   # record padded with \0 bytes

    $text =~ s/^\s*END\s*\z//m
        or die "ERROR: did not get 'END' tag\n";

    my $wrapper = _process_group $text;
    my ($type, $data) = %$wrapper;   # only one key

    ($type, _cleanup_mtl $data);
}

sub _process_group($)
{   my $text = shift;
    my $data;

    while($text =~ s/\A\s*GROUP\s*\=\s*(\w+)\s*
                     (.*?)
                     \s*END_GROUP\s*\=\s*\1\s*//xsm)
    {   my $name = $1;
        $data->{$name} = _process_group($2);
    }

    foreach my $line (split /\n/, $text)
    {   if($line =~ m/^\s*(\w+)\s*\=\s+\"(.*?)\"\s*$/ )
        {   $data->{$1} = $2;
        }
        elsif($line =~ m/^\s*(\w+)\s*\=\s+(.*?)\s*$/ )
        {   $data->{$1} = $2;
        }
        else
        {   warn "Do not understand line:\n  $line\n";
        }
    }

    $data;
}

sub _cleanup_mtl($)
{   my $data = shift;

    _cleanup_metadata_file_info    $data->{METADATA_FILE_INFO};
    _cleanup_min_max_radiance      $data->{MIN_MAX_RADIANCE};
    _cleanup_min_max_pixel_value   $data->{MIN_MAX_PIXEL_VALUE};
    _cleanup_product_parameters    $data->{PRODUCT_PARAMETERS};
    _cleanup_corrections_applied   $data->{CORRECTIONS_APPLIED};
    _cleanup_projection_parameters $data->{PROJECTION_PARAMETERS};

    my $mapproj = $data->{map_projection} = _get_map_proj $data;

    _cleanup_product_metadata      $data->{PRODUCT_METADATA}, $mapproj;
    $data;
}

sub _cleanup_metadata_file_info($)
{   my $d = shift or return;

    if($d->{REQUEST_ID} =~ m/(...)(\d\d)(\d\d)(\d\d)(\d{4})_(\d{5})/)
    {   my $date = sprintf "%04d-%02d-%02dZ"
            , ($2 < 70 ? 2000+$2 : 1900+$2), $3, $4;
        $d->{request_id} = { node => $1+0, date_iso => $date, seqnr => $5+0
            , dorran_unit => $6+0 };
    }

    # 0 = unknown, becomes undef.
    $d->{landsat_xband} = $d->{LANDSAT5_XBAND} || $d->{LANDSAT7_XBAND} || undef;

    # no simple way to translate DOY -> month/day
    if($d->{DATEHOUR_CONTACT_PERIOD} =~ m/^(\d\d)(\d\d\d)(\d\d)$/ )
    {   my ($year, $yday, $hour) = ($1, $2, $3);
        $year += $year < 70 ? 2000 : 1900;
        my @monthdays = (undef, 31,28,31,30,31,30,31,31,30,31,30,31);
        $monthdays[2] = 29 if $year%400==0 || ($year%4==0 && $year%100!=0);
        my ($month, $day) = (1, $yday);
        while($day > $monthdays[$month])
        {   $day -= $monthdays[$month];
            $month++;
        }
        $d->{received} = sprintf "%04d-%02d-%02dT%02d:00:00Z"
          , $year, $month, $day, $hour;
    }
}

sub _cleanup_product_metadata($$)
{   my ($d, $proj) = @_;
    $d or return;
    my $mapproj = $proj->nick;

    if($d->{PROCESSING_SOFTWARE} =~ m/([A-Z]+)_(.*)/)
    {   $d->{software_system}  = $1;
        $d->{software_version} = $2;
    }
    $d->{EPHEMERIS_TYPE} ||= 'PREDICTIVE';

    foreach my $band ( '', '_PAN', '_THM')
    {   $d->{"PRODUCT_UL_CORNER_LAT$band"} or next;
        my (@bbox, @bbox_map);
        foreach my $c (qw/UL UR LR LL/)
        {   my $lat = $d->{"PRODUCT_${c}_CORNER_LAT${band}"};
            my $lon = $d->{"PRODUCT_${c}_CORNER_LON${band}"};
            my $corner = Geo::Point->latlong($lat, $lon, 'wgs84');
            $d->{"product_".(lc $c)."_wgs84".lc $band} = $corner;
            push @bbox, $corner;

            my $x   = $d->{"PRODUCT_${c}_CORNER_MAPX${band}"};
            my $y   = $d->{"PRODUCT_${c}_CORNER_MAPY${band}"};
            my $map = Geo::Point->xy($x, $y, $mapproj);
            $d->{"product_".(lc $c)."_map".lc $band} = $map;
            push @bbox_map, $map;
        }
        my $bbox = Geo::Line->filled(points => \@bbox, clockwise => 1);
        $d->{"footprint".lc $band} = Geo::Surface->new($bbox);

        my $bbox_map = Geo::Line->filled(points => \@bbox_map, clockwise => 1);
        $d->{"footprint_map".lc $band} = Geo::Surface->new($bbox_map);
    }
}

sub _cleanup_min_max_radiance($)
{   my $d = shift or return;
    # strings can be used as numbers... nothing to do
}

sub _cleanup_min_max_pixel_value($)
{   my $d = shift or return;
    # strings can be used as numbers... nothing to do
}

sub _cleanup_product_parameters($)
{   my $d = shift or return;
    # too specific
}

sub _cleanup_corrections_applied($)
{   my $d = shift or return;

    foreach my $key (qw/BANDING COHERENT_NOICE MEMORY_EFFECT
       SCAN_CORRELATED_SHIFT INOPERABLE_DETECTORS DROPPED_LINES/)
    {   defined $d->{$key} or next;
        $d->{lc $key} = $d->{$key} eq 'Y' ? 1 : 0;
    }
}

sub _cleanup_projection_parameters($)
{   my $d = shift or return;

       $d->{REFERENCE_DATUM} eq 'WGS84'     # hard-coded in spec
    && $d->{REFERENCE_ELLIPSOID} eq 'WGS84'
        or die "ERROR: WGS84 expected\n";

    if(my $o = $d->{ORIENTATION})
    {   $d->{orientation}
          = $o eq 'NOM' ? 'Nominal Path'
          : $o eq 'NUP' ? 'North Up'
          : $o eq 'TN'  ? 'True North'
          : $o eq 'USR' ? 'User'
          :               'UNKNOWN';
    }

    if(my $r = $d->{RESAMPLING_OPTION})
    {   $d->{resampling_option}
          = $r eq 'NN'  ? 'Nearest Neighbor'
          : $r eq 'CC'  ? 'Cubic Convolution'
          : $r eq 'MTF' ? 'Modulation Transfer Function'
          : $r eq 'BI'  ? 'Bilinear'
          : $r eq 'KD'  ? 'Kaiser Damped'
          : $r eq '16'  ? '16 Point Sinc'
          : $r eq '8'   ? '8 Point Sinc'
          : $r eq 'DW'  ? 'Damped Window'
          :               'UNKNOWN';
    }
}


# See http://www.remotesensing.org/geotiff/proj_list
sub _get_map_proj($)
{   my $data    = shift;
    my $code    = $data->{PROJECTION_PARAMETERS}{MAP_PROJECTION};
    my $details = $data->{"${code}_PARAMETERS"};
    
    my $nick    = lc $code;
    my ($proj, $name, @params);

    my $units   = $details->{FALSE_EASTING_NORTHING_UNITS};
    push @params, '-M'
        if defined $units && $units eq 'meters';

    my @common = qw/
    FALSE_EASTING                        x_0
    FALSE_NORTHING                       y_0
    LATITUDE_OF_PROJECTION_ORIGIN        lat_0
    LATITUDE_OF_CENTER                   lat_0
    LONGITUDE_OF_CENTRAL_MERIDIAN        lon_0
    LONGITUDE_OF_CENTER                  lon_0
    VERTICAL_LONGITUDE_FROM_POLE         lon_0
    LATITUDE_OF_FIRST_STANDARD_PARALLEL  lat_1
    LATITUDE_FIRST_POINT_GEODETIC        lat_1
    LONGITUDE_OF_FIRST_STANDARD_PARALLEL lon_1
    LONGITUDE_FIRST_POINT_GEODETIC       lon_1
    LATITUDE_OF_SECOND_STANDARD_PARALLEL lat_2
    LATITUDE_SECOND_POINT_GEODETIC       lat_2
    LONGITUDE_SECOND_POINT_GEODETIC      lon_2
    LATITUDE_OF_TRUE_SCALE               lat_ts
    ANGLE_OF_AZIMUTH                     alpha
    LONGITUDE_ALONG_PROJECTION           lonc
    SCALE_FACTOR_AT_CENTRAL_MERIDIAN     k
    /;

    while(@common)
    {   my ($key, $label) = (shift @common, shift @common);
        push @params, $label => $details->{$key}
            if $details->{$key};
    }

    my $h = $details->{HEIGHT};  # always in meters, according to doc
    if(defined $h)
    {   push @params, h => ($units eq 'meters' ? $h : $h * METERS2FEET);
    }

    # convert to NLAPS type
    $code .= $details->{EQC_TYPE} if $code eq 'EQC';
    $code .= $details->{OM_TYPE}  if $code eq 'OM';
    $code .= $details->{SOM_TYPE} if $code eq 'SOM';

    if($code eq 'AKC')
    {   $name    = 'Alaska Conformal';
        $proj    = 'UNKNOWN'; #???
    }
    elsif($code eq 'AEA')     # epsg:9822
    {   $name    = 'Albers Equal-Area Conic';
        $proj    = 'eae';
    }
    elsif($code eq 'AZIM')
    {   $name    = 'Azimuthal Equidistant';
        $proj    = 'aeqd';
    }
    elsif($code =~ m/^EQC([AB])$/)
    {   $name    = "Equidistant Conic type $1";
        $proj    = 'eqdc';
    }
    elsif($code eq 'EQUI')    # epsg:9823 (spherical), 9842 (elliptical)
    {   $name    = 'Equirectangular';
        $proj    = 'UNKNOWN'; #???
    }
    elsif($code eq 'GNOM')
    {   $name    = 'Gnomonic';
        $proj    = 'gnom';
    }
    elsif($code eq 'GVNP')
    {   $name    = 'General Vertical Near Side Perspective';
        $proj    = 'nsper';
    }
    elsif($code eq 'HAMM')
    {   $name    = 'Hammer';
        $proj    = 'hammer';
    }
    elsif($code eq 'LAEA')    # epsg:9820
    {   $name    = 'Lambert Azimuthal Equal Area';
        $proj    = 'laea';
    }
    elsif($code eq 'LCC')     # epsg:9802 (?)
    {   $name    = 'Lambert Conformal Conic (2SP)';
        $proj    = 'lcc';
    }
    elsif($code eq 'MERC')
    {   $name    = 'Mercator (2SP)';
        $proj    = 'merc';
    }
    elsif($code eq 'MCYL')
    {   $name    = 'Miller Cylindrical';
        $proj    = 'mill';
    }
    elsif($code eq 'MOLL')
    {   $name    = 'Mollweide';
        $proj    = 'moll';
    }
    elsif($code eq 'OEA')
    {   $name    = 'Oblated Equal Area';
        $proj    = 'oea';
        push @params, theta => $details->{ANGLE};
    }
    elsif($code =~ m/^OM([AB])$/)   # epsg:9815
    {   $name    = "Oblique Mercator type $1";
        $proj    = 'omerc';
        #??? SCALE_FACTOR_AT_CENTER_OF_PROJECTION 
    }
    elsif($code eq 'ORTH')
    {   $name    = 'Orthographic';
        $proj    = 'ortho';
    }
    elsif($code eq 'PC')
    {   $name    = 'Polyconic';    # (American?)
        $proj    = 'poly';    # ???
    }
    elsif($code eq 'PS')      # epsg:9810
    {   $name    = 'Polar Stereographic';
        $proj    = 'stere';
        push @params, lat_0 => '90';  #???
    }
    elsif($code eq 'ROBN')
    {   $name    = 'Robinson';
        $proj    = 'robin';
    }
    elsif($code eq 'SINU')
    {   $name    = 'Sinusoidal (Sanson-Flamsteed)';
        $proj    = 'sinu';
    }
    elsif($code eq 'SOMA')
    {   $name    = 'Space Oblique Mercator type A';
        $proj    = "UNKNOWN"; # too complex
    }
    elsif($code eq 'SOMB')
    {   $name    = 'Space Oblique for Landsat';
        $proj    = 'lsat';
        push @params, lsat => $details->{LANDSAT_NUMBER}
                    , path => $details->{PATH};
    }
    elsif($code eq 'STRG')
    {   $name    = 'Stereographic';
        $proj    = 'stere';
    }
    elsif($code eq 'TM')
    {   $name    = 'Traverse Mercator (Gauss-Krueger)';
        $proj    = 'tmerc';
    }
    elsif($code eq 'UTM')
    {   $name    = 'Universal Transverse Mercator';
        my $zone = $details->{ZONE_NUMBER};
        $nick    = "utm$zone-wgs84";
        $proj    = 'utm';
        push @params, datum => 'WGS84', zone => $zone;
    }
    elsif($code eq 'VDGR')
    {   $name    = 'van der Grinten';
        $proj    = 'vandg';
    }
    elsif($code eq 'WIV')
    {   $name    = 'Wagner IV';
        $proj    = 'wag4';
    }
    elsif($code eq 'WVII')
    {   $name    = 'Wagner VII';
        $proj    = 'wag7';
    }
    else
    {   die "ERROR: unknown projection code $code\n";
    }

    unshift @params, proj => $proj;

    Geo::Proj->new
      ( nick  => $nick
      , name  => $name
      , proj4 => \@params
      );
}

1;
