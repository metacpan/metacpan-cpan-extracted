package Marketplace::Rakuten;

use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base qw(Str);
use HTTP::Tiny;
use Marketplace::Rakuten::Response;
use Marketplace::Rakuten::Order;
use Marketplace::Rakuten::Utils;
use namespace::clean;

=head1 NAME

Marketplace::Rakuten - Interface to http://webservice.rakuten.de/documentation

=head1 VERSION

Version 0.04

=head1 CATEGORIES

The list of categories for the German marketplace can be downloaded from
the L<http://api.rakuten.de/categories/csv/download>.

When adding or editing a product, you can pass the
C<rakuten_category_id> to C<add_product> or C<edit_product>

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

    use Marketplace::Rakuten;
    my $rakuten = Marketplace::Rakuten->new(key => 'xxxxxxx',
                                            endpoint => 'http://webservice.rakuten.de/merchants/'
                                            );
    my $res = $rakuten->get_key_info;

=head1 ACCESSORS

=head2 key

The API key (required).

=head2 endpoint

The URL of the endpoint. Default to http://webservice.rakuten.de/merchants/

If you need a specific api version, it could be something like http://webservice.rakuten.de/v2.05/merchants

=head2 ua

The user-agent. Built lazily.

=cut

has key => (is => 'ro',
            required => 1,
            isa => Str);

has endpoint => (is => 'ro',
                 default => sub { 'http://webservice.rakuten.de/merchants/' });

has ua => (is => 'lazy');

sub _build_ua {
    return HTTP::Tiny->new;
}


=head1 METHODS

=head2 api_call($method, $call, $data);

Generic method to do any call. The first argument is the HTTP request
method (get or post). The second argument is the path of the api, e.g.
(C<misc/getKeyInfo>). The third is the structure to send (an hashref).

Return a Marketplace::Rakuten::Response object.

The key is injected into the data hashref in any case.

=head2 API CALLS

=head3 Miscellaneous

=over 4

=item  get_key_info

=back

=head3 Product creation

=over 4

=item add_product(\%data)

L<http://webservice.rakuten.de/documentation/method/add_product>

Mandatory params: C<name>, C<price>, C<description>

Recommended: C<product_art_no> (the sku)

Return hashref: C<product_id>

=item add_product_image(\%data)

L<http://webservice.rakuten.de/documentation/method/add_product_image>

Mandatory params: C<product_art_no> (the sku) or C<product_id>
(rakuten id).

Return hashref: C<image_id>

=item add_product_variant(\%data)

L<http://webservice.rakuten.de/documentation/method/add_product_variant>

Mandatory params: C<product_art_no> (the sku) or C<product_id>,
C<price>, C<color>, C<label>

Return hashref: C<variant_id>

=item add_product_variant_definition

L<http://webservice.rakuten.de/documentation/method/add_product_variant>

Mandatory params: C<product_art_no> (the sku) or C<product_id>

Recommended: C<variant_1> Size C<variant_2> Color

You need to call this method before trying to upload variants. The
data returned are however just a boolean (kind of) success.

=item add_product_multi_variant

L<http://webservice.rakuten.de/documentation/method/add_product_multi_variant>

Mandatory params: C<product_art_no> (the sku) or C<product_id>, C<variation1_type>, C<variation1_value>, C<price>

Recommended: C<variant_art_no>

Return hashref: C<variant_id>

=item add_product_link

L<http://webservice.rakuten.de/documentation/method/add_product_link>

Mandatory params: C<product_art_no> (the sku) or C<product_id>,
C<name> (100 chars), C<url> (255 chars)

Return hashref: C<link_id>

=item add_product_attribute

L<http://webservice.rakuten.de/documentation/method/add_product_attribute>

Mandatory params: C<product_art_no> (the sku) or C<product_id>,
C<title> (50 chars), C<value>

Return hashref: C<attribute_id>

=back

=cut

sub api_call {
    my ($self, $method, $call, $data) = @_;
    die "Missing method argument" unless $method;
    die "Missing call name" unless $call;

    # populate the data and inject the key
    $data ||= {};
    $data->{key} = $self->key;


    my $ua = $self->ua;
    my $url = $self->endpoint;
    $url =~ s/\/$//;
    $call =~ s/^\///;
    $url .= '/' . $call;

    my $response;
    $method = lc($method);

    if ($method eq 'get') {
        my $params = $ua->www_form_urlencode($data);
        $url .= '?' . $params;
        $response = $ua->get($url);
    }
    elsif ($method eq 'post') {
        $response = $ua->post_form($url, $data);
    }
    else {
        die "Unsupported method $method";
    }
    die "HTTP::Tiny failed to provide a response!" unless $response;
    return Marketplace::Rakuten::Response->new(%$response);
}

sub get_key_info {
    my ($self, $data) = @_;
    $self->api_call(get  => 'misc/getKeyInfo')
}

sub add_product {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/addProduct', $data);
}

sub add_product_image {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/addProductImage', $data);
}

sub add_product_variant {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/addProductVariant', $data);
}

sub add_product_variant_definition {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/addProductVariantDefinition', $data);
}

sub add_product_multi_variant {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/addProductMultiVariant', $data);
}

sub add_product_link {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/addProductLink', $data);
}

sub add_product_attribute {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/addProductAttribute', $data);
}

# unclear what cross-selling is, so leaving it out.

# addProductToShopCategory is referring to an unknown
# shop_category_id, leaving it out for now.


=head3 Product editing

The following methods require and id passed (sku or id) and work the
same as for product adding, but no argument is mandatory.

They all return just a structure with a boolean success (-1 is
failure, 1 is success).

=over 4

=item edit_product(\%data)

Requires C<product_id> or C<product_art_no>

=item edit_product_variant(\%data);

Requires C<variant_id> or C<variant_art_no>

=item edit_product_variant_definition(\%data)

Requires C<product_id> or C<product_art_no>

=item edit_product_multi_variant(\%data);

Requires C<variant_id> or C<variant_art_no>

=item edit_product_attribute

Requires C<attribute_id>, C<title>, C<value>

=back

=cut

sub edit_product {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/editProduct', $data);
}

sub edit_product_variant {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/editProductVariant', $data);
}

sub edit_product_variant_definition {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/editProductVariantDefinition', $data);
}

sub edit_product_multi_variant {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/editProductMultiVariant', $data);
}

sub edit_product_attribute {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/editProductAttribute', $data);
}

=head3 Product deletion

The following methods require just an id or sku. Return a boolean success.

=over 4

=item delete_product(\%data)

Requires C<product_id> or C<product_art_no>

=item delete_product_variant(\%data);

Requires C<variant_id> or C<variant_art_no>

=item delete_product_image(\%data)

Requires C<image_id> (returned by add_product_image).

=item delete_product_link(\%data);

Requires C<link_id> (returned by add_product_link).

=item delete_product_attribute

Requires C<attribute_id> (returned by add_product_attribute).

=back

=cut

sub delete_product {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/deleteProduct', $data);
}

sub delete_product_variant {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/deleteProductVariant', $data);
}

sub delete_product_image {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/deleteProductImage', $data);
}

sub delete_product_link {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/deleteProductLink', $data);
}

sub delete_product_attribute {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/deleteProductAttribute', $data);
}

=head3 Orders

=over 4

=item get_orders(\%params)

No argument is required, but you probably want to pass something like

 { status => pending }

See L<http://webservice.rakuten.de/documentation/method/get_orders>
for the full list of options.

List of statuses:

=over 4

=item pending

=item editable

This is what you want to get for importing.

=item shipped

=item payout

Order is paid. Unclear when the status switches to this one.

=item cancelled

=back

The response is paginated and from here you get only the raw data.

Use get_parsed_orders to get the full list of objects.

=item get_parsed_orders(\%params)

The hashref with the parameters is the same of C<get_orders> (which
get called). This method takes care of the pagination and return a
list of L<Marketplace::Rakuten::Order> objects. You can access the raw
structures with $object->order.

=item get_pending_orders

Shortcut for $self->get_parsed_orders({ status => 'pending' });

=item get_editable_orders

Shortcut for $self->get_parsed_orders({ status => 'editable' });

=cut


sub get_orders {
    my ($self, $data) = @_;
    $self->api_call(get => 'orders/getOrders', $data);
}

sub get_pending_orders {
    my ($self) = @_;
    return $self->get_parsed_orders({ status => 'pending' });
}

sub get_editable_orders {
    my ($self) = @_;
    return $self->get_parsed_orders({ status => 'editable' });
}


sub get_parsed_orders {
    my ($self, $params) = @_;
    $params ||= {};
    my $res = $self->get_orders($params);
    die "Couldn't retrieve orders: " . Dumper($res->errors)
      unless $res->is_success;
    my $data = $res->data;
    my @orders = $self->_parse_orders($data);
    # print Dumper(\@orders);
    # print Dumper($res);
    while ($data->{orders} and
           $data->{orders}->{paging}->{pages}    and
           $data->{orders}->{paging}->{page}     and
           $data->{orders}->{paging}->{per_page} and
           $data->{orders}->{paging}->{pages} > $data->{orders}->{paging}->{page}) {
        my $next_page = $data->{orders}->{paging}->{page} + 1;
        my $per_page = $data->{orders}->{paging}->{per_page};
        $res = $self->get_orders({
                                  %$params,
                                  page => $next_page,
                                  per_page => $per_page
                                 });
        $data = $res->data;
        push @orders, $self->_parse_orders($data);
    }
    return @orders;
}

sub _parse_orders {
    my ($self, $struct) = @_;
    my @out;
    if ($struct->{orders}) {
        if (my $orders = $struct->{orders}->{order}) {
            foreach my $order (@$orders) {
                my $struct = { %$order };
                Marketplace::Rakuten::Utils::turn_empty_hashrefs_into_empty_strings($struct);
                push @out, Marketplace::Rakuten::Order->new(order => $struct);
            }
        }
    }
    return @out;
}


=item set_order_shipped(\%params)

Required parameter: order_no (the rakuten's order number).

Accepted parameters:

=over 4 

=item dhl (boolean, true if Rakuten-DHL-Rahmenvertrag is used)

=item carrier

=item tracking_number

=item tracking_url

=back

=cut

sub set_order_shipped {
    my ($self, $data) = @_;
    $self->api_call(post => 'orders/setOrderShipped', $data);
}

=item set_order_cancelled(\%params)

Required paramater: C<order_no> (rakuten's order number)

Optional: C<comment>

=cut

sub set_order_cancelled {
    my ($self, $data) = @_;
    $self->api_call(post => 'orders/setOrderCancelled', $data);
}

=item set_order_returned(\%params)

Required paramater: C<order_no> (rakuten's order number) and C<type>
(C<fully> or C<partly>):

L<http://webservice.rakuten.de/documentation/method/set_order_returned>

=back

=cut


sub set_order_returned {
    my ($self, $data) = @_;
    $self->api_call(post => 'orders/setOrderReturned', $data);
}

=head3 Category management

=over 4

=item add_shop_category(\%params)

Required parameter: C<name>

L<http://webservice.rakuten.de/documentation/method/add_shop_category>

Returned: C<shop_category_id>

=item edit_shop_category(\%params)

Required parameter C<shop_category_id> or C<external_shop_category_id>

L<http://webservice.rakuten.de/documentation/method/edit_shop_category>

=item get_shop_categories

No mandatory parameter.

L<http://webservice.rakuten.de/documentation/method/get_shop_categories>

=item delete_shop_category

Required parameter C<shop_category_id> or C<external_shop_category_id>

L<http://webservice.rakuten.de/documentation/method/delete_shop_category>

=item add_product_to_shop_category

Required parameters: C<shop_category_id> or C<external_shop_category_id>,
  C<product_id> or C<product_art_no> (Rakuten's id or our sku).

L<http://webservice.rakuten.de/documentation/method/add_product_to_shop_category>

=back

=cut

sub add_shop_category {
    my ($self, $data) = @_;
    $self->api_call(post => 'categories/addShopCategory', $data);
}

sub edit_shop_category {
    my ($self, $data) = @_;
    $self->api_call(post => 'categories/editShopCategory', $data);
}

sub get_shop_categories {
    my ($self, $data) = @_;
    $self->api_call(get => 'categories/getShopCategories', $data);
}

sub delete_shop_category {
    my ($self, $data) = @_;
    $self->api_call(post => 'categories/deleteShopCategory', $data);
}

sub add_product_to_shop_category {
    my ($self, $data) = @_;
    $self->api_call(post => 'products/addProductToShopCategory', $data);
}

=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-marketplace-rakuten at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Marketplace-Rakuten>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Marketplace::Rakuten


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Marketplace-Rakuten>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Marketplace-Rakuten>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Marketplace-Rakuten>

=item * Search CPAN

L<http://search.cpan.org/dist/Marketplace-Rakuten/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Marco Pessotto.

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

1; # End of Marketplace::Rakuten
