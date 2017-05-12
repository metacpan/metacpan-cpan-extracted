use strict;
use Test::More tests => 17;
use Test::HTTP::Router;
use HTTP::Router::Declare;

my $router = router {
    resources 'Users';
};

is scalar @{[ $router->routes ]} => 16;

params_ok $router, '/users', { method => 'GET' },
    { controller => 'Users', action => 'index' };
params_ok $router, '/users', { method => 'POST' },
    { controller => 'Users', action => 'create' };

params_ok $router, '/users/new', { method => 'GET' },
    { controller => 'Users', action => 'post' };

params_ok $router, '/users/1', { method => 'GET' },
    { controller => 'Users', action => 'show', user_id => 1 };
params_ok $router, '/users/1', { method => 'PUT' },
    { controller => 'Users', action => 'update', user_id => 1 };
params_ok $router, '/users/1', { method => 'DELETE' },
    { controller => 'Users', action => 'destroy', user_id => 1 };

params_ok $router, '/users/1/edit', { method => 'GET' },
    { controller => 'Users', action => 'edit', user_id => 1 };
params_ok $router, '/users/1/delete', { method => 'GET' },
    { controller => 'Users', action => 'delete', user_id => 1 };

# with format
params_ok $router, '/users.html', { method => 'GET' },
    { controller => 'Users', action => 'index', format => 'html' };
params_ok $router, '/users.html', { method => 'POST' },
    { controller => 'Users', action => 'create', format => 'html' };

params_ok $router, '/users/new.html', { method => 'GET' },
    { controller => 'Users', action => 'post', format => 'html' };

params_ok $router, '/users/1.html', { method => 'GET' },
    { controller => 'Users', action => 'show', user_id => 1, format => 'html' };
params_ok $router, '/users/1.html', { method => 'PUT' },
    { controller => 'Users', action => 'update', user_id => 1, format => 'html' };
params_ok $router, '/users/1.html', { method => 'DELETE' },
    { controller => 'Users', action => 'destroy', user_id => 1, format => 'html' };

params_ok $router, '/users/1/edit.html', { method => 'GET' },
    { controller => 'Users', action => 'edit', user_id => 1, format => 'html' };
params_ok $router, '/users/1/delete.html', { method => 'GET' },
    { controller => 'Users', action => 'delete', user_id => 1, format => 'html' };
