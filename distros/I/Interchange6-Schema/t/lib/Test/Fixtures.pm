package Test::Fixtures;

use Test::Exception;
use Test::Roo::Role;

# NOTE: make sure new fixtures are add to this hash

my %classes = (
    Address       => 'addresses',
    Attribute     => 'attributes',
    Country       => 'countries',
    Inventory     => 'inventory',
    Media         => 'media',
    MessageType   => 'message_types',
    Navigation    => 'navigation',
    Order         => 'orders',
    PriceModifier => 'price_modifiers',
    Product       => 'products',
    Role          => 'roles',
    ShipmentCarrier => 'shipment_carriers',
    ShipmentRate  => 'shipment_rates',
    State         => 'states',
    Tax           => 'taxes',
    User          => 'users',
    UriRedirect   => 'uri_redirects',
    Zone          => 'zones',
);

# NOTE: do not place any tests before the following test

test 'initial environment' => sub {

    my $self = shift;

    cmp_ok( $self->ic6s_schema->resultset('Address')->count, '==', 0,
        "no addresses" );

    cmp_ok( $self->ic6s_schema->resultset('Attribute')->count, '==', 0,
        "no attributes" );

    cmp_ok( $self->ic6s_schema->resultset('Country')->count, '>=', 249,
        "at least 249 countries" );

    cmp_ok( $self->ic6s_schema->resultset('Inventory')->count, '==', 0,
        "no inventory" );

    cmp_ok( $self->ic6s_schema->resultset('Media')->count, '==', 0,
        "no media" );

    cmp_ok( $self->ic6s_schema->resultset('MediaDisplay')->count, '==', 0,
        "no media displays" );

    cmp_ok( $self->ic6s_schema->resultset('MediaProduct')->count, '==', 0,
        "no media product rows" );

    cmp_ok( $self->ic6s_schema->resultset('MediaType')->count, '==', 0,
        "no media types" );

    cmp_ok( $self->ic6s_schema->resultset('MessageType')->count,
        '>=', 3, "at least 3 message_types" );

    cmp_ok( $self->ic6s_schema->resultset('Navigation')->count, '==', 0,
        "no navigation rows" );

    cmp_ok( $self->ic6s_schema->resultset('PriceModifier')->count, '==', 0,
        "no price_modifiers" );

    cmp_ok( $self->ic6s_schema->resultset('Product')->count, '==', 0,
        "no products" );

    cmp_ok( $self->ic6s_schema->resultset('Role')->count, '==', 3, "3 roles" );

    cmp_ok( $self->ic6s_schema->resultset('ShipmentMethod')->count, '==', 0,
        "no shipment_methods" );

    cmp_ok( $self->ic6s_schema->resultset('ShipmentCarrier')->count, '==', 0,
        "no shipment_carriers" );

    cmp_ok( $self->ic6s_schema->resultset('State')->count, '>=', 64,
        "at least 64 states" );

    cmp_ok( $self->ic6s_schema->resultset('Tax')->count, '==', 0, "0 taxes" );

    cmp_ok( $self->ic6s_schema->resultset('User')->count, '==', 0, "no users" );

    cmp_ok( $self->ic6s_schema->resultset('UriRedirect')->count, '==', 0, "0 uri_redirects" );

    cmp_ok( $self->ic6s_schema->resultset('Zone')->count, '>=', 316,
        "at least 316 zones" );

    foreach my $class ( sort keys %classes ) {
        my $predicate = "has_$classes{$class}";
        ok( !$self->$predicate, "$predicate is false" );
    }

    lives_ok( sub { $self->load_all_fixtures }, "load_all_fixtures" );

    foreach my $class ( sort keys %classes ) {
        my $predicate = "has_$classes{$class}";
        ok( $self->$predicate, "$predicate is true" );
    }

    lives_ok( sub { $self->clear_all_fixtures }, "clear_all_fixtures" );

    foreach my $class ( sort keys %classes ) {
        my $predicate = "has_$classes{$class}";
        ok( !$self->$predicate, "$predicate is false" );
    }

    cmp_ok( $self->ic6s_schema->resultset('Navigation')->count, '==', 0,
        "no navigation rows" );
};

test 'countries' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    # loaded on $schema->deploy so clear before testing
    lives_ok( sub { $self->clear_countries }, "clear_countries" );

    cmp_ok( $self->countries->count, '>=', 249, "at least 249 countries" );

    ok( $self->has_countries, "has_countries is true" );

    cmp_ok( $self->countries->find( { country_iso_code => 'MT' } )->name,
        'eq', 'Malta', "iso_code MT name Malta" );
};

test 'states' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    # loaded on $schema->deploy so clear before testing
    lives_ok( sub { $self->clear_states }, "clear_states" );

    cmp_ok( $self->states->count, '>=', 64, "at least 64 states" );

    ok( $self->has_states, "has_states is true" );

    cmp_ok( $self->states->search( { country_iso_code => 'US' } )->count,
        '==', 51, "51 states (including DC) in the US" );

    cmp_ok( $self->states->search( { country_iso_code => 'CA' } )->count,
        '==', 13, "13 provinces and territories in Canada" );

};

test 'taxes' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    my $rset;

    cmp_ok( $self->taxes->count, '==', 37, "37 Tax rates" );

    ok( $self->has_taxes, "has_taxes is true" );

    # EU Standard rate VAT
    lives_ok(
        sub {
            $rset = $self->taxes->search( { tax_name => "MT VAT Standard" } );
        },
        "search for Malta VAT"
    );
    cmp_ok( $rset->count, '==', 1, "Found one tax" );
    cmp_ok(
        $rset->first->description,
        'eq',
        'Malta VAT Standard Rate',
        "Tax description is correct"
    );

    # Canada GST/PST/HST/QST
    lives_ok(
        sub {
            $rset = $self->taxes->search( { tax_name => "CA ON HST" } );
        },
        "search for Canada Ontario HST"
    );
    cmp_ok( $rset->count, '==', 1, "Found one tax" );
    cmp_ok(
        $rset->first->description,
        'eq',
        'CA Ontario HST',
        "Tax description is correct"
    );

    my $country_count = $self->countries->count;
    my $state_count   = $self->states->count;

    lives_ok( sub { $self->clear_taxes }, "clear_taxes" );

    ok( !$self->has_taxes, "has_taxes is false" );

    cmp_ok( $schema->resultset('Tax')->count, '==', 0, "0 Taxes in DB" );

    # check no cascade delete to country/state
    cmp_ok( $country_count, '==', $self->countries->count, "country count" );
    cmp_ok( $state_count,   '==', $self->states->count,    "state count" );

};

test 'price modifiers' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    cmp_ok( $self->price_modifiers->count,
        '>=', 15, "at least 15 price_modifiers" );

    ok( $self->has_price_modifiers, "has_price_modifiers is true" );
};

test 'roles' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    cmp_ok( $self->roles->count, '==', 7, "7 roles" );

    ok( $self->has_roles, "has_roles is true" );
};

test 'zones' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    cmp_ok( $self->zones->count, '>=', 316, "at least 316 zones" );

    ok( $self->has_zones, "has_zones is true" );
};

test 'users' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    cmp_ok( $self->users->count, '==', 6, "6 users" );

    ok( $self->has_users, "has_users is true" );

    cmp_ok( $schema->resultset('User')->count, '==', 6, "6 users in the db" );

    cmp_ok(
        $self->users->search( { username => { -like => 'customer%' } } )->count,
        '==', 3, "3 customers"
    );

    cmp_ok(
        $self->users->search( { username => { -like => 'admin%' } } )->count,
        '==', 2, "2 admin" );

    cmp_ok(
        $self->users->search( { username => { -like => 'company%' } } )->count,
        '==', 1, "1 company" );
};

test 'uri_redirects' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    cmp_ok( $self->uri_redirects->count, '==', 3, "3 uri_redirects" );

    ok( $self->has_uri_redirects, "uri_redirects is true" );

    cmp_ok( $schema->resultset('UriRedirect')->count, '==', 3, "3 uri_redirects in the db" );
};

test 'attributes' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    cmp_ok( $self->attributes->count, '>=', 4, "at least 4 attributes" );

    ok( $self->has_attributes, "has_attributes is true" );

    cmp_ok( $schema->resultset('Attribute')->count,
        '>=', 4, "at least 4 Attributes in DB" );
};

test 'products' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    my ( $rset, $product );

    cmp_ok( $self->products->count, '>=', 52, "at least 52 products" );

    ok( $self->has_products,   "has_products is true" );
    ok( $self->has_attributes, "has_attributes is true" );

    lives_ok(
        sub {
            $rset = $self->products->search( { canonical_sku => undef }, );
        },
        "select canonical products"
    );

    cmp_ok( $rset->count, '==', 40, "40 canonical variants" );

    cmp_ok( $schema->resultset('AttributeValue')->count,
        '>=', 10, "at least 10 AttributeValues" );

    cmp_ok( $schema->resultset('ProductAttribute')->count,
        '>=', 24, "at least 24 ProductAttributes" );

    lives_ok( sub { $product = $self->products->find('os28066') },
        "find sku os28066" );

    cmp_ok( $product->reviews->count, '==', 9, "9 reviews in total" );
    cmp_ok( $product->reviews( { public => 1 } )->count,
        '==', 7, "7 public reviews" );
    cmp_ok( $product->reviews( { approved => 1 } )->count,
        '==', 7, "7 approved reviews" );
    cmp_ok( $product->reviews( { approved => 1, public => 1 } )->count,
        '==', 6, "6 approved and public reviews" );

    cmp_ok( $product->average_rating, "==", 4.3, "average rating is 4.3" );
    cmp_ok( $product->average_rating(1), "==", 4.3, "average rating is 4.3" );
    cmp_ok( $product->average_rating(2), "==", 4.27, "average rating is 4.27" );
    ok( !defined $self->products->find('os28009')->average_rating,
        "average rating for sku os28009 is undef" );

    lives_ok( sub { $rset = $product->top_reviews }, "get top reviews" );

    cmp_ok( $rset->count, '==', 5, "got 5 reviews" );
    cmp_ok( $rset->next->rating, '==', 5, "top rating is 5" );

    lives_ok( sub { $rset = $product->top_reviews(3) }, "get top 3 reviews" );

    cmp_ok( $rset->count, '==', 3, "got 3 reviews" );
    cmp_ok( $rset->next->rating, '==', 5, "top rating is 5" );
};

test 'inventory' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    cmp_ok( $self->inventory->count,
        ">=", 47, "at least 47 products in inventory" );
};

test 'addresses' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    cmp_ok( $self->addresses->count, '==', 9, "9 addresses" );

    ok( $self->has_addresses, "has_addresses is true" );
    ok( $self->has_users,     "has_users is true" );

    cmp_ok(
        $self->users->find( { username => 'customer1' } )
          ->search_related('addresses')->count,
        '==', 3, "3 addresses for customer1"
    );

    cmp_ok(
        $self->users->find( { username => 'customer2' } )
          ->search_related('addresses')->count,
        '==', 3, "3 addresses for customer2"
    );

    cmp_ok(
        $self->users->find( { username => 'customer3' } )
          ->search_related('addresses')->count,
        '==', 2, "2 addresses for customer3"
    );

    cmp_ok(
        $self->users->find( { username => 'company1' } )
          ->search_related('addresses')->count,
        '==', 1, "1 addresses for company1"
    );

    cmp_ok( $schema->resultset('Address')->count, '==', 9,
        "9 Addresses in DB" );
};

test 'orders' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    my $order;

    cmp_ok( $self->orders->count, '==', 2, "2 orders" );

    lives_ok( sub { $order = $self->orders->first }, "grab an order" );

    cmp_ok( $order->orderlines->count, '==', 2, "2 orderlines" );


};

test 'media' => sub {
    my $self   = shift;
    my $schema = $self->ic6s_schema;

    cmp_ok( $self->media->count, '>=', 52, "at least 52 media items" );

};

test 'navigation' => sub {
    my $self = shift;

    my ( $navs, $nav, $children, $products, $product );

    cmp_ok( $self->navigation->count, '==', 31, "31 navigation rows" );

    lives_ok(
        sub {
            $navs = $self->navigation->search(
                { type => 'nav', scope => 'menu-main', parent_id => undef },
                { order_by => { -desc => 'priority' } } );
        },
        "grab top-level menu-main items"
    );
    cmp_ok( $navs->count, '==', 7, "7 navigation rows" );

    # test top-level menu-main items one at a time

    # Hand Tools
    lives_ok( sub { $nav = $navs->next }, "get next nav" );
    cmp_ok( $nav->name, 'eq', 'Hand Tools', "got: " . $nav->name );
    lives_ok(
        sub {
            $products = $nav->products->search( {}, { order_by => 'me.sku' } );
        },
        "grab products"
    );
    cmp_ok( $products->count, '==', 17, "17 products" );
    lives_ok( sub { $product = $products->next }, "grab first product" );
    cmp_ok( $product->sku, 'eq', 'os28009',
        "1st product sku: " . $product->sku );
    lives_ok(
        sub { $children = $nav->children->search( {}, { order_by => 'name' } ) }
        ,
        "grab children order by name"
    );
    cmp_ok( $children->count, '==', 9, "9 children" );
    lives_ok( sub { $nav = $children->next }, "get next child" );
    cmp_ok( $nav->name, 'eq', 'Brushes', "got: " . $nav->name );
    lives_ok(
        sub {
            $products = $nav->products->search( {}, { order_by => 'me.sku' } );
        },
        "grab products"
    );
    cmp_ok( $products->count, '==', 2, "2 products" );
    lives_ok( sub { $product = $products->first }, "grab first product" );
    cmp_ok( $product->sku, 'eq', 'os28009',
        "1st product sku: " . $product->sku );

    # Hardware
    lives_ok( sub { $nav = $navs->next }, "get next nav" );
    cmp_ok( $nav->name, 'eq', 'Hardware', "got: " . $nav->name );
    lives_ok(
        sub {
            $products = $nav->products->search( {}, { order_by => 'me.sku' } );
        },
        "grab products"
    );
    cmp_ok( $products->count, '==', 3, "3 products" );
    lives_ok( sub { $product = $products->next }, "grab first product" );
    cmp_ok( $product->sku, 'eq', 'os28057a',
        "1st product sku: " . $product->sku );
    lives_ok(
        sub { $children = $nav->children->search( {}, { order_by => 'name' } ) }
        ,
        "grab children order by name"
    );
    cmp_ok( $children->count, '==', 1, "1 child" );
    lives_ok( sub { $nav = $children->next }, "get next child" );
    cmp_ok( $nav->name, 'eq', 'Nails', "got: " . $nav->name );
    lives_ok(
        sub {
            $products = $nav->products->search( {}, { order_by => 'me.sku' } );
        },
        "grab products"
    );
    cmp_ok( $products->count, '==', 3, "3 products" );
    lives_ok( sub { $product = $products->first }, "grab first product" );
    cmp_ok( $product->sku, 'eq', 'os28057a',
        "1st product sku: " . $product->sku );

    # Ladders
    lives_ok( sub { $nav = $navs->next }, "get next nav" );
    cmp_ok( $nav->name, 'eq', 'Ladders', "got: " . $nav->name );
    lives_ok(
        sub {
            $products = $nav->products->search( {}, { order_by => 'me.sku' } );
        },
        "grab products"
    );
    cmp_ok( $products->count, '==', 3, "3 products" );
    lives_ok( sub { $product = $products->next }, "grab first product" );
    cmp_ok( $product->sku, 'eq', 'os28008',
        "1st product sku: " . $product->sku );
    lives_ok(
        sub { $children = $nav->children->search( {}, { order_by => 'name' } ) }
        ,
        "grab children order by name"
    );
    cmp_ok( $children->count, '==', 2, "2 children" );
    lives_ok( sub { $nav = $children->next }, "get next child" );
    cmp_ok( $nav->name, 'eq', 'Ladders', "got: " . $nav->name );
    lives_ok(
        sub {
            $products = $nav->products->search( {}, { order_by => 'me.sku' } );
        },
        "grab products"
    );
    cmp_ok( $products->count, '==', 2, "2 products" );
    lives_ok( sub { $product = $products->first }, "grab first product" );
    cmp_ok( $product->sku, 'eq', 'os28008',
        "1st product sku: " . $product->sku );

};

# NOTE: do not place any tests after this final test

test 'cleanup' => sub {
    my $self = shift;

    lives_ok( sub { $self->clear_all_fixtures }, "clear_all_fixtures" );

    foreach my $class ( keys %classes ) {
        cmp_ok( $self->ic6s_schema->resultset($class)->count,
            '==', 0, "0 rows in $class" );

        my $has = "has_$classes{$class}";
        ok( !$self->$has, "$has is false" );
    }

    cmp_ok( $self->ic6s_schema->resultset('MediaDisplay')->count, '==', 0,
        "no media displays" );

    cmp_ok( $self->ic6s_schema->resultset('MediaProduct')->count, '==', 0,
        "no media product rows" );

    cmp_ok( $self->ic6s_schema->resultset('MediaType')->count, '==', 0,
        "no media types" );

};

1;
