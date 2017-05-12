package Test::UriRedirect;

use Test::Exception;
use Test::Roo::Role;

use DateTime;

test 'uri_redirects tests' => sub {

    my $self = shift;
    my ($nav, $uri_redirect);
    my $schema = $self->ic6s_schema;

    # pop nav from fixtures

    $nav = $self->navigation->find( { uri => 'hand-tools/hammers' } ); 

    lives_ok(
        sub {
            $uri_redirect = $schema->resultset("UriRedirect")->create(
                {
                    uri_source           => 'my_bad_uri',
                    uri_target           => $nav->uri
                }
            );
        },
        "Create Uri 301 Redirect my_bad_uri -> hand-tools/hammers"
    );

    cmp_ok( $self->uri_redirects->find({ uri_source => 'my_bad_uri' })->status_code,
        '==', 301, "301 default uri_redirect status_code" );

    lives_ok(
        sub {
            $uri_redirect = $self->uri_redirects->find( { uri_source => 'bad_uri_1' } );
        },
        "find uri_redirect uri_source bad_uri_1 from fixtures"
    );

    # 3 records from fixtures
    cmp_ok( $schema->resultset('UriRedirect')->count,
        '==', 4, "4 uri redirects" );

    # cleanup
    $self->clear_uri_redirects;

    scalar $schema->resultset("UriRedirect")->populate(
        [
            [qw/uri_source uri_target status_code/],
            [qw{/one /two 301}],
            [qw{/two /three 302}],
            [qw{/bad1 /bad2 301}],
            [qw{/bad2 /bad3 301}],
            [qw{/bad3 /bad1 302}],
        ]
    );

    cmp_ok( $schema->resultset('UriRedirect')->count,
        '==', 5, "5 uri redirects" );

    my ( $target, $code );

    lives_ok(
        sub {
            ( $target, $code ) =
              $schema->resultset("UriRedirect")->redirect('none');
        },
        "try non-existant redirect"
    );
    ok(!defined $target, "uri_target not defined");
    ok(!defined $code, "status_code not defined");

    lives_ok(
        sub {
            ( $target, $code ) =
              $schema->resultset("UriRedirect")->redirect('/one');
        },
        "try /one redirect"
    );
    cmp_ok($target, 'eq', '/three', "uri_target /three");
    cmp_ok($code, 'eq', 302, "status_code is 302");

    my $result;
    lives_ok(
        sub {
            $result =
              $schema->resultset("UriRedirect")->redirect('/one');
        },
        "try /one redirect"
    );
    cmp_ok($result->[0], 'eq', '/three', "uri_target /three");
    cmp_ok($result->[1], 'eq', 302, "status_code is 302");

    lives_ok(
        sub {
            ( $target, $code ) =
              $schema->resultset("UriRedirect")->redirect('/bad1');
        },
        "circular redirect"
    );
    is($target, undef, "uri_target undef");

    # cleanup
    $self->clear_uri_redirects;

    cmp_ok( $schema->resultset('UriRedirect')->count,
        '==', 0, "0 UriRedirect rows" );
};

1;
