package Interchange6::Cart;

=head1 NAME 

Interchange6::Cart - Cart class for Interchange6 Shop Machine

=cut

use Carp;
use Interchange6::Types -types;
use Module::Runtime 'use_module';
use Safe::Isa;

use Moo;
use MooX::HandlesVia;
use MooseX::CoverableModifiers;
with 'Interchange6::Role::Costs';
use namespace::clean;

=head1 DESCRIPTION

Generic cart class for L<Interchange6>.

=head1 SYNOPSIS

  my $cart = Interchange6::Cart->new();

  $cart->add( sku => 'ABC', name => 'Foo', price => 23.45 );

  $cart->update( sku => 'ABC', quantity => 3 );

  my $product = Interchange::Cart::Product->new( ... );

  $cart->add($product);

  $cart->apply_cost( ... );

  my $total = $cart->total;

=head1 ATTRIBUTES

See also L<Interchange6::Role::Costs/ATTRIBUTES>.

=head2 id

Cart id can be used for subclasses, e.g. primary key value for carts in the database.

=over

=item Writer: C<set_id>

=back

=cut

has id => (
    is     => 'ro',
    isa    => Str,
    writer => 'set_id',
);

=head2 name

The cart name. Default is 'main'.

=over

=item Writer: C<rename>

=back

=cut

has name => (
    is      => 'ro',
    isa     => NonEmptyStr,
    default => 'main',
    writer  => 'rename',
);

=head2 products

Called without args returns a hash reference of L<Interchange6::Cart::Product>.

Anything passed in as a value on object instantiation is ignored. To load
products into a cart the preferred methods are L</add> and L</seed> which
make sure appropriate arguements are passed.

=cut

has products => (
    # rwp allows us to clear out products in seed via _set_products
    # without disturbing what subclasses might expect of clear
    is  => 'rwp',
    isa => ArrayRef [ CartProduct ],
    default     => sub { [] },
    handles_via => 'Array',
    handles     => {
        clear          => 'clear',
        count          => 'count',
        is_empty       => 'is_empty',
        product_first  => 'first',
        product_get    => 'get',
        product_grep   => 'grep',
        product_index  => 'first_index',
        products_array => 'elements',
        product_delete => 'delete',
        product_push   => 'push',
        product_set    => 'set',
    },
    init_arg => undef,
);

=head2 product_class

To allow use of a subclassed L<Interchange6::Cart::Product>. Defaults to
C<Interchange6::Cart::Product>.

=cut

has product_class => (
    is      => 'ro',
    isa     => Str,
    default => 'Interchange6::Cart::Product',
);

=head2 sessions_id

The session ID for the cart.

=over

=item Writer: C<set_sessions_id>

=back

=cut

has sessions_id => (
    is      => 'ro',
    isa     => Str,
    clearer => 1,
    writer  => 'set_sessions_id',
);

=head2 subtotal

Returns current cart subtotal excluding costs.

=cut

has subtotal => (
    is        => 'lazy',
    clearer   => 1,
    predicate => 1,
);

sub _build_subtotal {
    my $self = shift;

    my $subtotal = 0;
    foreach my $product ( $self->products_array ) {
       $subtotal += $product->total;
    }

    return sprintf( "%.2f", $subtotal );
}

after 'clear', 'product_push', 'product_set', 'product_delete' => sub {
    my $self = shift;
    $self->clear_subtotal;
    $self->clear_weight;
};

after 'clear_subtotal' => sub {
    shift->clear_total;
};

=head2 users_id

The user id of the logged in user.

=over

=item Writer: C<set_users_id>

=back

=cut

has users_id => (
    is     => 'ro',
    isa    => Str,
    writer => 'set_users_id',
);

=head2 weight

Returns total weight of all products in the cart. If all products have
unedfined weight then this returns undef.

=cut

has weight => (
    is        => 'lazy',
    clearer   => 1,
    predicate => 1,
);

sub _build_weight {
    my $self = shift;
   
    my $weight = 0;
    foreach my $product ( grep { defined $_->weight } $self->products_array ) {
       $weight += $product->weight * $product->quantity;
    }

    return $weight;
}

=head1 METHODS

See also L<Interchange6::Role::Costs/METHODS>.

=head2 clear

Removes all products from the cart.

=head2 count

Returns the number of different products in the shopping cart. If you have 5 apples and 6 pears it will return 2 (2 different products).

=head2 is_empty

Return boolean 1 or 0 depending on whether the cart is empty or not.

=head2 product_delete($index)

Deletes the product at the specified index.

=head2 product_get($index)

Returns the product at the specified index.

=head2 product_grep( sub {...})

This method returns every element matching a given criteria, just like Perl's core grep function. This method requires a subroutine which implements the matching logic. The returned list is provided as a Collection::Array object.

=head2 product_index( sub {...})

This method returns the index of the first matching product in the cart. The matching is done with a subroutine reference you pass to this method. The subroutine will be called against each element in the array until one matches or all elements have been checked.

This method requires a single argument.

  my $index = $cart->product_index( sub { $_->sku eq 'ABC' } );

=head2 product_push($product)

Like Perl's normal C<push> this adds the supplied L<Interchange::Cart::Product>
to L</products>.

=head2 product_set($index, $product)

Sets the product at the specified index in L</products> to the supplied
L<Interchange::Cart::Product>.

=head2 products_array

Returns an array of Interchange::Cart::Product(s)

=head2 new

Inherited method. Returns a new Cart object.

=head2 add($product)

Add product to the cart. Returns product in case of success.

The product is an L<Interchange6::Cart::Product> or a hash (reference) of product attributes that would be passed to Interchange6::Cart::Product->new().

=cut

sub add {
    my $self    = shift;
    my $product = $_[0];
    my $update;

    croak "undefined argument passed to add" unless defined $product;

    $product = use_module( $self->product_class )->new(@_)
      unless $product->$_isa( $self->product_class );

    # Cart may already contain an product with the same sku.
    # If so then we add quantity to existing product otherwise we add new
    # product.

    if ( $product->should_combine_by_sku ) {

        # product can be combined with existing product so look for one
        # that also allows combining

        my $index = $self->product_index(
            sub { $_->sku eq $product->sku && $_->should_combine_by_sku } );

        if ( $index >= 0 ) {

          # product already exists in cart so we need to add new quantity to old

            my $oldproduct = $self->product_get($index);

            $product->set_quantity(
                $oldproduct->quantity + $product->quantity );

            $self->product_set( $index, $product );

            $update = 1;
        }
    }

    if ( !$update ) {

        # a new product for this cart

        $product->set_cart($self);
        $self->product_push($product);
    }

    $self->clear_subtotal;
    $self->clear_weight;
    return $product;
}

=head2 find

Searches for a cart product with the given SKU.
Returns cart product in case of sucess or undef on failure.

  if ($product = $cart->find(9780977920174)) {
      print "Quantity: $product->quantity.\n";
  }

=cut

sub find {
    my ( $self, $sku ) = @_;
    $self->product_first( sub { $sku eq $_->sku } );
}

=head2 has_subtotal

predicate on L</subtotal>.

=head2 has_total

predicate on L</total>.

=head2 has_weight

predicate on L</weight>.

=head2 quantity

Returns the sum of the quantity of all products in the shopping cart,
which is commonly used as number of products. If you have 5 apples and 6 pears it will return 11.

  print 'Products in your cart: ', $cart->quantity, "\n";

=cut

sub quantity {
    my $self = shift;

    my $qty  = 0;
    foreach my $product ( $self->products_array ) {
       $qty += $product->quantity;
    }

    return $qty;
}

=head2 remove

Remove product from the cart. Takes SKU of product to identify the product.

    $self->remove('ABC123');

=cut

sub remove {
    my $self = shift;
    my $index;

    croak "no argument passed to remove" unless @_ && defined($_[0]);

    my %args = ref($_[0]) eq '' ? ( sku => $_[0] ) : %{ $_[0] };

    if ( defined $args{index} ) {
        croak "bad index supplied to remove" if $args{index} !~ /^\d+$/;

        $index = $args{index};
    }
    elsif ( defined $args{id} ) {
        my @cart_products =
          $self->product_grep( sub { defined $_->id && $_->id eq $args{id} } );

        if ( @cart_products == 1 ) {
            $index = $self->product_index(
                sub { defined $_->id && $_->id eq $args{id} } );
        }
        elsif ( @cart_products > 1 ) {
            croak "Cannot remove product with non-unique id";
        }
        else {
            croak "Product with id $args{id} not found in cart";
        }
    }
    elsif ( defined $args{sku} ) {
        my @cart_products =
          $self->product_grep( sub { $_->sku eq $args{sku} } );

        if ( @cart_products == 1 ) {
            $index = $self->product_index( sub { $_->sku eq $args{sku} } );
        }
        elsif ( @cart_products > 1 ) {
            croak "Cannot remove product with non-unique sku";
        }
        else {
            croak "Product with sku $args{sku} not found in cart";
        }
    }
    else {
        croak "Args to remove must include one of: index, id or sku";
    }

    my $ret = $self->product_delete($index);

    # if we got here then product_delete really shouldn't fail
    # uncoverable branch true
    croak "remove failed" unless defined $ret;

    $self->clear_subtotal;
    $self->clear_weight;
    return $ret;
}

=head2 seed $product_ref

Seeds products within the cart from $product_ref.

B<NOTE:> use with caution since any existing products in the cart will be lost.

  $cart->seed([
      { sku => 'BMX2015', price => 20, quantity = 1 },
      { sku => 'KTM2018', price => 400, quantity = 5 },
      { sku => 'DBF2020', price => 200, quantity = 5 },
  ]);

If any product fails to be added (for example bad product args) then an
exception is thrown and no products will be added to cart.

On success returns L</products>.

=cut

sub seed {
    my ( $self, $product_ref ) = @_;

    croak "argument to seed must be an array reference"
      unless ref($product_ref) eq 'ARRAY';

    my $product_class = use_module( $self->product_class );

    my @products;
    for my $args ( @{$product_ref} ) {
        push @products, $product_class->new($args);
    }
    $self->_set_products( \@products );

    $self->clear_subtotal;
    $self->clear_weight;
    return $self->products;
}

=head2 update

Update quantity of products in the cart.

Parameters are pairs of SKUs and quantities, e.g.

  $cart->update(9780977920174 => 5,
                9780596004927 => 3);

Or a list of hash references, e.g.

  $cart->update(
      { index => 3,      quantity => 2 },
      { id    => 73652,  quantity => 1 },
      { sku   => 'AJ12', quantity => 4 },
  );

A quantity of zero is equivalent to removing this product.

Returns an array of updated products that are still in the cart.
Products removed via quantity 0 or products for which quantity has not
changed will not be returned.

If you have products that cannot be combined in the cart (see
L<Interchange6::Cart::Product/combine> and 
L<Interchange6::Cart::Product/should_combine_by_sku>) then it is possible to
have multiple cart products with the same sku. In this case the arguments
to L</update> must be a list of hash references using either
L<Interchange6::Cart::Product/id> or C<index> where C<index> is
the zero-based index of the product within L</products>.

=cut

sub update {
    my ( $self, @args ) = @_;
    my @products;

  ARGS: while ( @args > 0 ) {

        my ( $product, $sku, $qty );

        if ( ref( $args[0] ) eq '' ) {

            # original API expecting list of sku/qty pairs

            $sku = shift @args;
            $qty = shift @args;

            croak "sku not defined in arg to update" unless defined $sku;

            my @cart_products = $self->product_grep( sub { $_->sku eq $sku } );

            if ( @cart_products == 0 ) {
                croak "Product for $sku not found in cart.";
            }
            elsif ( @cart_products == 1 ) {

                # one matching product
                $product = $cart_products[0];
            }
            else {
                croak "More than one product in cart with sku $sku. ",
                  "You must pass a hash reference to the update method ",
                  "including the cart position/index to update this sku.";
            }

        }
        elsif ( ref( $args[0] ) eq 'HASH' ) {

            # a hash reference of items that should reference a single product

            my %selectors = %{ shift @args };

            $qty = delete $selectors{quantity};

            if ( defined $selectors{index} ) {

                # select by position in cart
                croak "bad index for update" if $selectors{index} !~ /^\d+$/;

                $product = $self->product_get( $selectors{index} );
            }
            else {
                my @cart_products;

                if ( defined $selectors{id} ) {

                    # search by product id
                    @cart_products = $self->product_grep(
                        sub { defined $_->id && $_->id eq $selectors{id} } );
                }
                elsif ( defined $selectors{sku} ) {

                    # search by product sku
                    @cart_products =
                      $self->product_grep( sub { $_->sku eq $selectors{sku} } );
                }
                else {
                    croak "Args to update must include index, id or sku";
                }

                if ( @cart_products == 0 ) {
                    croak "Product not found in cart for update.";
                }
                elsif ( @cart_products == 1 ) {

                    # one matching product
                    $product = $cart_products[0];
                }
                else {
                    croak "More than one product found in cart for update.",;
                }
            }

        }
        else {
            croak "Unexpected ", ref( $args[0] ), " argument to update";
        }

        croak "Product not found for update" unless $product;

        defined($qty) && ref($qty) eq ''
          or croak "quantity argument to update must be defined";

        if ( $qty == 0 ) {
            $self->remove( $product->sku );
            next;
        }

        # jump to next product if quantity stays the same
        next ARGS if $qty == $product->quantity;

        $product->set_quantity($qty);
        push @products, $product;
    }

    $self->clear_subtotal;
    $self->clear_weight;
    return @products;
}

=head1 AUTHORS

 Stefan Hornburg (Racke), <racke@linuxia.de>
 Peter Mottram (SysPete), <peter@sysnix.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
