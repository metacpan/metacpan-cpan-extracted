# -------------------------------------------------------------------------------------
# flo::plugin::Shop::Basket::Help
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# In the unfortunate event where a user doesn't support cookies or isn't logged in,
# displays some help and hope they don't go away.
# -------------------------------------------------------------------------------------
package flo::plugin::Shop::Basket::Help;
use strict;
use warnings;
use MKDoc::Ouch;
use flo::Standard;

use base qw /flo::Plugin/;


##
# $self->template_path();
# -----------------------
# Returns the template path in which to find the shopping
# basket templates.
##
sub template_path
{
    my $self = shift;
    return 'shop/basket/help';
}


##
# $self->http_get;
# ----------------
# Displays the form which lets the editor choose which audiences
# the current document relates to.
##
sub http_get
{
    my $self     = shift;
    $self->render_http (
	self       => $self,
	__input__  => 'XML',
	__output__ => 'XHTML',
       );
    
    return 'TERMINATE';
}


1;
