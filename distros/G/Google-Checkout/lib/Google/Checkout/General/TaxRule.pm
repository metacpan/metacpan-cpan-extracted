package Google::Checkout::General::TaxRule;

=head1 NAME

Google::Checkout::General::TaxRule

=head1 SYNOPSIS

  use Google::Checkout::XML::Constants;
  use Google::Checkout::General::TaxRule;
  use Google::Checkout::General::TaxTableAreas;
 
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

=head1 DESCRIPTION

This module is responsible for creating text rule which 
can then be added to a tax table (C<Google::Checkout::General::TaxTable>).

=over 4

=item new SHIPPING_TAX => ..., RATE => ..., AREA => ...

Constructor. If SHIPPING_TAX is true, it means the shipping
is taxable and the tax rate should be RATE. AREA should be 
an object of C<Google::Checkout::General::TaxTableAreas> specifying 
where this tax rule should be applied to.

=item get_rate

Returns the tax rate.

=item set_rate RATE

Sets the tax rate.

=item require_shipping_tax FLAG

If there is a FLAG pass in, it sets the shipping tax
flag and return the old value. If no argument is passed
in, it returns the current shipping tax flag.

=item get_area

Returns the C<Google::Checkout::General::TaxTableAreas> object 
where this tax rule is applied to.

=item set_area AREA

Sets where this tax rule should be applied to.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::General::TaxTableAreas

=cut

#--
#-- Represent the <[default|alternate>-tax-rule> element
#--

use strict;
use warnings;

sub new 
{
  my ($class, %args) = @_;

  my $self = { shipping_tax => $args{shipping_tax} ? 'true' : 'false',
               rate         => $args{rate} || 0 };
              
  if ($args{area})
  {
    if (ref $args{area} eq 'ARRAY')
    {
      push(@{$self->{area}}, $_) for @{$args{area}};
    }
    else
    {
      push(@{$self->{area}}, $args{area});
    }
  }

  return bless $self => $class;
}

sub get_rate 
{
  my ($self) = @_;
 
  return $self->{rate}; 
}

sub set_rate
{
  my ($self, $rate) = @_;

  $self->{rate} = $rate if $rate;
}

sub require_shipping_tax 
{
  my ($self, $data) = @_;

  my $oldv = $self->{shipping_tax};

  $self->{shipping_tax} = $data if @_ > 1;
 
  return $oldv;
}

sub get_area 
{
  my ($self) = @_;
 
  return $self->{area} || []; 
}

sub add_area
{
  my ($self, $area) = @_;

  push(@{$self->{area}}, $area) if $area;
}

1;
