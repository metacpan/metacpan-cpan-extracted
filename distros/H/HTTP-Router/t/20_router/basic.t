use Test::More tests => 5;
use Test::HTTP::Router;
use HTTP::Router;

my $r = HTTP::Router->new;
$r->add_route('/', params => { controller => 'Root', action => 'index' });
$r->add_route(
    '/foo',
    conditions => { method => 'GET' },
    params     => { controller => 'Foo', action => 'index' }
);

is @{[ $r->routes ]} => 2;

path_ok $r, '/';
params_ok $r, '/', { controller => 'Root', action => 'index' };

match_ok $r, '/foo', { method => 'GET' };
params_ok $r, '/foo', { method => 'GET' }, { controller => 'Foo', action => 'index' };
