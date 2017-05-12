# -------------------------------------------------------------------------------------
# flo::plugin::Shop::Order::WorldPay 
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This class contains all the necessary logic to connect to a worldpay payment server.
# -------------------------------------------------------------------------------------
package flo::plugin::Shop::Order::WorldPay;
use strict;
use warnings;
use base qw /flo::plugin::Shop::Order/;
use Digest::MD5 qw /md5_hex/;


sub activate
{
    my $self = shift;
    $flo::plugin::Shop::Order::CURRENT ||= $self;

    return unless (flo::Plugin::activate ($self, @_)); # SUPER->SUPER

    my $cgi = $self->cgi();
    my $id  = $cgi->param ('cartId') || $cgi->param ('id') || return;
    $self->{order} = MKDoc::ECommerce::Order->load ($id)   || return;

    return 1;
}


sub http_get
{
    my $self = shift;

    $self->wl_is_accepted() && $self->wl_valid_callback_host() && $self->{order}->accept();
    $self->wl_is_rejected() && $self->wl_valid_callback_host() && $self->{order}->reject();
    $self->SUPER::http_get (@_);
}


sub wl_cart_id
{
    my $self = shift;
    my $cgi  = flo::Standard::cgi();
    return $cgi->param ('cartId');
}


sub wl_is_rejected
{
    my $self = shift;
    my $cgi  = flo::Standard::cgi();
    my $stat = $cgi->param ('transStatus') || return;
    return $stat ne 'Y';
}


sub wl_is_accepted
{
    my $self = shift;
    my $cgi  = flo::Standard::cgi();
    my $stat = $cgi->param ('transStatus') || return;
    return $stat eq 'Y';
}


sub wl_valid_callback_host
{
    my $self = shift;
    my $host = flo::Standard::cgi()->remote_host();

    die "no host" unless ($host);
    die "$host: not a valid IPv4 address" if ($host !~ /(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/);

    my $lead = $1 . '.' . $2 . '.' . $3;
                                                                                                                   
    $lead ne "195.35.90" && $lead ne "155.136.68" && $lead ne "193.41.220" && return; 
    $4 < 0 || $4 > 255                                                     && return;
    return 1; 
}


sub post
{
    my $self = shift;
    return $self->http_get (@_);
}


sub auth_valid_to
{
    return time() + (3600 * 24 * 30);
}


sub auth_valid_to_ms
{
    my $self = shift;
    return $self->auth_valid_to() . '000';
}


sub pay_param_instId
{
    return $ENV{ECOMMERCE_INSTID} || die '$ENV{ECOMMERCE_INSTID} is not defined';
}


sub pay_param_cartId
{
    my $self = shift;
    return $self->{order}->id() || die '$self->{order}->{id} is not defined';
}


sub pay_param_amount
{
    my $self = shift;
    return $self->{order}->{deal_price} || die '$self->{order}->{deal_price} is not defined';
}


sub pay_param_currency
{
    return $ENV{ECOMMERCE_CURRENCY} || die '$ENV{ECOMMERCE_CURRENCY} is not defined';
}


sub pay_param_signatureFields
{
    return 'instId:cartId:amount:currency';
}


sub pay_md5_secret
{
    return $ENV{ECOMMERCE_SECRET} || die '$ENV{ECOMMERCE_SECRET} is not defined';
}


sub pay_param_signature
{
    my $self = shift;
    my $string = join ':', ( $self->pay_md5_secret(),
			     $self->pay_param_instId(),
			     $self->pay_param_cartId(),
			     $self->pay_param_amount(),
			     $self->pay_param_currency() );
    
    return md5_hex ($string);
}


1;
