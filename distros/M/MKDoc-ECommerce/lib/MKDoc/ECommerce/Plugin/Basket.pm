# -------------------------------------------------------------------------------------
# flo::plugin::Shop::Basket
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
package flo::plugin::Shop::Basket;
use strict;
use warnings;

use base qw /MKDoc::Core::Plugin/;


sub activate
{
    my $self = shift;
    my $session = MKDoc::Session->load() || return $self->SUPER::activate (@_);
    my $saveme  = 0;
    $session->{basket}  ||= do { $saveme = 1; new MKDoc::ECommerce::Basket() };
    $session->{country} ||= do { $saveme = 1; $ENV{ECOMMERCE_COUNTRY} || 'United Kingdom' };

    $session->save() if ($saveme);

    return $self->SUPER::activate (@_);
}


1;


__END__
