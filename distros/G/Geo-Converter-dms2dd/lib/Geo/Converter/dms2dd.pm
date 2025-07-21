#  package to convert degrees minutes seconds values to decimal degrees
#  also does some simple validation of decimal degree values as a side effect
package Geo::Converter::dms2dd;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.06';

use Carp;

use Readonly;
use Regexp::Common qw/number/;
use English qw { -no_match_vars };

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw( dms2dd );

#############################################################
##  some stuff to handle values in degrees 

#  some regexes
Readonly my $RE_REAL => qr /$RE{num}{real}/xms;
Readonly my $RE_INT  => qr /$RE{num}{int} /xms;
Readonly my $RE_HEMI => qr {
                            #  the hemisphere if given as text
                            #  handle full words, ignoring numbers and punctuation
                            #  needs utf solution
                            \s*
                            [NESWnesw]
                            [a-zA-Z]*
                            \s*
                        }xms;

#  a few constants
Readonly my $MAX_VALID_DD  =>  360;
Readonly my $MIN_VALID_DD  => -180;
Readonly my $MAX_VALID_LAT =>   90;
Readonly my $MAX_VALID_LON =>  180;

Readonly my $INVALID_CHAR_CONTEXT => 3;

#  how many distinct numbers we can have in a DMS string?
Readonly my $MAX_DMS_NUM_COUNT => 3;

my $err_msg_pfx = 'DMS2DD Value error: ';

#  convert degrees minutes seconds values into decimal degrees
#  e.g.;
#  S23°32'09.567"  = -23.5359908333333
#  149°23'18.009"E = 149.388335833333
sub dms2dd {
    my $args = shift;

    my $value = $args->{value};
    croak "Argument 'value' not supplied\n"
      if !defined $value;

    my $first_char_invalid;
    if (not $value =~ m/ \A [\s0-9NEWSnews+-] /xms) {
        $first_char_invalid = substr $value, 0, $INVALID_CHAR_CONTEXT;
    }

    croak $err_msg_pfx . "Invalid string at start of value: $value\n"
      if defined $first_char_invalid;

    my @nums = eval {
        _dms2dd_extract_nums ( { value => $value } );
    };
    croak $EVAL_ERROR if ($EVAL_ERROR);

    my $hemi = eval {
        _dms2dd_extract_hemisphere (
            { value => $value },
        );
    };
    croak $EVAL_ERROR if $EVAL_ERROR;

    my $multiplier = 1;
    if ($hemi =~ / ^\s* [SsWw-] /xms) {
        $multiplier = -1;
    }

    #  now apply the defaults
    #  $deg is +ve, as hemispheres are handled separately
    my $deg = abs ($nums[0] || 0);
    my $min = $nums[1] || 0;
    my $sec = $nums[2] || 0;
    
    my $dd = $multiplier
            * (   $deg
                + $min / 60
                + $sec / 3600
              );

    my $valid = eval {
        _dms2dd_validate_dd_value ( {
            %$args,
            value       => $dd,
            hemisphere  => $hemi,
        } );
    };
    croak $EVAL_ERROR if $EVAL_ERROR;

    #my $res = join (q{ }, $value, $dd, $multiplier, $hemi, @nums) . "\n";

    return $dd;
}

#  are the numbers we extracted OK?
#  must find three or fewer of which only the last can be decimal 
sub _dms2dd_extract_nums {
    my $args = shift;

    my $value = $args->{value};

    my @nums = $value =~ m/$RE_REAL/gxms;
    my $deg = $nums[0];
    my $min = $nums[1];
    my $sec = $nums[2];

    #  some verification
    my $msg;

    if (! defined $deg) {
        $msg = 'No numeric values in string';
    }
    elsif (scalar @nums > $MAX_DMS_NUM_COUNT) {
        $msg = 'Too many numbers in string';
    }

    if (defined $sec) {
        if ($min !~ / \A $RE_INT \z/xms) {
            $msg = 'Seconds value given, but minutes value is floating point';
        }
        elsif ($sec < 0 || $sec > 60) {
            $msg = 'Seconds value is out of range';
        }
    }
    
    if (defined $min) {
        if ($deg !~ / \A $RE_INT \z/xms) {
            $msg = 'Minutes value given, but degrees value is floating point';
        }
        elsif ($min < 0 || $min > 60) {
            $msg = 'Minutes value is out of range';
        }
    }

    #  the valid degrees values depend on the hemisphere,
    #  so are trapped elsewhere

    #my $msg_pfx     = 'DMS value error: ';
    my $msg_suffix  = qq{: '$value'\n};

    croak $err_msg_pfx . $msg . $msg_suffix
        if $msg;

    return wantarray ? @nums : \@nums;
}

sub _dms2dd_validate_dd_value {
    my $args = shift;

    my $is_lat = $args->{is_lat};
    my $is_lon = $args->{is_lon};

    my $dd   = $args->{value};
    my $hemi = $args->{hemisphere};

    my $msg_pfx = 'DMS2DD Coord error: ';
    my $msg;

    #  if we know the hemisphere then check it is in bounds,
    #  otherwise it must be in the interval [-180,360]
    if ($is_lat // ($hemi =~ / ^[SsNn] /xms)) {
        if ($is_lon) {
            $msg = "Longitude specified, but latitude found:  $dd\n"
        }
        elsif (abs ($dd) > $MAX_VALID_LAT) {
            $msg = "Latitude out of bounds: $dd\n"
        }
    }
    elsif ($is_lon // ($hemi =~ / [EeWw] /xms)) {
        if ($is_lat) {
            $msg = "Latitude specified, but longitude found\n"
        }
        elsif (abs ($dd) > $MAX_VALID_LON) {
            $msg = "Longitude out of bounds: $dd\n"
        }
    }
    elsif ($dd < $MIN_VALID_DD || $dd > $MAX_VALID_DD) {
        $msg = "Coord out of bounds:  $dd\n";
    }
    croak "$msg_pfx $msg" if $msg;

    return 1;
}

sub _dms2dd_extract_hemisphere {
    my $args = shift;

    my $value = $args->{value};

    my $hemi;
    #  can start with [NESWnesw-]
    if ($value =~ m/ \A ( $RE_HEMI | [-] )/xms) {
        $hemi = $1;
    }
    #  cannot end with [-]
    if ($value =~ m/ ( $RE_HEMI ) \z /xms) {
        my $hemi_end = $1;

        croak "Cannot define hemisphere twice: $value\n"
          if (defined $hemi && defined $hemi_end);

        $hemi = $hemi_end;
    }
    if (! defined $hemi) {
        $hemi = q{};
    }

    return $hemi;
}


1;


=pod

=encoding ISO8859-1

=head1 NAME

Geo::Converter::dms2dd

=head1 VERSION

0.02

=head1 SYNOPSIS

 use Geo::Converter::dms2dd qw { dms2dd };

 my $dms_value;
 my $dd_value;
 
 $dms_value = q{S23°32'09.567"};
 $dd_value  = dms2dd ({value => $dms_value});
 print $dms_value
 #  -23.5359908333333

 $dms_value = q{149°23'18.009"E};
 $dd_value  = dms2dd ({value => $dms_value});
 print $dd_value
 #   149.388335833333
 
 $dms_value = q{east 149°23'18.009};
 $dd_value  = dms2dd ({value => $dms_value});
 print $dd_value
 #   149.388335833333
 
 
 #  The following all croak with warnings:
 
 $dms_value = q{S23°32'09.567"};
 $dd_value  = dms2dd ({value => $dms_value, is_lon => 1});
 # Coord error:  Longitude specified, but latitude found

 $dms_value = q{149°23'18.009"E};
 $dd_value  = dms2dd ({value => $dms_value, is_lat => 1});
 # Coord error:  Latitude out of bounds: 149.388335833333
 
 $dms_value = q{149°23'18.009"25};  #  extra number
 $dd_value  = dms2dd ({value => $dms_value});
 # DMS value error: Too many numbers in string: '149°23'18.009"25'


=head1 DESCRIPTION

Use this module to convert a coordinate value in degrees minutes seconds
to decimal degrees.  It exports a single sub C<dms2dd> which will
parse and convert a single value.

A reasonable amount of location information is provided in
degrees/minutes/seconds (DMS) format, for example from Google Earth, GIS packages or
similar.  For example, one might be given a location coordinate for just north east
of Dingo in Queensland, Australia.  Four possible formats are:

 S23°32'09.567", E149°23'18.009"
 23°32'09.567"S, 149°23'18.009"E
 -23 32 9.567,   +149 23 18.009
 -23.535991,     149.388336

The first three coordinates are in degrees/minutes/seconds while the fourth
is in decimal degrees.  The fourth coordinate can be used in numeric
calculations, but the first three must first be converted to decimal degrees.

The conversion process used in dms2dd is pretty generous in what it treats as DMS,
as there is a multitude of variations in punctuation and the like.
Up to three numeric values are extracted and any additional text is largely
ignored unless it could be interpreted as the hemisphere (see below).
It croaks if there are four or more numeric values.
If the hemisphere is known or the C<is_lat> or C<is_lon> arguments are specified then
values are validated (e.g. latitudes must be in the interval [-90, 90], 
and longitudes with a hemisphere specified must be within [-180, 180]).  
Otherwise values between [-180, 360] are accepted.  If seconds are specified
and minutes have values after the radix (decimal point) then it croaks
(e.g. 35 26.5' 22").  Likewise, it croaks for cases like (35.2d 26').
It will also croak if you specify the hemisphere at the start and end of the
value, even if it is the same hemisphere.

Note that this module only works on a single value. 
Call it once each for latitude and longitude values to convert a full coordinate.

=head1 AUTHOR

Shawn Laffan S<(I<shawnlaffan@gmail.com>)>.

=head1 BUGS AND IRRITATIONS

Hemispheres are very liberally interpreted.  So long as the text component
starts with a valid character then it is used.  This means that
(E 35 26') is treated the same as (Egregious 35 26').

It also does not deal with non-English spellings of north, south, east or west.
Hemispheres need to satisfy qr/[NESWnesw+-]/.  A solution could be to drop
in an appropriate regexp as an argument, or maybe there is an i18n
solution.  Patches welcome.

It could probably also give the parsed degrees, minutes and seconds rather
than convert them.  They are pretty easy to calculate, though.


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=head1 See also

L<Geo::Coordinates::DecimalDegrees>, although it requires the
degrees, minutes and seconds values to already be parsed from the string.

=cut


