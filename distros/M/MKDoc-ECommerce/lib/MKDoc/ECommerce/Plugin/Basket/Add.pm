# -------------------------------------------------------------------------------------
# flo::plugin::Shop::Basket::Add
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This MKDoc plugin adds an item into someones' shopping basket.
# If the client sent a cookie, then this cookie is used to fetch the existing basket.
#
# Otherwise, this module creates a new shopping basket and sends a cookie to the
# client for future retrieval.
# -------------------------------------------------------------------------------------
package flo::plugin::Shop::Basket::Add;
use strict;
use warnings;
use flo::Standard;
use flo::plugin::Shop::Basket::Help;
use MKDoc::Session;
use MKDoc::ECommerce::Item;
use MKDoc::ECommerce::Basket;

use base qw /flo::plugin::Shop::Basket/;


sub http_post
{
    my $self = shift;
    my $cgi  = flo::Standard::cgi();
    
    # if there is no session present, redirect to a help
    # page about cookies, user accounts and stuff
    my $session = MKDoc::Session->load() || do {
        my $help_p = new flo::plugin::Shop::Basket::Help();
        print $cgi->redirect ($help_p->uri());
        return 'TERMINATE';
    };
    
    # if the session holds no basket object, create one
    $session->{basket} ||= new MKDoc::ECommerce::Basket();
    
    my $item = new MKDoc::ECommerce::Item (
        reference   => $cgi->param ('reference'),
        description => $cgi->param ('description'),
        unit_price  => $cgi->param ('unit_price'),
        quantity    => $cgi->param ('quantity'),
        signature   => $cgi->param ('signature'),
    );
    
    $item and do {
        $session->{basket}->add ($item);
        $session->save();
    };
    
    return $self->redirect();
}


sub redirect
{
    my $self = shift;
    my $cgi  = flo::Standard::cgi();
    
    # redirect the user to whereever s?he comes from and terminate
    my $from = $cgi->param ('from') || $ENV{HTTP_REFERER} || do {
	my $cgix = flo::Standard::cgi()->new();
	for ($cgix->param()) { $cgix->delete ($_) }
	$cgix->path_info ('/');
	$cgix->self_url;
    };
    
    print $cgi->redirect ($from);
    return 'TERMINATE';
}


1;


__END__
