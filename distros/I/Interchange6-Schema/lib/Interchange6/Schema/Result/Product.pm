use utf8;

package Interchange6::Schema::Result::Product;

=head1 NAME

Interchange6::Schema::Result::Product

=cut

use base 'Interchange6::Schema::Base::Attribute';

use DateTime;
use Encode;
use Try::Tiny;

use Interchange6::Schema::Candy -components => [
    qw(
      InflateColumn::DateTime
      TimeStamp
      Helper::Row::SelfResultSet
      Helper::Row::ProxyResultSetMethod
      Helper::Row::OnColumnChange
      )
];

=head1 DESCRIPTION

The products table contains three product types parent, child and single.

=over

=item *

B<Parent Product> A parent product is a container product in which variations of parent product or "child products" are linked.

=item *

B<Child Product> A child product for example "Acme Pro 10lb Dumbbell" would include the canonical_sku of the parent item whose description might be something like "Acme Pro Dumbbell".  In general a child product would contain attributes while a parent product would not.

=item *

B<Single Product> A single product does not have child products and will become a parent product if a child product exists.

=back

=cut

=head1 ACCESSORS

=head2 image

This simple accessor is available to resultset searches which wish to add
column C<image> to stash an image in the result.

=cut

__PACKAGE__->mk_group_accessors( column => 'image' );

=head2 sku

SKU used by shop.

Primary key.

=cut

primary_column sku => {
    data_type     => "varchar",
    size          => 64
};

=head2 manufacturer_sku

Manufacturer's sku.

Is nullable.

=cut

column manufacturer_sku => {
    data_type   => "varchar",
    size        => 64,
    is_nullable => 1,
};

=head2 name

The name used to identify the product.

=cut

column name => {
    data_type     => "varchar",
    size          => 255
};

=head2 short_description

A brief summary of the product.

=cut

column short_description => {
    data_type     => "varchar",
    default_value => "",
    size          => 500
};

=head2 description

Full product description.

=cut

column description => {
    data_type     => "text"
};

=head2 price

Numeric value representing product cost.

Defaults to 0.

When C<price> is updated and product has related
L<Interchange6::Schema::Result::PriceModifier/discount> then also update
the related L<Interchange6::Schema::Result::PriceModifier/price>.
This is done using the method C<update_price_modifiers>.

=cut

# Max decimal places used by any currency as of 2015-12-01 is 3
#
# Note on amount of storage used by different backends for numeric/decimal:
#
# Pg: depends on the actual value being stored
# MySQL: 4 bytes for every 9 digits before and after the decimal point
#        with different amount for 'leftover' digits.
#        See: http://dev.mysql.com/doc/refman/5.1/en/precision-math-decimal-characteristics.html
#        So 20,3 takes 8 bytes for lhs and 2 for rhs = 10 total
#
column price => {
    data_type          => "numeric",
    size               => [ 21, 3 ],
    default_value      => 0,
    keep_storage_value => 1,
};

before_column_change price => {
    method   => 'update_price_modifiers',
    txn_wrap => 1,
};

=head2 uri

Unique product uri.  Example "acme-pro-dumbbells". Is nullable.

=cut

unique_column uri => {
    data_type     => "varchar",
    is_nullable   => 1,
    size => 255
};

=head2 weight

Numeric weight of the product. Defaults to zero.

=cut

column weight => {
    data_type   => "numeric",
    size        => [ 10, 2 ],
    default_value => 0
};

=head2 priority

Display order priority.

=cut

column priority => {
    data_type     => "integer",
    default_value => 0
};

=head2 gtin

Unique EAN or UPC type data. Is nullable.

=cut

unique_column gtin => {
    data_type     => "varchar",
    is_nullable   => 1,
    size          => 32
};

=head2 canonical_sku

The SKU of the main product if this product is a variant of a main product.  Is nullable.

=cut

column canonical_sku => {
    data_type     => "varchar",
    is_nullable   => 1,
    size          => 64
};

=head2 active

Is this product active? Default is yes.

=cut

column active => {
    data_type     => "boolean",
    default_value => 1
};

=head2 inventory_exempt

Is this product exempt from inventory? Default is no.

=cut

column inventory_exempt => {
    data_type     => "boolean",
    default_value => 0
};

=head2 combine

Indicate whether products with the same SKU should be combined in the Cart.

Defaults to true.

=cut

column combine => {
    data_type     => "boolean",
    default_value => 1,
};

=head2 created

Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created => {
    data_type     => "datetime",
    set_on_create => 1
};

=head2 last_modified

Date and time when this record was last modified returned as L<DateTime> object.
Value is auto-set on insert and update.

=cut

column last_modified => {
    data_type     => "datetime",
    set_on_create => 1,
    set_on_update => 1
};

=head1 RELATIONS

=head2 canonical

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Product>

=cut

belongs_to
  canonical => "Interchange6::Schema::Result::Product",
  { 'foreign.sku' => 'self.canonical_sku' },
  { join_type => 'left' };

=head2 variants

Type: has_many

Related object: L<Interchange6::Schema::Result::Product>

=cut

has_many
  variants => "Interchange6::Schema::Result::Product",
  { "foreign.canonical_sku" => "self.sku" },
  { cascade_copy            => 0, cascade_delete => 0 };

=head2 cart_products

Type: has_many

Related object: L<Interchange6::Schema::Result::CartProduct>

=cut

has_many
  cart_products => "Interchange6::Schema::Result::CartProduct",
  "sku",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 price_modifiers

Type: has_many

Related object: L<Interchange6::Schema::Result::PriceModifier>

=cut

has_many
  price_modifiers => "Interchange6::Schema::Result::PriceModifier",
  "sku";

=head2 inventory

Type: might_have

Related object: L<Interchange6::Schema::Result::Inventory>

=cut

might_have
  inventory => "Interchange6::Schema::Result::Inventory",
  "sku",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 media_products

Type: has_many

Related object: L<Interchange6::Schema::Result::MediaProduct>

=cut

has_many
  media_products => "Interchange6::Schema::Result::MediaProduct",
  "sku",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 merchandising_products

Type: has_many

Related object: L<Interchange6::Schema::Result::MerchandisingProduct>

=cut

has_many
  merchandising_products =>
  "Interchange6::Schema::Result::MerchandisingProduct",
  "sku",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 merchandising_product_related

Type: has_many

Related object: L<Interchange6::Schema::Result::MerchandisingProduct>

=cut

has_many
  merchandising_product_related =>
  "Interchange6::Schema::Result::MerchandisingProduct",
  { "foreign.sku_related" => "self.sku" },
  { cascade_copy          => 0, cascade_delete => 0 };

=head2 navigation_products

Type: has_many

Related object: L<Interchange6::Schema::Result::NavigationProduct>

=cut

has_many
  navigation_products => "Interchange6::Schema::Result::NavigationProduct",
  "sku",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 navigation

Type: many_to_many with navigation

=cut

many_to_many navigations => "navigation_products", "navigation";

=head2 orderlines

Type: has_many

Related object: L<Interchange6::Schema::Result::Orderline>

=cut

has_many
  orderlines => "Interchange6::Schema::Result::Orderline",
  "sku",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 product_attributes

Type: has_many

Related object: L<Interchange6::Schema::Result::ProductAttribute>

=cut

has_many
  product_attributes => "Interchange6::Schema::Result::ProductAttribute",
  "sku",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 media

Type: many_to_many with media

=cut

many_to_many media => "media_products", "media";

=head2 product_messages

Type: has_many

Related object: L<Interchange6::Schema::Result::ProductMessage>

=cut

has_many
  product_messages => "Interchange6::Schema::Result::ProductMessage",
  "sku", { cascade_copy => 0 };

=head2 messages

Type: many_to_many

Accessor to related Message results.

=cut

many_to_many messages => "product_messages", "message";

=head1 METHODS

Attribute methods are provided by the L<Interchange6::Schema::Base::Attribute> class.

=head2 insert

Override inherited method to call L</generate_uri> method in case L</name>
and L</sku> have been supplied as arguments but L</uri> has not.

=cut

sub insert {
    my ( $self, @args ) = @_;
    $self->generate_uri unless $self->uri;
    $self->next::method(@args);
    return $self;
}

=head2 update_price_modifiers

Called when L</price> is updated.

=cut

sub update_price_modifiers {
    my ( $self, $old_value, $new_value ) = @_;

    my $price_modifiers =
      $self->price_modifiers->search( { discount => { '!=' => undef } } );

    while ( my $result = $price_modifiers->next ) {
        $result->update(
            {
                price => sprintf( "%.2f",
                    $new_value - ( $new_value * $result->discount / 100 ) )
            }
        );
    }
}

=head2 generate_uri($attrs)

Called by L</new> if no uri is given as an argument.

The following steps are taken:

=over

1. Join C<< $self->name >> and C<< $self->uri >> with C<-> and stash
in C<$uri> to allow manipulation via filters

2. Remove leading and trailing spaces and replace remaining spaces and
C</> with C<->

3. Search for all rows in L<Interchange6::Schema::Result::Setting> where
C<scope> is C<Product> and C<name> is <generate_uri_filter>

4. For each row found eval C<< $row->value >>

5. Finally set the value of column L</uri> to C<$uri>

=back

Filters stored in L<Interchange6::Schema::Result::Setting> are executed via
eval and have access to C<$uri> and also the product result held in 
C<$self>

Examples of filters stored in Setting might be:

    {
        scope => 'Product',
        name  => 'generate_uri_filter',
        value => '$uri =~ s/badstuff/goodstuff/gi',
    },
    {
        scope => 'Product',
        name  => 'generate_uri_filter',
        value => '$uri = lc($uri)',
    },

=cut

sub generate_uri {
    my $self = shift;

    my $uri = join("-", $self->name, $self->sku);

    # make sure we have clean utf8
    try {
        $uri = Encode::decode( 'UTF-8', $uri, Encode::FB_CROAK )
          unless utf8::is_utf8($uri);
    }
    catch {
        # Haven't yet found a way to get here :)
        # uncoverable subroutine
        # uncoverable statement
        $self->throw_exception(
            "Product->generate_uri failed to decode UTF-8 text: $_" );
    };

    $uri =~ s/^\s+//;       # remove leading space
    $uri =~ s/\s+$//;       # remove trailing space
    $uri =~ s{[\s/]+}{-}g;  # change space and / to -

    my $filters = $self->result_source->schema->resultset('Setting')->search(
        {
            scope => 'Product',
            name  => 'generate_uri_filter',
        },
    );

    while ( my $filter = $filters->next ) {
        eval $filter->value;
        $self->throw_exception("Product->generate_uri filter croaked: $@")
          if $@;
    }

    $self->uri($uri);
}

=head2 path

Produces navigation path for this product.
Returns array reference in scalar context.

Uses $type to select specific taxonomy from navigation if present.

=cut

sub path {
    my ( $self, $type ) = @_;

    my $options = {};

    if ( defined $type ) {
        $options = { "navigation.type" => $type };
    }

    # search navigation entries for this product
    my $navigation_product = $self->search_related(
        'navigation_products',
        $options,
        {
            prefetch => 'navigation',
            order_by => {
                -desc =>
                  [ 'me.priority', 'navigation.priority' ]
            },
            rows => 1,
        }
    )->single;

    my @path;

    if ( defined $navigation_product ) {
        my $nav = $navigation_product->navigation;
        my @anc = $nav->ancestors;

        @path = ( @anc, $nav );
    }

    return wantarray ? @path : \@path;
}

#=head2 tier_pricing
#
#Tier pricing can be calculated for a single role and also a combination of several roles.
#
#=over 4
#
#=item Arguments: array reference of L<Role names|Interchange6::Schema::Result::Role/name>
#
#=item Return Value: in scalar context an array reference ordered by quantity ascending of hash references of quantity and price, in list context returns an array instead of array reference
#
#=back
#
#The method always returns the best price for specific price points including
#any PriceModifier rows where roles_id is undef.
#
#  my $aref = $product->tier_pricing( 'trade' );
#
#  # [ 
#  #   { quantity => 1,   price => 20 }, 
#  #   { quantity => 10,  price => 19 }, 
#  #   { quantity => 100, price => 18 }, 
#  # ]
#
#=cut
#
## TODO: SysPete is not happy with the initial version of this method.
## Patches always welcome.
#
#sub tier_pricing {
#    my ( $self, $args ) = @_;
#
#    my $cond = { 'role.name' => undef };
#
#    if ( $args ) {
#        $self->throw_exception(
#            "Argument to tier_pricing must be an array reference")
#          unless ref($args) eq 'ARRAY';
#
#        $cond = { 'role.name' => [ undef, { -in => $args } ] };
#    }
#
#    my @result = $self->price_modifiers->search(
#        $cond,
#        {
#            join   => 'role',
#            select => [ 'quantity', { min => 'price' } ],
#            as       => [ 'quantity', 'price' ],
#            group_by => 'quantity',
#            order_by => { -asc => 'quantity' },
#            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
#        },
#    )->all;
#
#    if ( scalar @result && $result[0]->{quantity} < 1 ) {
#
#        # zero or minus qty should not be possible so we adjust to one if found
#
#        $result[0]->{quantity} = 1;
#    }
#
#    # maybe no qty 1 tier is defined so make sure we've got one
#
#    if ( scalar @result && $result[0]->{quantity} == 1 ) {
#        $result[0]->{price} = $self->price
#          if $self->price < $result[0]->{price};
#    }
#    else {
#        unshift @result, +{ quantity => 1, price => $self->price };
#    }
#
#    # Remove quantities that are inappropriate due to price at higher
#    # quantity being higher (or same as) that a price at a lower quantity.
#    # Normally caused when there are different price breaks for different
#    # roles but we have been asked to combine multiple roles.
#
#    my @return;
#    my $previous;
#    foreach my $i ( @result ) {
#        push @return, $i;
#        unless ( defined $previous ) {
#            $previous = $i->{price};
#            next;
#        }
#        pop @return unless $i->{price} < $previous;
#    }
#
#    return wantarray ? @return : \@return;
#}

=head2 selling_price

Arguments should be given as a hash reference with the following keys/values:

=over 4

=item * quantity => $quantity

C<quantity> defaults to 1 if not supplied.

=back

PriceModifier rows which have C<roles_id> undefined are always included in the
search in addition to any C<roles> that belonging to L<Schema/logger_in_user>.
This enables promotional prices to be specified between fixed dates in
L<Interchange6::Schema::Result::PriceModifier/price> to apply to all classes
of user whether logged in or not.

Returns lowest price from L</price> and
L<Interchange6::Schema::Result::PriceModifier/price>.

Throws exception on bad arguments though unexpected keys in the hash reference
will be silently discarded.

If the query was constructed using
L<Interchange6::Schema::ResultSet::Product/with_lowest_selling_price> then
the cached value will be used rather than running a new query B<UNLESS>
arguments are supplied in which case a new query is performed.

=cut

sub selling_price {
    my ( $self, $args ) = @_;

    my $schema = $self->result_source->schema;

    my $price = $self->price;

    if ( $self->has_column_loaded('selling_price') && !defined $args ) {

        # initial query on Product already included selling_price so use it

        return $self->get_column('selling_price');
    }

    if ($args) {
        $self->throw_exception(
            "Argument to selling_price must be a hash reference")
          unless ref($args) eq 'HASH';
    }
    else {
        $args = {};
    }

    # quantity

    if ( defined $args->{quantity} ) {
        $self->throw_exception(
            sprintf( "Bad quantity: %s", $args->{quantity} ) )
          unless $args->{quantity} =~ /^\d+$/;
    }
    else {
        $args->{quantity} = 1;
    }

    # start building the the search condition

    my $today = $schema->format_datetime(DateTime->today);

    my $search_condition = {
        quantity   => { '<=', $args->{quantity} },
        start_date => [ undef, { '<=', $today } ],
        end_date   => [ undef, { '>=', $today } ],
        roles_id   => undef,
    };

    if ( my $user = $schema->current_user ) {

        # add roles_id condition

        $search_condition->{roles_id} = [
            undef,
            {
                -in => $schema->resultset('UserRole')
                  ->search( { users_id => $user->id } )->get_column('roles_id')
                  ->as_query
            }
        ];
    }

    # now finally we can see if there is a better price for this customer

    my $selling_price =
      $self->price_modifiers->search($search_condition)->get_column('price')
      ->min;

    return
      defined $selling_price
      && $selling_price < $price ? $selling_price : $price;
}

=head2 highest_price

If this is a canonical product without variants or a variant product then
this method will return undef. If highest price is the same as L</selling_price>
then we again return undef.

If the query was constructed using
L<Interchange6::Schema::ResultSet::Product/with_highest_price> then
the cached value will be used rather than running a new query.

This method calls L</variant_count> and L</selling_price> so when constructing
a resultset query consider also chaining the associated ResultSet methods.

=cut

sub highest_price {
    my $self = shift;

    return undef unless $self->variant_count;

    my $highest_price;

    if ( $self->has_column_loaded('highest_price') ) {
        $highest_price = $self->get_column('highest_price');
    }
    else {
        $highest_price = $self->variants->get_column('price')->max;
    }

    if ( $self->has_column_loaded('selling_price') ) {
        return $highest_price if $highest_price > $self->selling_price;
        return undef;
    }

    if ( $highest_price >
        $self->self_rs->with_lowest_selling_price->single->selling_price )
    {
        return $highest_price;
    }

    return undef;
}

=head2 find_variant \%input [\%match_info]

Find product variant with the given attribute values
in $input.

Returns variant in case of success.

Returns undef in case of failure.

You can pass an optional hash reference \%match_info
which is filled with attribute matches (only valid
in case of failure).

=cut

sub find_variant {
    my ( $self, $input, $match_info ) = @_;

    if ( $self->canonical_sku ) {
        return $self->canonical->find_variant( $input, $match_info );
    }

    my $gather_matches;

    if ( ref($match_info) eq 'HASH' ) {
        $gather_matches = 1;
    }

    # get all variants
    my $all_variants = $self->search_related('variants');
    my $variant;

    while ( $variant = $all_variants->next ) {
        my $sku;

        if ($gather_matches) {
            $sku = $variant->sku;
        }

        my $variant_attributes = $variant->search_related(
            'product_attributes',
            {
                'attribute.type' => 'variant',
            },
            {
                join     => 'attribute',
                prefetch => 'attribute',
            },
        );

        my %match;

        while ( my $prod_att = $variant_attributes->next ) {
            my $name = $prod_att->attribute->name;

            my $pav_rs =
              $prod_att->search_related( 'product_attribute_values', {},
                { join => 'attribute_value', prefetch => 'attribute_value' } );

            if (   $pav_rs->count != 1
                || !defined $input->{$name}
                || $pav_rs->next->attribute_value->value ne $input->{$name} )
            {
                if ($gather_matches) {
                    $match_info->{$sku}->{$name} = 0;
                    next;
                }
                else {
                    last;
                }
            }

            if ($gather_matches) {
                $match_info->{$sku}->{$name} = 1;
            }

            $match{$name} = 1;
        }

        if ( scalar( keys %$input ) == scalar( keys %match ) ) {
            return $variant;
        }
    }

    return;
}

=head2 attribute_iterator( %args )

=over 4

=item Arguments: C<< hashref => 1 >>

=back

Return a hashref of attributes keyed on attribute name instead of an arrayref.

=over 4

=item Arguments: C<< selected => $sku >>

=back

Set the 'selected' SKU. For a child product this is set automatically.

=over 4

=item Arguments: C<< cond => $cond >>

=back

Search condition to use. Default is:

    { 'attribute.type' => 'variant' }

=over 4

=item Arguments: C<< order_by => $order_by >>

=back

Ordering to use in query. Default is:

    [
        { -desc => 'attribute.priority' },
        { -asc => 'attribute.title' },
        { -desc => 'attribute_value.priority' },
        { -asc => 'attribute_value.title' },
    ]

Set the 'selected' SKU. For a child product this is set automatically.

=over 4

=item Returns: An arrayref of attributes complete with their respective attribute values.

=back

For canonical products, it shows all the attributes of the child products.

For a child product, it shows all the attributes of the siblings.

Example of returned arrayref:

   [
     {
       attribute_values => [
         {
           priority => 2,
           selected => 0,
           title => "Pink",
           value => "pink"
         },
         {
           priority => 1,
           selected => 0,
           title => "Yellow",
           value => "yellow"
         }
       ],
       name => "color",
       priority => 2,
       title => "Color"
     },
     {
       attribute_values => [
         {
           priority => 2,
           selected => 0,
           title => "Small",
           value => "small"
         },
         {
           priority => 1,
           selected => 0,
           title => "Medium",
           value => "medium"
         },
       ],
       name => "size",
       priority => 1,
       title => "Size"
     }
   ]

=cut

sub attribute_iterator {
    my ( $self, %args ) = @_;
    my ($canonical);

    if ( $canonical = $self->canonical ) {

        # get canonical object
        $args{selected} = $self->sku;
        return $canonical->attribute_iterator(%args);
    }

    my $cond = {
        'attribute.type' => 'variant',
    };

    $cond = $args{cond} if defined $args{cond};

    my $order_by = [
        { -desc => 'attribute.priority' },
        { -asc => 'attribute.title' },
        { -desc => 'attribute_value.priority' },
        { -asc => 'attribute_value.title' },
    ];

    $order_by = $args{order_by} if defined $args{order_by};

    # search for variants
    my @prod_atts = $self->search_related('variants')->search_related(
        'product_attributes',
        $cond,
        {
            join    => [
                'attribute', { product_attribute_values => 'attribute_value' },
            ],
            prefetch => [
                'attribute', { product_attribute_values => 'attribute_value' },
            ],
            order_by => $order_by,
        }
    )->hri->all;

    my %attributes;
    my @ordered_names;
    foreach my $prod_att ( @prod_atts ) {
        my $name = $prod_att->{attribute}->{name};

        unless ( exists $attributes{$name} ) {
            push @ordered_names, $name;
            $attributes{$name} = {
                name             => $name,
                title            => $prod_att->{attribute}->{title},
                priority         => $prod_att->{attribute}->{priority},
                value_map        => {},
                attribute_values => [],
            };
        }

        my $att_record = $attributes{$name};

        foreach my $prod_att_val ( @{ $prod_att->{product_attribute_values} } )
        {
            my %attr_value = (
                value    => $prod_att_val->{attribute_value}->{value},
                title    => $prod_att_val->{attribute_value}->{title},
                priority => $prod_att_val->{attribute_value}->{priority},
                selected => 0,
            );

            if ( !exists $att_record->{value_map}->{ $attr_value{value} } ) {
                $att_record->{value_map}->{ $attr_value{value} } = \%attr_value;
                push @{$attributes{$name}->{attribute_values}}, \%attr_value;
            }

            # determined whether this is the current attribute
            if ( $args{selected} && $prod_att->{sku} eq $args{selected} ) {
                $att_record->{value_map}->{ $attr_value{value} }->{selected} =
                  1;
            }
        }
    }

    foreach my $key ( keys %attributes ) {
        delete $attributes{$key}->{value_map};
    }

    if ( $args{hashref} ) {
        return \%attributes;
    }

    return [ map { $attributes{$_} } @ordered_names ];
}

=head2 add_variants @variants

Add variants from a list of hash references.

Returns product object.

Each hash reference contains attributes and column
data which overrides data from the canonical product.

The canonical sku of the variant is automatically set.

Example for the hash reference (attributes in the first line):

     {color => 'yellow', size => 'small',
      sku => 'G0001-YELLOW-S',
      name => 'Six Small Yellow Tulips',
      uri => 'six-small-yellow-tulips'}

Since there is a risk that attributes names might clash with Product column
names (for example L</weight>) an improved syntax exists to prevent such
problems. This is considered to be the preferred syntax:

    {
        sku   => 'ROD00014-2-6-mid',
        uri   => 'fishingrod-weight-2-length-6-flex-mid',
        price => 355,
        attributes => [
            { weight => '2' },
            { length => '6' },
            { action => 'mid' },
        ],
    }

=cut

sub add_variants {
    my ( $self, @variants ) = @_;
    my %attr_map;
    my $attr_rs = $self->result_source->schema->resultset('Attribute');

    for my $var_ref (@variants) {
        my ( %attr, %product, $sku );

        unless ( exists $var_ref->{sku} && ( $sku = $var_ref->{sku} ) ) {
            die "SKU missing in input for add_variants.";
        }

        if ( defined $var_ref->{attributes} ) {

            # new syntax with explicit attributes

            %attr = %{ delete $var_ref->{attributes} };
        }

        # weed out attribute values that might be mixed in with columns
        # as happens with old syntax

        while ( my ( $name, $value ) = each %$var_ref ) {
            if ( $self->result_source->has_column($name) ) {
                $product{$name} = $value;
            }
            else {
                $attr{$name} = $value;
            }
        }

        while ( my ( $name, $value ) = each %attr ) {

            my ( $attribute, $attribute_value );

            if ( !$attr_map{$name} ) {
                my $set = $attr_rs->search(
                    {
                        name => $name,
                        type => 'variant',
                    }
                );

                if ( !( $attribute = $set->next ) ) {
                    die "Missing variant attribute '$name' for SKU $sku";
                }

                $attr_map{$name} = $attribute;
            }

            # search for attribute value
            unless ( $attribute_value =
                $attr_map{$name}
                ->find_related( 'attribute_values', { value => $value } ) )
            {
                die "Missing variant attribute value '$value'"
                  . " for attribute '$name' and SKU $sku";
            }

            $attr{$name} = $attribute_value;
        }

        # clone with new values
        $product{canonical_sku} = $self->sku;

        $self->copy( \%product );

        # find or create product attribute and product attribute value
        while ( my ( $name, $value ) = each %attr ) {
            my $product_attribute = $attr_map{$name}
              ->find_or_create_related( 'product_attributes', { sku => $sku } );

            $product_attribute->create_related( 'product_attribute_values',
                { attribute_values_id => $value->id } );
        }
    }

    return $self;
}

=head2 discount_percent

If L</selling_price> is lower than L</price> returns the rounded percentage
discount or undef.

B<NOTE:> for parent products (products that have variants) this will always
return undef.

=cut

sub discount_percent {
    my $self = shift;

    if ( $self->variant_count || $self->selling_price == $self->price ) {
        return undef;
    }

    return sprintf( "%.0f",
        ( $self->price - $self->selling_price ) / $self->price * 100 );

}

=head2 media_by_type

Return a Media resultset with the related media, filtered by type
(e.g. video or image). On the results you can call
C<display_uri("type")> to get the actual uri.

=cut

sub media_by_type {
    my ( $self, $typename ) = @_;
    my @media_out;

    # track back the schema and search the media type id
    my $type = $self->result_source->schema->resultset('MediaType')
      ->find( { type => $typename } );
    return unless $type;
    return $self->media->search(
        {
            media_types_id => $type->media_types_id,
        },
        {
            order_by => 'uri',
        }
    );
}

=head2 product_reviews

Reviews should only be associated with parent products.

This method returns the related L<Interchange6::Schema::Result::ProductMessage>
records for a parent product where the related
L<Interchange6::Schema::Result::Message> has
L<Interchange6::Schema::Result::MessageType/name> of C<product_review>.
For a child product the ProductReview records for the parent are returned.

=cut

sub product_reviews {
    my $self = shift;

    $self = $self->canonical if $self->canonical_sku;

    return $self->product_messages->search(
        {
            'message_type.name' => 'product_review',
        },
        {
            join => { message => 'message_type' },
        }
    );
}

=head2 reviews

Reviews should only be associated with parent products. This method returns the related Message (reviews) records for a parent product. For a child product the Message records for the parent are returned.

=over

=item * Arguments: L<$cond|DBIx::Class::SQLMaker> | undef, L<\%attrs?|DBIx::Class::ResultSet#ATTRIBUTES>

=back

Arguments are passed as paremeters to search the related reviews.

=cut

sub reviews {
    my $self = shift;

    # use parent if I have one
    $self = $self->canonical if $self->canonical_sku;

    return $self->product_reviews->search_related('message', @_);
}

=head2 top_reviews

Returns the highest-rated approved public reviews for this product. Argument is max number of reviews to return which defaults to 5.

=cut

sub top_reviews {
    my ( $self, $rows ) = @_;
    $rows = 5 unless defined $rows;
    return $self->reviews( { public => 1, approved => 1 },
        { rows => $rows, order_by => { -desc => 'rating' } } );
}

=head2 variant_count

Returns the number of variants of this product.

=cut

proxy_resultset_method 'variant_count';

=head2 has_variants

Alias for L</variant_count> for backwards-compatibility.

=cut

sub has_variants {
    return shift->variant_count;
}

=head2 average_rating

Returns the average rating across all public and approved product reviews or undef if there are no reviews. Optional argument number of decimal places of precision must be a positive integer less than 10 which defaults to 1.

If the query was constructed using
L<Interchange6::Schema::ResultSet::Product/with_average_rating> then
the cached value will be used rather than running a new query.

=cut

proxy_resultset_method _average_rating => {
    slot             => 'average_rating',
    resultset_method => 'with_average_rating',
};

sub average_rating {
    my ( $self, $precision ) = @_;

    $precision = 1 unless ( defined $precision && $precision =~ /^\d$/ );

    my $avg = $self->_average_rating;

    return defined $avg ? sprintf( "%.*f", $precision, $avg ) : undef;
}

=head2 add_to_reviews

Reviews should only be associated with parent products. This method returns the related ProductReview records for a parent product. For a child product the ProductReview records for the parent are returned.

=cut

# much of this was cargo-culted from DBIx::Class::Relationship::ManyToMany

sub add_to_reviews {
    my $self = shift;
    @_ > 0
      or $self->throw_exception( "add_to_reviews needs an object or hashref" );
    my $rset_message = $self->result_source->schema->resultset("Message");
    my $obj;
    if ( ref $_[0] ) {
        if ( ref $_[0] eq 'HASH' ) {
            $_[0]->{type} = "product_review";
            $obj = $rset_message->create( $_[0] );
        }
        else {
            $obj = $_[0];
            unless ( my $type = $obj->message_type->name eq "product_review" ) {
                $self->throw_exception(
                    "cannot add message type $type to reviews" );
            }
        }
    }

    $self->throw_exception("Bad argument supplied to add_to_reviews")
      unless $obj;

    # uncoverable condition left
    # uncoverable condition false
    my $sku = $self->canonical_sku ? $self->canonical_sku : $self->sku;
    $self->product_messages->create( { sku => $sku, messages_id => $obj->id } );
    return $obj;
}

=head2 set_reviews

=over 4

=item Arguments: (\@hashrefs_of_col_data | \@result_objs)

=item Return Value: not defined

=back

Similar to L<DBIx::Class::Relationship::Base/set_$rel> except that this method DOES delete objects in the table on the right side of the relation.

=cut

sub set_reviews {
    my $self = shift;
    @_ > 0
      or $self->throw_exception(
        "set_reviews needs a list of objects or hashrefs" );
    my @to_set = ( ref( $_[0] ) eq 'ARRAY' ? @{ $_[0] } : @_ );
    $self->product_reviews->delete_all;
    $self->add_to_reviews( $_ ) for (@to_set);
}

=head2 quantity_in_stock

Returns undef if L<inventory_exempt> is true and otherwise returns the
quantity of the product in the inventory. For a product variant the
quantity returned is for the variant itself whereas for a canonical
(parent) product the quantity returned is the total for all variants.

If the query was constructed using
L<Interchange6::Schema::ResultSet::Product/with_quantity_in_stock> then
the cached value will be used rather than running a new query.

=cut

sub quantity_in_stock {
    my $self = shift;

    # if already loaded by resultset query then return that value
    return $self->get_column('quantity_in_stock')
      if $self->has_column_loaded('quantity_in_stock');

    my $quantity;
    my $variants = $self->variants;
    if ( $variants->has_rows ) {
        my $not_exempt = $variants->search( { inventory_exempt => 0 } );
        if ( $not_exempt->has_rows ) {
            $quantity = $not_exempt->search_related( 'inventory',
                { quantity => { '>' => 0 } } )->get_column('quantity')->sum;
        }
    }
    elsif ( ! $self->inventory_exempt ) {
        my $inventory = $self->inventory;
        $quantity = defined $inventory ? $self->inventory->quantity : 0;
    }
    return $quantity;
}

=head2 delete

Overload delete to force removal of any product reviews. Only parent products should have reviews so in the case of child products no attempt is made to delete reviews.

=cut

# FIXME: (SysPete) There ought to be a way to force this with cascade delete.

sub delete {
    my ( $self, @args ) = @_;
    my $guard = $self->result_source->schema->txn_scope_guard;
    $self->product_reviews->delete_all unless defined $self->canonical_sku;
    $self->next::method(@args);
    $guard->commit;
}

1;
