use strict;
use Test::More tests => 8;
use Test::HTTP::Router;
use HTTP::Router::Declare;

my $router = router {
    resources 'Users', { collection => { recent => 'GET' }, member => { settings => 'GET' } } => then {
        resources 'Articles';
        resources 'Entries',  { only => [qw(show update)] };
    };
};

is scalar @{[ $router->routes ]} => 40;

params_ok $router, '/users', { method => 'GET' },
    { controller => 'Users', action => 'index' };
params_ok $router, '/users/recent', { method => 'GET' },
    { controller => 'Users', action => 'recent' };
params_ok $router, '/users/1/settings', { method => 'GET' },
    { controller => 'Users', action => 'settings', user_id => 1 };

params_ok $router, '/users/1/articles', { method => 'GET'  },
    { controller => 'Articles', action => 'index', user_id => 1 };
params_ok $router, '/users/1/articles', { method => 'POST' },
    { controller => 'Articles', action => 'create', user_id => 1 };

params_ok $router, '/users/1/entries/1', { method => 'GET' },
    { controller => 'Entries', action => 'show', user_id => 1, entry_id => 1 };
match_not_ok $router, '/users/1/entries/1', { method => 'DELETE' };
