# $Id$
package Handel::Storage::RDBO::Order::Item;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Storage::RDBO/;
    use Handel::Constraints qw/:all/;
};

__PACKAGE__->setup({
    schema_class     => 'Handel::Schema::RDBO::Order::Item',
    currency_columns => [qw/price total/],
    constraints      => {
        quantity     => {'Check Quantity' => \&constraint_quantity},
        price        => {'Check Price'    => \&constraint_price},
        total        => {'Check Total'    => \&constraint_price},
        id           => {'Check Id'       => \&constraint_uuid},
        orderid      => {'Check Order Id' => \&constraint_uuid}
    },
    default_values   => {
        id           => sub {__PACKAGE__->new_uuid(shift)},
        price        => 0,
        quantity     => 1,
        total        => 0
    }
});

1;
__END__

=head1 NAME

Handel::Storage::RDBO::Order::Item - RDBO storage configuration for Handel::Order::Item

=head1 SYNOPSIS

    package Handel::Order::Item;
    use strict;
    use warnings;
    use base qw/Handel::Base/;
    
    __PACKAGE__->storage_class('Handel::Storage::RDBO::Order::Item');

=head1 DESCRIPTION

Handel::Storage::RDBO::Order::Item is a subclass of
L<Handel::Storage::RDBO|Handel::Storage::RDBO> that contains all of the default
settings used by Handel::Order::Item.

=head1 SEE ALSO

L<Handel::Order::Item>, L<Handel::Storage::RDBO>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
