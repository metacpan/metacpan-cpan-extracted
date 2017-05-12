package Google::Checkout::General::MerchantItem;

=head1 NAME

Google::Checkout::General::MerchantItem

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::General::ShoppingCart;
  use Google::Checkout::General::MerchantItem;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $checkout_flow = Google::Checkout::General::MerchantCheckoutFlow->new(
                      shipping_method       => [$method],
                      edit_cart_url         => "http://edit/cart/url",
                      continue_shopping_url => "http://continue/shopping/url",
                      buyer_phone           => "1-111-111-1111",
                      tax_table             => [$table1, $table2],
                      merchant_calculation  => $merchant_calculation);

  my $cart = Google::Checkout::General::ShoppingCart->new(
             expiration    => "+1 month",
             private       => "Private data",
             checkout_flow => $checkout_flow);

  my $item1 = Google::Checkout::General::MerchantItem->new(
              name               => "Test item 1",
              description        => "Test description 1",
              price              => 12.34,
              quantity           => 12,
              private            => "Item #1",
              tax_table_selector => "item");


  $cart->add_item($item1);

  my $response = Google::Checkout::General::GCO->new->checkout($cart);

  die $response if is_gco_error($response);

  #--
  #-- redirect URL
  #--
  print $response,"\n";

=head1 DESCRIPTION

This is the main class for constructing merchant items which buyer
will buy and checkout.

=over 4

=item new HASH

Constructor. The following arguments are required (if any one of them
is missing, a C<Google::Checkout::General::Error> object is returned instead): NAME, name of
the merchant item; DESCRIPTION, a description of the merchant item;
PRICE, price; QUANTITY, quantity to order. The following arguments are
optional: PRIVATE, private data provided by the merchant; 
TAX_TABLE_SELECTOR, name of the tax table used to calculate tax for
this merchant item.

=item get_name 

Returns the name of the merchant item.

=item set_name NAME

Sets the name of the merchant item.

=item get_description 

Returns the description of the merchant item.

=item set_description DESCRIPTION

sets the description of the merchant item.

=item get_price

Returns the price of the merchant item.

=item set_price PRICE

Sets the price of the merchant item.

=item get_quantity

Returns the quantity.

=item set_quantity QUANTITY

Sets the quantity.

=item get_private

Returns the private data. This mothod returns the
private data in an array reference.

=item add_private PRIVATE_DATA

Adds another piece of private data.

=item get_tax_table_selector

Returns the name of the tax table selector.

=item set_tax_table_selector SELECTOR

Sets the tax table to be used for this merchant item.

=item get_merchant_item_id

Returns the merchant item id

=item set_merchant_item_id ID

Sets the merchant item id

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::General::Error

=cut

#--
#--   <item>...</item> 
#--

use strict;
use warnings;

use Google::Checkout::General::Error;
use Google::Checkout::General::Util qw/date_time_string/;

sub new 
{
  my ($class, %args) = @_;

  #--
  #-- The followings are required so raise error if any of them are missing
  #--
  return Google::Checkout::General::Error->new(
    @{$Google::Checkout::General::Error::ERRORS{MISSING_ITEM_NAME}})        
      unless defined $args{name};

  return Google::Checkout::General::Error->new(
    @{$Google::Checkout::General::Error::ERRORS{MISSING_ITEM_DESCRIPTION}}) 
      unless defined $args{description};

  return Google::Checkout::General::Error->new(
    @{$Google::Checkout::General::Error::ERRORS{MISSING_ITEM_PRICE}})       
      unless defined $args{price};

  return Google::Checkout::General::Error->new(
    @{$Google::Checkout::General::Error::ERRORS{MISSING_ITEM_QUANTITY}})    
      unless defined $args{quantity};

  my $self = {name        => $args{name},
              description => $args{description},
              price       => $args{price},
              quantity    => $args{quantity} };

  #--
  #-- The followings are optional
  #--

  if (defined $args{private})
  {
    if (ref $args{private})
    {
      for my $note (grep $_ ne '', $args{private})
      {
        push(@{$self->{private}}, $note);
      }
    }
    else
    {
      if ($args{private} ne '') {
        push(@{$self->{private}}, $args{private});
      } else {
        $self->{private} = [];
      }
    }
  } else {
    $self->{private} = [];
  }

  $self->{tax_table_selector} = $args{tax_table_selector}
    if $args{tax_table_selector};

  #--
  #-- add merchant item id if there is one
  #--
  $self->{merchant_item_id} = $args{merchant_item_id}
    if $args{merchant_item_id};

  return bless $self => $class;
}

sub get_name        
{ 
  my ($self) = @_;

  return $self->{name}; 
}

sub get_description 
{ 
  my ($self) = @_;

  return $self->{description}; 
}

sub get_price       
{ 
  my ($self) = @_;

  return $self->{price}; 
}

sub get_quantity    
{ 
  my ($self) = @_;

  return $self->{quantity};
}

sub set_name        
{ 
  my ($self, $data) = @_;

  $self->{name} = $data if defined $data;
}

sub set_description 
{ 
  my ($self, $data) = @_;

  $data->{description} = $data if defined $data; 
}

sub set_price       
{ 
  my ($self, $data) = @_;

  $self->{price} = $data if defined $self;
}

sub set_quantity    
{ 
  my ($self, $data) = @_;

  $self->{quantity} = $data if defined $data;
}

#--
#-- The followings are optional
#--

sub get_private 
{ 
  my ($self) = @_;

  return $self->{private}; 
}

sub add_private
{
  my ($self, $private_data) = @_;

  push(@{$self->{private}}, $private_data) if defined $private_data && 
                                              $private_data ne '';
}

sub get_tax_table_selector 
{ 
  my ($self) = @_;

  return $self->{tax_table_selector}; 
}

sub set_tax_table_selector
{
  my ($self, $tax_table_selector) = @_;

  $self->{tax_table_selector} = $tax_table_selector 
    if defined $tax_table_selector;
}

sub get_merchant_item_id
{
  my ($self) = @_;

  return $self->{merchant_item_id};
}

sub set_merchant_item_id
{
  my ($self, $id) = @_;

  $self->{merchant_item_id} = $id if $id;
}

1;
