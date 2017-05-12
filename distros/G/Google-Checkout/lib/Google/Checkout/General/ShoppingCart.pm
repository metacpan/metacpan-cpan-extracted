package Google::Checkout::General::ShoppingCart;

=head1 NAME

Google::Checkout::General::ShoppingCart

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::General::ShoppingCart;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $cart = Google::Checkout::General::ShoppingCart->new(
             expiration    => "+1 month",
             private       => "Private data",
             checkout_flow => $checkout_flow);

  my $response = Google::Checkout::General::GCO->new->checkout($cart);

  die $response if is_gco_error $response;

  #--
  #-- Redirect URL
  #--
  print $response,"\n";

=head1 DESCRIPTION

This module is responsible for writing the <shopping-cart> XML.

=over 4

=item new EXPIRATION => ..., PRIVATE => ..., CHECKOUT_FLOW => ...

Constructor. EXPIRATION can be any valid date/time string 
recognized by C<Date::Manip>. PRIVATE can be any custom private
data provided by the merchant. CHECKOUT_FLOW should be a 
C<Google::Checkout::General::MerchantCheckoutFlow> object.

=item get_expiration

Returns the expiration time for this shopping cart.

=item set_expiration DATE_TIME_STRING

Sets the expiration date for this shopping cart. DATE_TIME_STRING
can be anything recognized by the C<Date::Manip> module. 
C<perldoc Date::Manip> for more detail.

=item get_private

Returns the private data (as array reference).

=item add_private PRIVATE_DATA

Adds another private data to the shopping cart.

=item get_items

Returns all the merchant items added to this
shopping cart so far. It's returned as an array
reference where each element is an object of 
C<Google::Checkout::General::MerchantItem>.

=item add_item ITEM

Adds another merchant item to the shopping cart.
ITEM should be an object of C<Google::Checkout::General::MerchantItem>.

=item get_checkout_flow

Returns the C<Google::Checkout::General::MerchantCheckoutFlow> object.

=item set_checkout_flow

Sets the C<Google::Checkout::General::MerchantCheckoutFlow> object.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::General::MerchantItem
Google::Checkout::General::MerchantCheckoutFlow

=cut

#--
#--  <shopping-cart>...</shopping-cart> 
#--

use strict;
use warnings;

use Google::Checkout::General::Util qw/date_time_string is_gco_error is_merchant_item/;

sub new 
{
  my ($class, %args) = @_;

  my $self = {};
  if ($args{expiration})
  {
    my $date_time = date_time_string($args{expiration});

    $self->{expiration} = $date_time unless is_gco_error($date_time);
  }

  if (defined $args{private})
  {
    if (ref $args{private})
    {
      for my $note (grep $_ ne '', @{$args{private}})
      {
        push(@{$self->{private}}, $note);
      }
    }
    else
    {
      push(@{$self->{private}}, $args{private});
    }
  }

  $self->{checkout_flow} = $args{checkout_flow} if defined $args{checkout_flow};

  return bless $self => $class;
}

sub get_expiration 
{ 
  my ($self) = @_;

  return $self->{expiration}; 
}

sub set_expiration 
{
  my ($self, $data) = @_;
  my $date_time = date_time_string($data);

  $self->{expiration} = $date_time unless is_gco_error($date_time);
}

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

sub get_items
{
  my ($self) = @_;
  
  return exists $self->{items} ? $self->{items} : [];
}

sub add_item
{
  my ($self, $item) = @_;

  push(@{$self->{items}}, $item) if is_merchant_item($item);
}

sub get_checkout_flow() 
{ 
  my ($self) = @_;

  return $self->{checkout_flow}; 
}

sub set_checkout_flow() 
{ 
  my ($self, $data) = @_;

  $self->{checkout_flow} = $data if defined $data;
}

1;
