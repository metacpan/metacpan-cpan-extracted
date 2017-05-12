package Google::Checkout::General::TaxTable;

=head1 NAME

Google::Checkout::General::TaxTable

=head1 SYNOPSIS

  use Google::Checkout::XML::Constants;
  use Google::Checkout::General::TaxRule;
  use Google::Checkout::General::TaxTable;
  use Google::Checkout::General::TaxTableArea;
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

This module is used to create tax table which can then be
added to C<Google::Checkout::General::MerchantCheckoutFlow>.

=over 4

=item new DEFAULT => ..., NAME => ..., STANDALONE => ..., RULES => ...

Constructor. If DEFAULT is true, this will be the default tax table.
Otherwise, NAME can be used to selectively apply different tax table
to different merchant items. If STANDALONE is true, this tax table
can be used as standalone. RULES should be an array reference of 
C<Google::Checkout::General::TaxRule>.

=item is_default FLAG

FLAG is optional and if passed in, it will be used to set whether
or not this is the default tax table. After the flag is set,
the old value is returned. If FLAG is not passed in, the current
value is returned.

=item get_name

Returns the name of the tax table.

=item set_name NAME

Sets the name of the tax table.

=item get_standalone

Returns the string 'true' if this tax table can be used as
standalone. Returns the string 'false' otherwise.

=item set_standalone FLAG

If FLAG is true, the tax table can be standalone. Otherwise,
it's not standalone.

=item get_tax_rules

Returns an array reference of all tax rules. Each element is
an object of C<Google::Checkout::General::TaxRule>.

=item add_tax_rule RULE

Adds another C<Google::Checkout::General::TaxRule>.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::General::TaxRule
Google::Checkout::General::MerchantCheckoutFlow

=cut

use strict;
use warnings;

sub new 
{
  my ($class, %args) = @_;

  my $self = {default      => $args{default},
              name         => $args{name} || '',
              standalone   => $args{standalone} ? 'true' : 'false'};

  $self->{rules} = $args{rules} if $args{rules};

  return bless $self => $class;
}

sub is_default 
{
  my ($self, $data) = @_;

  my $oldv = $self->{default};

  $self->{default} = $data if @_ > 1;

  return $oldv;
}

sub get_name 
{
  my ($self) = @_;
 
  return $self->{name}; 
}

sub set_name
{
  my ($self, $name) = @_;

  $self->{name} = $name if $name;
}

sub get_standalone 
{
  my ($self) = @_; 

  return $self->{standalone}; 
}

sub set_standalone
{
  my ($self, $value) = @_;

  $self->{standalone} = $value ? 'true' : 'false';
}

sub get_tax_rules 
{ 
  my ($self) = @_;

  return $self->{rules}; 
}

sub add_tax_rule
{
  my ($self, $rule) = @_;

  push(@{$self->{rules}}, $rule) if $rule;
}

1;
