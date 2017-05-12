package Test::PriceModifier;

use Test::Deep;
use Test::Exception;
use Test::Roo::Role;
use Test::MockTime qw( :all );
use DateTime;

test 'pricing tests' => sub {

    my $self      = shift;
    my $schema    = $self->ic6s_schema;
    my $rset_pm   = $schema->resultset('PriceModifier');
    my $rset_role = $schema->resultset('Role');

    # fixtures
    $self->products unless $self->has_products;
    $self->navigation unless $self->has_navigation;
    $self->price_modifiers unless $self->has_price_modifiers;

    my ( $role_multi, $product, $nav, $products, @products );

    cmp_ok( $rset_role->find({ name => 'trade' })->label,
        'eq', 'Trade customer', "Trade customer role exists" );

    cmp_ok( $rset_role->find({ name => 'user' })->label,
        'eq', 'User', "User role exists" );

    lives_ok( sub { $product = $self->products->find('os28005') },
        "Find product os28005" );

    # sqlite uses float for numerics and messes them up so use sprintf in
    # all following tests that compare non-integer values

    # price always fixed

    cmp_ok( sprintf( "%.02f", $product->price ),
        '==', 8.99, "price is 8.99" );

    # end of 1999

    set_absolute_time('1999-12-31T23:59:59Z');

    cmp_ok( sprintf( "%.02f", $product->selling_price ),
        '==', 8.99, "selling_price is 8.99" );

    # during 2000

    set_absolute_time('2000-06-01T00:00:00Z');

    cmp_ok( sprintf( "%.02f", $product->selling_price ),
        '==', 7.50, "selling_price is 7.50" );

    cmp_ok( sprintf( "%.02f", $product->selling_price( { quantity => 1 } ) ),
        '==', 7.50, "undef role qty 1 selling_price is 7.50" );

    cmp_ok( sprintf ( "%.2f", $product->selling_price( { quantity => 15 } ) ),
        '==', 7.50, "undef role qty 15 selling_price is 7.50" );

    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 30 } ) ),
        '==', 7.50, "undef role qty 30 selling_price is 7.50" );

    my $user = $self->users->find({ username => 'customer1'});

    my $trade_role = $self->roles->find({ name => 'trade' });

    my $wholesale_role = $self->roles->find({ name => 'wholesale' });

    ok $user, "we have user customer1";

    lives_ok { $schema->set_current_user($user) }
    "set Schema's current_user to customer1 user object";

    cmp_ok( sprintf( "%.02f", $product->selling_price( { quantity => 1 } ) ),
        '==', 7.50, "user qty 1 selling_price is 7.50" );

    lives_ok { $user->add_to_roles($trade_role) }
    "add trade role to user";

    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 1 } ) ),
        '==', 6.90, "trade qty 1 selling_price is 6.90" );

    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 15 } ) ),
        '==', 6.90, "trade qty 15 selling_price is 6.90" );

    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 50 } ) ),
        '==', 6.90, "trade qty 50 selling_price is 6.90" );

    lives_ok { $user->remove_from_roles($trade_role) }
    "remove trade role from user";

    # 2001

    set_absolute_time('2001-01-01T00:00:00Z');

    lives_ok { $schema->set_current_user(undef) }
    "switch to anonymous user";

    cmp_ok( sprintf( "%.02f", $product->selling_price ),
        '==', 8.99, "selling_price is 8.99" );

    cmp_ok( sprintf( "%.02f", $product->selling_price( { quantity => 1 } ) ),
        '==', 8.99, "undef role qty 1 selling_price is 8.99" );

    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 15 } ) ),
        '==', 8.49, "undef role qty 15 selling_price is 8.49" );

    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 30 } ) ),
        '==', 8.49, "undef role qty 30 selling_price is 8.49" );

    cmp_ok( sprintf( "%.02f", $product->selling_price( { quantity => 1 } ) ),
        '==', 8.99, "user qty 1 selling_price is 8.99" );

    lives_ok { $schema->set_current_user($user) }
    "switch to current_user";

    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 15 } ) ),
        '==', 8.20, "user qty 15 selling_price is 8.20" );

    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 25 } ) ),
        '==', 8.00, "user qty 25 selling_price is 8.00" );

    # stop mocking time

    restore_time();

    lives_ok { $user->add_to_roles($trade_role) }
    "add trade role to user";

    cmp_ok( $product->selling_price( { quantity => 1 } ),
        '==', 8, "trade qty 1 selling_price is 8" );
    cmp_ok( $product->selling_price( { quantity => 2 } ),
        '==', 8, "trade qty 2 selling_price is 8" );
    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 15 } ) ),
        '==', 7.80, "trade qty 15 selling_price is 7.80" );
    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 30 } ) ),
        '==', 7.50, "trade qty 30 selling_price is 7.50" );
    cmp_ok( $product->selling_price( { quantity => 50 } ),
        '==', 7, "trade qty 50 selling_price is 7" );

    cmp_ok( $product->selling_price( { quantity => 1 } ),
        '==', 8, "user & trade qty 1 selling_price is 8" );
    cmp_ok( $product->selling_price( { quantity => 2 } ),
        '==', 8, "user & trade qty 2 selling_price is 8" );
    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 15 } ) ),
        '==', 7.80, "user & trade qty 15 selling_price is 7.80" );
    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 30 } ) ),
        '==', 7.50, "user & trade qty 30 selling_price is 7.50" );
    cmp_ok( $product->selling_price( { quantity => 50 } ),
        '==', 7, "user & trade qty 50 selling_price is 7" );

    lives_ok { $user->add_to_roles($wholesale_role) }
    "add wholesale role to user";

    cmp_ok( $product->selling_price( { quantity => 1 } ),
        '==', 7, "wholesale & trade qty 1 selling_price is 7" );
    cmp_ok( $product->selling_price( { quantity => 2 } ),
        '==', 7, "wholesale & trade qty 2 selling_price is 7" );
    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 15 } ) ),
        '==', 6.80, "wholesale & trade qty 15 selling_price is 6.80" );
    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 30 } ) ),
        '==', 6.70, "wholesale & trade qty 30 selling_price is 6.70" );
    cmp_ok( sprintf( "%.2f", $product->selling_price( { quantity => 50 } ) ),
        '==', 6.50, "wholesale & trade qty 50 selling_price is 6.50" );

    lives_ok { $user->remove_from_roles($trade_role) }
    "remove trade role from user";

    lives_ok { $user->remove_from_roles($wholesale_role) }
    "remove wholesale role from user";

    lives_ok { $schema->set_current_user(undef) }
    "switch to anonymous user";

    # NavigationProduct->product_with_selling_price

    lives_ok(
        sub {
            $nav =
              $schema->resultset('Navigation')->find(
                { uri => 'painting-supplies/paintbrushes' } );
        },
        "find paintbrushes in navigation"
    );

    cmp_ok( $nav->name, 'eq', "Paintbrushes", "nav has name Paintbrushes" );

    # no args to product_with_selling_price

    lives_ok(
        sub {
            $products =
              $nav->navigation_products->search_related('product')->active;
        },
        "find all active paintbrush products"
    );

    cmp_ok( $products->count, "==", 3, "we have 3 products" );

    lives_ok(
        sub {
            @products = $products->listing->search( undef,
                { order_by => { -desc => 'product.sku' } } )->hri->all;
        },
        "get product listing order by sku desc"
    );

    my $expected = [
        {
            quantity_in_stock => undef,
            name              => "Disposable Brush Set",
            price             => num(14.99, 0.01),
            average_rating    => undef,
            selling_price     => num(14.99, 0.01),
            short_description => "Disposable Brush Set",
            sku               => "os28007",
            uri               => "disposable-brush-set",
            variant_count     => 0,
        },
        {
            quantity_in_stock => undef,
            name              => "Painters Brush Set",
            price             => num(29.99, 0.01),
            average_rating    => undef,
            selling_price     => num(24.99, 0.01),
            short_description => "Painters Brush Set",
            sku               => "os28006",
            uri               => "painters-brush-set",
            variant_count     => 0,
        },
        {
            quantity_in_stock => undef,
            name              => "Trim Brush",
            price             => num(8.99, 0.01),
            average_rating    => undef,
            selling_price     => num(8.99, 0.01),
            short_description => "Trim Brush",
            sku               => "os28005",
            uri               => "trim-brush",
            variant_count     => 0,
        }
    ];

    lives_ok(
        sub {
            @products = $products->listing->search(
                undef,
                {
                    order_by => { -desc => 'product.sku' },
                    rows     => 2,
                    page     => 1
                }
            )->hri->all;
        },
        "get product listing order by sku desc with 2 rows and page 1"
    );

    $expected = [
        {
            quantity_in_stock => undef,
            name              => "Disposable Brush Set",
            price             => num(14.99, 0.01),
            average_rating    => undef,
            selling_price     => num(14.99, 0.01),
            highest_price     => num(14.99, 0.01),
            short_description => "Disposable Brush Set",
            sku               => "os28007",
            uri               => "disposable-brush-set",
            variant_count     => 0,
        },
        {
            quantity_in_stock => undef,
            name              => "Painters Brush Set",
            price             => num(29.99, 0.01),
            average_rating    => undef,
            selling_price     => num(24.99, 0.01),
            highest_price     => num(29.99, 0.01),
            short_description => "Painters Brush Set",
            sku               => "os28006",
            uri               => "painters-brush-set",
            variant_count     => 0,
        },
    ];

    cmp_deeply( \@products, $expected, "do we have expected products?" );

    lives_ok(
        sub {
            @products = $products->listing->search(
                undef,
                {
                    order_by => { -desc => 'product.sku' },
                    rows     => 2,
                    page     => 2
                }
            )->hri->all;
        },
        "get product listing order by sku desc with 2 rows and page 2"
    );

    $expected = [
        {
            quantity_in_stock => undef,
            name              => "Trim Brush",
            price             => num(8.99, 0.01),
            average_rating    => undef,
            selling_price     => num(8.99, 0.01),
            highest_price     => num(8.99, 0.01),
            short_description => "Trim Brush",
            sku               => "os28005",
            uri               => "trim-brush",
            variant_count     => 0,
        }
    ];

    cmp_deeply( \@products, $expected, "do we have expected products?" );

    # quantity 10

    lives_ok(
        sub {
            $products =
              $products->columns( [qw/name price short_description sku uri/] )
              ->with_lowest_selling_price( { quantity => 10 } )
              ->search( undef, { order_by => { -desc => 'product.sku' } } );
        },
        "get product listing { quantity => 10} order by sku desc"
    );
    @products = $products->hri->all;

    $expected = [
        {
            name              => "Disposable Brush Set",
            price             => num( 14.99, 0.01 ),
            selling_price     => num( 14.99, 0.01 ),
            short_description => "Disposable Brush Set",
            sku               => "os28007",
            uri               => "disposable-brush-set",
        },
        {
            name              => "Painters Brush Set",
            price             => num( 29.99, 0.01 ),
            selling_price     => num( 24.99, 0.01 ),
            short_description => "Painters Brush Set",
            sku               => "os28006",
            uri               => "painters-brush-set",
        },
        {
            name              => "Trim Brush",
            price             => num( 8.99, 0.01 ),
            selling_price     => num( 8.49, 0.01 ),
            short_description => "Trim Brush",
            sku               => "os28005",
            uri               => "trim-brush",
        }
    ];

    cmp_deeply( \@products, $expected, "do we have expected products?" );

    cmp_deeply $products->first->selling_price( { quantity => 2 } ),
      num( 14.99, 0.01 ),
    "selling_price with arg from prefetched product with_lowest_selling_price";

    # user customer1

    my $users_id = $self->users->find({ username => 'customer1' })->id;

    lives_ok(
        sub {
            @products =
              $products->columns( [qw/name price short_description sku uri/] )
              ->with_lowest_selling_price( { users_id => $users_id } )
              ->search( undef, { order_by => { -desc => 'product.sku' } } )
              ->hri->all;
        },
        "get product listing { users_id => (id of customer1) }"
    );

    $expected->[2]->{selling_price} = num(8.99, 0.01);

    cmp_deeply( \@products, $expected, "do we have expected products?" );

    # user customer1 & quantity = 10

    lives_ok { $schema->set_current_user($user) }
    "switch to user customer1";

    lives_ok(
        sub {
            @products =
              $products->columns( [qw/name price short_description sku uri/] )
              ->with_lowest_selling_price(
                { quantity => 10 } )
              ->search( undef, { order_by => { -desc => 'product.sku' } } )
              ->hri->all;
        },
        "get product listing { quantity => 10 }"
    );

    $expected->[2]->{selling_price} = num(8.20, 0.01);

    cmp_deeply( \@products, $expected, "do we have expected products?" );

    lives_ok { $schema->set_current_user($user) }
    "switch to back to anonymous user";

    # test average_rating and selling_price for variant

    lives_ok(
        sub {
            @products = $self->products->search( { "product.sku" => 'os28066' },
                { alias => 'product' } )->listing->hri->all;
        },
        "get product listing for just sku os28066"
    );

    $expected = [
        {
            quantity_in_stock => undef,
            name              => "Big L Carpenters Square",
            price             => num(14.99, 0.01),
            average_rating    => num(4.27, 0.01),
            selling_price     => num(11.99, 0.01),
            highest_price     => num(133.99, 0.01),
            short_description => "Big L Carpenters Square",
            sku               => "os28066",
            uri               => "big-l-carpenters-square",
            variant_count     => 6,
        },
    ];

    cmp_deeply( \@products, $expected, "do we have expected product?" );

    # TODO: add tier pricing tests
    #$product->tier_pricing([qw/user trade wholesale/]);

    # discount

    lives_ok( sub { $product = $self->products->find('os28008') },
        "find product os28008" );

    cmp_deeply( $product->price, num(29.99, 0.01), "price is 29.99" );

    cmp_deeply(
        $product->selling_price,
        num( 29.99, 0.01 ),
        "selling_price is 29.99"
    );

    throws_ok(
        sub {
            $product->create_related(
                'price_modifiers',
                {
                    quantity => 1,
                    roles_id => undef,
                    price    => 20,
                    discount => 10
                }
            );
        },
        qr/Cannot set both price and discount/,
        "fail to create related PriceModifier with both price and discount"
    );

    my $price_modifier;
    lives_ok(
        sub {
            $price_modifier = $product->create_related(
                'price_modifiers',
                {
                    quantity => 1,
                    roles_id => undef,
                    discount => 10
                }
            );
        },
        "create related PriceModifier with 10% discount"
    );

    isa_ok( $price_modifier, "Interchange6::Schema::Result::PriceModifier",
        "result" );

    cmp_deeply( $product->price, num(29.99, 0.01), "price is 29.99" );

    cmp_deeply(
        $product->selling_price,
        num( 26.99, 0.01 ),
        "selling_price is 26.99"
    );

    lives_ok( sub { $price_modifier->update( { discount => 20 } ) },
        "change discount to 20%" );

    cmp_deeply( $product->price, num(29.99, 0.01), "price is 29.99" );

    cmp_deeply(
        $product->selling_price,
        num( 23.99, 0.01 ),
        "selling_price is 23.99"
    );

    lives_ok( sub { $product->update( { price => 32.99 } ) },
        "change price to 32.99" );

    cmp_deeply( $product->price, num(32.99, 0.01), "price is 32.99" );

    cmp_deeply(
        $product->selling_price,
        num( 26.39, 0.01 ),
        "selling_price is 26.39"
    );

    lives_ok { $product->delete_related('price_modifiers') }
    "delete price_modifiers for this product";

    ok !$product->related_resultset('price_modifiers')->count,
      "product has no related price_modifiers";

    lives_ok(
        sub {
            $price_modifier = $product->create_related(
                'price_modifiers',
                {
                    quantity => 1,
                    roles_id => undef,
                    price    => 100,
                }
            );
        },
        "create related PriceModifier with inflated price"
    );
    cmp_ok( $product->selling_price, 'eq', '32.99',
        "selling_price is 32.99" );

    # cleanup
    $rset_pm->delete_all;
    $self->clear_roles;
    $self->clear_price_modifiers;
    $self->clear_products;
};

1;
