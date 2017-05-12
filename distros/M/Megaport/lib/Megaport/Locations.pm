package Megaport::Locations;
use parent 'Megaport::Internal::_Result';

use 5.10.0;
use strict;
use warnings;

use Class::Tiny {
  _request => {
    pkey => 'id',
    method => 'GET',
    path => '/locations'
  }
};

1;
__END__
=encoding utf-8
=head1 NAME

Megaport::Locations

=head1 DESCRIPTION

This provide a simple read-only list of Megaport on-net datacentres. Details about the objects returned by the API can be found L<here|https://dev.megaport.com/#lists-used-for-ordering-locations>.

=head1 METHODS

=head2 list

    # Optional array or arrayref
    my @list = $locations->list;
    my $list = $locations->list;

    # Use search terms to find a partial list
    my @oceania = $locations->list(networkRegion => 'ANZ');
    my @uk = $locations->list(country => 'United Kingdom');

    # Or use a regexp to get a bit fancy
    my @dlr = $locations->list(name => qr/^Digital Realty/);

Returns a list or allows searching based on any field present in the object.

=head2 get

    my $gs = $locations->get(id => 3);
    my $sy3 = $locations->get(name => 'Equinix SY3');

Best used to search by C<id> but as with L<list/list>, any field can be used. This method uses L<List::Util/first> to return the first matching entry. The data is stored in a hash internally so the keys are unordered. Using this method with a search term like C<country> will yield unexpected results.

=head1 AUTHOR

Cameron Daniel E<lt>cdaniel@cpan.orgE<gt>

=cut
