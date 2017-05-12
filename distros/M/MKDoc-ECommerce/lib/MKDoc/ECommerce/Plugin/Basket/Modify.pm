# -------------------------------------------------------------------------------------
# flo::plugin::Shop::Basket::Modify
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This MKDoc plugin removes an item from someones' shopping basket.
# If the client sent a cookie, then this cookie is used to fetch the existing basket.
#
# Otherwise, this module creates a new shopping basket and sends a cookie to the
# client for future retrieval.
# -------------------------------------------------------------------------------------
package flo::plugin::Shop::Basket::Modify;
use strict;
use warnings;
use flo::Standard;
use flo::plugin::Shop::Basket::Help;
use MKDoc::Session;
use MKDoc::ECommerce::Item;
use MKDoc::ECommerce::Basket;
use URI;

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
    
    $session->{country} = $cgi->param ('country');
    
    # change quantities
    if ($cgi->param ('submit-change') || defined $cgi->param ('submit-change.x'))
    {
	foreach ($cgi->param())
	{
	    /^submit-change-qty-/ and do {
		my $ref_id  = $_;
		my $new_qty = $cgi->param ($_);
		$ref_id  = $self->_extract_ref_id ($ref_id);
		$new_qty = $self->_extract_value  ($new_qty);
		$session->{basket}->set_quantity ($ref_id, $new_qty);
	    };
	}
    }
    
    # delete items
    for ($cgi->param ())
    {
        s/\.x$//;
	/^submit-delete-id-/ and do {
	    my $ref_id = $self->_extract_ref_id ($_);
	    $session->{basket}->delete ($ref_id);
	};
    }
    
    # save session
    $session->save();
    
    # redirect user to appropriate location and terminate
    my $from = $cgi->param ('from') || $ENV{HTTP_REFERER} || do {
	my $cgix = flo::Standard::cgi()->new();
	for ($cgix->param()) { $cgix->delete ($_) }
	$cgix->path_info ('/');
	$cgix->self_url;
    };
    print $cgi->redirect ($from);
    return 'TERMINATE';
}


sub _extract_ref_id
{
    my $self   = shift;
    my $ref_id = shift;
    $ref_id    =~ s/^submit-change-qty-//;
    $ref_id    =~ s/^submit-delete-id-//;
    return $ref_id;
}


sub _extract_value
{
    my $self  = shift;
    my $value = shift;
    no warnings;
    {
	$value = int ($value);
	$value = 0 if ($value < 0);
    }
    return $value;
}


1;


__END__
