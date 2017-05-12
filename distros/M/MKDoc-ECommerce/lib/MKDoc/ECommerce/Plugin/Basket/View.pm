# -------------------------------------------------------------------------------------
# flo::plugin::Shop::Basket::View
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# Provides common methods which are used to view the basket,
# add an item to the basket, or delete an item from the basket.
# -------------------------------------------------------------------------------------
package flo::plugin::Shop::Basket::View;
use warnings;
use flo::Standard;
use flo::plugin::Shop::Basket::Help;
use MKDoc::Session;
use MKDoc::ECommerce::Item;
use MKDoc::ECommerce::Basket;
use Geography::Countries;

use base qw /flo::plugin::Shop::Basket/;


sub template_path
{
    my $self = shift;
    return 'shop/basket/view';
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
    my $cgi  = flo::Standard::cgi();

    # if there is no session present, redirect to a help
    # page about cookies, user accounts and stuff
    my $session = $self->session() || do {
	my $help_p = new flo::plugin::Shop::Basket::Help();
	print $cgi->redirect ($help_p->uri());
	return 'TERMINATE';
    };

    $self->render_http (
	self       => $self,
	__input__  => 'XML',
	__output__ => 'XHTML',
       );
    
    return 'TERMINATE';
}


sub get_rules
{
    my $self = shift;
    my $session = $self->session() || return;
    my $country = $session->{country};
    my $basket  = $session->{basket};
    return new MKDoc::ECommerce::Rules ( country => $country, basket => $basket );
}


sub session
{
    return MKDoc::Session->load();
}


sub countries_selected
{
    my $self    = shift               || return;
    my $session = $self->session()    || return 'United Kingdom';
    my $country = $session->{country} || return 'United Kingdom';
    return $country;
}


sub countries_unselected
{
    my $self      = shift;
    my $selected  = $self->countries_selected() || 'this will never match';
    my @countries = map { $_ eq $selected ? () : $_ } Geography::Countries::countries();
    return wantarray ? @countries : \@countries;
}


1;


__END__
