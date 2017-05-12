package Megaport::Ports;
use parent 'Megaport::Internal::_Result';

use 5.10.0;
use strict;
use warnings;

use Class::Tiny {
  _request => {
    pkey => 'productUid',
    method => 'GET',
    path => '/dropdowns/partner/megaports'
  }
};

1;
__END__
=encoding utf-8
=head1 NAME

Megaport::Ports

=head1 DESCRIPTION

This provide a simple read-only list of Megaport "partner ports". Details about the objects returned by the API can be found L<here|https://dev.megaport.com/#lists-used-for-ordering-partner-megaports>.

=head3 Partner Ports

In Megaport terminology, a partner port is a Megaport service that is active on the network which is a valid target for VXC orders. Not all Megaport POPs are interconnected, there is the concept of C<networkRegion> which defines which locations are accessible to each other.

This endpoint provides a C<locationId> for each service but doesn't indicate the C<networkRegion>. For now, this will need to be handled in application code.

=head1 METHODS

=head2 list

    # Optional array or arrayref
    my @list = $ports->list;
    my $list = $ports->list;

    # Use search terms to find a partial list
    my @telx_nyc2 = $ports->list(locationId => 78);
    my @google_cloud = $ports->list(companyUid => '29ba879b-45c8-48eb-bd97-618d0f20ea04');

    # Or use a regexp to get a bit fancy
    my @amsix = $ports->list(companyName => qr/^AMS-IX/);

Returns a list or allows searching based on any field present in the object.

=head2 get

    # id is an alias for productUid
    my $azure_wash_dc = $ports->get(id => '4695b867-84ad-48b4-bf25-fca26c443f2c');

Best used to search by C<id> but as with L<list/list>, any field can be used. This method uses L<List::Util/first> to return the first matching entry. The data is stored in a hash internally so the keys are unordered. Using this method with a search term like C<companyUid> will yield unexpected results.

=head1 AUTHOR

Cameron Daniel E<lt>cdaniel@cpan.orgE<gt>

=cut
