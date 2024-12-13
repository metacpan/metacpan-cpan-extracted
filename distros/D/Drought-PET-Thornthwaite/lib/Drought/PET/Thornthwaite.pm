package Drought::PET::Thornthwaite;

use 5.006;
use strict;
use warnings;
use Carp qw(carp croak cluck confess);
require Exporter;
use Math::Trig;
use Scalar::Util qw(looks_like_number reftype);

our @ISA        = qw(Exporter);
our @EXPORT_OK  = qw(
        pet_thornthwaite
        tei_thornthwaite
    );

=head1 NAME

Drought::PET::Thornthwaite - Calculate potential evapotranspiration (PET) using the Thornthwaite method

=head1 VERSION

Version 0.50

=cut

our $VERSION = '0.50';

=head1 SYNOPSIS

 use Drought::PET::Thornthwaite qw(pet_thornthwaite tei_thornthwaite);

=head1 DESCRIPTION

Evapotranspiration is the amount of water removed from the soil due to both evaporation and 
vegetative consumption. Factors such as sun angle, temperature, soil type, the amount of 
available water, and the types of vegetation all affect the amount of evapotranspiration 
that occurs in a given location. The potential evapotranspiration (PET) is defined as the 
amount of evapotranspiration that would occur under a defined set of conditions if the amount 
of available water in the soil was limitless and accessible. The PET is a component of various 
drought and water balance models. Numerous techniques have been developed to calculate 
and estimate potential evapotranspiration.

The Drought::PET::Thornthwaite package provides functions that can calculate the PET 
based on the Thornthwaite Equation (Thornthwaite 1948). This equation estimates PET based 
on the day of year, the latitude of the target location, the temperature observed during 
the period for which PET is calculated, and a monthly temperature-based climatological index 
specific to the target region. This index is typically called the Thornthwaite heat index, 
or the temperature efficiency index. The documentation for this package refers to this index 
as the temperature efficiency index (TEI).

=head1 EXPORT

The following functions provided by the Drought::PET::Thornthwaite package 
are exportable.

=head2 pet_thornthwaite

 my $pet = pet_thornthwaite($yday,$ndays,$lat,$temp,$tei,$missing_val);

Calculate the potential evapotranspiration in millimeters using the Thornthwaite Equation. 
Temperatures at or below zero return a zero PET. For temperatures at or above 26.5 degrees, 
an adjusted equation described in Huang et al. 1996 is used to estimate the PET, since the 
original Thornthwaite Equation becomes increasingly inaccurate at higher temperatures.

This function requires five arguments:

=over 4

=item * C<$yday>: The day of the year (1 - 366). If the PET is calculated for a period of more than one day, supply the midpoint date

=item * C<$ndays>: The number of days in the period over which the PET is calculated, e.g., 7 for a weekly PET. Must be 1 or greater

=item * C<$lat>: The latitude of the location for which the PET is calculated in degrees (must be 0 to 90)

=item * C<$temp>: The average temperature observed during the period in degrees Celsius

=item * C<$tei>: The climatological "temperature efficiency index" defined in Thornthwaite (1948)

An optional sixth argument can be supplied, which would be considered the missing data value. 
The default missing value is NaN. If the YDAY, NDAYS, or LAT arguments are non-numeric or 
invalid, the pet_thornthwaite function will L<croak|https://perldoc.perl.org/Carp>. 
If the TEMP or TEI arguments are undefined, missing, or invalid, the function will return 
the missing value.

This function currently only works for Northern Hemisphere locations.

=back

=cut

sub pet_thornthwaite {
    # Define a NaN value for later use
    my $inf           = exp(~0 >> 1);
    my $nan           = $inf / $inf;

    # Make sure the caller supplied sufficient arguments
    unless(@_ and @_ >= 5) { croak "Insufficient arguments supplied"; }

    # Get the arguments
    my $yday        = shift;
    my $ndays       = shift;
    my $lat         = shift;
    my $temperature = shift;
    my $tei         = shift;
    my $missing_val = $nan;

    # Replace the default missing value if the caller supplied one
    if(@_) { $missing_val = shift; }

    # Validate the non-data arguments
    if(not looks_like_number($yday))       { croak "YDAY arg must be numeric";           }
    $yday  = int($yday);
    if(not $yday >= 1 or not $yday <= 366) { croak "YDAY arg must be between 1 and 366"; }
    if(not looks_like_number($ndays))      { croak "NDAYS arg must be numeric";          }
    $ndays = int($ndays);
    if(not $ndays >= 1)                    { croak "NDAYS arg must be 1 or greater";     }
    if(not looks_like_number($lat))        { croak "LAT arg must be numeric";            }
    if(not $lat >= 0 or not $lat <= 90)    { croak "LAT arg must be between 0 and 90";   }

    # Return the missing value if the data arguments are missing or invalid
    if(
        not defined($temperature)           or
        not defined($tei)                   or
        not looks_like_number($temperature) or
        not looks_like_number($tei)         or
        $temperature == $missing_val        or
        $tei         == $missing_val        or
        not defined($temperature <=> 0)     or
        not defined($tei <=> 0)
    ) { return $missing_val; }

    # Calculate the PET!

    if($temperature <= 0) { return 0; }

    elsif($temperature > 0 and $temperature < 26.5) {
        # Calculate the hours of sunlight
        my $lat_radians       = (pi/180)*$lat;
        my $solar_declination = 0.409*sin((2*pi/365)*$yday - 1.39);
        my $sunset_angle      = acos(-tan($lat_radians)*tan($solar_declination));
        my $daylength         = (24/pi)*$sunset_angle;
        # Calculate alpha term
        my $alpha             = (6.75e-7)*($tei**3) - (7.71e-5)*($tei**2) + 0.01792*$tei + 0.49239;
        # Apply the original Thornthwaite Equation
        my $pet_gross         = 16*((10*$temperature)/($tei))**$alpha;
        return $pet_gross*($daylength/12)*($ndays/30);
    }

    else {
        # Apply the hot temperature formula described in Huang et al. 1996
        return (-415.85 + 32.25*$temperature - 0.43*($temperature**2))*($ndays/30);
    }

}

=head2 tei_thornthwaite

 my $tei = tei_thornthwaite($jan,$feb,$mar,$apr,$may,$jun,$jul,$aug,$sep,$oct,$nov,$dec);

Calculates and returns the temperature efficiency index (TEI, sometimes called the 
Thornthwaite heat index) based on a monthly average temperature climatology for a given 
location. Since the equation involves a summation of adjusted monthly temperatures, 12 
arguments are required, consisting of the average temperature for each calendar month of 
the year. An optional 13th argument can also be supplied to define a numeric value 
interpreted as missing data. If not supplied, the default missing value is NaN.

The missing value will be returned if any of the temperature values are missing, 
undef, or invalid (e.g., non-numeric).

=cut

sub tei_thornthwaite {
    # Define a NaN value for later use
    my $inf           = exp(~0 >> 1);
    my $nan           = $inf / $inf;

    # Make sure the caller supplied sufficient arguments
    unless(@_ and @_ >= 12) { croak "Insufficient arguments supplied"; }

    # Get the arguments
    my @monthly_temperatures;
    my $invalid = 0;
    for(my $i=0; $i<12; $i++) { push(@monthly_temperatures,shift); } 
    my $missing_val = $nan;

    # Replace the default missing value if the caller supplied one
    if(@_) { $missing_val = shift; }

    # Calculate the TEI!
    my $tei = 0;

    for(my $i=0; $i<12; $i++) {
        # Return a missing value if any of the monthly temps are missing or invalid
        if(
            not defined($monthly_temperatures[$i])           or
            not looks_like_number($monthly_temperatures[$i]) or
            $monthly_temperatures[$i] == $missing_val        or
            not defined($monthly_temperatures[$i] <=> 0)
        ) { return $missing_val; }
        # Set any monthly mean temp below 0 to 0
        $monthly_temperatures[$i] = $monthly_temperatures[$i] > 0 ? $monthly_temperatures[$i] : 0;
        $tei += ($monthly_temperatures[$i]/5)**1.514;
    }

    return $tei;
}

=head1 INSTALLATION

The best way to install this module is with a CPAN client, which will resolve and
install the dependencies:

 cpan Drought::PET::Thornthwaite
 cpanm Drought::PET::Thornthwaite

You can also install the module directly from the distribution directory after
downloading it and extracting the files, which will also install the dependencies:

 cpan .
 cpanm .

If you want to install the module manually do the following in the distribution
directory:

 perl Makefile.PL
 make
 make test
 make install

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

 perldoc Drought::PET::Thornthwaite

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Drought-PET-Thornthwaite>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Drought-PET-Thornthwaite>

=item * Search CPAN

L<https://metacpan.org/release/Drought-PET-Thornthwaite>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-drought-pet-thornthwaite at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Drought-PET-Thornthwaite>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Adam Allgood

=head1 REFERENCES

=over 4

=item * Huang, J, H. M. Van Den Dool, and K. P. Georgarakos, 1996: Analysis of Model-Calculated Soil Moisture over the United States (1931-1993) and Applications to Long-Range Temperature Forecasts. I<Journal of Climate>, B<9> 1350-1362.

=item * Thornthwaite, C. W., 1948: An approach toward a rational classification of climate. I<Geographical Review>, B<38> 55-94.

=back

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Adam Allgood.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1; # End of Drought::PET::Thornthwaite

