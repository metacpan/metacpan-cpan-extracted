# $Id$
package Handel::Test::RDBO::Checkout;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Checkout/;
};

__PACKAGE__->order_class('Handel::Test::RDBO::Order');

1;
