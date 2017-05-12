use strict;
use Test::More tests => 8;
use Test::HTTP::Router;
use HTTP::Router::Declare;

my $router = router {
    resources 'Users', {
        collection => { recent   => 'GET' },
        member     => { settings => 'GET' },
    };

    resources 'Articles', { except => [qw(edit delete)] };
    resources 'Entries',  { only => [qw(show update)] };
};

is scalar @{[ $router->routes ]} => 36; # users => 20, articles => 12, entries => 4

params_ok $router, '/users/recent', { method => 'GET' },
    { controller => 'Users', action => 'recent' };
params_ok $router, '/users/recent.html', { method => 'GET' },
    { controller => 'Users', action => 'recent', format => 'html' };

params_ok $router, '/users/1/settings', { method => 'GET' },
    { controller => 'Users', action => 'settings', user_id => 1 };
params_ok $router, '/users/1/settings.html', { method => 'GET' },
    { controller => 'Users', action => 'settings', user_id => 1, format => 'html' };

match_not_ok $router, '/articles/1/edit', { method => 'GET' }, 'not matched excepted action';

params_ok $router, '/entries/1', { method => 'GET' },
    { controller => 'Entries', action => 'show', entry_id => 1 };
match_not_ok $router, '/entries/1', { method => 'DELETE' }, 'not matched !only action';
