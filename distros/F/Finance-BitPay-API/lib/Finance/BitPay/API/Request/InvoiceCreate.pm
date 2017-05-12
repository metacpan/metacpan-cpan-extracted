package Finance::BitPay::API::Request::InvoiceCreate;
use base qw(Finance::BitPay::API::Request);
use strict;

use constant URL          => 'https://bitpay.com/api/invoice';
use constant ATTRIBUTES   => qw(price currency posData notificationURL transactionSpeed fullNotifications notificationEmail redirectURL orderID itemDesc itemCode physical buyerName buyerAddress1 buyerAddress2 buyerCity buyerState buyerZip buyerCountry buyerEmail buyerPhone );

sub price             { my $self = shift; $self->get_set(@_) }
sub currency          { my $self = shift; $self->get_set(@_) }
sub posData           { my $self = shift; $self->get_set(@_) }
sub notificationURL   { my $self = shift; $self->get_set(@_) }
sub transactionSpeed  { my $self = shift; $self->get_set(@_) }
sub fullNotifications { my $self = shift; $self->get_set(@_) }
sub notificationEmail { my $self = shift; $self->get_set(@_) }
sub redirectURL       { my $self = shift; $self->get_set(@_) }
sub orderID           { my $self = shift; $self->get_set(@_) }
sub itemDesc          { my $self = shift; $self->get_set(@_) }
sub itemCode          { my $self = shift; $self->get_set(@_) }
sub physical          { my $self = shift; $self->get_set(@_) }
sub buyerName         { my $self = shift; $self->get_set(@_) }
sub buyerAddress1     { my $self = shift; $self->get_set(@_) }
sub buyerAddress2     { my $self = shift; $self->get_set(@_) }
sub buyerCity         { my $self = shift; $self->get_set(@_) }
sub buyerState        { my $self = shift; $self->get_set(@_) }
sub buyerZip          { my $self = shift; $self->get_set(@_) }
sub buyerCountry      { my $self = shift; $self->get_set(@_) }
sub buyerEmail        { my $self = shift; $self->get_set(@_) }
sub buyerPhone        { my $self = shift; $self->get_set(@_) }
sub attributes { ATTRIBUTES }
sub url        { URL        }
sub is_ready   {
    my $self = shift;
    return defined $self->price
       and defined $self->currency;
}

1;

__END__

