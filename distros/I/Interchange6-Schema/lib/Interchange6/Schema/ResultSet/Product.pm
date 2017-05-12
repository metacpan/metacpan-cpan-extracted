use utf8;

package Interchange6::Schema::ResultSet::Product;

=head1 NAME

Interchange6::Schema::ResultSet::Product

=cut

=head1 SYNOPSIS

Provides extra accessor methods for L<Interchange6::Schema::Result::Product>

=cut

use strict;
use warnings;
use mro 'c3';

use parent 'Interchange6::Schema::ResultSet';

=head1 METHODS

See also L<DBIx::Class::Helper::ResultSet::Shortcut> which is loaded by this
result set.

=head2 active

Returns all rows where L<Interchange6::Schema::Result::Product/active> is true.

=cut

sub active {
    return $_[0]->search({ $_[0]->me('active') => 1 });
}

=head2 canonical_only

Returns all rows where L<Interchange6::Schema::Result::Product/canonical_sku>
is null, i.e. only canonical products.

=cut

sub canonical_only {
    return $_[0]->search({ $_[0]->me('canonical_sku') => undef });
}

=head2 listing

This is just a shortcut for:

  $self->columns( [ 'sku', 'name', 'uri', 'price', 'short_description' ] )
      ->with_average_rating
      ->with_lowest_selling_price
      ->with_highest_price
      ->with_quantity_in_stock
      ->with_variant_count

Though in addition if you pass in arguments these are passed through to the
appropriate with_* method so you can do:

  $self->listing({ quantity => 10 })

And the result will be:

  $self->columns( [ 'sku', 'name', 'uri', 'price', 'short_description' ] )
      ->with_average_rating
      ->with_lowest_selling_price({ quantity => 10 })
      ->with_highest_price
      ->with_quantity_in_stock
      ->with_variant_count

=cut

sub listing {
    my ( $self, $args ) = @_;
    return $self->columns(
        [ 'sku', 'name', 'uri', 'price', 'short_description' ] )
      ->with_average_rating->with_lowest_selling_price(
        {
            quantity => $args->{quantity},
        }
      )->with_highest_price->with_quantity_in_stock->with_variant_count;
}

=head2 with_average_rating

Adds C<average_rating> column which is available to order_by clauses and
whose value can be retrieved via
L<Interchange6::Schema::Result::Product/average_rating>.

This is the average rating across all public and approved product reviews or
undef if there are no reviews. Product reviews are only related to canonical
products so for variants the value returned is that of the canonical product.

=cut

sub with_average_rating {
    my $self = shift;

    return $self->search(
        undef,
        {
            '+select' => [
                {
                    coalesce => [

                        $self->correlate('canonical')
                          ->related_resultset('product_messages')
                          ->search_related(
                            'message',
                            { 'message.approved' => 1, 'message.public' => 1,
                           'message_type.name' => 'product_review' },
                            { join => 'message_type' },
                          )->get_column('rating')->func_rs('avg')->as_query,

                        $self->correlate('product_messages')
                          ->search_related(
                            'message',
                            { 'message.approved' => 1, 'message.public' => 1,
                           'message_type.name' => 'product_review' },
                            { join => 'message_type' },
                          )->get_column('rating')->func_rs('avg')->as_query,

                      ],
                    -as => 'average_rating'
                }
            ],
            '+as' => ['average_rating'],
        }
    );
}

=head2 with_media $type?

Prefetch related active L<Interchange6::Schema::Result::Media> where
L<Interchange6::Schema::Result::MediaType/type> is C<$type>.

C<$type> defaults to C<image> if not provided.

=cut

sub with_media {
    my $self = shift;
    my $type = defined $_[0] ? $_[0] : 'image';

    return $self->search(
        {
            'media.active'    => 1,
            'media_type.type' => $type,
        },
        {
            prefetch => { media_products => 'media' },
            join     => { media_products => { media => 'media_type' } },
        }
    );
}

=head2 with_quantity_in_stock

Adds C<quantity_in_stock> column which is available to order_by clauses and
whose value can be retrieved via
L<Interchange6::Schema::Result::Product/quantity_in_stock>.

The value is retrieved is L<Interchange6::Schema::Result::Inventory/quantity>.

For a product variant and for a canonical product with no variants the
quantity returned is for the product itself.

For a canonical (parent) product the quantity returned is the total for all its
variants.

=cut

sub with_quantity_in_stock {
    my $self = shift;

    return $self->search(
        undef,
        {
            '+select' => [
                {
                    coalesce => [

                        $self->correlate('variants')
                          ->related_resultset('inventory')
                          ->get_column('quantity')->sum_rs->as_query,

                        $self->correlate('inventory')->get_column('quantity')
                          ->as_query,

                    ],
                    -as => 'quantity_in_stock',
                }
            ],
            '+as' => ['quantity_in_stock'],
        }
    );
}

=head2 with_lowest_selling_price

Arguments should be given as a hash reference with the following keys/values:

=over 4

=item * quantity => $quantity

C<quantity> defaults to 1 if not supplied.

=back

The lowest of L<Interchange6::Schema::Result::PriceModifier/price> and
L<Interchange6::Schema::Result::Product/price>.

For products with variants this is the lowest variant selling_price.

Value is placed in the column C<selling_price>.

If L<Schema/current_user> is defined then any roles assigned to that
user will be included in the search of
L<Interchange6::Schema::Result::PriceModifier>.

=cut

sub with_lowest_selling_price {
    my ( $self, $args ) = @_;

    if ( defined($args) ) {
        $self->throw_exception(
            "argument to with_lowest_selling_price must be a hash reference")
          unless ref($args) eq "HASH";
    }

    $args->{quantity} = 1 unless defined $args->{quantity};

    my $schema = $self->result_source->schema;

    my $today = $schema->format_datetime(DateTime->today);

    # start building the search condition

    my $search_cond = {
        'start_date' => [ undef, { '<=', $today } ],
        'end_date'   => [ undef, { '>=', $today } ],
        'quantity'   => { '<=' => $args->{quantity} },
        'roles_id'   => undef,
    };

    if ( my $user = $schema->current_user ) {

        # add roles_id condition

        $search_cond->{roles_id} = [
            undef,
            {
                -in => $schema->resultset('UserRole')
                  ->search( { users_id => $user->id } )
                  ->get_column('roles_id')->as_query
            }
        ];
    }

    # most db engines have 'least' but SQLite has 'min'

    my $least = 'least';
    $least = 'min' if $schema->storage->sqlt_type eq 'SQLite';

    # much hoop jumping required to make sure we don't trip over nulls
    #
    # see:
    # https://dev.mysql.com/doc/refman/5.0/en/comparison-operators.html#function_least
    #
    # which states:
    # Before MySQL 5.0.13, LEAST() returns NULL only if all arguments are NULL.
    # As of 5.0.13, it returns NULL if any argument is NULL. 
    # 
    # Complete madness!
    #
    # Compare to the sanity of PostgreSQL:
    # NULL values in the list are ignored. The result will be NULL only if all
    # the expressions evaluate to NULL.

    my $variant_price_modifiers =
      $self->correlate('variants')
      ->search_related( 'price_modifiers', $search_cond )->get_column('price')
      ->min_rs->as_query;

    my $variant_prices =
      $self->correlate('variants')->get_column('price')->min_rs->as_query;

    my $self_price_modifiers =
      $self->correlate('price_modifiers')->search( $search_cond )
      ->get_column('price')->min_rs->as_query;

    my $return = $self->search(
        undef,
        {
            '+select' => [
                {
                    coalesce => [
                        {
                            $least => [
                                {
                                    coalesce => [
                                        $variant_price_modifiers,
                                        $variant_prices
                                    ]
                                },
                                $variant_prices
                            ]
                        },
                        {
                            coalesce =>
                              [ $self_price_modifiers, $self->me('price') ],

                        },
                    ],
                    -as => 'selling_price'
                }
            ],
            '+as' => ['selling_price'],
        }
    );
    return $return;
}

=head2 with_highest_price

For canonical products with no variants and for variant products 
C<highest_price> is always undef. For canonical products that have variants
this is the highest of L<Interchange6::Schema::Result::Product/price> of
the variants.

=cut

sub with_highest_price {
    my $self = shift;

    my $schema = $self->result_source->schema;

    return $self->search(
        undef,
        {
            '+columns' => {
                highest_price => {
                    coalesce => [
                        $self->correlate('variants')->get_column('price')
                          ->max_rs->as_query,
                        $self->me('price')
                    ]
                }
            }
        }
    );
}

=head2 with_variant_count

Adds column C<variant_count> which is a count of variants of each product.

=cut

sub with_variant_count {
    my $self = shift;
    return $self->search(
        undef,
        {
            '+columns' => {
                variant_count =>
                  $self->correlate('variants')->count_rs->as_query
            }
        }
    );
}

1;
