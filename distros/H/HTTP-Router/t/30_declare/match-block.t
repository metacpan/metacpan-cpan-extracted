use strict;
use Test::More tests => 7;
use Test::HTTP::Router;
use HTTP::Router::Declare;

my $router = router {
    match '/account' => to { controller => 'Account' } => then {
        match '/login'  => to { action => 'login' };
        match '/logout' => to { action => 'logout' };
    };

    match '/users' => then {
        match '/new'  => to { controller => 'Account', action => 'register' };
        match '/list' => to { controller => 'Users',   action => 'list' };
    };

    match { method => 'POST' } => then {
        match '/search' => to { controller => 'Items', action => 'search' };
        match '/tags'   => to { controller => 'Tags',  action => 'index' };
    };
};

is scalar @{[ $router->routes ]} => 6;

path_ok $router, '/account/login';
path_ok $router, '/account/logout';

path_ok $router, '/users/new';
path_ok $router, '/users/list';

match_ok $router, '/search', { method => 'POST' };
match_ok $router, '/tags', { method => 'POST' };
