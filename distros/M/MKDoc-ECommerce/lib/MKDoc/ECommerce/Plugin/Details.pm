# -------------------------------------------------------------------------------------
# MKDoc::ECommerce::Details
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# Provides a method for the user to enter details when checking out.
# -------------------------------------------------------------------------------------
package MKDoc::ECommerce::Details; 
use MKDoc::ECommerce::Plugin::Order;
use MKDoc::ECommerce::Address;
use MKDoc::ECommerce::Order;
use MKDoc::Core::Session;

use warnings;
use strict;

use base qw /MKDoc::Core::Plugin/;


##
# $self->template_path();
# -----------------------
# Returns the template path in which to find the shopping
# basket templates.
##
sub template_path
{
    my $self = shift;
    return 'ecommerce/details';
}


##
# $self->http_post;
# -----------------
# Attempts to create a valid address, store it, and create an order
# with worldpay's gateway.
##
sub http_post
{
    my $self  = shift;
    my $req   = $self->request();
    my $session = $self->session() || return $self->http_get();
    
    # try to set the address in the session
    # if the address is invalid, re-display the form 
    my %param = map { $_ => $req->param ($_) } $req->param();
    $param{country} = $session->{country};
    
    my $addr  = new MKDoc::ECommerce::Address (%param);
    $addr || return $self->http_get();
    
    $session->{address} = $addr;
    $session->save();
    
    
    # create an order object with the session_id, the address
    # and the basket object and save it
    my $order = new MKDoc::ECommerce::Order (
        session_id => $session->id(),
        address    => $session->{address},
        basket     => $session->{basket}
    );
    $order->save();
    
    
    # now that we have created the order, redirect to the order
    # page from where the payment can be made. 
    my $uri = $MKDoc::ECommerce::Plugin::Order::CURRENT->uri();
    $uri    =~ s/^(https?:\/\/.*?\/).*?(\..*)$/$1$2/;
    $uri   .= "?id=$order->{id}";
    print $req->redirect ($uri);
    return 'TERMINATE';
}


##
# $self->http_get;
# ----------------
# Displays the form which lets the editor choose which audiences
# the current document relates to.
##
sub http_get
{
    my $self = shift;
    
    $self->_http_get_initialize_req();
    return $self->SUPER::http_get (@_); 
}


sub _http_get_initialize_req
{
    my $self = shift;
    my $req  = $self->request();
    $req->param ('submit_ok') && return;
    
    my $session  = $self->session()   || return;
    my $address = $session->{address} || return;
    
    for (keys %{$address})
    {
	$req->param ($_, $address->{$_});
    }
}


sub session
{
    my $self = shift;
    return MKDoc::Session->load();
}


1;


__END__
