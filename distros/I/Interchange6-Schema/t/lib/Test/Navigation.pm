package Test::Navigation;
use utf8;

use Test::Deep;
use Test::Exception;
use Test::Roo::Role;

test 'navigation tests' => sub {

    my $self = shift;

    my $schema = $self->ic6s_schema;

    # prereqs
    $self->navigation unless $self->has_navigation;

    my ( $nav, $navlist, $nav_product, $result, @results );

    my $product = $self->products->find('os28077');

    my @product_path = $product->path;

    cmp_ok( scalar(@product_path), '==', 2, "Length of path for product" );

    cmp_ok( $product_path[0]->uri,
        'eq', 'tool-storage', "1st branch URI for product" );

    cmp_ok( $product_path[1]->uri,
        'eq', 'tool-storage/tool-belts', "2nd branch URI for product" );

    cmp_ok(
        $product_path[1]->parent_id,
        '==',
        $product_path[0]->id,
        "Correct parent for second navigation item"
    );

    # also check in scalar context

    my $product_path = $product->path;

    cmp_ok( scalar(@$product_path), '==', 2, "Length of path for product" );

    cmp_ok( $product_path->[0]->uri,
        'eq', 'tool-storage', "1st branch URI for product" );

    cmp_ok( $product_path->[1]->uri,
        'eq', 'tool-storage/tool-belts', "2nd branch URI for product" );

    # add product to country navigation

    my @path = (
        {
            name => 'South America',
            uri  => 'South-America',
            type => 'country'
        },
        { name => 'Chile', uri => 'South-America/Chile', type => 'country' },
    );

    lives_ok( sub { $navlist = navigation_make_path( $schema, \@path ) },
        "Create country navlist" );

    cmp_ok( scalar(@$navlist), '==', 2,
        "Number of navigation items created for country type." );

    lives_ok(
        sub {
            $nav_product =
              $schema->resultset('NavigationProduct')
              ->create(
                { navigation_id => $navlist->[1]->id, sku => $product->sku } );
        },
        "Create navigation_product"
    );

    # we should get the primary path since fixtures sets higher prio for this

    @product_path = $product->path;

    cmp_ok( scalar(@product_path), '==', 2, "Length of path for product" );

    cmp_ok( $product_path[0]->uri,
        'eq', 'tool-storage', "1st branch URI for product" );

    # now the country path

    @product_path = $product->path('country');

    cmp_ok( scalar(@product_path), '==', 2, "Length of path for product" );

    cmp_ok( $product_path[0]->uri, 'eq', 'South-America',
        "path[0] is correct" );

    cmp_ok( $product_path[1]->uri,
        'eq', 'South-America/Chile', "path[1] is correct" );

    lives_ok(
        sub {
            $nav = $self->navigation->find( { uri => 'hand-tools/hammers' } );
        },
        "find nav hand-tools/hammers"
    );

    cmp_ok( $nav->siblings->count, "==", 8, "nav has 8 siblings" );

    cmp_ok( $nav->siblings_with_self->count, "==", 9,
        "9 siblings with self" );

    lives_ok { @results = $nav->siblings_with_self }
    "get array of nav siblings";

    cmp_ok( scalar @results, "==", 9, "9 siblings with self (list context)" );

    # generate_uri

    my %data = (
        "I can eat glass and it doesn't hurt me" =>
          "I-can-eat-glass-and-it-doesn't-hurt-me",
        'Μπορώ να φάω σπασμένα γυαλιά χωρίς να πάθω τίποτα'
          => 'Μπορώ-να-φάω-σπασμένα-γυαλιά-χωρίς-να-πάθω-τίποτα',
        'aɪ kæn iːt glɑːs ænd ɪt dɐz nɒt hɜːt miː' =>
          'aɪ-kæn-iːt-glɑːs-ænd-ɪt-dɐz-nɒt-hɜːt-miː',
        'ᛖᚴ ᚷᛖᛏ ᛖᛏᛁ ᚧ ᚷᛚᛖᚱ ᛘᚾ ᚦᛖᛋᛋ ᚨᚧ ᚡᛖ ᚱᚧᚨ ᛋᚨᚱ'
          => 'ᛖᚴ-ᚷᛖᛏ-ᛖᛏᛁ-ᚧ-ᚷᛚᛖᚱ-ᛘᚾ-ᚦᛖᛋᛋ-ᚨᚧ-ᚡᛖ-ᚱᚧᚨ-ᛋᚨᚱ',
        '私はガラスを食べられます。 それは私を傷つけません'
          => '私はガラスを食べられます。-それは私を傷つけません',
        '  banana  apple ' => 'banana-apple',
        '  /  //  banana  / ///   / apple  / ' => '-banana-apple-',
    );

    use Encode;
    foreach my $key ( keys %data ) {

        lives_ok(
            sub { $nav = $self->navigation->create( { name => $key } ) },
            "create nav for name: " . Encode::encode_utf8($key)
        );

        lives_ok( sub { $nav->get_from_storage }, "refetch nav from db" );

        cmp_ok( $nav->uri, 'eq', $data{$key}, "uri is set correctly" );
    }
    
    lives_ok(
        sub {
            $result = $schema->resultset('Setting')->create(
                {
                    scope => 'Navigation',
                    name  => 'generate_uri_filter',
                    value => '$uri =~ s/[abc]/X/g',
                }
            );
        },
        'add filter to Setting: $uri =~ s/[abc]/X/g'
    );

    lives_ok(
        sub {
            $nav = $self->navigation->create(
                { name => 'one banana and a carrot' } );
        },
        "create nav with name: one banana and a carrot"
    );

    lives_ok( sub { $nav->get_from_storage }, "refetch nav from db" );

    cmp_ok( $nav->uri, 'eq', 'one-XXnXnX-Xnd-X-XXrrot',
        "uri is: one-XXnXnX-Xnd-X-XXrrot" );

    lives_ok( sub { $result->delete }, "remove filter" );

    lives_ok(
        sub {
            $result = $schema->resultset('Setting')->create(
                {
                    scope => 'Navigation',
                    name  => 'generate_uri_filter',
                    value => '$uri = lc($uri)',
                }
            );
        },
        'add filter to Setting: $uri = lc($uri)'
    );

    lives_ok(
        sub {
            $nav = $self->navigation->create(
                { name => 'One BANANA and a carrot' } );
        },
        "create nav with name: One BANANA and a carrot"
    );

    lives_ok( sub { $nav->get_from_storage }, "refetch nav from db" );

    cmp_ok( $nav->uri, 'eq', 'one-banana-and-a-carrot',
        "uri is: one-banana-and-a-carrot" );

    lives_ok( sub { $result->delete }, "remove filter" );

    lives_ok(
        sub {
            $result = $schema->resultset('Setting')->create(
                {
                    scope => 'Navigation',
                    name  => 'generate_uri_filter',
                    value => '$uri =',
                }
            );
        },
        'add broken filter to Setting: $uri ='
    );

    throws_ok(
        sub {
            $nav = $self->navigation->create(
                { name => 'One BANANA and a carrot' } );
        },
        qr/Navigation->generate_uri filter croaked/,
        "generate_uri should croak"
    );

    lives_ok( sub { $result->delete }, "remove filter" );

    throws_ok(
        sub {
            $nav = $self->navigation->create(
                {
                    name => 'one banana and a carrot',
                }
            );
        },
        qr/exception/i,
        "fail nav for name 'one banana and a carrot' - uri constraint fails"
    );

    # undef uri supplied

    lives_ok(
        sub {
            $nav = $self->navigation->create(
                { name => 'one banana and a carrot', uri => undef } );
        },
        "create nav with name: one banana and a carrot with undef uri"
    );

    lives_ok( sub { $nav->get_from_storage }, "refetch nav from db" );

    ok( !defined $nav->uri, "uri is undef" );

    lives_ok(
        sub {
            $nav = $self->navigation->create(
                { name => 'one banana and 4 carrots', uri => undef } );
        },
        "create nav with name: one banana and 4 carrots with undef uri"
    );

    lives_ok( sub { $nav->get_from_storage }, "refetch nav from db" );

    ok( !defined $nav->uri, "uri is undef" );

    lives_ok {
        $product = $self->products->create(
            {
                name        => "product with no nav",
                sku         => "productnonav",
                price       => 1,
                description => ""
            }
          )
    }
    "create product with no nav";

    cmp_deeply ( [$product->path], [], "product->path is epmty list" );

    # cleanup
    $self->clear_navigation;
};

sub navigation_make_path {
    my ( $schema, $path ) = @_;
    my ( $nav, @list );
    my $parent = undef;

    for my $navref (@$path) {
        $nav = $schema->resultset('Navigation')
          ->create( { %$navref, parent_id => $parent } );
        $parent = $nav->id;
        push @list, $nav;
    }

    return \@list;
}

1;
