package Interchange6::Test::Role::Fixtures;
use utf8;

=head1 NAME

Interchange6::Test::Role::Fixtures

=cut

use Interchange6::Schema::Populate;
use Sub::Quote qw/quote_sub/;
use DateTime;

use Moo::Role;

# accessors are ordered in this array based on the order in which
# clear_all_fixtures needs to receive them so that there are no FK issues in
# the database during row deletion

my @accessors = qw(orders addresses shipment_rates taxes zones states
  countries navigation price_modifiers roles inventory media products
  attributes users uri_redirects message_types shipment_carriers);

# we also need a package global mapping of accessor to result class

our %accessor2class = (
    addresses         => "Address",
    attributes        => "Attribute",
    countries         => "Country",
    #currencies        => "Currency",
    inventory         => "Inventory",
    media             => "Media",
    message_types     => "MessageType",
    navigation        => "Navigation",
    orders            => "Order",
    price_modifiers   => "PriceModifier",
    products          => "Product",
    roles             => "Role",
    shipment_carriers => "ShipmentCarrier",
    shipment_rates    => "ShipmentRate",
    states            => "State",
    taxes             => "Tax",
    uri_redirects     => "UriRedirect",
    users             => "User",
    zones             => "Zone",
);

# Create all of the accessors and clearers. Builders should be defined later.

foreach my $accessor (@accessors) {
    has $accessor => (
        is        => 'lazy',
        clearer   => "_clear_$accessor",
        predicate => 1,
    );

    next if $accessor eq 'media';       # see below
    next if $accessor eq 'orders';      # see below
    next if $accessor eq 'products';    # see below

    my $cref = q{
        my $self = shift;
        $self->ic6s_schema->resultset($class)->delete;
        my $_clear_accessor = "_clear_$accessor";
        $self->$_clear_accessor;
    };
    quote_sub "main::clear_$accessor", $cref,
      { '$accessor' => \$accessor, '$class' => \$accessor2class{$accessor} };
}

# clearing products is not so simple...

sub clear_media {
    my $self = shift;

    my $schema = $self->ic6s_schema;
    $schema->resultset('Media')->delete;
    $schema->resultset('MediaDisplay')->delete;
    $schema->resultset('MediaType')->delete;

    $self->_clear_media;
}

sub clear_orders {
    my $self = shift;
    my $schema = $self->ic6s_schema;
    $schema->resultset('OrderlinesShipping')->delete;
    $schema->resultset('Shipment')->delete;
    $schema->resultset('Orderline')->delete;
    $schema->resultset('Order')->delete;
    $self->_clear_orders;
}

sub clear_products {
    my $self = shift;

    # find canonical products
    my $rset = $self->products->search( { canonical_sku => undef } );
    while ( my $product = $rset->next ) {
        my $rset = $product->variants;

        # delete variants before canonical product
        $product->variants->delete_all;
        $product->delete;
    }
    $self->_clear_products;
    $self->clear_price_modifiers;
}

=head1 ATTRIBUTES

Fixtures are not installed in the database until the attribute is called. This is achieved by all accessors being lazy and so builders exist for each accessor to install the fixtures on demand.

=head2 addresses

Depends on users, states (possibly) and countries.

=cut

sub _build_addresses {
    my $self = shift;
    my $rset = $self->ic6s_schema->resultset('Address');

    my $user;

    # we must have users and countries before we can proceed
    $self->users     unless $self->has_users;
    $self->countries unless $self->has_countries;

    my $customers =
      $self->users->search( { username => { like => 'customer%' } },
        { order_by => 'username' } );

    $user = $customers->next;

    scalar $rset->populate(
        [
            [qw(users_id type address address_2 city country_iso_code)],
            [ $user->id, 'billing',  '42',  'Triq il-Kbira', 'Qormi',  'MT' ],
            [ $user->id, 'shipping', '11',  'The Mall',      'London', 'GB' ],
            [ $user->id, 'shipping', '143', 'Place Blanche', 'Paris',  'FR' ],
        ]
    );

    $user = $customers->next;

    my $state_on = $self->states->search(
        {
            country_iso_code => 'CA',
            state_iso_code   => 'ON'
        },
        { rows => 1 }
    )->single;

    my $state_ny = $self->states->search(
        {
            country_iso_code => 'US',
            state_iso_code   => 'NY'
        },
        { rows => 1 }
    )->single;

    scalar $rset->populate(
        [
            [
                qw(users_id type address address_2 city states_id country_iso_code)
            ],
            [
                $user->id, 'billing',     '10', 'Yale Street',
                'London',  $state_on->id, 'CA'
            ],
            [
                $user->id,  'billing',     '2', 'Time Square',
                'New York', $state_ny->id, 'US'
            ],
            [
                $user->id, 'shipping',    '134', 'Mill Street',
                'Hancock', $state_ny->id, 'US'
            ],
        ]
    );

    $user = $customers->next;

    scalar $rset->populate(
        [
            [qw(users_id type address address_2 city country_iso_code)],
            [ $user->id, 'billing',  '17', 'Allerhop', 'Wedemark', 'DE'],
            [ $user->id, 'shipping', '276', 'Büchel', 'Aachen', 'DE'],
        ]
    );

    my $company = $self->users->search( { username => { like => 'company%' } },
        { rows => 1 } );

    $user = $company->first;

    scalar $rset->populate(
        [
            [qw(users_id type address address_2 postal_code city country_iso_code phone)],
            [ $user->id, '', 'Demo Building', "Thomasstr. 21", '10110', 'Berlin', 'DE', '0135-9808-3432'],
        ]
    );


    return $rset;
}

=head2 countries

Populated via L<Interchange6::Schema::Populate::CountryLocale>.

=cut

sub _build_countries {
    my $self    = shift;
    my $rset    = $self->ic6s_schema->resultset('Country');

    if ( $rset->count == 0 ) {
        Interchange6::Schema::Populate->new( schema => $self->ic6s_schema )
          ->populate_countries;
    }
    return $rset;
}

=head2 roles

=cut

sub _build_roles {
    my $self    = shift;
    my $rset = $self->ic6s_schema->resultset("Role");

    if ( $rset->count == 0 ) {
        Interchange6::Schema::Populate->new( schema => $self->ic6s_schema )
          ->populate_roles;
    }

    # Add a few additional roles
    scalar $rset->populate(
        [
            { name => 'editor', label => 'Editor', description => 'Editor' },
            { name => 'wholesale', label => 'Wholesale customer', description => 'Wholesale Customer.' },
            { name => 'trade', label => 'Trade customer', description => 'Trade Customer.' },
            { name => 'company', label => 'Company', description => 'Company Information' },
        ]
    );
    return $rset;
}

=head2 orders

=cut

sub _build_orders {
    my $self = shift;
    my $schema = $self->ic6s_schema;

    # prereqs
    $self->products unless $self->has_products;
    $self->addresses unless $self->has_addresses;

    my $rset =  $schema->resultset('Order');

    my $customer1 = $self->users->find( { username => 'customer1' } );

    my $billing_address =
      $customer1->addresses->search( { type => 'billing' }, { rows => 1 } )
      ->single;

    my $shipping_address =
      $customer1->addresses->search( { type => 'shipping' }, { rows => 1 } )
      ->single;

    my @orderlines = (
        {
            sku         => 'os28112',
            name        => 'Garden Shovel',
            description => '',
            quantity    => 1,
            price       => 13.99,
            subtotal    => 13.99,
        },
        {
            sku         => 'os28113',
            name        => 'The Claw Hand Rake',
            description => '',
            quantity    => 2,
            price       => 14.99,
            subtotal    => 29.98,
        },
    );

    my $payment_order = {
        users_id => $customer1->id,
        amount   => 56.47,
    };

    $rset->create(
        {
            order_number          => '122334',
            order_date            => DateTime->now,
            users_id              => $customer1->id,
            email                 => $customer1->email,
            shipping_addresses_id => $shipping_address->id,
            billing_addresses_id  => $billing_address->id,
            orderlines            => \@orderlines,
            subtotal              => 43.97,
            shipping              => 12.50,
            total_cost            => 56.47,
            payment_orders        => [$payment_order],
        }
    );

    my $customer2 = $self->users->find( { username => 'customer2' });

    $billing_address =
      $customer2->addresses->search( { type => 'billing' }, { rows => 1 } )
      ->single;

    $shipping_address =
      $customer2->addresses->search( { type => 'shipping' }, { rows => 1 } )
      ->single;

    $payment_order = {
        users_id => $customer2->id,
        amount   => 56.47,
    };

    $rset->create(
        {
            order_number          => '122339',
            order_date            => DateTime->now,
            users_id              => $customer2->id,
            email                 => $customer2->email,
            shipping_addresses_id => $shipping_address->id,
            billing_addresses_id  => $billing_address->id,
            orderlines            => \@orderlines,
            subtotal              => 43.97,
            shipping              => 12.50,
            total_cost            => 56.47,
            payment_orders        => [$payment_order],
        }
    );

    return $rset;
}

=head2 shipment_carriers

=cut

sub _build_shipment_carriers {
    my $self = shift;
    my $rset = $self->ic6s_schema->resultset('ShipmentCarrier');

    $rset->create(
        {
            name             => 'UPS',
            account_number   => '1U99999',
            shipment_methods => [
                {
                    name       => '1DM',
                    title      => 'Next Day Air Early AM',

                },
                {
                    name       => 'GNDRES',
                    title      => 'Ground Residential',
                }
            ]
        }
    );
    $rset->create(
        {
            name             => 'KISS',
            account_number   => '1K99999',
            shipment_methods => [
                {
                    name       => 'KISSFAST',
                    title      => 'Keep it Simple and Stupid',
                },
            ]
        }
    );
    return $rset;
}

=head2 shipment_rates

=cut

sub _build_shipment_rates {
    my $self   = shift;
    my $schema = $self->ic6s_schema;
    my $rset   = $schema->resultset('ShipmentRate');

    # prereqs
    $self->shipment_carriers unless $self->has_shipment_carriers;
    $self->zones unless $self->has_zones;

    $rset->create(
        {
            zones_id => $self->zones->find( { zone => 'US lower 48' } )->id,
            shipment_methods_id => $schema->resultset('ShipmentMethod')
              ->search( { name => 'GNDRES' }, { rows => 1 } )->single->id,
            min_value => 0,
            max_value => 0,
            value_type => 'weight',
            value_unit => 'kg',
            price      => 9.95,
        },
    );
    $rset->create(
        {
            zones_id => $self->zones->find( { zone => 'US lower 48' } )->id,
            shipment_methods_id => $schema->resultset('ShipmentMethod')
              ->search( { name => '1DM' }, { rows => 1 } )->single->id,
            min_value => 0,
            max_value => 0,
            value_type => 'weight',
            value_unit => 'kg',
            price      => 29.95,
        },
    );
    return $rset;
}

=head2 price_modifiers

=cut

sub _build_price_modifiers {
    my $self    = shift;
    my $rset    = $self->ic6s_schema->resultset('PriceModifier');

    # we must have roles and products before we can proceed
    $self->products unless $self->has_products;
    $self->roles unless $self->has_roles;

    my $start = DateTime->new( year => 2000, month => 1,  day => 1 );
    my $end   = DateTime->new( year => 2000, month => 12, day => 31 );

    my $product = $self->products->find(
        { sku => 'G0001' });
    my $role_user = $self->roles->find(
        { name => 'user' });
    my $role_trade = $self->roles->find(
        { name => 'trade' });
    my $role_wholesale = $self->roles->find(
        { name => 'wholesale' });

    scalar $rset->populate(
        [
            [qw/sku quantity roles_id price start_date end_date/],
            [ 'os28005', 10,  undef,               8.49,  undef,  undef ],
            [ 'os28005', 10,  $role_user->id,      8.20,  undef,  undef ],
            [ 'os28005', 20,  $role_user->id,      8.00,  undef,  undef ],
            [ 'os28005', 30,  $role_user->id,      7.80,  undef,  undef ],
            [ 'os28005', 1,   $role_trade->id,     8,     undef,  undef ],
            [ 'os28005', 10,  $role_trade->id,     7.80,  undef,  undef ],
            [ 'os28005', 20,  $role_trade->id,     7.50,  undef,  undef ],
            [ 'os28005', 50,  $role_trade->id,     7,     undef,  undef ],
            [ 'os28005', 1,   $role_wholesale->id, 7,     undef,  undef ],
            [ 'os28005', 10,  $role_wholesale->id, 6.80,  undef,  undef ],
            [ 'os28005', 20,  $role_wholesale->id, 6.70,  undef,  undef ],
            [ 'os28005', 50,  $role_wholesale->id, 6.50,  undef,  undef ],
            [ 'os28005', 200, $role_wholesale->id, 6.10,  undef,  undef ],
            [ 'os28005', 1,   undef,               7.50,  $start, $end ],
            [ 'os28005', 1,   $role_trade->id,     6.90,  $start, $end ],
            [ 'os28006', 1,   undef,               24.99, undef,  undef ],
            [ 'os28085-6', 1, undef,               34.99, undef,  undef ],
        ]
    );
    return $rset;
}

=head2 products

=cut

sub _build_products {
    my $self = shift;
    my $rset = $self->ic6s_schema->resultset('Product');

    # we must have attributes and message_types (for reviews)
    $self->attributes unless $self->has_attributes;
    #$self->currencies unless $self->has_currencies;
    $self->message_types unless $self->has_message_types;

    my @products = (
        [qw(sku name short_description description price uri weight)],
        [
            "os28004",
            qq(Ergo Roller),
            qq(Ergo Roller),
qq(The special ergonomic design of our paint rollers has been recommended by physicians to ease the strain of repetitive movements.  This unique roller design features "pores" to hold and evenly distribute more paint per wetting than any other brush.),
            21.99,
            "ergo-roller",
            1
        ],
        [
            "os28005",
            qq(Trim Brush),
            qq(Trim Brush),
qq(Our trim paint brushes are perfectly designed.  The ergonomic look and feel will save hours of pain and the unique brush design allows paint to flow evenly and consistently.),
            8.99,
            "trim-brush",
            1
        ],
        [
            "os28006",
            qq(Painters Brush Set),
            qq(Painters Brush Set),
qq(This set includes 2" and 3" trim brushes and our ergonomically designer paint roller.  A perfect choice for any painting project.),
            29.99,
            "painters-brush-set",
            1
        ],
        [
            "os28007",
            qq(Disposable Brush Set),
            qq(Disposable Brush Set),
qq(This set of disposable foam brushes is ideal for any staining project.  The foam design holds the maximum amount of stain and the wood handle allows you to preview the color before you apply it.  This set includes a brush for all needs. 1/2", 1", 2", 3" are included.),
            14.99,
            "disposable-brush-set",
            1
        ],
        [
            "os28008",
            qq(Painters Ladder),
            qq(Painters Ladder),
qq(This 6' painters ladder is perfect for getting around in almost any room.  The paint tray is reinforced to hold up to a 5 gallon paint bucket.  The only time you'll have to get down is to move your ladder!),
            29.99,
            "painters-ladder",
            3
        ],
        [
            "os28009",
            qq(Brush Set),
            qq(Brush Set),
qq(This Hand Brush set includes our carpenters hand brush and a flat handled brush for the bigger cleanups.  Both brushes are made of the finest horsehair and are ideal for all surfaces.),
            9.99,
            "brush-set",
            1
        ],
        [
            "os28011",
            qq(Spackling Knife),
            qq(Spackling Knife),
qq(A must have for all painters!  This spackling knife is ergonomically designed for ease of use and boasts a newly designed finish to allow easy clean up.),
            14.99,
            "spackling-knife",
            1
        ],
        [
            "os28044",
            qq(Framing Hammer),
            qq(Framing Hammer),
qq(Enjoy the perfect feel and swing of our line of hammers. This framing hammer is ideal for the most discriminating of carpenters.  The handle is perfectly shaped to fit the hand and the head is weighted to get the most out of each swing.),
            19.99,
            "framing-hammer",
            2
        ],
        [
            "os28057a",
            qq(16 Penny Nails),
            qq(16 Penny Nails),
qq(Try our high quality 16 penny titanium nails for a lifetime of holding power. Box count about 100 nails.),
            14.99,
            "16-penny-nails",
            1
        ],
        [
            "os28057b",
            qq(8 Penny Nails),
            qq(8 Penny Nails),
qq(Our 8 penny nails are perfect for those hard to reach spots. Made of titanium they are guaranteed to last as long as your project. Box count about 200 nails.),
            12.99,
            "8-penny-nails",
            1
        ],
        [
            "os28057c",
            qq(10 Penny Nails),
            qq(10 Penny Nails),
qq(Perfect for all situations our titanium 10 Penny nails should be a part of every project.  Box count about 100 nails.),
            13.99,
            "10-penny-nails",
            1
        ],
        [
            "os28062",
            qq(Electricians Plier Set),
            qq(Electricians Plier Set),
qq(This electricians set includes heavy duty needle-nose pliers and wire cutters.  The needle-nose pliers have an extended tip making them easy to get into those hard to reach places, and the cutters are equipped with spring action so they bounce back ready for the next cut.),
            24.99,
            "electricians-plier-set",
            1
        ],
        [
            "os28064",
            qq(Mechanics Wrench Set),
            qq(Mechanics Wrench Set),
qq(This 5 piece set is ideal for all mechanics. Available in standard and metric sizes these tools are guaranteed to cover all of your needs.),
            19.99,
            "mechanics-wrench-set",
            2
        ],
        [
            "os28065",
            qq(Mechanics Pliers),
            qq(Mechanics Pliers),
qq(Our mechanics pliers are available in multiple sizes for all of your needs.  From 1/4" to 3" in diameter.),
            18.99,
            "mechanics-pliers",
            2
        ],
        [
            "os28066",
            qq(Big L Carpenters Square),
            qq(Big L Carpenters Square),
qq(The "Big L" is a must for every carpenter. Designed for ease of use, this square is perfect for measuring and marking cuts, ensuring that you get the right cut every time!),
            14.99,
            "big-l-carpenters-square",
            1
        ],
        [
            "os28068a",
            qq(Breathe Right Face Mask),
            qq(Breathe Right Face Mask),
qq(The unique design of our "Breathe Right" face mask is a must for all applications. Our patented micro-fiber insures that 90% of all dust and harmful materials are filtered out before you breathe them in. EDITED),
            5.99,
            "breathe-right-face-mask",
            1
        ],
        [
            "os28068b",
            qq(The Bug Eye Wear),
            qq(The Bug Eye Wear),
qq(Nothing protects your vision like "The Bug".  The unique design of these safety goggles is practically impenetrable and our special venting technology will make you forget you even have them on.),
            12.00,
            "the-bug-eye-wear",
            1
        ],
        [
            "os28069",
            qq(Flat Top Toolbox),
            qq(Flat Top Toolbox),
qq(This heavy weight tool box is perfect for any handy person.  The lift out top is perfect for a carry along, and there is plenty of open space for larger tool storage.),
            44.99,
            "flat-top-toolbox",
            2
        ],
        [
            "os28070",
            qq(Electricians Tool Belt),
            qq(Electricians Tool Belt),
qq(This tool belt is perfectly designed for the specialized tools of the electrical trade.  There is even a pocket for your voltage meter in this 100% leather belt!),
            39.99,
            "electricians-tool-belt",
            1
        ],
        [
            "os28072",
            qq(Deluxe Hand Saw),
            qq(Deluxe Hand Saw),
qq(Our deluxe hand saw is perfect for precision work. This saw features an ergonomic handle and carbide tipped teeth.  Available in 2', 2.5', and 3' lengths.),
            17.99,
            "deluxe-hand-saw",
            1
        ],
        [
            "os28073",
            qq(Mini-Sledge),
            qq(Mini-Sledge),
qq(Our mini-sledge hammer is superior for smaller jobs that require a little more power.  Give this one a try on landscaping stakes and concrete frames.),
            24.99,
            "mini-sledge",
            3
        ],
        [
            "os28074",
            qq(Rubber Mallet),
            qq(Rubber Mallet),
qq(Perfectly weighted and encased in rubber this mallet is designed for ease of use in all applications.),
            24.99,
            "rubber-mallet",
            2
        ],
        [
            "os28075",
            qq(Modeling Hammer),
            qq(Modeling Hammer),
qq(Ideal for the hobbiest this modeling hammer is made for the delicate work. Fits easily into small spaces and the smaller head size is perfect for intricate projects.),
            14.99,
            "modeling-hammer",
            2
        ],
        [
            "os28076",
            qq(Digger Hand Trencher),
            qq(Digger Hand Trencher),
qq(The "Digger" is a gardeners dream.  Specially designed for moving dirt it boasts two different styles of blade.  Use the one side for trenching, or use the other side with it's wider angle to get hard to handle roots out of the ground.  Available in 3" size only.),
            18.99,
            "digger-hand-trencher",
            1
        ],
        [
            "os28077",
            qq(Carpenter's Tool Belt),
            qq(Carpenter's Tool Belt),
qq(Specially designed this tool belt comes with all of the carpenter's necessities.  Made of 100% leather this tool belt boasts a hammer hockey, tape measure hockey, and cordless drill holster.  Multiple pockets will allow you to eliminate those extra trips back to the tool box.),
            39.99,
            "carpenter-foots-tool-belt",
            1
        ],
        [
            "os28080",
            qq(The Blade Hand Planer),
            qq(The Blade Hand Planer),
qq(The perfect precision hand planer.  Our patented blade technology insures that you will never have to change or sharpen the blade.  Available in 1", 1.5", and 2" widths.),
            19.99,
            "the-blade-hand-planer",
            1
        ],
        [
            "os28081",
            qq(Steel Wool),
            qq(Steel Wool),
qq(Available in all different weights this steel wool is more durable than any other.  Perfect for stain removal or smoothing hard to reach surfaces.),
            8.99,
            "steel-wool",
            1
        ],
        [
            "os28082",
            qq(24" Level),
            qq(24" Level),
qq(Certified accuracy, High strength, long life, Built-in rubber grips for usefulness. Easy to clean.),
            34.99,
            "24-inch-level",
            1
        ],
        [
            "os28084",
            qq(Tape Measure),
            qq(Tape Measure),
qq(No matter what you need to measure you are sure to find the ideal tape measure here.  All of our tape measures are spring loaded for fast retraction and all lock in place for extended measuring.  Available in 10', 16', 24', and 36'.),
            19.99,
            "tape-measure",
            1
        ],
        [
            "os28085",
            qq(Big A A-Frame Ladder),
            qq(Big A A-Frame Ladder),
qq(The "Big A" is the ideal A-Frame ladder.  Available in both 6' and 12' heights you are sure to find the one that meets your needs.  The treads of both sides are reinforced for climbing making placement a breeze.),
            36.99,
            "big-a-a-frame-ladder",
            3
        ],
        [
            "os28086",
            qq(Folding Ruler),
            qq(Folding Ruler),
qq(This 6' folding ruler is a perfect fit in almost any toolbox.  Only 12" folded this measuring tool is handy and portable.),
            12.99,
            "folding-ruler",
            1
        ],
        [
            "os28087",
            qq(Sanders Multi-Pac),
            qq(Sanders Multi-Pac),
qq(This multi-pack of sand paper includes all levels of sand paper from a very fine grit to a very course grit.  Ideal for all applications!),
            11.99,
            "sanders-multi-pac",
            1
        ],
        [
            "os28108",
            qq(Hand Brush),
            qq(Hand Brush),
qq(This carpenters hand brush is ideal for the small clean ups needed for precision work. Made of refined horse hair it is perfect for even the most sensitive of materials.),
            5.99,
            "hand-brush",
            1
        ],
        [
            "os28109",
            qq(Mini-Spade),
            qq(Mini-Spade),
qq(This mini-spade is perfect hole digging, tree planting, or trenching.  The easy grip handle allows more control over thrust and direction.  Available in 4' only),
            24.99,
            "mini-spade",
            2
        ],
        [
            "os28110",
            qq(Mighty Mouse Tin Snips),
            qq(Mighty Mouse Tin Snips),
qq(Small and ready to go these tin snips are ideal for cutting patches and vent holes.  With the patented blades they are also perfect for cutting aluminum flashing.  Available in 3" length only.),
            14.99,
            "mighty-mouse-tin-snips",
            1
        ],
        [
            "os28111",
            qq(Hedge Shears),
            qq(Hedge Shears),
qq(A perfect fit for all users these 10" hedge shears are designed to make the most out of every cut. The ergonomic handle design will allow hours of cutting time so you can tackle those really big projects.  One size only),
            19.99,
            "hedge-shears",
            1
        ],
        [
            "os28112",
            qq(Garden Shovel),
            qq(Garden Shovel),
qq(The blade on this garden shovel is 7" inches long making it ideal for the potting enthusiast.  Ergonomic design makes for ease of use with this tool.),
            13.99,
            "garden-shovel",
            2
        ],
        [
            "os28113",
            qq(The Claw Hand Rake),
            qq(The Claw Hand Rake),
qq(Extend the reach of your potting with "The Claw".  Perfect for agitating soil in the most difficult places this 3 tine tool is ideal for every gardener.  Small and Large sizes available.),
            14.99,
            "the-claw-hand-rake",
            1
        ],
        [
            "os29000",          qq(3' Step Ladder),
            qq(3' Step Ladder), qq(),
            44.99,              "3-foot-step-ladder",
            0
        ],
        [
            "sv13213",
            "Painting Service",
            "Let our professional painters do the work for you",
"If you don't have time for DIY then why not take advantage of our professional painting service. Fixed hourly rates for any job",
            75,
            "professional-painting-service",
            0
        ]
    );

    scalar $rset->populate( [@products] );

    # sv13213 is inventory_exempt
    $rset->find( { sku => "sv13213" } )->update( { inventory_exempt => 1 } );

    $rset->find( { sku => "os28057a" } )
      ->add_attribute( { type => 'simple', name => 'length' }, '3.5 inches' );

    $rset->find( { sku => "os28057b" } )
    ->add_attribute( { type => 'simple', name => 'length' }, '2.5 inches' );

    $rset->find( { sku => "os28057c" } )
      ->add_attribute( { type => 'simple', name => 'length' }, '3.0 inches' );

    $rset->find( { sku => "os28057a" } )
      ->add_attribute( { type => 'simple', name => 'box_quantity' }, '100' );

    $rset->find( { sku => "os28057b" } )
      ->add_attribute( { type => 'simple', name => 'box_quantity' }, '200' );

    $rset->find( { sku => "os28057c" } )
      ->add_attribute( { type => 'simple', name => 'box_quantity' }, '100' );

    $rset->find( { sku => "os28085" } )->add_variants(
        {
            sku   => 'os28085-6',
            price => 36.99,
            uri   => 'big-a-a-frame-ladder-6-foot-high',
            height => '6 foot',
        },
        {
            sku   => 'os28085-12',
            price => 54.99,
            uri   => 'big-a-a-frame-ladder-12-foot-high',
            height => '12 foot',
        },
    );
    $rset->find( { sku => "os28080" } )->add_variants(
        {
            sku   => 'os28080-1',
            price => 19.99,
            uri   => 'the-blade-hand-planer-one-inch-wide',
            width => '1.0 inch',
        },
        {
            sku   => 'os28080-1HLF',
            price => 20.99,
            uri   => 'the-blade-hand-planer-one-and-a-half-inches-wide',
            width => '1.5 inch',
        },
        {
            sku   => 'os28080-2',
            price => 21.99,
            uri   => 'the-blade-hand-planer-two-inches-wide',
            width => '2.0 inch',
        },
    );
    $rset->find( { sku => "os28072" } )->add_variants(
        {
            sku    => 'os28072-2',
            price  => 16.99,
            uri    => 'deluxe-hand-saw-two-foot',
            length => '2 foot',
        },
        {
            sku    => 'os28072-2HLF',
            price  => 17.99,
            uri    => 'deluxe-hand-saw-two-and-a-half-foot',
            length => '2.5 foot',
        },
        {
            sku    => 'os28072-3',
            price  => 18.99,
            uri    => 'deluxe-hand-saw-three-foot',
            length => '3 foot',
        },
    );
    $rset->find( { sku => "os28065" } )->add_variants(
        {
            diameter => '1/4 inch',
            sku      => 'os28065-QTR',
            uri      => 'mechanics-pliers-quarter-inch-diameter',
        },
        {
            diameter => '1/2 inch',
            sku      => 'os28065-HLF',
            uri      => 'mechanics-pliers-half-inch-diameter',
        },
        {
            diameter => '1 inch',
            sku      => 'os28065-1',
            uri      => 'mechanics-pliers-1-inch-diameter',
        },
        {
            diameter => '2 inches',
            sku      => 'os28065-2',
            uri      => 'mechanics-pliers-2-inch-diameter',
        },
        {
            diameter => '3 inches',
            sku      => 'os28065-3',
            uri      => 'mechanics-pliers-3-inch-diameter',
        },
    );
    $rset->find( { sku => "os28084" } )->add_variants(
        {
            length => '10 foot',
            sku    => 'os28084-10',
            uri    => 'tape-measure-10-foot-long',
            price  => 10.99,
        },
        {
            length => '16 foot',
            sku    => 'os28084-16',
            uri    => 'tape-measure-16-foot-long',
            price  => 12.99,
        },
        {
            length => '24 foot',
            sku    => 'os28084-24',
            uri    => 'tape-measure-24-foot-long',
            price  => 15.99,
        },
        {
            length => '36 foot',
            sku    => 'os28084-36',
            uri    => 'tape-measure-36-foot-long',
            price  => 19.99,
        },
    );
    $rset->find( { sku => "os28004" } )->add_variants(
        {
            roller => 'camel',
            color  => 'black',
            sku    => 'os28004-CAM-BLK',
            uri    => 'ergo-roller-camel-hair-black',
            price  => 16,
        },
        {
            roller => 'camel',
            color  => 'white',
            sku    => 'os28004-CAM-WHT',
            uri    => 'ergo-roller-camel-hair-white',
            price  => 16,
        },
        {
            roller => 'human',
            color  => 'black',
            sku    => 'os28004-HUM-BLK',
            uri    => 'ergo-roller-human-hair-black',
            price  => 16.5,
        },
        {
            roller => 'human',
            color  => 'white',
            sku    => 'os28004-HUM-WHT',
            uri    => 'ergo-roller-human-hair-white',
            price  => 16.5,
        },
        {
            roller => 'synthetic',
            color  => 'black',
            sku    => 'os28004-SYN-BLK',
            uri    => 'ergo-roller-synthetic-black',
            price  => 12.25,
        },
        {
            roller => 'synthetic',
            color  => 'white',
            sku    => 'os28004-SYN-WHT',
            uri    => 'ergo-roller-synthetic-white',
            price  => 12.25,
        },
    );

    $rset->find( { sku => "os28066" } )->add_variants(
        {
            handle => 'ebony',
            blade  => 'plastic',
            sku    => 'os28066-E-P',
            uri    => 'big-l-carpenters-square-ebony-handle-plastic-blade',
            price  => 32.55,
        },
        {
            handle => 'ebony',
            blade  => 'steel',
            sku    => 'os28066-E-S',
            uri    => 'big-l-carpenters-square-ebony-handle-steel-blade',
            price  => 33.99,
        },
        {
            handle => 'ebony',
            blade  => 'titanium',
            sku    => 'os28066-E-T',
            uri    => 'big-l-carpenters-square-ebony-handle-titanium-blade',
            price  => 133.99,
        },
        {
            handle => 'wood',
            blade  => 'plastic',
            sku    => 'os28066-W-P',
            uri    => 'big-l-carpenters-square-wood-handle-plastic-blade',
            price  => 12.55,
        },
        {
            handle => 'wood',
            blade  => 'steel',
            sku    => 'os28066-W-S',
            uri    => 'big-l-carpenters-square-wood-handle-steel-blade',
            price  => 11.99,
        },
        {
            handle => 'wood',
            blade  => 'titanium',
            sku    => 'os28066-W-T',
            uri    => 'big-l-carpenters-square-wood-handle-titanium-blade',
            price  => 113.99,
        },
    );

    # add some reviews

    my $product = $rset->find('os28066');
    my $customer1 =
      $self->users->search( { username => 'customer1' }, { rows => 1 } )
      ->single;

    $product->set_reviews(
        {
            title   => "fantastic",
            content => "really amazing",
            rating  => 5,
            author_users_id => $customer1->id,
            public  => 1,
            approved => 1,
        },
        {
            title   => "great",
            content => "there is so much I wan to say",
            rating  => 4.8,
            author_users_id => $customer1->id,
            public  => 1,
            approved => 1,
        },
        {
            title   => "brilliant",
            content => "let me carp on about this great product",
            rating  => 4.7,
            author_users_id => $customer1->id,
            public  => 1,
            approved => 1,
        },
        {
            title   => "fantastic",
            content => "public but not approved",
            rating  => 4,
            author_users_id => $customer1->id,
            public  => 1,
            approved => 0,
        },
        {
            title   => "fantastic",
            content => "approved but not public",
            rating  => 4,
            author_users_id => $customer1->id,
            public  => 0,
            approved => 1,
        },
        {
            title   => "really good",
            content => "does what it says on the tin",
            rating  => 4.3,
            author_users_id => $customer1->id,
            public  => 1,
            approved => 1,
        },
        {
            title   => "amazing",
            content => "so good I bought one for my dad",
            rating  => 3.8,
            author_users_id => $customer1->id,
            public  => 1,
            approved => 1,
        },
        {
            title   => "not bad",
            content => "better available on the market but not at this price",
            rating  => 3,
            author_users_id => $customer1->id,
            public  => 1,
            approved => 1,
        },
        {
            title   => "total junk",
            content => "product is completely worthless",
            rating  => 0,
            author_users_id => $customer1->id,
            public  => 0,
            approved => 0,
        },
    );

    return $rset;
}

=head2 attributes

Colours, sizes and heights for products.

FIXME: attributes for other things to be added?

=cut

sub _build_attributes {
    my $self = shift;
    my $rset = $self->ic6s_schema->resultset('Attribute');

    # generic product attributes
    $rset->create(
        {
            name  => 'box_quantity',
            title => 'Qty in box',
            type  => 'simple',
            attribute_values => [
                { value => '100', title => '100' },
                { value => '200', title => '200' },
            ]
        }
    );
    $rset->create(
        {
            name             => 'length',
            title            => 'Length',
            type             => 'simple',
            attribute_values => [
                { value => '2.5 inches', title => q(2½") },
                { value => '3.0 inches', title => q(3") },
                { value => '3.5 inches', title => q(3½") },
            ]
        }
    );

    # variants
    $rset->create(
        {
            name             => 'width',
            title            => 'Width',
            type             => 'variant',
            priority         => 1,
            attribute_values => [
                { priority => 40, value => '1.0 inch',   title => q(1") },
                { priority => 30, value => '1.5 inch', title => q(1.5") },
                { priority => 20, value => '2.0 inch', title => q(2") },
            ]
        }
    );
    $rset->create(
        {
            name             => 'diameter',
            title            => 'Diameter',
            type             => 'variant',
            priority         => 1,
            attribute_values => [
                { priority => 80, value => '1/4 inch', title => q(1/4") },
                { priority => 70, value => '1/2 inch', title => q(1/2") },
                { priority => 60, value => '1 inch',   title => q(1") },
                { priority => 50, value => '2 inches', title => q(2") },
                { priority => 40, value => '3 inches', title => q(3") },
            ]
        }
    );
    $rset->create(
        {
            name             => 'height',
            title            => 'Height',
            type             => 'variant',
            priority         => 2,
            attribute_values => [
                { priority => 800,  value => '2 foot',   title => "2'" },
                { priority => 750,  value => '2.5 foot', title => "2.5'" },
                { priority => 700,  value => '3 foot',   title => "3'" },
                { priority => 650,  value => '6 foot',   title => "6'" },
                { priority => 600, value => '10 foot',  title => "10'" },
                { priority => 550, value => '12 foot',  title => "12'" },
                { priority => 500, value => '16 foot',  title => "16'" },
                { priority => 450, value => '24 foot',  title => "24'" },
                { priority => 400, value => '36 foot',  title => "36'" },
            ]
        }
    );
    $rset->create(
        {
            name             => 'length',
            title            => 'Length',
            type             => 'variant',
            priority         => 1,
            attribute_values => [
                { priority => 80,  value => '2 foot',   title => "2'" },
                { priority => 85,  value => '2.5 foot', title => "2.5'" },
                { priority => 80,  value => '3 foot',   title => "3'" },
                { priority => 75, value => '10 foot',  title => "10'" },
                { priority => 70, value => '16 foot',  title => "16'" },
                { priority => 65, value => '24 foot',  title => "24'" },
                { priority => 60, value => '36 foot',  title => "36'" },
            ]
        }
    );
    $rset->create(
        {
            name             => 'color',
            title            => 'Color',
            type             => 'variant',
            priority         => 1,
            attribute_values => [
                { value => 'black', title => 'Black' },
                { value => 'white', title => 'White' },
            ]
        }
    );
    $rset->create(
        {
            name             => 'roller',
            title            => 'Roller',
            type             => 'variant',
            priority         => 2,
            attribute_values => [
                { value => 'camel',     title => 'Camel hair' },
                { value => 'human',     title => 'Human hair' },
                { value => 'synthetic', title => 'Synthetic' },
            ]
        }
    );
    $rset->create(
        {
            name             => 'handle',
            title            => 'Handle',
            type             => 'variant',
            priority         => 2,
            attribute_values => [
                { value => 'ebony', title => 'Ebony' },
                { value => 'wood',  title => 'Wood' },
            ]
        }
    );
    $rset->create(
        {
            name             => 'blade',
            title            => 'Blade',
            type             => 'variant',
            priority         => 1,
            attribute_values => [
                { value => 'plastic',  title => 'Plastic' },
                { value => 'steel',    title => 'Steel' },
                { value => 'titanium', title => 'Titanium' },
            ]
        }
    );

    return $rset;
}

=head2 inventory

=cut

sub _build_inventory {
    my $self = shift;
    my $rset = $self->ic6s_schema->resultset('Inventory');

    # we must have products before we can proceed
    $self->products unless $self->has_products;

    my @inventory = (
        [qw(sku quantity )],
        [ "os28004-CAM-BLK", 34, ],
        [ "os28004-CAM-WHT", 27, ],
        [ "os28004-HUM-BLK", 19, ],
        [ "os28004-HUM-WHT", 131, ],
        [ "os28004-SYN-BLK", 0, ],
        [ "os28004-SYN-WHT", 42, ],
        [ "os28005",         100, ],
        [ "os28006",         90, ],
        [ "os28007",         85, ],
        [ "os28008",         100, ],
        [ "os28009",         0, ],
        [ "os28011",         40, ],
        [ "os28044",         3, ],
        [ "os28057a",        100, ],
        [ "os28057b",        29, ],
        [ "os28057c",        50, ],
        [ "os28062",         88, ],
        [ "os28064",         94, ],
        [ 'os28065-QTR',     103, ],
        [ 'os28065-HLF',     87, ],
        [ 'os28065-1',       3, ],
        [ 'os28065-2',       0, ],
        [ 'os28065-3',       49, ],
        [ "os28066-E-P",     98, ],
        [ "os28066-E-S",     67, ],
        [ "os28066-E-T",     42, ],
        [ "os28066-W-P",     103, ],
        [ "os28066-W-S",     7, ],
        # os28066-W-T intentionally not added to inventory
        [ "os28068a",     100, ],
        [ "os28068b",     99, ],
        [ "os28069",      100, ],
        [ "os28070",      0, ],
        [ 'os28072-2',    19, ],
        [ 'os28072-2HLF', 47, ],
        [ 'os28072-3',    23, ],
        [ "os28073",      0, ],
        [ "os28074",      95, ],
        [ "os28075",      100, ],
        [ "os28076",      100, ],
        [ "os28077",      97, ],
        [ 'os28080-1',    67, ],
        [ 'os28080-1HLF', 32, ],
        [ 'os28080-2',    145, ],
        [ "os28081",      100, ],
        [ "os28082",      99, ],
        [ "os28084-10",   56, ],
        [ "os28084-16",   9, ],
        [ "os28084-24",   0, ],
        [ "os28084-36",   45, ],
        [ 'os28085-6',    3, ],
        [ 'os28085-12',   0, ],
        [ "os28086",      100, ],
        [ "os28087",      30, ],
        [ "os28108",      90, ],
        [ "os28109",      100, ],
        [ "os28110",      99, ],
        [ "os28111",      99, ],
        [ "os28112",      100, ],
        [ "os28113",      100, ],
        # os29000 intentionally not added to inventory
    );

    scalar $rset->populate( [@inventory] );

    return $rset;
}

=head2 media

=cut

sub _build_media {
    my $self = shift;
    my $schema = $self->ic6s_schema;

    my $imagetype =
      $schema->resultset('MediaType')->create( { type => 'image' } );

    foreach my $display (qw/image_detail image_thumb/) {
        $imagetype->add_to_media_displays(
            {
                type => $display,
                name => $display,
                path => "/images/$display",
            }
        );
    }

    my $products = $self->products;
    while ( my $product = $products->next ) {
        $product->add_to_media(
            {
                file       => $product->sku . ".gif",
                uri        => $product->sku . ".gif",
                mime_type  => 'image/gif',
                media_type => { type => 'image' }
            }
        );
    }

    return $schema->resultset('Media');
}

=head2 message_types

Populated via L<Interchange6::Schema::Populate::MessageType>.

=cut

sub _build_message_types {
    my $self = shift;
    my $rset = $self->ic6s_schema->resultset('MessageType');

    if ( $rset->count == 0 ) {
        Interchange6::Schema::Populate->new( schema => $self->ic6s_schema )
          ->populate_message_types;
    }
    return $rset;
}

=head2 navigation

=cut

sub _build_navigation {
    my $self = shift;
    my $rset = $self->ic6s_schema->resultset('Navigation');

    # we must have products before we can proceed
    $self->products unless $self->has_products;

    scalar $rset->populate(
        [
            [ 'uri',        'type', 'scope',     'name',       'priority' ],
            [ 'hand-tools', 'nav',  'menu-main', 'Hand Tools', 90 ],
            [ 'hardware',   'nav',  'menu-main', 'Hardware',   80 ],
            [ 'ladders',    'nav',  'menu-main', 'Ladders',    70 ],
            [ 'measuring-tools', 'nav', 'menu-main', 'Measuring Tools', 60 ],
            [
                'painting-supplies', 'nav', 'menu-main', 'Painting Supplies',
                50
            ],
            [ 'safety-equipment', 'nav', 'menu-main', 'Safety Equipment', 40 ],
            [ 'tool-storage',     'nav', 'menu-main', 'Tool Storage',     30 ],
        ]
    );

    my %navs;
    while ( my $nav = $rset->next ) {
        $nav->add_attribute( template => 'category' );
        $navs{ $nav->uri } = $nav->id;
    }

    my @navigation = (
        [
            'hand-tools/brushes', 'nav',
            'menu-main',          'Brushes',
            $navs{'hand-tools'}, [qw( os28009 os28108 )]
        ],
        [
            'hand-tools/hammers', 'nav',
            'menu-main',          'Hammers',
            $navs{'hand-tools'}, [qw( os28044 os28073 os28075 os28074 )]
        ],
        [
            'hand-tools/hand-planes', 'nav',
            'menu-main',              'Hand Planes',
            $navs{'hand-tools'}, [qw( os28080 )]
        ],
        [
            'hand-tools/hand-saws', 'nav',
            'menu-main',            'Hand Saws',
            $navs{'hand-tools'}, [qw( os28072 )]
        ],
        [
            'hand-tools/picks-and-hatchets', 'nav',
            'menu-main',                     'Picks & Hatchets',
            $navs{'hand-tools'}, [qw( os28076 os28113 )]
        ],
        [
            'hand-tools/pliers', 'nav',
            'menu-main',         'Pliers',
            $navs{'hand-tools'}, [qw( os28062 os28065 )]
        ],
        [
            'hand-tools/shears', 'nav',
            'menu-main',         'Shears',
            $navs{'hand-tools'}, [qw( os28111 os28110 )]
        ],
        [
            'hand-tools/shovels', 'nav',
            'menu-main',          'Shovels',
            $navs{'hand-tools'}, [qw( os28112 os28109 )]
        ],
        [
            'hand-tools/wrenches', 'nav',
            'menu-main',           'Wrenches',
            $navs{'hand-tools'}, [qw( os28064 )]
        ],
        [
            'hardware/nails', 'nav',
            'menu-main',      'Nails',
            $navs{'hardware'}, [qw( os28057c os28057a os28057b )]
        ],
        [
            'ladders/ladders', 'nav',
            'menu-main',       'Ladders',
            $navs{'ladders'}, [qw( os28085 os28008 )]
        ],
        [
            'ladders/step-tools', 'nav',
            'menu-main',          'Step Tools',
            $navs{'ladders'}, [qw( os29000 )]
        ],
        [
            'measuring-tools/levels', 'nav',
            'menu-main',              'Levels',
            $navs{'measuring-tools'}, [qw( os28082 )]
        ],
        [
            'measuring-tools/rulers', 'nav',
            'menu-main',              'Rulers',
            $navs{'measuring-tools'}, [qw( os28086 )]
        ],
        [
            'measuring-tools/squares', 'nav',
            'menu-main',               'Squares',
            $navs{'measuring-tools'}, [qw( os28066 )]
        ],
        [
            'measuring-tools/tape-measures', 'nav',
            'menu-main',                     'Tape Measures',
            $navs{'measuring-tools'}, [qw( os28084 )]
        ],
        [
            'painting-supplies/paintbrushes', 'nav',
            'menu-main',                      'Paintbrushes',
            $navs{'painting-supplies'}, [qw( os28007 os28006 os28005 )]
        ],
        [
            'painting-supplies/putty-knives', 'nav',
            'menu-main',                      'Putty Knives',
            $navs{'painting-supplies'}, [qw( os28011 )]
        ],
        [
            'painting-supplies/rollers', 'nav',
            'menu-main',                 'Rollers',
            $navs{'painting-supplies'}, [qw( os28004 )]
        ],
        [
            'painting-supplies/sandpaper', 'nav',
            'menu-main',                   'Sand Paper',
            $navs{'painting-supplies'}, [qw( os28087 os28081 )]
        ],
        [
            'safety-equipment/breathing-protection', 'nav',
            'menu-main',                             'Breathing Protection',
            $navs{'safety-equipment'}, [qw( os28068a )]
        ],
        [
            'safety-equipment/eye-protection', 'nav',
            'menu-main',                       'Eye Protection',
            $navs{'safety-equipment'}, [qw( os28068b )]
        ],
        [
            'tool-storage/tool-belts', 'nav',
            'menu-main',               'Tool Belts',
            $navs{'tool-storage'}, [qw( os28077 os28070 )]
        ],
        [
            'tool-storage/toolboxes', 'nav',
            'menu-main',              'Toolboxes',
            $navs{'tool-storage'}, [qw( os28069 )]
        ],
    );

    foreach my $nav (@navigation) {
        my $nav_result = $rset->create(
            {
                uri       => $nav->[0],
                type      => $nav->[1],
                scope     => $nav->[2],
                name      => $nav->[3],
                parent_id => $nav->[4],
                navigation_products =>
                  [ map { { "sku" => $_, priority => 100 } } @{ $nav->[5] } ],
            }
        );

        # add navigation_product links to parent nav as well
        my $parent = $nav_result->parent;
        foreach my $sku ( @{ $nav->[5] } ) {
            $parent->add_to_navigation_products(
                { sku => $sku, navigation_id => $parent->id } );
        }
    }

    return $rset;
}

=head2 states

Populated via L<Interchange6::Schema::Populate::StateLocale>.

=cut

sub _build_states {
    my $self = shift;
    my $rset = $self->ic6s_schema->resultset('State');

    # we must have countries before we can proceed
    $self->countries unless $self->has_countries;

    if ( $rset->count == 0 ) {
        Interchange6::Schema::Populate->new( schema => $self->ic6s_schema )
          ->populate_states;
    }
    return $rset;
}

=head2 taxes

=cut

sub _build_taxes {
    my $self = shift;
    my %countries;
    my $rset = $self->ic6s_schema->resultset('Tax');

    # we must have countries and states before we can proceed
    $self->countries unless $self->has_countries;
    $self->states    unless $self->has_states;

    # EU Standard rate VAT
    my @data = (
        [ 'BE', 21, '1996-01-01' ],
        [ 'BG', 20, '1999-01-01' ],
        [ 'CZ', 21, '2013-01-01' ],
        [ 'DK', 25, '1992-01-01' ],
        [ 'DE', 19, '2007-01-01' ],
        [ 'EE', 20, '2009-07-01' ],
        [ 'GR', 23, '2011-01-01' ],
        [ 'ES', 21, '2012-09-01' ],
        [ 'FR', 20, '2014-01-01' ],
        [ 'HR', 25, '2012-03-01' ],
        [ 'IE', 23, '2012-01-01' ],
        [ 'IT', 22, '2013-10-01' ],
        [ 'CY', 19, '2014-01-13' ],
        [ 'LV', 21, '2009-01-01' ],
        [ 'LT', 21, '2009-09-01' ],
        [ 'LU', 15, '1992-01-01' ],
        [ 'HU', 27, '2012-01-01' ],
        [ 'MT', 18, '2004-01-01' ],
        [ 'NL', 21, '2012-10-01' ],
        [ 'AT', 20, '1984-01-01' ],
        [ 'PL', 23, '2011-01-01' ],
        [ 'PT', 23, '2011-01-01' ],
        [ 'RO', 24, '2010-07-01' ],
        [ 'SI', 22, '2013-07-01' ],
        [ 'SK', 20, '2011-01-01' ],
        [ 'FI', 24, '2013-01-01' ],
        [ 'SE', 25, '1990-07-01' ],
        [ 'GB', 20, '2011-01-04' ],
    );
    foreach my $aref (@data) {

        my ( $code, $rate, $from ) = @{$aref};

        my $c_name =
          $self->countries->find( { country_iso_code => $code } )->name;

        $rset->create(
            {
                tax_name         => "$code VAT Standard",
                description      => "$c_name VAT Standard Rate",
                percent          => $rate,
                country_iso_code => $code,
                valid_from       => $from,
            }
        );
    }

    # Canada GST/PST/HST/QST
    my %data = (
        BC => [ 'PST', 7 ],
        MB => [ 'RST', 8 ],
        NB => [ 'HST', 13 ],
        NL => [ 'HST', 13 ],
        NS => [ 'HST', 15 ],
        ON => [ 'HST', 13 ],
        PE => [ 'HST', 14 ],
        QC => [ 'QST', 9.975 ],
        SK => [ 'PST', 10 ],
    );
    foreach my $code ( sort keys %data ) {

        my $state = $self->states->find(
            { country_iso_code => 'CA', state_iso_code => $code } );

        $rset->create(
            {
                tax_name         => "CA $code $data{$code}[0]",
                description      => "CA " . $state->name . " $data{$code}[0]",
                percent          => $data{$code}[1],
                country_iso_code => 'CA',
                states_id        => $state->states_id
            }
        );
    }

    return $rset;
}

=head2 uri_redirects

=cut

sub _build_uri_redirects {
    my $self    = shift;
    my $rset    = $self->ic6s_schema->resultset('UriRedirect');

   scalar $rset->populate(
        [
            [qw( uri_source uri_target status_code)],
            [ 'bad_uri_1', 'correct_uri_1', 301 ],
            [ 'bad_uri_2', 'correct_uri_2', 302 ],
            [ 'bad_uri_3', 'correct_uri_3', 301 ],
        ]
    );
    return $rset;
}

=head2 users

    [qw( username email password nickname )],
    [ 'customer1', 'customer1@example.com', 'c1passwd', 'Cust1' ],
    [ 'customer2', 'customer2@example.com', 'c1passwd', 'Cust2' ],
    [ 'customer3', 'customer3@example.com', 'c1passwd', 'Cust3' ],
    [ 'admin1',    'admin1@example.com',    'a1passwd', 'Deity1' ],
    [ 'admin2',    'admin2@example.com',    'a2passwd', 'Deity2' ],

=cut

sub _build_users {
    my $self    = shift;
    my $rset    = $self->ic6s_schema->resultset('User');

    # we must have roles before we can proceed
    $self->roles unless $self->has_roles;

    scalar $rset->populate(
        [
            [qw( username email password first_name last_name nickname)],
            [
                'customer1', 'customer1@example.com',
                'c1passwd',  "Customer",
                "One",       "Cust1",
            ],
            [
                'customer2', 'customer2@example.com',
                'c1passwd',  "Customer",
                "Two",       "Cust2",
            ],
            [
                'customer3', 'customer3@example.com',
                'c1passwd',  "Customer",
                "Three",     "Cust3",
            ],
            [
                'admin1',   'admin1@example.com',
                'a1passwd', "Admin",
                "One",      "Deity1"
            ],
            [
                'admin2',   'admin2@example.com',
                'a2passwd', "Admin",
                "Two",      "Deity2"
            ],
            [
                'company1', 'demo@cart.pm',
                'com1passwd', "Demo Shop",
                "Ltd.", "Com1"
            ],
        ]
    );

    my $admins = $rset->search({first_name => "Admin"});
    while ( my $admin = $admins->next ) {
        $admin->set_roles([{name => "admin"}]);
    }
    return $rset;
}

=head2 zones

Populated via L<Interchange6::Schema::Populate::Zone>.

=cut

sub _build_zones {
    my $self = shift;
    my $rset = $self->ic6s_schema->resultset('Zone');

    if ( $rset->count == 0 ) {
        Interchange6::Schema::Populate->new( schema => $self->ic6s_schema )
          ->populate_zones;
    }
    return $rset;
}

=head1 METHODS

All attributes have a corresponding C<clear_$attribute> method which deletes all rows from the corresponding table and clears the accessor. Each also has a C<has_$attribute> accessor which returns true if the accessor has been set and false otherwise. All attributes are created lazy and are set on access. The full list of clear/has methods are:

=over

=item * clear_addresses

=item * clear_attributes

=item * clear_countries

=item * clear_inventory

=item * clear_media

=item * clear_message_types

=item * clear_navigation

=item * clear_orders

=item * clear_price_modifiers

=item * clear_products

=item * clear_roles

=item * clear_shipment_carriers

=item * clear_shipment_rates

=item * clear_states

=item * clear_taxes

=item * clear_users

=item * clear_uri_redirects

=item * clear_zones

=item * has_addresses

=item * has_attributes

=item * has_countries

=item * has_inventory

=item * has_media

=item * has_message_types

=item * has_navigation

=item * has_orders

=item * has_price_modifiers

=item * has_products

=item * has_roles

=item * has_shipment_carriers

=item * has_shipment_rates

=item * has_states

=item * has_taxes

=item * has_users

=item * has_uri_redirects

=item * has_zones

=back

=head2 clear_all_fixtures

This additional method calls all of the clear_$accessor methods.

=cut

sub clear_all_fixtures {
    my $self = shift;
    foreach my $accessor (@accessors) {
        my $clear_accessor = "clear_$accessor";
        $self->$clear_accessor;
    }
}

=head2 load_all_fixtures

Loads all fixtures.

=cut

sub load_all_fixtures {
    my $self = shift;
    # do this in reverse orser
    my @a = @accessors;
    while ( scalar @a > 0 ) {
        my $accessor = pop @a;
        $self->$accessor;
    }
}

1;
