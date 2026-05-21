use v5.40;
use Test2::V0;
use Path::Tiny;

use Minima::Router;

# Main globals
my $r = Minima::Router->new;
my $routes = Path::Tiny->tempfile;

# Works without doing anything
is( $r->match('/'), undef, 'works out of the box' );

# Non-existing routes file
like(
    dies { $r->read_file('ThisFileDoesNotExist') },
    qr/does not exist/,
    'dies for non-existing routes file'
);

# Comments and blanks
$routes->spew(<<~EOF
    # Comment

    # GET / C A
    EOF
);
$r->read_file($routes);
is( $r->match('/'), undef, 'ignores comments and blank lines' );


# Prefix
$routes->spew(<<~EOF
    * / :C A
    EOF
);
$r->clear_routes;
$r->read_file($routes);
my $prefix_match = $r->match('/');
is(
    $prefix_match->{controller},
    'Controller::C',
    'adds default prefix'
);

$routes->spew(<<~EOF
    * / ::C A
    EOF
);
$r->clear_routes;
$r->read_file($routes);
$prefix_match = $r->match('/');
is(
    $prefix_match->{controller},
    'Controller::C',
    'treats multiple shortcut colons like one'
);

$routes->spew(<<~EOF
    * / :C A
    EOF
);
$r->set_prefix('SecretPrefix');
$r->clear_routes;
$r->read_file($routes);
$prefix_match = $r->match('/');
is(
    $prefix_match->{controller},
    'SecretPrefix::C',
    'adds custom prefix'
);

# Specials
is( $r->not_found_route, undef,
    'returns undef for no not found route registered' );
is( $r->error_route, undef,
    'returns undef for no error route registered' );

$routes->spew(<<~EOF
    * u
    @ not_found C N
    @ server_error C E
    EOF
);
$r->clear_routes;
$r->read_file($routes);
my $error_r = $r->error_route;
is( $error_r->{controller}, 'C', 'returns correct error controller' );
is( $error_r->{action}, 'E', 'returns correct error action' );

my $not_found = $r->not_found_route;
is( $not_found->{controller}, 'C', 'returns correct not found controller' );
is( $not_found->{action}, 'N', 'returns correct not found action' );

my $match = $r->match('/');
is( $match->{controller}, 'C', 'also returns not found controller for bad route' );
is( $match->{action}, 'N', 'also returns not found action for bad route' );

my $undef = $r->match('u');
is( $undef->{controller}, undef, 'works with empty controller' );
is( $undef->{action}, undef, 'works with empty action' );

# Normal
$routes->spew(<<~EOF
    * / C H
    EOF
);
$r->read_file($routes);
$match = $r->match('/');
is( $match->{controller}, 'C', 'returns correct controller match' );
is( $match->{action}, 'H', 'returns correct action match' );

# HEAD vs. GET
{
    $routes->spew(<<~EOF
        GET  both C b
        _GET get  C g
        EOF
    );
    $r->clear_routes;
    $r->read_file($routes);
    my $env = {
        PATH_INFO      => 'both',
        REQUEST_METHOD => 'GET',
    };

    # GET on GET
    my $match = $r->match($env);
    is( $match->{action}, 'b', 'matches on universal GET' );

    # HEAD on GET
    $env->{REQUEST_METHOD} = 'HEAD';
    $match = $r->match($env);
    is( $match->{action}, 'b', 'matches HEAD on universal GET' );

    # PUT on GET
    $env->{REQUEST_METHOD} = 'PUT';
    $match = $r->match($env);
    is( $match, undef, 'respects method constraint' );

    # GET on GET_
    $env->{PATH_INFO} = 'get';
    $env->{REQUEST_METHOD} = 'GET';
    $match = $r->match($env);
    is( $match->{action}, 'g', 'matches GET on exclusive GET' );

    # HEAD on GET
    $env->{REQUEST_METHOD} = 'HEAD';
    $match = $r->match($env);
    is( $match, undef, 'does not match HEAD on exclusive GET' );
}

# Commands
{
    $routes->spew(<<~\EOF);
    * / @c a
    EOF

    $r->clear_routes;
    like(
        dies { $r->read_file($routes) },
        qr/unknown.*command/i,
        'dies for unknown route command'
    );
}

# Redirects
{
    $routes->spew(<<~\EOF
        GET /old @redirect /new
        GET /tmp @r /target
        GET /gone @redirect_permanent /here
        GET /kept @rp /there
        EOF
    );
    $r->clear_routes;
    $r->read_file($routes);

    my $match = $r->match({
        PATH_INFO      => '/old',
        REQUEST_METHOD => 'GET',
    });
    is( $match->{redirect}, '/new', 'matches redirect destination' );
    is( $match->{redirect_status}, 302, 'sets temporary redirect status' );

    $match = $r->match({
        PATH_INFO      => '/tmp',
        REQUEST_METHOD => 'GET',
    });
    is( $match->{redirect}, '/target', 'matches short redirect alias' );
    is( $match->{redirect_status}, 302, 'sets short redirect status' );

    $match = $r->match({
        PATH_INFO      => '/gone',
        REQUEST_METHOD => 'GET',
    });
    is( $match->{redirect}, '/here', 'matches permanent redirect destination' );
    is( $match->{redirect_status}, 301, 'sets permanent redirect status' );

    $match = $r->match({
        PATH_INFO      => '/kept',
        REQUEST_METHOD => 'GET',
    });
    is( $match->{redirect}, '/there', 'matches short permanent redirect alias' );
    is( $match->{redirect_status}, 301, 'sets short permanent redirect status' );
}

done_testing;
