
#_{ Encoding and name
=encoding utf8
=head1 NAME

Geo::Coordinates::Converter::LV03 - Convert Swiss LV03 coordinates to WSG84 and vice versa

=cut
package Geo::Coordinates::Converter::LV03;


use strict;
use warnings;
use utf8;
 #_}
#_{ Version
=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';
#_}
#_{ Synopsis
=head1 SYNOPSIS

    use Geo::Coordinates::Converter::LV03;

    my ($x, $y) = Geo::Coordinates::Converter::LV03::lat_lng_2_y_x($φ, $λ);
    my ($φ, $λ) = Geo::Coordinates::Converter::LV03::y_x_2_lat_lng($x, $y);
   
=cut
 #_}
#_{ Export
=head1 EXPORT

On request, C<lat_lng_2_y_x> and C<y_x_2_lat_lng> are exported:

    use Geo::Coordinates::Converter::LV03 qw(lat_lng_2_y_x y_x_2_lat_lng);

    my ($x, $y) = lat_lng_2_y_x($φ, $λ);
    my ($φ, $λ) = y_x_2_lat_lng($x, $y);


=head1 SUBROUTINES/METHODS
=cut

use Exporter qw(import);
use vars qw(@ISA @EXPORT_OK);
@ISA = 'Exporter';
@EXPORT_OK = qw(lat_lng_2_y_x y_x_2_lat_lng);

#_}
#_{ Methods
sub lat_lng_2_y_x { #_{
#_{ POD

=head2 lat_lng_2_y_x($lat, $lng)

Convert a latitude/longitude tuple to a Swiss LV03 datum.

Note: the Swiss seem to name the east-west axis by B<Y> and the
the north-south axis by B<X>. Hence the strangly order of C<y> and C<x> in the sub's name.

=cut
#_}

#  https://www.swisstopo.admin.ch/content/swisstopo-internet/de/online/calculation-services/_jcr_content/contentPar/tabs/items/dokumente_und_publik/tabPar/downloadlist/downloadItems/7_1467103072612.download/ch1903wgs84de.pdf
#
#  Note: $x is in north south direction, $y in east west direction!
#  But they are returned as ($y, $x)...

  my $φ = shift; # Breite
  my $λ = shift; # Länge

# φ und λ sind in Sexagesimalsekunden umzuwandeln:
  $φ *= 3600;
  $λ *= 3600;

# Hilfsgrössen (Breiten- und Längendifferenz gegenüber Bern in der Einheit [10000"]) berechnen:
  my $φ_ = ($φ - 169_028.66) / 10_000;
  my $λ_ = ($λ -  26_782.5 ) / 10_000;

  my $φ2 = $φ_ * $φ_;
  my $λ2 = $λ_ * $λ_;
  my $φ3 = $φ2 * $φ_;
  my $λ3 = $λ2 * $λ_;

  my $y = 600_072.37                 +
          211_455.93 * $λ_           - 
           10_938.51 * $λ_ * $φ_     -
                0.36 * $λ_ * $φ2     - 
               44.54 * $λ3;

  my $x = 200_147.07                 + 
          308_807.95 *       $φ_     +
            3_745.25 * $λ2           +
               76.63 *       $φ2     -
              194.56 * $λ2 * $φ_     +
              119.79 *       $φ3;


   
  return ($y, $x);
} #_}
sub y_x_2_lat_lng { #_{

=head2 y_x_2_lat_lng($y, $x)

Convert a Swiss LV03 datum to a latitude and longitude tuple.

Note: the Swiss seem to name the east-west axis by B<Y> and the
the north-south axis by B<X>. Hence, the first argument is named C<y>, the second C<x>.

=cut

  my $y = shift;  # Rechtswert
  my $x = shift;  # Hochwert

# Die Projektionskoordinaten y und x sind ins zivile System (Bern = 0 / 0) und in die Einheit [1000 km] umzuwandeln:

  my $y_ = ($y - 600_000) / 1_000_000;
  my $x_ = ($x - 200_000) / 1_000_000;

# Lange und Breite in der Einheit [10000"] berechnen:

  my $y2 = $y_*$y_;
  my $y3 = $y2*$y_;

  my $x2 = $x_*$x_;
  my $x3 = $x2*$x_;

  my $λ_ =  2.677_9094                 +
            4.728_982   * $y_          +
            0.791_484   * $y_ * $x_    +
            0.130_6     * $y_ * $x2    -
            0.043_6     * $y3;

  my $φ_ = 16.902_3892                 +
            3.238_272         * $x_    -
            0.270_978   * $y2          -
            0.002_528         * $x2    -
            0.044_7     * $y2 * $x_    -
            0.014_0           * $x3;

# Umrechnen in ° Einheit
  my $φ = $φ_ * 100 / 36;
  my $λ = $λ_ * 100 / 36;

  return ($φ, $λ);

} #_}
#_}
#_{ Warning

=head1 WARNING

The document from which I derived the formulas (see LINKS) contains
this friendly warning; »I<Diese Formeln haben eine reduzierte Genauigkeit und sind
vor allem für Navigationszwecke vorgesehen. Sie dürfen nicht für die amtliche Vermessung oder für geodätische Anwendungen verwendet werden!>« (that is: only to be used for navigational purposes,
not of exact (or even official) measurements or geodatic applications).

=cut
#_}
#_{ Why
=head1 WHY

Why was I not using the already existing L<Geo::Coordinates::Converter|https://metacpan.org/pod/Geo::Coordinates::Converter>?

I tried, but that module's code seemed too hard and esoteric to extend. So I made this module a seperate one.

=cut
#_}
#_{ Author
=head1 AUTHOR

René Nyffenegger, C<< <rene.nyffenegger at adp-gmbh.ch> >>

=cut
#_}
#_{ See also
=head1 SEE ALSO

L<https://www.swisstopo.admin.ch/content/swisstopo-internet/de/online/calculation-services/_jcr_content/contentPar/tabs/items/dokumente_und_publik/tabPar/downloadlist/downloadItems/7_1467103072612.download/ch1903wgs84de.pdf>

L<< https://asciich.ch/wordpress/koordinatenumrechner-schweiz-international/ >>: A converter in javascript.

Fabien Fivaz's L<< wgs84_to_lv03.pl|https://github.com/ffivaz/wgs84_to_lv03 >>. Apparently, his script uses the online service at
L<< http://geodesy.geo.admin.ch/reframe/ >> to convert the coordinates.

=cut
#_}
#_{ Bugs and caveats
=head1 BUGS AND CAVEATS

The common order of using lattitude and longitude is first: lattitude, the longitude. lattitude goes in y-direction, longitude in x-direction. So,
they're in a different order than the usually known C<X> then C<y>. More gravely is the fact, that the C<x> in L</lat_lng_2_y_x> and in
L</y_x_2_lat_lng> is what usually is the C<y>, and vice versa. I should and might change that once. Then again, I might not find the time.

Please report any bugs or feature requests to C<bug-geo-coordinates-converter-lv03 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coordinates-Converter-LV03>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=cut
#_}
#_{ Source code
=head1 SOURCE CODE

The source code is in a L<github repository|https://github.com/ReneNyffenegger/Geo-Coordinates-Converter-LV03>. Meaningful pull requests are welcome.

=cut
#_}
#_{ License and Copyright
=head1 LICENSE AND COPYRIGHT

Copyright 2017 René Nyffenegger.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
#_}

'tq84';
