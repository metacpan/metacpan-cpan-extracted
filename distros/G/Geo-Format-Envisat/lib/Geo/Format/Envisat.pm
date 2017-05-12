# Copyrights 2008-2011 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.
use warnings;
use strict;

package Geo::Format::Envisat;
use vars '$VERSION';
$VERSION = '0.03';

use base 'Exporter';

our @EXPORT = qw/envisat_mph_from_name envisat_meta_from_file/;

use File::Basename qw/basename/;
use POSIX          qw/tzset mktime strftime/;
use IO::Uncompress::AnyUncompress qw/$AnyUncompressError/;
use Geo::Point     ();

my @month = qw/XXX JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC/;
my %month;
$month{$_} = keys %month for @month;
delete $month{XXX};

$ENV{TZ}   = 'UTC';
tzset;              # needed for mktime()

use constant MPH_LENGTH => 1247;

sub _decode_name($);
sub _cleanup_mph($);
sub _cleanup_sph($);
sub _cleanup_dsd($);
sub _read_block($$);
sub _decompose($);
sub _timestamp_to_time($);
sub _timestamp_iso($);
sub _add_missing_stripped($);
sub _strip_unit($);


sub envisat_mph_from_name($)
{   my $filename = shift;
    my $mph      = _decode_name $filename;

    if(my $size = -s $filename)
    {   $mph->{TOT_SIZE} = "$size<bytes>";
    }

    my ($year, $month, $day) = $mph->{start_day} =~ m/(\d{4})(\d\d)(\d\d)/;
    my ($hour, $min, $sec ) = $mph->{start_time} =~ m/(\d\d)(\d\d)(\d\d)/;
    $mph->{SENSING_START} = sprintf "%02d-%s-%04d %02d:%02d:%02d.%06d"
       , $day, $month[$month], $year, $hour, $min, $sec, 0;

    _cleanup_mph($mph);
    $mph;
}


sub envisat_meta_from_file($@)
{   my ($fn, %args) = @_;
    my $mph_from_filename = _decode_name $fn;

    my $meta;
    my $file = IO::Uncompress::AnyUncompress->new($fn)
        or die "ERROR: cannot read from $fn: $AnyUncompressError\n";

    my $mph  = _decompose(_read_block $file, MPH_LENGTH);

    foreach my $k (keys %$mph_from_filename)
    {   if(! exists $mph->{$k} )
        {   $mph->{$k} = $mph_from_filename->{$k};
        }
        elsif($mph->{$k} ne $mph_from_filename->{$k})
        {   warn "field $k differs: \n  in file    : `$mph->{$k}'\n"
               , "  in filename: `$mph_from_filename->{$k}'\n";
        }
    }

    _cleanup_mph $mph;

    my ($sph, %dsd);
    if(my $sphsize = $mph->{sph_size})
    {   my $dsd_size   = $mph->{dsd_size};
        my $dsd_num    = $mph->{num_dsd};
        my $sph_length = $sphsize - $dsd_size * $dsd_num;
        $sph = _decompose(_read_block $file, $sph_length);
        _cleanup_sph $sph;

        for(1..$dsd_num)
        {   my $dsd = _decompose(_read_block $file, $dsd_size);
            _cleanup_dsd $dsd;
            $dsd->{num_dsr} > 0
                or next;
            (my $name = $dsd->{ds_name}) =~ s/\s+/_/g;
            $dsd{$name} = $dsd;
        }

        # only forward seeks permitted.
        my $take = exists $args{take_dsd_content} ? $args{take_dsd_content} : 0;
        if($take)
        {   my @sorted = sort {$a->{ds_offset} <=> $b->{ds_offset}} values %dsd;
            foreach my $dsd (@sorted)
            {   next if $dsd->{DS_TYPE} eq 'M';
                $file->seek($dsd->{ds_offset}, 0);
                $dsd->{content} = _read_block $file, $dsd->{ds_size};
            }
        }
    }

    $file->close;

    +{ mph => $mph, sph => $sph, dsd => \%dsd };
}

##### some helpers

sub _decode_name($)
{   my $name     = uc basename shift;
    $name =~
      m/^ (\w{10})    # product ID
          (\w)        # processing stage flag
          (\w{3})     # originator ID
          (\d{8}) _   # start_day
          (\d{6}) _   # start_time
          (\d{8})     # duration
          (\w)        # phase id
          (\d{3}) _   # cycle number within phase
          (\d{5}) _   # relative orbit number within cycle
          (\d{5}) _   # absolute orbit number
          (\d{4})     # product file counter
          \. (\w\w)   # satellite ID
       /x
       or return ();

    { PRODUCT_ID => $1
    , PROC_STAGE => $2
    , originator_id => $3   # proc center abbreviated into 3 chars
    , start_day  => $4
    , start_time => $5
    , duration   => $6+0
    , PHASE      => $7
    , CYCLE      => "+$8"
    , REL_ORBIT  => "+$9"
    , ABS_ORBIT  => "+$10"
    , product_file_counter => $11
    , satellite_id => $12
    };
}

sub _cleanup_mph($)
{   my $mph = shift;

    if(my $s = $mph->{PROC_STAGE})
    {   $mph->{proc_stage}
          = $s eq 'N' ? 'Near Real Time'
          : $s eq 'T' ? 'test product'
          : $s eq 'V' ? 'fully validated'
          : $s eq 'S' ? 'special product'
          : $s eq 'X' ? 'not used'
          : $s gt 'N' && $s lt 'V' ? "consolidation level $s"
          :             'ERROR';
    }

    if(my $s = $mph->{satellite_id})
    {   $mph->{satellite}
          = $s eq 'N1' ? 'Envisat'
          : $s eq 'E1' ? 'ERS1'
          : $s eq 'E2' ? 'ERS2'
          :              'ERROR';
    }

    if(my $s = $mph->{VECTOR_SOURCE})
    {   $mph->{vector_source}
          = $s eq 'FP' ? 'FOS predicted orbit state vectors'
          : $s eq 'DN' ? 'DORIS Level 0 navigator product acquired at PDHS'
          : $s eq 'FR' ? 'FOS restituted orbit state vectors'
          : $s eq 'DI' ? 'DORIS initial (prelimary) orbit'
          : $s eq 'DP' ? 'DORIS precise orbit'
          : $s eq ''   ? 'not used'
          :              'ERROR';
    }

    # add lower-cased field versions without unit specification
    foreach my $field (qw/TOT_SIZE SPH_SIZE DSD_SIZE DELTA_UT1 CLOCK_STEP
      X_POSITION Y_POSITION Z_POSITION X_VELOCITY Y_VELOCITY Z_VELOCITY/)
    {   $mph->{lc $field} = _strip_unit $mph->{$field}
            if $mph->{$field};
    }

    # make numeric
    foreach my $field (qw/CYCLE REL_ORBIT ABS_ORBIT LEAP_SIGN
       NUM_DATA_SETS NUM_DSD SAT_BINARY_TIME PRODUCT_ERR/)
    {   defined $mph->{$field} or next;
        $mph->{lc $field} = $mph->{$field} + 0;
    }

    # convert to OS time
    foreach my $field (qw/SENSING_START SENSING_STOP PROC_TIME
       STATE_VECTOR_TIME UTC_SBT_TIME LEAP_UTC/)
    {   defined $mph->{$field} or next;
        $mph->{lc $field} = _timestamp_to_time $mph->{$field};
        $mph->{lc($field).'_iso'} = _timestamp_iso $mph->{lc $field};
    }

    if(my $station = $mph->{ACQUISITION_STATION})
    {   $station =~ s/\s//g;
        $mph->{acquisition_station} = [ split /\,/, $station ];
    }

    _add_missing_stripped $mph;
}

sub _cleanup_sph($)
{   my $sph = shift;
    
    # add field versions without unit specification
    $sph->{lc $_} = _strip_unit $sph->{$_}
       for qw/AZIMUTH_SPACING LINE_LENGTH LINE_TIME_INTERVAL RANGE_SPACING/;

    # convert to OS time
    foreach my $field (qw/FIRST_LINE_TIME LAST_LINE_TIME/)
    {   $sph->{lc $field} = _timestamp_to_time $sph->{$field};
        $sph->{lc($field).'_iso'} = _timestamp_iso $sph->{lc $field};
    }

    # make numeric
    foreach my $field (qw/AZIMUTH_LOOKS NUM_SLICES RANGE_LOOKS
        SLICE_POSITION STRIPLINE_CONTINUITY_INDICATOR/)
    {   $sph->{lc $field} = $sph->{$field} + 0;
    }

    if(my $t = $sph->{DATA_TYPE})
    {   $sph->{pixel_octets}
          = $t eq 'UWORD' ? 2     # unsigned
          : $t eq 'SWORD' ? 2     # signed
          : $t eq 'UBYTE' ? 1     # unsigned
          :                 'ERROR';
    }

    # Simplify coordinates
    my %bounds;
    foreach my $azimuth ('FIRST', 'LAST')
    {   foreach my $range ('NEAR', 'MID', 'FAR')
        {   (my $lat = $sph->{"${azimuth}_${range}_LAT"}) =~ s/\<.*//;
            $lat *= 1e-6;
            $sph->{lc "${azimuth}_${range}_lat"} = $lat;
            (my $long = $sph->{"${azimuth}_${range}_LONG"}) =~ s/\<.*//;
            $long *= 1e-6;
            $sph->{lc "${azimuth}_${range}_long"} = $long;

            my $point = Geo::Point->latlong($lat, $long, 'wgs84');
            push @{$bounds{$azimuth}}, $point;
            $sph->{lc "${azimuth}_${range}_point"} = $point;
        }
    }

    # I don't know how multiple polys should be calculated (when there
    # is strip spacing.  Polygon clockwise starting left-top
    my @poly
      = $sph->{PASS} eq 'DESCENDING'
      ? (@{$bounds{FIRST}}, reverse @{$bounds{LAST}} )
      : (@{$bounds{LAST}},  reverse @{$bounds{FIRST}});

    my $footprint = Geo::Line->filled(points => \@poly, clockwise => 1);
    $sph->{target_polys} = Geo::Surface->new($footprint);

    _add_missing_stripped $sph;
}

sub _cleanup_dsd($)
{   my $dsd = shift;

    $dsd->{lc $_} = _strip_unit $dsd->{$_}
        for qw/DS_OFFSET DS_SIZE DSR_SIZE/;

    $dsd->{num_dsr} = $dsd->{NUM_DSR} + 0;

    my $t = $dsd->{DS_TYPE};
    $dsd->{ds_type}
      = $t eq 'M' ? 'Measurement DS'
      : $t eq 'A' ? 'Annotation DS'
      : $t eq 'G' ? 'Global ADS'
      : $t eq 'R' ? 'Reference only'
      :             'ERROR';

    # field can also contain 'MISSING' and 'NOT USED' :-(
    $dsd->{filename} = $t eq 'R' ? $dsd->{FILENAME} : undef;

    _add_missing_stripped $dsd;
}

sub _read_block($$)
{   my ($fh, $size) = @_;
    my $buffer = '';
    $fh->read($buffer, $size - length $buffer, length $buffer)
        while length $buffer < $size;
    $buffer;
}

sub _decompose($)
{   my @lines = split /\n/, shift;
    my %h;

    foreach my $line (@lines)
    {   if   ($line =~ m/^(\w+)\=\"(.*?)"/) { $h{$1} = $2 }
        elsif($line =~ m/^(\w+)\=(.*)/)     { $h{$1} = $2 }
    }
    \%h;
}

sub _timestamp_to_time($)
{   my $stamp = shift;
    $stamp =~ m/^(\d\d)\-([A-Z]{3})\-(\d{4}) (\d\d):(\d\d):(\d\d)\.(\d+)/
       or return 'ERROR';
    my $secs = mktime($6, $5, $4, $1, $month{$2}-1, $3-1900);
    0.0 + "$secs.$7";
}

sub _timestamp_iso($)
{   my $time = shift;
    my $frag = $time =~ s/\.(\d+)$// ? $1 : 0;
    (strftime "%FT%T", gmtime $time). ($frag ? ".$frag" : '') . 'Z';
}

sub _add_missing_stripped($)
{   my $h = shift;

    # for all fields without a lower-cased value, we generate one
    # where the blanks are stripped off.
    foreach my $f (keys %$h)
    {   next if exists $h->{lc $f};   # skips lc keys as well
        ($h->{lc $f} = $h->{$f}) =~ s/\s+$//;
    }
}

sub _strip_unit($)
{   (my $value = $_[0]) =~ s/\<[^<>]*\>\s*$//;
    $value + 0;
}

1;
