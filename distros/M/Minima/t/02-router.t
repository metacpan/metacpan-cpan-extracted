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
is( $r->error_route, undef,
    'returns undef for no error route registered' );

$routes->spew(<<~EOF
    @ not_found C N
    @ server_error C E
    EOF
);
$r->clear_routes;
$r->read_file($routes);
my $error_r = $r->error_route;
is( $error_r->{controller}, 'C', 'returns correct error controller' );
is( $error_r->{action}, 'E', 'returns correct error action' );

my $match = $r->match('/');
is( $match->{controller}, 'C', 'returns correct not found controller' );
is( $match->{action}, 'N', 'returns correct not found action' );

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

done_testing;
