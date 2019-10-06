package IP::Info::Response;

$IP::Info::Response::VERSION   = '0.18';
$IP::Info::Response::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

IP::Info::Response - Response handler for the module IP::Info.

=head1 VERSION

Version 0.18

=cut

use Data::Dumper;

use Moo;
use namespace::clean;

=head1 DESCRIPTION

Response handler for the module IP::Info and exposes the response data to user.

=cut

has 'ip_address' => (is => 'rw', required => 1);
has 'ip_type'    => (is => 'rw', required => 1);
has 'network'    => (is => 'rw', required => 1);
has 'location'   => (is => 'rw', required => 1);

=head1 METHODS

=head2 ip_type()

Returns the IP Type.

=head2 ip_address()

Returns the IP address.

=head2 network()

Returns the object of type L<IP::Info::Response::Network>.

=head2 location()

Returns the object of type L<IP::Info::Response::Location>.

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

    perldoc IP::Info::Response

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

1; # End of IP::Info::Response
