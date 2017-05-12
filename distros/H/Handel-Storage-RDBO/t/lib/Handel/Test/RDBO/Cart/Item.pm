# $Id$
package Handel::Test::RDBO::Cart::Item;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Cart::Item/;
};

__PACKAGE__->storage_class('Handel::Test::RDBO::Storage::Cart::Item');
__PACKAGE__->create_accessors;

1;
