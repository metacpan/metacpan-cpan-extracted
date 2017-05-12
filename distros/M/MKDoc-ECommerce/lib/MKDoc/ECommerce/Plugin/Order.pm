# -------------------------------------------------------------------------------------
# MKDoc::ECommerce::Plugin::Order
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# Order module which needs to be overriden / subclassed. It works as a standalone
# by connecting to itself, however it should be subclassed to be plugged into payment
# systems such as Worldpay / Paypal / etc. etc.
# -------------------------------------------------------------------------------------
package MKDoc::ECommerce::Plugin::Order;
use MKDoc::ECommerce::Order;
use Petal::Mail;
use warnings;
use strict;

use base qw /MKDoc::Core::Plugin/;


our $CURRENT = shift;


sub activate
{
    my $self = shift;
    $MKDoc::ECommerce::Plugin::Order::CURRENT ||= $self;

    return unless ($self->SUPER::activate (@_));

    my $req = $self->request();    
    my $id  = $req->param ('id') || return;
    $self->{order} = MKDoc::ECommerce::Order->load ($id) || return;
    
    return 1;
}


sub template_path
{
    my $self = shift;
    return 'ecommerce/order';
}


sub http_get
{
    my $self = shift;
    my $req  = $self->request();

    $req->param ('accept_me') && $self->{order}->accept();
    $req->param ('reject_me') && $self->{order}->reject();

    $self->render_http (
	self       => $self,
	__input__  => 'XML',
	__output__ => 'XHTML',
       );
    
    return 'TERMINATE';
}


sub http_post
{
    my $self = shift;
    return $self->http_get (@_);
}


sub order_uri
{
    my $self = shift;

    my $req  = $self->request()->new();
    $req->delete_all();

    my $path_info = $req->path_info();
    $path_info =~ s/^.*\//\//;
    $req->path_info ($path_info);

    $req->param ( id => $self->{order}->id() );
    return $req->self_url();
}


1;


__END__
