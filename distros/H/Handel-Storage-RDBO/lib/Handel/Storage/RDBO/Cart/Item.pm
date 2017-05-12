# $Id$
package Handel::Storage::RDBO::Cart::Item;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Storage::RDBO/;
    use Handel::Constraints qw/:all/;
};

__PACKAGE__->setup({
    schema_class     => 'Handel::Schema::RDBO::Cart::Item',
    currency_columns => [qw/price/],
    constraints      => {
        quantity     => {'Check Quantity' => \&constraint_quantity},
        price        => {'Check Price'    => \&constraint_price},
        id           => {'Check Id'       => \&constraint_uuid},
        cart         => {'Check Cart'     => \&constraint_uuid}
    },
    default_values   => {
        id           => sub {__PACKAGE__->new_uuid(shift)},
        price        => 0,
        quantity     => 1
    }
});

1;
__END__

=head1 NAME

Handel::Storage::RDBO::Cart::Item - RDBO storage configuration for Handel::Cart::Item

=head1 SYNOPSIS

    package Handel::Cart::Item;
    use strict;
    use warnings;
    use base qw/Handel::Base/;
    
    __PACKAGE__->storage_class('Handel::Storage::RDBO::Cart::Item');

=head1 DESCRIPTION

Handel::Storage::RDBO::Cart::Item is a subclass of
L<Handel::Storage::RDBO|Handel::Storage::RDBO> that contains all of the default
settings used by Handel::Cart::Item.

=head1 SEE ALSO

L<Handel::Cart::Item>, L<Handel::Storage::RDBO>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
