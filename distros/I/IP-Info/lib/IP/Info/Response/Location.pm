package IP::Info::Response::Location;

$IP::Info::Response::Location::VERSION   = '0.18';
$IP::Info::Response::Location::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

IP::Info::Response::Location - Placeholder for Location for the module L<IP::Info::Response>.

=head1 VERSION

Version 0.18

=cut

use Data::Dumper;

use Moo;
use namespace::clean;

has 'country_code'=> (is => 'ro');
has 'country_cf'  => (is => 'ro');
has 'country'     => (is => 'ro');
has 'city_cf'     => (is => 'ro');
has 'city'        => (is => 'ro');
has 'postal_code' => (is => 'ro');
has 'time_zone'   => (is => 'ro');
has 'area_code'   => (is => 'ro');
has 'state_code'  => (is => 'ro');
has 'state_cf'    => (is => 'ro');
has 'state'       => (is => 'ro');
has 'continent'   => (is => 'ro');
has 'longitude'   => (is => 'ro');
has 'latitude'    => (is => 'ro');
has 'region'      => (is => 'ro');
has 'msa'         => (is => 'ro');
has 'dma'         => (is => 'ro');

sub BUILD {
    my ($self, $param) = @_;

    $self->{country}      = $param->{CountryData}->{country};
    $self->{country_cf}   = $param->{CountryData}->{country_cf};
    $self->{country_code} = $param->{CountryData}->{country_code};

    $self->{state}        = $param->{StateData}->{state};
    $self->{state_cf}     = $param->{StateData}->{state_cf};
    $self->{state_code}   = $param->{StateData}->{state_code};

    $self->{city}         = $param->{CityData}->{city};
    $self->{city_cf}      = $param->{CityData}->{city_cf};
    $self->{postal_code}  = $param->{CityData}->{postal_code};
    $self->{area_code}    = $param->{CityData}->{area_code};
    $self->{time_zone}    = $param->{CityData}->{time_zone};
}

=head1 METHODS

=head2 longitute()

Returns the IP Location Longitude.

=head2 latitude()

Returns the IP Location Latitude.

=head2 city_cf()

Returns the IP Location City CF.

=head2 city()

Returns the IP Location City.

=head2 postal_code()

Returns the IP Location Postal Code.

=head2 time_zone()

Returns the IP Location Time Zone.

=head2 area_code()

Returns the IP Location Area Code.

=head2 region()

Returns the IP Location Region.

=head2 continent()

Returns the IP Location Continent.

=head2 state_code()

Returns the IP Location State Code.

=head2 state_cf()

Returns the IP Location State CF.

=head2 state()

Returns the IP Location State.

=head2 country_code()

Returns the IP Location Country Code.

=head2 country_cf()

Returns the IP Location Country CF.

=head2 country()

Returns the IP Location Country.

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/IP-Info>

=head1 BUGS

Please  report  any  bugs or feature requests to C<bug-ip-info at rt.cpan.org> or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IP-Info>.
I will be notified and then you'll automatically be notified of  progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IP::Info::Response::Location

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IP-Info>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IP-Info>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IP-Info>

=item * Search CPAN

L<http://search.cpan.org/dist/IP-Info/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2016 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of IP::Info::Response::Location
