use strict;
use Test::More tests => 5;
use Test::HTTP::Router;
use HTTP::Router::Declare;

my $router = router {
    match '/' => to { controller => 'Root', action => 'index' };

    match '/home', { method => 'GET' }
        => to { controller => 'Home', action => 'show' };
    match '/date/{year}', { year => qr/^\d{4}$/ }
        => to { controller => 'Date', action => 'by_year' };

    match '/{controller}/{action}/{id}';
};

is scalar @{[ $router->routes ]} => 4;

path_ok $router, '/';

match_ok $router, '/home', { method => 'GET' };
path_ok $router, '/date/2009';

path_ok $router, '/foo/bar/baz';
