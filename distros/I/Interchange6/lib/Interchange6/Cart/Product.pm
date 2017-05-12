package Interchange6::Cart::Product;

use Interchange6::Types -types;

use Moo;
use MooX::HandlesVia;
use MooseX::CoverableModifiers;
with 'Interchange6::Role::Costs';
use namespace::clean;

=head1 NAME 

Interchange6::Cart::Product - Cart product class for Interchange6 Shop Machine

=head1 DESCRIPTION

Cart product class for L<Interchange6>.

See L<Interchange6::Role::Costs> for details of cost attributes and methods.

=head1 ATTRIBUTES

See also L<Interchange6::Role::Costs/ATTRIBUTES>.

Each cart product has the following attributes:

=head2 id

Can be used by subclasses, e.g. primary key value for cart products in the database.

=cut

has id => (
    is  => 'ro',
    isa => Int,
);

=head2 cart

A reference to the Cart object that this Cart::Product belongs to.

=over

=item Writer: C<set_cart>

=back

=cut

has cart => (
    is      => 'ro',
    isa     =>  Maybe[Cart],
    default => undef,
    writer  => 'set_cart',
    weak_ref => 1,
);

=head2 name

Product name is required.

=cut

has name => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

=head2 price

Product price is required and a positive number or zero.

Price is required, because you want to maintain the price that was valid at the time of adding to the cart. Should the price in the shop change in the meantime, it will maintain this price.

=over

=item Writer: C<set_price>

=back

=cut

has price => (
    is        => 'ro',
    isa       => PositiveOrZeroNum,
    required  => 1,
    writer    => 'set_price',
);

=head2 selling_price

Selling price is the price after group pricing, tier pricing or promotional discounts have been applied. If it is not set then it defaults to L</price>.

=over

=item Writer: C<set_selling_price>

=back

=cut

has selling_price => (
    is        => 'lazy',
    isa       => PositiveOrZeroNum,
    writer    => 'set_selling_price',
);

sub _build_selling_price {
    my $self = shift;
    return $self->price;
}

=head2 discount_percent

This is the integer discount percentage calculated from the difference
between L</price> and L</selling_price>. This attribute should not normally
be set since as it is a calculated value.

L</discount_percent> is cleared if either L</set_price> or
L<set_selling_price> methods are called.

=cut

has discount_percent => (
    is      => 'lazy',
    clearer => 1
);

sub _build_discount_percent {
    my $self = shift;
    return 0 if $self->price == $self->selling_price;
    return int( ( $self->price - $self->selling_price ) / $self->price * 100 );
}

after 'set_price', 'set_selling_price' => sub {
    shift->clear_discount_percent;
};

=head2 quantity

Product quantity is optional and has to be a natural number greater
than zero. Default for quantity is 1.

=cut

has quantity => (
    is => 'ro',
    # https://github.com/interchange/Interchange6/issues/28
    # Tupe::Tiny::XS sometimes incorrectly passes Int assertion for
    # non-integer values such as 2.3 so we can't just do:
    #    isa => PositiveInt
    # but if we stringify the value then things work as expected. Huh?
    # Also prevent uninitialized warning in case value is undef.
    isa => sub {
        no warnings 'uninitialized';
        PositiveInt->assert_valid("$_[0]");
    },
    default => 1,
    writer  => 'set_quantity',
);

after set_quantity => sub {
    my $self = shift;
    $self->clear_subtotal;
    $self->clear_total;
};

=head2 sku

Unique product identifier is required.

=cut

has sku => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

=head2 canonical_sku

If this product is a variant of a "parent" product then C<canonical_sku>
is the sku of the parent product.

=cut

has canonical_sku => (
    is      => 'ro',
    default => undef,
);

=head2 subtotal

Subtotal calculated as L</price> * L</quantity>. Lazy set via builder.

=cut

has subtotal => (
    is        => 'lazy',
    isa       => Num,
    clearer   => 1,
    predicate => 1,
);

sub _build_subtotal {
    my $self = shift;
    return sprintf( "%.2f", $self->selling_price * $self->quantity);
}

=head2 uri

Product uri

=cut

has uri => (
    is  => 'ro',
    isa => Str,
);

=head2 weight

Weight of quantity 1 of this product.

=cut

has weight => (
    is     => 'ro',
    isa    => Num,
    writer => 'set_weight',
);

=head2 extra

Hash reference of extra things the cart product might want to store such as:

=over

=item * variant attributes in order to be able to change variant within cart

=item * simple attributes to allow display of them within cart

=back

=cut

has extra => (
    is          => 'ro',
    isa         => HashRef,
    default     => sub { {} },
    handles_via => 'Hash',
    handles     => {
        get_extra     => 'get',
        set_extra     => 'set',
        delete_extra  => 'delete',
        keys_extra    => 'keys',
        clear_extra   => 'clear',
        exists_extra  => 'exists',
        defined_extra => 'defined',
    },
);

=head2 combine

Indicate whether products with the same SKU should be combined in the Cart

=over 

=item Writer: C<combine>

=back

=cut
   
has combine => (
    is      => 'ro',
    isa     => CodeRef | Bool,
    default => 1,
);

=head1 METHODS

See also L<Interchange6::Role::Costs/METHODS>.

=head2 L</extra> methods

=over

=item * get_extra($key, $key2, $key3...)

See L<Data::Perl::Role::Collection::Hash/get>

=item * set_extra($key => $value, $key2 => $value2...)

See L<Data::Perl::Role::Collection::Hash/set>

=item * delete_extra($key, $key2, $key3...)

See L<Data::Perl::Role::Collection::Hash/set>

=item * keys_extra

See L<Data::Perl::Role::Collection::Hash/keys>

=item * clear_extra

See L<Data::Perl::Role::Collection::Hash/clear>

=item * exists_extra($key)

See L<Data::Perl::Role::Collection::Hash/exists>

=item * defined_extra($key)

See L<Data::Perl::Role::Collection::Hash/defined>

=back

=head2 L</subtotal> methods

=over

=item * clear_subtotal

Clears L</subtotal>.

=item * has_subtotal

predicate on L</subtotal>.

=back

=head2 is_variant

Returns 1 if L</canonical_sku> is defined else 0.

=cut

sub is_variant {
    return defined shift->canonical_sku ? 1 : 0;
}

=head2 is_canonical

Returns 0 if L</canonical_sku> is defined else 1.

=cut

sub is_canonical {
    return defined shift->canonical_sku ? 0 : 1;
}

=head2 should_combine_by_sku

Determines whether a product should be combined by sku based on the 
value of L</combine>.

If L</combine> isa CodeRef the result of applying that CodeRef is returned
otherwise:
   Returns 0 if a product should not be combined
   Returns 1 if a product should be combined

=cut
   
sub should_combine_by_sku {
   my ($self) = @_;

   return $self->combine->()
      if ref $self->combine eq 'CODE';

   return $self->combine;
}

# after cost changes we need to clear the cart subtotal/total
# our own total is handled by the Costs role

after 'clear_costs', 'cost_set', 'apply_cost', 'set_quantity' => sub {
    my $self = shift;
    if ( $self->cart ) {
        $self->cart->clear_subtotal;
        $self->cart->clear_total;
    }
};
after 'set_quantity', 'set_weight' => sub {
    my $self = shift;
    if ( $self->cart ) {
        $self->cart->clear_weight;
    }
};

1;
