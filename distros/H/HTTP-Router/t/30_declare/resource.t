use strict;
use Test::More tests => 15;
use Test::HTTP::Router;
use HTTP::Router::Declare;

my $router = router {
    resource 'Account';
};

is scalar @{[ $router->routes ]} => 14;

params_ok $router, '/account', { method => 'GET'    }, { controller => 'Account', action => 'show' };
params_ok $router, '/account', { method => 'POST'   }, { controller => 'Account', action => 'create' };
params_ok $router, '/account', { method => 'PUT'    }, { controller => 'Account', action => 'update' };
params_ok $router, '/account', { method => 'DELETE' }, { controller => 'Account', action => 'destroy' };

params_ok $router, '/account/new',    { method => 'GET' }, { controller => 'Account', action => 'post' };
params_ok $router, '/account/edit',   { method => 'GET' }, { controller => 'Account', action => 'edit' };
params_ok $router, '/account/delete', { method => 'GET' }, { controller => 'Account', action => 'delete' };

# with format
params_ok $router, '/account.html', { method => 'GET' },
    { controller => 'Account', action => 'show', format => 'html' };
params_ok $router, '/account.html', { method => 'POST' },
    { controller => 'Account', action => 'create', format => 'html' };
params_ok $router, '/account.html', { method => 'PUT' },
    { controller => 'Account', action => 'update', format => 'html' };
params_ok $router, '/account.html', { method => 'DELETE' },
    { controller => 'Account', action => 'destroy', format => 'html' };

params_ok $router, '/account/new.html', { method => 'GET' },
    { controller => 'Account', action => 'post', format => 'html' };
params_ok $router, '/account/edit.html', { method => 'GET' },
    { controller => 'Account', action => 'edit', format => 'html' };
params_ok $router, '/account/delete.html', { method => 'GET' },
    { controller => 'Account', action => 'delete', format => 'html' };
