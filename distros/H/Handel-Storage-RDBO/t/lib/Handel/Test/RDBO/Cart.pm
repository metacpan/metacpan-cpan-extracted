# $Id$
package Handel::Test::RDBO::Cart;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Cart/;
};

__PACKAGE__->storage_class('Handel::Test::RDBO::Storage::Cart');
__PACKAGE__->item_class('Handel::Test::RDBO::Cart::Item');
__PACKAGE__->create_accessors;

1;
