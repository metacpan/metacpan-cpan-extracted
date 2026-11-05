package Meteorology::PET;

use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

1;

__END__

=pod

=head1 NAME

Meteorology::PET - Perl packages to calculate potential evapotranspiration (PET)

=head1 SYNOPSIS

    # Calculate PET using the Thornthwaite method!
    
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

C<Meteorology::PET> is a collection of modules that provide the ability to calculate potential 
evapotranspiration (PET). PET is an estimation of how much moisture could be removed from the Earth's surface 
through evaporation and transpiration under specific conditions if the ground moisture supply had no limit. 
PET has numerous applications in meteorology and hydrology, and this package is intended to provide a robust 
toolkit to accurately compute PET in modern Perl. Where applicable, each module provides support for computing 
PET for a single location (scalar mode) or across multiple locations simultaneously using L<PDL> ndarray objects.

=head1 AVAILABLE ALGORITHMS

=over 4

=item * L<Meteorology::PET::Thornthwaite>

Calculate potential evapotranspiration (PET) using the Thornthwaite Method

=back

=head1 SEE ALSO

=over 4

=item * L<Meteorology::PET::Thornthwaite>

=item * L<PDL>

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

