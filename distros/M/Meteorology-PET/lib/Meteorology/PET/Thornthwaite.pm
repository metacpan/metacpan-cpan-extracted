package Meteorology::PET::Thornthwaite;

use 5.008001;
use strict;
use warnings;

use Array::Compare;
use Carp qw(croak);
use Math::Trig qw(pi acos tan);
use Scalar::Util qw(blessed looks_like_number reftype);

our $VERSION = "0.01";

=pod

=head1 NAME

Meteorology::PET::Thornthwaite - Calculate potential evapotranspiration (PET) using the Thornthwaite Method

=head1 SYNOPSIS

    use Meteorology::PET::Thornthwaite;
    
    my $pet_calc = Meteorology::PET::Thornthwaite->new({
        LATITUDE          => $lat,
        TEMPERATURE_CLIMO => \@temperature_climo,
        TEMPERATURE_UNITS => 'F',
        PET_UNITS         => 'mm',
    });
    
    my $pet = $pet_calc->pet({
        YDAY              => 180,
        NDAYS             => 31,
        TEMPERATURE       => $temperature,
        TEMPERATURE_UNITS => 'C',
    });

=head1 DESCRIPTION

The C<Meteorology::PET::Thornthwaite> module provides an object-oriented interface with a dedicated method to 
calculate potential evapotranspiration (PET) using equations developed by Charles Warren Thornthwaite and published 
in I<Geographical Review> in 1948. Relying on temperature data and daylight hours as a function of latitude and the 
time of year, the Thornthwaite method is straightforward to implement, and has been utilized in many weather and 
climate applications, such as the two-layer soil water balance model used in the Palmer Drought Index (Palmer 1965), 
and the one-layer "Leaky Bucket" soil moisture model (e.g., Huang et al. 1996) used for seasonal temperature forecasts.

In addition to a location's temperature observations, the time of year, and its latitude, the Thornthwaite Equation 
also requires a monthly temperature climatology for the location, used to compute a term called the Temperature 
Efficiency Index (TEI). To allow for faster processing, therefore, information about the location(s) to be used, such 
as the monthly temperature climatology and latitude, are supplied at the time of object construction (C<new>), allowing 
the TEI to be pre-computed.

The module is designed to work with two data input types:

=over 4

=item * Scalar values for a single location

=item * L<PDL> ndarray objects for multiple locations

=back

The module automatically detects which input type the caller is using by analyzing the latitude and temperature 
climatology arguments passed to the constructor. All PDL arguments must have the exact same spatial dimensions. The 
PDL module is not required to be installed on your system if you are only using the scalar argument mode.

All input and output data units must be specified. The module has a limited ability to convert between units: Kelvin/
Celsius/Fahrenheit (K, C, F) for temperatures, and millimeters/inches (mm/in) for PET.

=head1 METHODS

=head2 new

    my $pet_calc = Meteorology::PET::Thornthwaite->new({
        LATITUDE          => $lat,
        TEMPERATURE_CLIMO => \@temperature_climo,
        TEMPERATURE_UNITS => 'F',
        PET_UNITS         => 'mm',
    });

Returns a C<Meteorology::PET::Thornthwaite> object to the calling program, defining the location(s) to be used in 
PET calculations by latitude and 12-month temperature climatology. The constructor accepts a L<hash ref|https://perldoc.perl.org/perlref> 
argument with four required parameters:

=over 4

=item * C<LATITUDE> - location latitude(s) ranging from -90 to 90. Can be a numeric scalar value for a single 
location, or a PDL ndarray object for multiple locations.

=item * C<TEMPERATURE_CLIMO> - an array ref containing 12 monthly temperature climatological values for the location(s). 
The array elements can be numeric scalars for a single location, or PDL ndarray objects for multiple locations. The 
dimensions of each PDL object must match those of C<LATITUDE> exactly.

=item * C<TEMPERATURE_UNITS> - The units of the C<TEMPERATURE_CLIMO> values. Can be C<C> (Celsius), C<K> (Kelvin), or 
C<F> (Fahrenheit).

=item * C<PET_UNITS> - The units of the PET values that this object will return via calls to the C<pet> method. Can be 
C<mm> (millimeters) or C<in> (inches).

=back

=cut

sub new {
    my $class  = shift;
    my $method = "${class} (new)";
    my $args   = shift;
    croak("$method - Argument required and must be a hash ref") unless(ref($args) && reftype($args) eq 'HASH');

    # Validate that all of the required parameters are defined
    croak("$method - LATITUDE parameter is undefined")          unless(defined($args->{LATITUDE}));
    croak("$method - TEMPERATURE_CLIMO parameter is undefined") unless(defined($args->{TEMPERATURE_CLIMO}));
    croak("$method - TEMPERATURE_UNITS parameter is undefined") unless(defined($args->{TEMPERATURE_UNITS}));
    croak("$method - PET_UNITS parameter is undefined")         unless(defined($args->{PET_UNITS}));

    # Validate that TEMPERATURE_CLIMO has 12 values
    croak("$method - TEMPERATURE_CLIMO parameter must be an array ref with 12 elements") unless(ref($args->{TEMPERATURE_CLIMO}) eq 'ARRAY' && @{$args->{TEMPERATURE_CLIMO}} == 12);

    # Validate units parameters
    croak("$method - TEMPERATURE_UNITS parameter is invalid") unless($args->{TEMPERATURE_UNITS} =~ /^[CFK]$/);
    croak("$method - PET_UNITS parameter is invalid") unless($args->{PET_UNITS} =~ /^(mm|in)$/);

    # Add units params to the object under construction
    my $self = {};
    $self->{TEMPERATURE_UNITS} = $args->{TEMPERATURE_UNITS};
    $self->{PET_UNITS}         = $args->{PET_UNITS};

    # Initialize the rest of the object params, then determine object mode (scalar or PDL)
    my $pdl_mode   = 0;
    my $lat        = undef;
    my $tei        = undef;

    # --- PDL Mode ---

    if(blessed($args->{LATITUDE}) && $args->{LATITUDE}->isa('PDL')) {
        $pdl_mode = 1;

        eval {
            require PDL;
            1;
        } or croak("$method - In PDL mode, but the PDL module cannot be loaded");

        # Validate PDL args and calculate TEI
        $lat           = $args->{LATITUDE}->copy;
        unless($lat->min >= -90 && $lat->max <= 90) { croak("$method - LATITUDE values must be within [-90, 90]"); }
        $tei           = $lat->zeros;
        my $array_comp = Array::Compare->new();
        my @lat_dims   = $lat->dims;

        for(my $i=0; $i<@{$args->{TEMPERATURE_CLIMO}}; $i++) {
            croak("$method - In PDL mode, but element $i in the TEMPERATURE_CLIMO parameter is not a PDL object") unless(blessed($args->{TEMPERATURE_CLIMO}[$i]) && $args->{TEMPERATURE_CLIMO}[$i]->isa('PDL'));
            my $mtemp_in = $args->{TEMPERATURE_CLIMO}[$i]->copy;
            my @pdl_dims = $mtemp_in->dims;
            croak("$method - The dimensions of element $i in the TEMPERATURE_CLIMO parameter do not match the LATITUDE parameter's dimensions") unless($array_comp->compare(\@lat_dims,\@pdl_dims));
            my $mtemp    = undef;
            if($args->{TEMPERATURE_UNITS} eq 'F')    { $mtemp = ($mtemp_in - 32.0) / 1.8; }
            elsif($args->{TEMPERATURE_UNITS} eq 'K') { $mtemp = $mtemp_in - 273.15;       }
            else                                     { $mtemp = $mtemp_in->copy;          }
            my $ptemps   = $mtemp->lclip(0);
            $tei        += ($ptemps / 5) ** 1.514;
        }

    }

    # --- Scalar Mode ---

    else {
        $lat = $args->{LATITUDE};
        unless(looks_like_number($lat) && $lat >= -90 && $lat <= 90) { croak("$method - LATITUDE value must be numeric and within [-90, 90]"); }
        $tei = 0;

        for(my $i=0; $i<@{$args->{TEMPERATURE_CLIMO}}; $i++) {
            unless(looks_like_number($args->{TEMPERATURE_CLIMO}[$i])) { croak("$method - Element $i in the TEMPERATURE_CLIMO parameter must be numeric"); }
            my $mtemp_in = $args->{TEMPERATURE_CLIMO}[$i];
            my $mtemp    = undef;
            if($args->{TEMPERATURE_UNITS} eq 'F')    { $mtemp = ($mtemp_in - 32.0) / 1.8; }
            elsif($args->{TEMPERATURE_UNITS} eq 'K') { $mtemp = $mtemp_in - 273.15;       }
            else                                     { $mtemp = $mtemp_in;                }
            my $ptemp    = $mtemp > 0 ? $mtemp : 0;
            $tei += ($ptemp / 5) ** 1.514;
        }

    }

    $self->{LATITUDE} = $lat;
    $self->{TEI}      = $tei;
    $self->{PDL_MODE} = $pdl_mode;

    bless($self,$class);
    return $self;
}

=pod

=head2 pet

    my $pet = $pet_calc->pet({
        YDAY              => 180,
        NDAYS             => 31,
        TEMPERATURE       => $temperature,
        TEMPERATURE_UNITS => 'C',
    });

Returns a scalar PET value to the calling program in scalar mode, or a PDL object containing PET values in PDL 
mode for the locations defined in the constructor. Accepts a L<hash ref|https://perldoc.perl.org/perlref> argument 
with four required parameters:

=over 4

=item * C<YDAY> - the day of the year of the midpoint of the time period to calculate PET, ranging from 1 (Jan 1) to 
366 (Dec 31 of a leap year).

=item * C<NDAYS> - the number of days in the time period for which to calculate PET. The original Thornthwaite 
formulation assumed monthly time scales, but the equation can be scaled for daily, weekly, bi-weekly, or other periods.

=item * C<TEMPERATURE> - the mean temperature observed at the location(s) during the time period defined by C<YDAY> and 
C<NDAYS>. Can be a numeric scalar value or a PDL object with dimensions matching the objects passed to the constructor.

=item * C<TEMPERATURE_UNITS> - The units of the C<TEMPERATURE> value(s). Can be C<C> (Celsius), C<K> (Kelvin), or
C<F> (Fahrenheit).

=back

=cut

sub pet {
    my $self   = shift;
    my $class  = ref($self);
    my $method = "${class} (pet)";
    my $args   = shift;
    croak("$method - Argument required and must be a hash ref") unless(ref($args) && reftype($args) eq 'HASH');

    # Validate that all of the required parameters are defined
    croak("$method - YDAY parameter is undefined")              unless(defined($args->{YDAY}));
    croak("$method - NDAYS parameter is undefined")             unless(defined($args->{NDAYS}));
    croak("$method - TEMPERATURE parameter is undefined")       unless(defined($args->{TEMPERATURE}));
    croak("$method - TEMPERATURE_UNITS parameter is undefined") unless(defined($args->{TEMPERATURE_UNITS}));

    # Validate YDAY
    my $yday   = $args->{YDAY};
    croak("$method - YDAY parameter must be an integer between 1 and 366") unless(looks_like_number($yday) && $yday =~ /^[1-9]\d*$/ && $yday <= 366);

    # Validate NDAYS
    my $ndays  = $args->{NDAYS};
    croak("$method - NDAYS parameter must be a positive integer") unless(looks_like_number($ndays) && $ndays =~ /^[1-9]\d*$/);

    # Validate TEMPERATURE_UNITS
    croak("$method - TEMPERATURE_UNITS parameter is invalid") unless($args->{TEMPERATURE_UNITS} =~ /^[CFK]$/);

    my $pet_mm = undef;

    # --- PDL Mode ---

    if($self->{PDL_MODE}) {
        croak("$method - In PDL mode, but the TEMPERATURE parameter is not a PDL object") unless(blessed($args->{TEMPERATURE}) && $args->{TEMPERATURE}->isa('PDL'));
        # Validate temperature PDL dimensions
        my @lat_dims    = $self->{LATITUDE}->dims;
        my @arg_dims    = $args->{TEMPERATURE}->dims;
        my $array_comp  = Array::Compare->new();
        croak("$method - TEMPERATURE parameter dimensions do not match the object data (e.g., LATITUDE)") unless($array_comp->compare(\@lat_dims,\@arg_dims));
        # Convert temperature to degC if needed
        my $temp        = undef;
        if($args->{TEMPERATURE_UNITS} eq 'F')    { $temp = ($args->{TEMPERATURE} - 32.0) / 1.8; }
        elsif($args->{TEMPERATURE_UNITS} eq 'K') { $temp = $args->{TEMPERATURE} - 273.15;       }
        else                                     { $temp = $args->{TEMPERATURE}->copy;          }
        # Flip YDAY by half a year for any southern hemisphere latitudes
        my $is_south  = $self->{LATITUDE} < 0;
        my $sh_yday   = $yday + 182.5;
        $sh_yday      = $sh_yday > 365 ? $sh_yday - 365 : $sh_yday;
        $sh_yday      = int($sh_yday + 0.5);
        my $yday_pdl  = $temp->zeros + $yday;
        if($is_south->any) { $yday_pdl->where($is_south) .= $sh_yday; }
        # And now with southern hemisphere YDAYs flipped, make all latitudes positive for the calculation
        my $lat       = abs($self->{LATITUDE});
        # Now crunch out the PET!
        my $tei       = $self->{TEI}->copy;
        $tei->where($tei <= 0) .= 1;      # Avoid div0 errors
        my $lat_rad   = ($lat * pi) / 180;
        my $solar_dec = 0.409 * (((2 * pi) / 365) * $yday_pdl - 1.39)->sin;
        my $cos_arg   = -1 * $lat_rad->tan * $solar_dec->tan;
        $cos_arg->clip(-1, 1, $cos_arg);  # Make sure the results are bounded by [-1, 1]
        my $daylength = (24 / pi) * $cos_arg->acos;
        my $alpha     = (6.75e-7) * ($tei**3) - (7.71e-5) * ($tei**2) + 0.01792 * $tei + 0.49239;
        $pet_mm       = $temp->zeros;
        my $thornth   = ($temp > 0) & ($temp < 26.5) & ($self->{TEI} > 0); # These values will use the Thornthwaite equation
        my $hotadj    = ($temp >= 26.5);                                   # These hot values will use the Huang et al. equation
        my $pos_temp  = $temp->lclip(1e-20);                               # Prevents errors with negative temps (and zero)
        my $pet_gross = 16 * ((10 * $pos_temp) / $tei)**$alpha;
        my $pet_nml   = $pet_gross * ($daylength / 12) * ($ndays / 30);
        $pet_mm->where($thornth) .= $pet_nml->where($thornth);
        my $pet_hot   = (-415.85 + 32.25 * $temp - 0.43 * ($temp**2)) * ($ndays / 30);
        $pet_mm->where($hotadj)  .= $pet_hot->where($hotadj);
    }

    # --- Scalar Mode ---

    else {
        croak("$method - TEMPERATURE parameter must be numeric") unless(looks_like_number($args->{TEMPERATURE}));
        # Convert temperature to degC if needed
        my $temp        = undef;
        if($args->{TEMPERATURE_UNITS} eq 'F')    { $temp = ($args->{TEMPERATURE} - 32.0) / 1.8; }
        elsif($args->{TEMPERATURE_UNITS} eq 'K') { $temp = $args->{TEMPERATURE} - 273.15;       }
        else                                     { $temp = $args->{TEMPERATURE};                }
        # Flip YDAY by half a year if latitude is southern hemisphere
        my $lat  = $self->{LATITUDE};
        if($lat < 0) {
            $yday = $yday + 182.5 > 365 ? $yday + 182.5 - 365 : $yday + 182.5; 
            $yday = int($yday + 0.5);
        }
        $lat     = abs($lat);
        # Now crunch out the PET!
        my $tei  = $self->{TEI};
        if($temp <= 0 || ($temp < 26.5 && $tei <= 0)) { $pet_mm = 0; }  # Frozen ground
        elsif($temp < 26.5) {  # These values will use the Thornthwaite equation
            my $lat_rad   = ($lat * pi) / 180;
            my $solar_dec = 0.409 * sin(((2 * pi) / 365) * $yday - 1.39);
            my $cos_arg = -tan($lat_rad) * tan($solar_dec);
            # Make sure the result is bounded by [-1, 1]
            if($cos_arg > 1)  { $cos_arg = 1;  }
            if($cos_arg < -1) { $cos_arg = -1; }
            my $daylength = (24 / pi) * acos($cos_arg);
            my $alpha     = (6.75e-7) * ($tei**3) - (7.71e-5) * ($tei**2) + 0.01792 * $tei + 0.49239;
            my $pet_gross = 16 * ((10 * $temp) / $tei)**$alpha;
            $pet_mm       = $pet_gross * ($daylength / 12) * ($ndays / 30);
        }
        else {                 # This hot value will use the Huang et al. equation
            $pet_mm       = (-415.85 + 32.25 * $temp - 0.43 * ($temp**2)) * ($ndays / 30);
        }
    }

    if($self->{PET_UNITS} eq 'in') { return $pet_mm / 25.4; }
    else                           { return $pet_mm;        }
}

=head1 SEE ALSO

=over 4

=item * L<Meteorology::PET>

=item * L<Array::Compare>

=item * L<PDL>

=back

=head1 REFERENCES

=over 4

=item * Thornthwaite, C. W., 1948: An approach toward a rational classification of climate. I<Geographical Review>, 38, 55-94.

=item * Palmer, Wayne C., 1965: Meteorological Drought. U.S. Weather Bureau, Research Paper No. 45.

=item * Huang, J., H. M. van den Dool, and K. E. Georgakakos, 1996: Analysis of model-calculated soil moisture over the United
States (1931-1993) and applications to long-range temperature forecasts. I<J. Climate>, 9, 1350-1362.

=back

=head1 AUTHOR

Adam Allgood, NOAA/NWS/NCEP/Weather Prediction Center

=head1 LICENSE

As a work of the United States Government, this project is in the
public domain within the United States.

Additionally, we waive copyright and related rights in the work
worldwide through the CC0 1.0 Universal public domain dedication.

=head2 CC0 1.0 Universal Summary

This is a human-readable summary of the L<Legal Code (read the full text)|https://creativecommons.org/publicdomain/zero/1.0/legalcode>.

=head3 No Copyright

The person who associated a work with this deed has dedicated the work to
the public domain by waiving all of his or her rights to the work worldwide
under copyright law, including all related and neighboring rights, to the
extent allowed by law.

You can copy, modify, distribute and perform the work, even for commercial
purposes, all without asking permission.

=head3 Other Information

In no way are the patent or trademark rights of any person affected by CC0,
nor are the rights that other persons may have in the work or in how the
work is used, such as publicity or privacy rights.

Unless expressly stated otherwise, the person who associated a work with
this deed makes no warranties about the work, and disclaims liability for
all uses of the work, to the fullest extent permitted by applicable law.
When using or citing the work, you should not imply endorsement by the
author or the affirmer.

=cut

1;

__END__


