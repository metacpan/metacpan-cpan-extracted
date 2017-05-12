# $Id$
package Handel::Test::RDBO::Storage::Order;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Storage::RDBO::Order/;
};

__PACKAGE__->item_storage_class('Handel::Test::RDBO::Storage::Order::Item');

1;
