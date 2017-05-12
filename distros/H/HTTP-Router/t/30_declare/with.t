use strict;
use Test::More tests => 4;
use Test::HTTP::Router;
use HTTP::Router::Declare;

my $router = router {
    with { controller => 'Account' } => then {
        match '/login'  => to { action => 'login' };
        match '/logout' => to { action => 'logout' };
        match '/signup' => to { action => 'signup' };
    };
};

is scalar @{[ $router->routes ]} => 3;

path_ok $router, '/login';
path_ok $router, '/logout';
path_ok $router, '/signup';
