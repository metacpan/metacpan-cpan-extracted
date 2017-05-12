package Google::Checkout::General::AddressFilters;

=head1 NAME

Google::Checkout::General::AddressFilters

=head1 SYNOPSIS

  use Google::Checkout::XML::Constants;
  use Google::Checkout::General::ShippingRestrictions;
  use Google::Checkout::General::MerchantCalculatedShipping;

  my $address_filters = Google::Checkout::General::AddressFilters->new(
                    allowed_zip           => ["94*"],
                    excluded_zip          => ["90*"],
                    excluded_country_area => [Google::Checkout::XML::Constants::FULL_50_STATES]);

  my $custom_shipping = Google::Checkout::General::MerchantCalculatedShipping->new(
                        price         => 45.99,
                        address_filters   => $address_filters,
                        shipping_name => "Custom shipping");

=head1 DESCRIPTION

This module is used to define shipping address-filters which can then
be added as part of a shipping method.

=over 4

=item new HASH

Constructor. Takes a hash as its argument with the following keys: 
ALLOWED_STATE, array reference of allowed states; ALLOWED_ZIP, array
reference of allowed zip code; ALLOWED_COUNTRY_AREA, array reference
of allowed country area; EXCLUDED_STATE, array reference of excluded
states; EXCLUDED_ZIP, array reference of excluded zip codes;
EXCLUDED_COUNTRY_AREA, array reference of excluded country area;
ALLOWED_ALLOW_US_PO_BOX, true or false to enable PO Box addresses;
ALLOWED_WORLD_AREA true or false to enable international shipping;
ALLOWED_POSTAL_AREA, array reference of allowed countries. For
ALLOWED_ZIP and EXCLUDED_ZIP, it's possible to use the wildcard 
operator (*) to specify a range of zip codes as in "94*" for all zip
codes starting with "94".

=item get_allowed_state 

Returns the allowed states (array reference).

=item add_allowed_state STATE

Adds another allowed state.

=item get_allowed_zip 

Returns the allowed zip codes (array reference).

=item add_allowed_zip ZIP

Adds another allowed zip code. Zip code can
have the wildcard operator to specify a range
of zip codes.

=item get_allowed_country_area

Returns the allowed country area (array reference).

=item add_allowed_country_area AREA

Adds another allowed country area. Currently, the 
only supported country area is C<Google::Checkout::XML::Constants::FULL_50_STATES>.

=item get_excluded_state

Returns the excluded states (array reference).

=item add_excluded_state STATE

Adds another excluded state.

=item get_excluded_zip

Returns the excluded zip codes (array reference).

=item add_excluded_zip ZIP

Adds another excluded zip code. Zip code can
have the wildcard operator to specify a range
of zip codes.

=item add_excluded_country_area AREA

Adds another excluded country area.

=item add_allowed_allow_us_po_box BOOLEAN

Set weather or not US PO Box addresses are allowed

=item get_allowed_allow_us_po_box

Returns true, false, or undefined if this has not been set

=item add_allowed_world_area BOOLEAN

Enables international shipping by setting the world_area value

=item get_allowed_world_area

Returns true or undefined

=item get_allowed_postal_area

Returns the allowed postal area (array reference).

=item add_allowed_postal_area AREA

Add a postal area

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::General::ShippingRestrictions

=cut

#--
#-- <address-filters> ... </address-filters>
#--

use strict;
use warnings;

use Google::Checkout::General::ShippingRestrictions;
our @ISA = qw/Google::Checkout::General::ShippingRestrictions/;


1;
