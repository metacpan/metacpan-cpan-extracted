package Google::Checkout::General::MerchantCalculationResult;

=head1 NAME

Google::Checkout::General::MerchantCalculationResult

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is used internally by C<Google::Checkout::General::MerchantCalculationResults>.

=over 4

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::General::MerchantCalculationResults

=cut

#--
#-- Used by MerchantCalculationResults (note the 's' at the end)
#--

use strict;
use warnings;

sub new
{
  my ($class, %args) = @_;

  my $self = {};

  my $_has_coupon_calculated_amount = exists $args{coupon_calculated_amount};
  my $_has_coupon_message           = exists $args{coupon_message} && 
                                      length($args{coupon_message});

  my $_has_certificate_calculated_amount = 
       exists $args{certificate_calculated_amount};

  my $_has_certificate_message = exists $args{certificate_message} &&
                                 length($args{certificate_message});

  my $_has_coupon_result = exists $args{valid_coupon}             ||
                           exists $args{coupon_calculated_amount} ||
                           exists $args{coupon_code}              ||
                           exists $args{coupon_message};

  my $_has_gift_certificate = exists $args{valid_certificate}             ||
                              exists $args{certificate_calculated_amount} ||
                              exists $args{certificate_code}              ||
                              exists $args{certificate_message};

  my $_has_merchant_code_results = $_has_coupon_result || 
                                   $_has_gift_certificate;

     $self = {_has_total_tax      => exists $args{total_tax},
              _has_shipping_rate  => exists $args{shipping_rate},
              _has_shippable      => exists $args{shippable},
              total_tax           => $args{total_tax}                     || 0,
              shipping_rate       => $args{shipping_rate}                 || 0,,
              shippable           => $args{shippable}                     || '',
              coupon_valid        => defined($args{valid_coupon}) ? $args{valid_coupon} : 0,
              coupon_amount       => $args{coupon_calculated_amount}      || 0,
              coupon_code         => $args{coupon_code}                   || '',
              coupon_message      => $args{coupon_message}                || '',
              certificate_valid   => $args{valid_certificate}             || 1,
              certificate_amount  => $args{certificate_calculated_amount} || 0,
              certificate_code    => $args{certificate_code}              || '',
              certificate_message => $args{certificate_message}           || '',
              shipping_name       => $args{shipping_name}, 
              address_id          => $args{address_id} };

  $self->{_has_coupon_calculated_amount}      = $_has_coupon_calculated_amount;
  $self->{_has_coupon_message}                = $_has_coupon_message;
  $self->{_has_certificate_message}           = $_has_certificate_message;
  $self->{_has_coupon_result}                 = $_has_coupon_result;
  $self->{_has_gift_certificate}              = $_has_gift_certificate;
  $self->{_has_merchant_code_results}         = $_has_merchant_code_results;
  $self->{_has_certificate_calculated_amount} = 
    $_has_certificate_calculated_amount;

  return bless $self => $class;
}

sub has_shipping_rate        
{ 
  my ($self) = @_;

  return $self->{_has_shipping_rate};
}

sub has_shippable            
{ 
  my ($self) = @_;

  return $self->{_has_shippable};
}

sub has_total_tax            
{ 
  my ($self) = @_;

  return $self->{_has_total_tax};
}

sub has_coupon_result        
{ 
  my ($self) = @_;

  return $self->{_has_coupon_result};
}

sub has_certificate_result   
{ 
  my ($self) = @_;

  return $self->{_has_gift_certificate};
}

sub has_merchant_code_result 
{ 
  my ($self) = @_;

  return $self->{_has_merchant_code_results}; 
}

sub has_coupon_calculated_amount 
{ 
  my ($self) = @_;

  return $self->{_has_coupon_calculated_amount}; 
}

sub has_coupon_message
{ 
  my ($self) = @_;

  return $self->{_has_coupon_message};
}

sub has_certificate_calculated_amount 
{ 
  my ($self) = @_;

  return $self->{_has_certificate_calculated_amount}; 
}

sub has_certificate_message
{ 
  my ($self) = @_;

  return $self->{_has_certificate_message};
}

sub get_shipping_name 
{ 
  my ($self) = @_;

  return $self->{shipping_name} || ''; 
}

sub set_shipping_name 
{
  my ($self, $name) = @_;

  $self->{shipping_name } = $name if $name;
}

sub get_address_id 
{ 
  my ($self) = @_;

  return $self->{address_id} || ''; 
}

sub set_address_id
{
  my ($self, $id) = @_;

  $self->{address_id} = $id if $id;
}

sub get_total_tax 
{
  my ($self) = @_;
 
  return $self->{total_tax}; 
}

sub set_total_tax 
{
  my ($self, $total) = @_;

  if(defined $total)
  {
    $self->{total_tax} = $total;
    $self->{_has_total_tax} = 1;
  }
}

sub get_shipping_rate 
{
  my ($self) = @_;
 
  return $self->{shipping_rate}; 
}

sub set_shipping_rate
{
  my ($self, $rate) = @_;

  if (defined $rate)
  {
    $self->{shipping_rate} = $rate;
    $self->{_has_shipping_rate} = 1;
  }
}

sub is_shippable 
{ 
  my ($self) = @_;

  return $_[0]->{shippable} ? 'true' : 'false'; 
}

sub set_shippable 
{
  my ($self, $shippable) = @_;

  $self->{shippable} = $shippable;
  $self->{_has_shippable} = 1;
}

sub is_coupon_valid 
{
  my ($self) = @_;
 
  return $self->{coupon_valid} ? 'true' : 'false'; 
}

sub set_coupon_valid 
{
  my ($self, $valid) = @_;

  $self->{coupon_valid} = $valid;
  $self->{_has_coupon_result} = 1;
  $self->{_has_merchant_code_results} = 1;
}

sub is_certificate_valid 
{
  my ($self) = @_;
 
  return $self->{certificate_valid} ? 'true' : 'false'; 
}

sub set_certificate_valid
{
  my ($self, $valid) = @_;

  $self->{certificate_valid} = $valid;
  $self->{_has_gift_certificate} = 1;
  $self->{_has_merchant_code_results} = 1;
}

sub get_coupon_amount 
{ 
  my ($self) = @_;

  return $self->{coupon_amount} || 0;
}

sub set_coupon_amount 
{ 
  my ($self, $data) = @_;

  $self->_set_data(1, coupon_amount => $data); 
  $self->{_has_coupon_calculated_amount} = 1;
}

sub get_coupon_code 
{ 
  my ($self) = @_;

  return $self->{coupon_code}  || '';
}

sub set_coupon_code 
{ 
  my ($self, $data) = @_;

  $self->_set_data(1, coupon_code => $data); 
}

sub get_coupon_message 
{ 
  my ($self) = @_;

  return $self->{coupon_message} || '';
}

sub set_coupon_message 
{
  my ($self, $data) = @_;
 
  $self->_set_data(1, coupon_message => $data);
  $self->{_has_coupon_message} = 1 if length $data;
}

sub get_certificate_amount 
{ 
  my ($self) = @_;

  return $self->{certificate_amount} || 0; 
}

sub set_certificate_amount 
{
  my ($self, $data) = @_;
 
  $self->_set_data(0, certificate_amount => $data);
  $self->{_has_certificate_calculated_amount} = 1 if defined $data;
}

sub get_certificate_code 
{ 
  my ($self) = @_;

  return $self->{certificate_code} || ''; 
}

sub set_certificate_code 
{ 
  my ($self, $data) = @_;

  $self->_set_data(0, certificate_code => $data) 
}

sub get_certificate_message 
{ 
  my ($self) = @_;

  return $self->{certificate_message} || ''; 
}

sub set_certificate_message 
{ 
  my ($self, $data) = @_;

  $self->_set_data(0, certificate_message => $data);
  $self->{_has_certificate_message} = $_[1] if length $data; 
}

#-- PRIVATE --#

sub _set_data
{
  my ($self, $coupon, $which, $data) = @_;

  if (defined $data)
  {
    $self->{$which} = $data;
    $self->{_has_merchant_code_results} = 1;
    $self->{$coupon ? '_has_coupon_result' : '_has_gift_certificate'} = 1;
  }
}

1;
