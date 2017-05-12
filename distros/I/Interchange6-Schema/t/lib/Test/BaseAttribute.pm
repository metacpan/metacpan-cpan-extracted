package Test::BaseAttribute;

use Test::Deep;
use Test::Most;
use Test::Roo::Role;
use Data::Dumper::Concise;

test 'base attribute tests' => sub {

    my $self = shift;

    my ( $count, %navigation, $product, %size, $meta, $ret, @ret, $rset );

    my $schema = $self->ic6s_schema;

    $navigation{1} = $schema->resultset("Navigation")->create(
        {
            uri         => 'climbing-gear',
            type        => 'menu',
            description => 'Gear for climbing'
        }
    );

    # add Navigation attribute as hashref
    my $nav_attribute = $navigation{1}
      ->add_attribute( { name => 'meta_title' }, 'Find the best rope here.' );

    throws_ok(
        sub { $nav_attribute->find_attribute_value() },
qr/find_attribute_value input requires at least a valid attribute value/,
        "fail find_attribute_value with no arg"
    );

    lives_ok(
        sub { $meta = $nav_attribute->find_attribute_value('meta_title') },
        "find_attribute_value with scalar arg" );

    ok( $meta eq 'Find the best rope here.',
        "Testing  Navigation->add_attribute method with hash." )
      || diag "meta_title: " . $meta;

    lives_ok(
        sub {
            $meta =
              $nav_attribute->find_attribute_value( { name => 'meta_title' } );
        },
        "find_attribute_value with hashref arg"
    );

    ok( $meta eq 'Find the best rope here.',
        "Testing  Navigation->add_attribute method with hash." )
      || diag "meta_title: " . $meta;

    lives_ok( sub { $meta = $nav_attribute->find_attribute_value('FooBar') },
        "find_attribute_value with scalar FooBar" );

    is( $meta, undef, "not found" );

    # add Navigation attribute as scalar
    $nav_attribute = $navigation{1}
      ->add_attribute( 'meta_keyword', 'DBIC, Interchange6, Fun' );

    $meta = $nav_attribute->find_attribute_value('meta_keyword');

    ok( $meta eq 'DBIC, Interchange6, Fun',
        "Testing  Navigation->add_attribute method with scalar." )
      || diag "meta_keyword: " . $meta;

    # update Navigation attribute
    $nav_attribute = $navigation{1}
      ->update_attribute_value( 'meta_title', 'Find the very best rope here!' );

    $meta = $nav_attribute->find_attribute_value('meta_title');

    ok(
        $meta eq 'Find the very best rope here!',
        "Testing  Navigation->add_attribute method."
    ) || diag "meta_title: " . $meta;

    # delete Navigation attribute
    $nav_attribute = $navigation{1}
      ->delete_attribute( 'meta_title', 'Find the very best rope here!' );

    $meta = $nav_attribute->find_attribute_value('meta_title');

    is( $meta, undef, "undefined as expected" );

    # add product 
    lives_ok(
        sub {
            $product = $schema->resultset("Product")->create(
                {
                    sku  => 'FB001',
                    name => 'Foo Bars',
                    short_description =>
                        'All natural Foo Bars will cure you hunger.',
                    description =>
                        'All natural organic Foo Bars are made from the finest products on earth.',
                    price         => '9.95',
                    uri           => 'foo-bars',
                    weight        => '1',
                    canonical_sku => undef,
                }
            );
        },
        "create product FB001"
    );

    # add attribute and attribute_value
    my $prod_attribute = $product->add_attribute(
        { name => 'bar_flavor', type => 'menu', title => 'Choose Flavor' },
        { value => 'vanilla', title => 'Vanilla', priority => 1 }
    );

    my $variant = $prod_attribute->find_attribute_value('bar_flavor');

    ok( $variant eq 'vanilla', "Testing  Product->add_attribute method." )
      || diag "Attribute bar_flavor value " . $variant;

    $product->add_attribute(
        { name => 'bar_flavor', type => 'menu', title => 'Choose Flavor' },
        { value => 'mint', title => 'Mint', priority => 2 }
    );

    $product->add_attribute(
        { name => 'bar_size', type => 'menu', title => 'Choose Size' },
        { value => 'small', title => 'Small', priority => 1 }
    );

    # return a list of all attributes
    my $attr_rs = $product->search_attributes;

    cmp_ok( $attr_rs->count, '==', 2, "Testing search_attributes method." );

    # with search conditions
    $attr_rs = $product->search_attributes( { name => 'color' } );

    cmp_ok( $attr_rs->count, '==', 0,
        "Testing search_attributes method with condition." );

    $attr_rs = $product->search_attributes( { name => 'bar_flavor' } );

    cmp_ok( $attr_rs->count, '==', 1,
        "Testing search_attributes method with condition." );

    # with search attributes
    $attr_rs = $product->search_attributes(
        undef, { order_by => { -desc => 'priority' } }
    );

    cmp_ok( $attr_rs->count, '==', 2,
        "Testing search_attributes method with result search attributes" );

    my $attr_name = $attr_rs->next->name;

    cmp_ok( $attr_name, 'eq', 'bar_flavor',
        "Testing name of first attribute returned" );

    # return an arrayref of all product attributes and attribute_values
    lives_ok(
        sub {
            $ret = $product->search_attribute_values(
                undef, { order_by => 'priority' }, { order_by => 'priority' }
                );
            },
        "Create attribute and attribute_value arrayref"
    );

    cmp_deeply(
        $ret,
        bag(
          {
            'priority' => 0,
            'attribute_values' => [
                                    {
                                      'priority' => 1,
                                      'attributes_id' => re(qr/^\d+$/),
                                      'value' => 'vanilla',
                                      'attribute_values_id' => re(qr/^\d+$/),
                                      'title' => 'Vanilla'
                                    },
                                    {
                                      'priority' => 2,
                                      'attributes_id' => re(qr/^\d+$/),
                                      'value' => 'mint',
                                      'attribute_values_id' => re(qr/^\d+$/),
                                      'title' => 'Mint'
                                    }
                                  ],
            'attributes_id' => re(qr/^\d+$/),
            'dynamic' => 0,
            'name' => 'bar_flavor',
            'title' => 'Choose Flavor',
            'type' => 'menu'
          },
          {
            'priority' => 0,
            'attribute_values' => [
                                    {
                                      'priority' => 1,
                                      'attributes_id' => re(qr/^\d+$/),
                                      'value' => 'small',
                                      'attribute_values_id' => re(qr/^\d+$/),
                                      'title' => 'Small'
                                    }
                                  ],
            'attributes_id' => re(qr/^\d+$/),
            'dynamic' => 0,
            'name' => 'bar_size',
            'title' => 'Choose Size',
            'type' => 'menu'
          }
        ),
        "Deep comparison is good"
        ) or diag Dumper($ret);

    # return an array of all product attributes and attribute_values
    lives_ok(
        sub {
            @ret = $product->search_attribute_values(
                undef,
                { order_by => 'priority' },
                { order_by => 'priority' }
            );
        },
        "Create attribute and attribute_value array"
    );

    cmp_deeply(
        \@ret,
        bag(
            {
                'priority'         => 0,
                'attribute_values' => [
                    {
                        'priority'            => 1,
                        'attributes_id'       => re(qr/^\d+$/),
                        'value'               => 'vanilla',
                        'attribute_values_id' => re(qr/^\d+$/),
                        'title'               => 'Vanilla'
                    },
                    {
                        'priority'            => 2,
                        'attributes_id'       => re(qr/^\d+$/),
                        'value'               => 'mint',
                        'attribute_values_id' => re(qr/^\d+$/),
                        'title'               => 'Mint'
                    }
                ],
                'attributes_id' => re(qr/^\d+$/),
                'dynamic'       => 0,
                'name'          => 'bar_flavor',
                'title'         => 'Choose Flavor',
                'type'          => 'menu'
            },
            {
                'priority'         => 0,
                'attribute_values' => [
                    {
                        'priority'            => 1,
                        'attributes_id'       => re(qr/^\d+$/),
                        'value'               => 'small',
                        'attribute_values_id' => re(qr/^\d+$/),
                        'title'               => 'Small'
                    }
                ],
                'attributes_id' => re(qr/^\d+$/),
                'dynamic'       => 0,
                'name'          => 'bar_size',
                'title'         => 'Choose Size',
                'type'          => 'menu'
            }
        ),
        "Deep comparison is good"
    ) or diag Dumper($ret);

    lives_ok(
        sub {
            $navigation{bananas} =
              $schema->resultset("Navigation")
              ->create(
                { uri => 'bananas', type => 'menu', description => 'Bananas' }
              );
        },
        "Create Navigation item"
    );
    my $navigation_id = $navigation{bananas}->navigation_id;

    lives_ok(
        sub {
            $ret = $self->attributes->create(
                { name => 'colour', title => 'Colour' } );
        },
        "Create Attribute"
    );
    my $attributes_id = $ret->attributes_id;

    lives_ok(
        sub {
            $schema->resultset('NavigationAttribute')->create(
                {
                    navigation_id => $navigation_id,
                    attributes_id => $attributes_id,
                }
            );
        },
        "Create NavigationAttribute to link them together"
    );

    lives_ok(
        sub { $ret = $navigation{bananas}->find_attribute_value('colour') },
        "find_attribute_value colour for bananas Navigation item"
    );
    is( $ret, undef, "got undef" );

    throws_ok(
        sub { $navigation{bananas}->find_or_create_attribute() },
qr/Both attribute and attribute value are required for find_or_create_attribute/,
        "Fail find_or_create_attribute with no args"
    );

    throws_ok(
        sub {
            $navigation{bananas}->find_or_create_attribute( 'colour', undef );
        },
qr/Both attribute and attribute value are required for find_or_create_attribute/,
        "Fail find_or_create_attribute with undef value"
    );

    throws_ok(
        sub {
            $navigation{bananas}->find_or_create_attribute( undef, 'colour' );
        },
        qr/Both attribute and attribute value are required for find_or_create/,
        "Fail find_or_create_attribute with value but undef attribute"
    );

    lives_ok(
        sub {
            $navigation{bananas}->find_or_create_attribute( 'fruity', 'yes' );
        },
        "find_or_create_attribute OK for bananas: fruity yes"
    );

    throws_ok( sub { $navigation{bananas}->find_base_attribute_value() },
        qr/Missing/, "Fail find_base_attribute_value with no args" );

    throws_ok(
        sub { $navigation{bananas}->find_base_attribute_value('colour') },
        qr/Missing base name for find_base_attribute_value/,
        "Fail find_base_attribute_value with undef base"
    );

    throws_ok(
        sub {
            $navigation{bananas}
              ->find_base_attribute_value( undef, 'Navigation' );
        },
        qr/Missing attribute object for find_base_attribute_value/,
        "Fail find_base_attribute_value with base but undef attribute"
    );

    # cleanup
    lives_ok( sub { $schema->resultset("Navigation")->delete_all },
        "delete_all from Navigation" );
    lives_ok( sub { $self->clear_products },   "clear_products" );
    lives_ok( sub { $self->clear_attributes }, "clear_attributes" );

};

1;
