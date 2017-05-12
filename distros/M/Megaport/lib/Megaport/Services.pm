package Megaport::Services;
use parent 'Megaport::Internal::_Result';

use 5.10.0;
use strict;
use warnings;

use Class::Tiny {
  _request => {
    pkey => 'productUid',
    method => 'GET',
    path => '/products'
  }
};

1;
=encoding utf-8
=head1 NAME

Megaport::Services

=head1 DESCRIPTION

This provide a simple read-only list of Megaport services owned by the logged in account. Details about the objects returned by the API can be found L<here|https://dev.megaport.com/#general-get-product-list>.

=head1 METHODS

=head2 list

    # Optional array or arrayref
    my @list = $services->list;
    my $list = $services->list;

    # Use search terms to find a partial list
    my @fast = $services->list(portSpeed => 10000);
    my @merican = $services->list(market => 'US');

Returns a list or allows searching based on any field present in the object.

=head2 get

    my $gs_port = $services->get(id => 'my-product-uid');
    my $first = $services->get(name => 'My First Megaport');

Best used to search by C<id> but as with L<list/list>, any field can be used. This method uses L<List::Util/first> to return the first matching entry. The data is stored in a hash internally so the keys are unordered. Using this method with a search term like C<productType> will yield unexpected results.

=head1 AUTHOR

Cameron Daniel E<lt>cdaniel@cpan.orgE<gt>

=cut
