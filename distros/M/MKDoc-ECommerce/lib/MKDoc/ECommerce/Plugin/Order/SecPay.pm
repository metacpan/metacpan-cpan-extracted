# -------------------------------------------------------------------------------------
# flo::plugin::Shop::Order::SecPay
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This class contains all the necessary logic to connect to a secpay payment server.
# -------------------------------------------------------------------------------------
package flo::plugin::Shop::Order::SecPay;
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
    my $id  = $cgi->param ('trans_id') || $cgi->param ('id') || return;
    $self->{order} = MKDoc::ECommerce::Order->load ($id)     || return;
    
    return 1;
}


sub http_get
{
    my $self = shift;
    
    $self->sp_is_accepted() && $self->sp_valid_callback_host() && $self->{order}->accept();
    $self->sp_is_rejected() && $self->sp_valid_callback_host() && $self->{order}->reject();
    $self->SUPER::http_get (@_);
}


sub sp_cart_id
{
    my $self = shift;
    my $cgi  = flo::Standard::cgi();
    return $cgi->param ('trans_id');
}


sub sp_is_rejected
{
    my $self = shift;
    my $cgi  = flo::Standard::cgi();
    my $stat = $cgi->param ('code') || return;
    return $stat eq 'N';
}


sub sp_is_accepted
{
    my $self = shift;
    my $cgi  = flo::Standard::cgi();
    my $stat = $cgi->param ('code') || return;
    return $stat eq 'A';
}


sub sp_valid_callback_host
{
    my $self = shift;
    
    my $secret = $ENV{ECOMMERCE_SECRET};
    $secret and do {
	my $path_info = flo::Standard::raw_path_info();
	my $query_str = $ENV{QUERY_STRING};
	$query_str    =~ s/\&hash\=.*$//;
	
	my $md5_1 = md5_hex ("$path_info?$query_str&$secret");
	
	my $md5_2 = $ENV{QUERY_STRING};
	$md5_2    =~ s/^.*\&hash\=//;
	
	$md5_1 ne $md5_2 and return;
    };
    
    return 1;
}


sub post
{
    my $self = shift;
    return $self->http_get (@_);
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
    return 'merchant:trans_id:amount:currency';
}


sub pay_md5_secret
{
    return $ENV{ECOMMERCE_SECRET} || die '$ENV{ECOMMERCE_SECRET} is not defined';
}


sub pay_param_signature
{
    my $self = shift;
    my $string = join '&',
    ( merchant => $self->pay_param_instId(),
      trans_id => $self->pay_param_cartId(),
      amount   => $self->pay_param_amount(),
      currency => $self->pay_param_currency(),
      $self->pay_md5_secret() );
    
    return md5_hex ($string);
}


1;
