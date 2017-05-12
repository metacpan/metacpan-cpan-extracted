package Google::Checkout::General::TaxTableAreas;

=head1 NAME

Google::Checkout::General::TaxTableAreas

=head1 SYNOPSIS

  use Google::Checkout::XML::Constants;
  use Google::Checkout::General::TaxRule;
  use Google::Checkout::General::TaxTable;
  use Google::Checkout::General::TaxTableAreas;
  use Google::Checkout::General::MerchantCheckoutFlow;

  #--
  #-- Shipping tax set to 1 means shippings
  #-- are taxable and the rate is 2.5%. This
  #-- tax rule should apply to all 50 states
  #--
  my $tax_rule = Google::Checkout::General::TaxRule->new(
                 shipping_tax => 1,
                 rate => 0.025,
                 area => Google::Checkout::General::TaxTableAreas->new(
                         country => [Google::Checkout::XML::Constants::FULL_50_STATES]));

  #--
  #-- default tax table
  #--
  my $tax_table1 = Google::Checkout::General::TaxTable->new(
                   default => 1,
                   rules => [$tax_rule]);

  #--
  #-- same tax table but with a name
  #--
  my $tax_table2 = Google::Checkout::General::TaxTable->new(
                   default    => 0,
                   name       => "tax",
                   standalone => 1,
                   rules      => [$tax_rule]);

  my $checkout_flow = Google::Checkout::General::MerchantCheckoutFlow->new(
                      shipping_method       => [$flat_rate_shipping],
                      edit_cart_url         => "http://edit/cart/url",
                      continue_shopping_url => "http://continue/shopping/url",
                      buyer_phone           => "1-111-111-1111",
                      tax_table             => [$tax_table1,$tax_table2],
                      merchant_calculation  => $merchant_calculation);

=head1 DESCRIPTION

A sub-class of C<Google::Checkout::General::ShippingRestrictions>. 
This module is responsible for creating tax table areas which can 
then be added to C<Google::Checkout::General::TaxRule>.

=over 4

=item new STATE => ..., ZIP => ..., COUNTRY => ...

Constructor. Takes array reference of state, zip code
and country area where this tax table area will cover.

=item get_state

Returns an array reference of states.

=item add_state STATE

Adds another state.

=item get_zip

Returns an array reference of zip codes.

=item add_zip ZIP

Adds another zip code. Zip code might
contains wildcard operator to specify a 
range of zip codes.

=item get_country

Returns the country area.

=item add_country COUNTRY_AREA

Adds another country area. Currently, only 
C<Google::Checkout::XML::Constants::FULL_50_STATES> is supported.

=item get_country

Returns the country area.

=item add_postal POSTAL_AREA

Adds another postal area.

=item get_postal

Returns the postal area.

=item add_world BOOLEAN

Adds world area.

=item get_world

Returns 

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::General::TaxRule
Google::Checkout::General::ShippingRestrictions

=cut

use strict;
use warnings;

use Google::Checkout::General::ShippingRestrictions;
our @ISA = qw/Google::Checkout::General::ShippingRestrictions/;

sub new 
{
  my ($class, %args) = @_;

  my %translated;

  #--
  #-- States
  #--
  $translated{allowed_state}        = $args{state}   if $args{state};
  $translated{allowed_zip}          = $args{zip}     if $args{zip};
  $translated{allowed_country_area} = $args{country} if $args{country};
  $translated{allowed_postal_area}  = $args{postal}  if $args{postal};
  $translated{allowed_world_area}   = $args{world}   if $args{world};

  my $self = $class->SUPER::new(%translated);

  return bless $self => $class;
}

sub get_state   
{
  my ($self) = @_; 

  return $self->get_allowed_state;
}

sub get_zip     
{ 
  my ($self) = @_;

  return $self->get_allowed_zip;
}

sub get_country 
{ 
  my ($self) = @_;

  return $self->get_allowed_country_area; 
}

sub get_postal 
{ 
  my ($self) = @_;

  return $self->get_allowed_postal_area; 
}

sub get_world 
{ 
  my ($self) = @_;

  return $self->get_allowed_world_area; 
}

sub add_state   
{ 
  my ($self, $data) = @_;

  return $self->add_allowed_state($data);
}

sub add_zip     
{ 
  my ($self, $data) = @_;

  return $self->add_allowed_zip($data);
}

sub add_country 
{ 
  my ($self, $data) = @_;

  return $self->add_allowed_country_area($data);
}

sub add_postal
{ 
  my ($self, $data) = @_;

  return $self->add_allowed_postal_area($data);
}

sub add_world
{ 
  my ($self, $data) = @_;

  return $self->add_allowed_world_area($data);
}

1;
