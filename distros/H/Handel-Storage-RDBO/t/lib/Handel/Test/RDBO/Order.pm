# $Id$
package Handel::Test::RDBO::Order;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Order/;
};

__PACKAGE__->storage_class('Handel::Test::RDBO::Storage::Order');
__PACKAGE__->item_class('Handel::Test::RDBO::Order::Item');
__PACKAGE__->cart_class('Handel::Test::RDBO::Cart');
__PACKAGE__->checkout_class('Handel::Test::RDBO::Checkout');
__PACKAGE__->create_accessors;

1;
