package Google::Checkout::General::Shipping;

=head1 NAME

Google::Checkout::General::Shipping

=head1 DESCRIPTION

Parent class of C<Google::Checkout::General::FlatRateShipping>, 
C<Google::Checkout::General::Pickup>, and 
C<Google::Checkout::General::MerchantCalculatedShipping>. 
Normally, you won't need to use this module directly.

=over 4

=item new NAME => ..., SHIPPING_NAME => ..., PRICE => ..., RESTRICTION => ..., AddressFilters => ...

Constructor. NAME is used internally. SHIPPING_NAME is the name of the
shipping method. RPICE is the shipping charge and RESTRICTION is an object
of C<Google::Checkout::General::ShippingRestrictions> where shipping restrictions 
are defined. ADDRESS_FILTERS is an object of C<Google::Checkout::General::AddressFilters> 
where address filters are defined. Again, you probably won't need to use this module directly.

=item get_name

Returns the internally used name.

=item set_name NAME

Sets the internal name.

=item get_shipping_name

Returns the name of the shipping method.

=item set_shipping_name NAME

Sets the name of the shipping method.

=item get_price

Returns the charging price for this shipping method.

=item set_price PRICE

Sets the charging price for this shipping method.

=item get_address_filters

Returns the shipping address-filters: An object of
C<Google::Checkout::General::AddressFilters>.

=item set_address_filters ADDRESS_FILTERS

Sets the shipping address filters to ADDRESS_FILTERS: An object of
C<Google::Checkout::General::AddressFilters>.

=item get_restriction

Returns the shipping restrictions: An object of
C<Google::Checkout::General::ShippingRestrictions>.

=item set_restriction RESTRICTION

Sets the shipping restriction to RESTRICTION: An object of
C<Google::Checkout::General::ShippingRestrictions>.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::General::ShippingRestrictions

=cut

#--
#-- Parent for the various shipping classes
#--

use strict;
use warnings;

sub new 
{
  my ($class, %args) = @_;

  my $self = { name            => $args{name},
               shipping_name   => $args{shipping_name},
               price           => defined $args{price} ? $args{price} : -1,
               address_filters => $args{address_filters},
               restriction     => $args{restriction} };

  return bless $self => $class;
}

sub get_name 
{ 
  my ($self) = @_;

  return $self->{name}; 
}

sub set_name 
{ 
  my ($self, $data) = @_;

  $self->{name} = $data if defined $data;
}

sub get_shipping_name 
{
  my ($self) = @_;
 
  return $self->{shipping_name}; 
}

sub set_shipping_name 
{ 
  my ($self, $data) = @_;

  $self->{shipping_name} = $data if defined $data;
}

sub get_price 
{ 
  my ($self) = @_;

  return $self->{price}; 
}

sub set_price 
{ 
  my ($self, $data) = @_;

  $data->{price} = $data if defined $data;
}

sub get_address_filters 
{ 
  my ($self) = @_;

  return $self->{address_filters}; 
}

sub set_address_filters 
{ 
  my ($self, $data) = @_;

  $self->{address_filters} = $data if defined $data; 
}

sub get_restriction 
{ 
  my ($self) = @_;

  return $self->{restriction}; 
}

sub set_restriction 
{ 
  my ($self, $data) = @_;

  $self->{restriction} = $data if defined $data; 
}

1;
