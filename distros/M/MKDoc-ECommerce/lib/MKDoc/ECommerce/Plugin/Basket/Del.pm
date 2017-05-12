# -------------------------------------------------------------------------------------
# flo::plugin::Shop::Basket::Del
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This MKDoc plugin removes an item from someones' shopping basket.
# -------------------------------------------------------------------------------------
package flo::plugin::Shop::Basket::Del;
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
    
    # delete the object which needs deleting
    my $reference = $cgi->param ('reference');
    $reference and do { 
        $session->{basket}->delete ($reference);
        $session->save();
    };
    
    # redirect the user to wherever he comes from and terminate
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
