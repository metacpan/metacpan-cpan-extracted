# -------------------------------------------------------------------------------------
# flo::plugin::Shop::Basket::Mail
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# Provides common methods which are used to view the basket,
# add an item to the basket, or delete an item from the basket.
# -------------------------------------------------------------------------------------
package flo::plugin::Shop::Basket::Mail;
use warnings;
use flo::Standard;
use base qw /flo::plugin::Shop::Basket::View/;


sub template_path
{
    my $self = shift;
    return 'shop/basket/mail';
}


1;


__END__
