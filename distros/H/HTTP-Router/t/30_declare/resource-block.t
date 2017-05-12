use strict;
use Test::More tests => 8;
use Test::HTTP::Router;
use HTTP::Router::Declare;

my $router = router {
    resource 'Account', { member => { settings => 'GET' } } => then {
        resource 'Admin';
        resource 'User', { only => [qw(show update)] };
    };
};

is scalar @{[ $router->routes ]} => 34;

params_ok $router, '/account', { method => 'GET' },
    { controller => 'Account', action => 'show' };
params_ok $router, '/account', { method => 'POST' },
    { controller => 'Account', action => 'create' };
params_ok $router, '/account/settings', { method => 'GET' },
    { controller => 'Account', action => 'settings' };

params_ok $router, '/account/admin', { method => 'GET' },
    { controller => 'Admin', action => 'show' };
params_ok $router, '/account/admin', { method => 'POST' },
    { controller => 'Admin', action => 'create' };

params_ok $router, '/account/user', { method => 'GET' },
    { controller => 'User', action => 'show' };
match_not_ok $router, '/account/user', { method => 'POST' };
