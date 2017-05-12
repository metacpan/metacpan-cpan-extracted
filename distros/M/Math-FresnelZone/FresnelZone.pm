package Math::FresnelZone;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(fresnel fresnelMi fresnelKm);

our $VERSION = '0.03';

our $KILOMETERS_IN_A_MILE = 1.609344;
our $FEET_IN_A_METER      = 3.280839;

sub fresnel { 
   my $d = shift || 1;
   my $f = shift || 2.4;
   my $m = shift || 0;
   $d = $d * $KILOMETERS_IN_A_MILE if $m; # convert miles into kilometers
   my $fz = 72.6*sqrt($d/(4*$f));
   $fz = $fz * $FEET_IN_A_METER  if $m;   # convert meters back into feet
   return $fz;
}

sub fresnelMi { fresnel(shift,shift,1); }

sub fresnelKm { fresnel(shift,shift,0); }

1;
__END__

=head1 NAME

Math::FresnelZone - Perl extension for calculating the Fresnel Zone Radius of a given distance and frequency

=head1 SYNOPSIS

  use Math::FresnelZone;
  use Math::FresnelZone qw(fresnel fresnelMi fresnelKm);

=head1 DESCRIPTION

The arguments are:

   0 - distance in kilometers or miles (default is 1), 
   1 - frequency in GHz (defualt 2.4), 
   2 - set to true to specify that the distance you are inputting is in miles and that the results should be in in feet (default is 0 - IE kilometers/meters)

=head2 fresnel()

   my $fresnel_zone_radius_in_meters = fresnel(); # fresnel zone radius in meters for 1 kilometer at 2.4 GHz
   my $fzr_in_meters = fresnel(5); # fresnel zone radius in meters for 5 kilometers at 2.4 GHz
   my $fzr_in_meters = fresnel(5,4.8); # fresnel zone radius in meters for 5 kilometers at 4.8 GHz
   my $fzr_in_feet = fresnel(3,9.6,1); # fresnel zone in feet for 3 miles at 9.6 GHz

If you are inputting Kilometers the result is in meters (these 3 calls have identical results):

   fresnel($Km,$GHz);
   fresnelKm($Km,$GHz); # see documentaion below for info about fresnelKm()
   fresnel($Km,$GHz,0);

If you are inputting Miles (by specifying a true value as the 3rd argument) the result is in feet (these 2 calls have identical results)

   fresnel($Mi,$GHz,1);
   fresnelMi($Mi,$GHz); # see documentaion below for info about fresnelMi()

=head2 fresnelKm()

You can use this to make it easier to avoid ambiguity if are working in kilometers/meters.
It takes the first two arguments only: distance in kilometers and frequency in GigaHertz

 my $fzr_in_meters = fresnelKm($Km,$GHz);

=head2 fresnelMi()

You can use this to make it easier to avoid ambiguity if are working in miles/feet.
It takes the first two arguments only: distance in miles and frequency in GigaHertz

 my $fzr_in_feet = fresnelMi($Mi,$GHz);

=head2 EXPORT

None by default. You can export any of the 3 functions as in the synopsis example.

=head2 VARIABLES

These variables are used when using miles/feet instead of kilometers/meters to modify the input for the formula and the output for the user:

   $Math::FresnelZone::KILOMETERS_IN_A_MILE  (Default is 1.609344)
   $Math::FresnelZone::FEET_IN_A_METER (Defualt is 3.280839)

Feel free to change them if you need more or less than six decimal places and/or want really inaccurate results :)

=head1 SEE ALSO

To find out more about the fresnel zone (pronounced fray-NELL) you can google the man who this formula/zone is named after to learn more: Augustin Jean Fresnel.

Mr. Fresnel was a French physicist who supported the wave theory of light, investigated polarized light, 
and developed a compound lens for use in lighthouses (IE the "Fresnel lens") (1788-1827).

Also googling the phrase "Fresnel Zone" turns up some interesting glossary refernces to what the fresnel zone is.

Here is a link to an image illustrating what a fresnel zone is and the formula:
L<http://drmuey.com/images/fresnelzone.jpg>

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl> 

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
