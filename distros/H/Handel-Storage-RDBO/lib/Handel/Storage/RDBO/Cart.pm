# $Id$
package Handel::Storage::RDBO::Cart;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Storage::RDBO/;
    use Handel::Constants qw/CART_TYPE_TEMP/;
    use Handel::Constraints qw/:all/;
};

__PACKAGE__->setup({
    schema_class       => 'Handel::Schema::RDBO::Cart',
    item_storage_class => 'Handel::Storage::RDBO::Cart::Item',
    constraints        => {
        id             => {'Check Id'      => \&constraint_uuid},
        shopper        => {'Check Shopper' => \&constraint_uuid},
        type           => {'Check Type'    => \&constraint_cart_type},
        name           => {'Check Name'    => \&constraint_cart_name}
    },
    default_values     => {
        id             => sub {__PACKAGE__->new_uuid(shift)},
        type           => CART_TYPE_TEMP
    }
});


1;
__END__

=head1 NAME

Handel::Storage::RDBO::Cart - RDBO storage configuration for Handel::Cart

=head1 SYNOPSIS

    package Handel::Cart;
    use strict;
    use warnings;
    use base qw/Handel::Base/;
    
    __PACKAGE__->storage_class('Handel::Storage::RDBO::Cart');

=head1 DESCRIPTION

Handel::Storage::RDBO::Cart is a subclass of
L<Handel::Storage::RDBO|Handel::Storage::RDBO> that contains all of the default
settings used by Handel::Cart.

=head1 SEE ALSO

L<Handel::Cart>, L<Handel::Storage::RDBO>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
