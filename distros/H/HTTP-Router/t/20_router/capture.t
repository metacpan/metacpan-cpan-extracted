use Test::More tests => 7;
use Test::HTTP::Router;
use HTTP::Router;

my $r = HTTP::Router->new;
$r->add_route('/bar', params => { action => 'path' });
$r->add_route(
    '/{year}',
    conditions => { year => qr/^\d{4}$/ },
    params     => { action => 'by_year' }
);
$r->add_route('/{user_id}', params => { action => 'capture' });

is @{[ $r->routes ]} => 3;

path_ok $r, '/2009';
params_ok $r, '/2009', { action => 'by_year', year => 2009 };

path_ok $r, '/foo';
params_ok $r, '/foo', { action => 'capture', user_id => 'foo' };

path_ok $r, '/bar';
params_ok $r, '/bar', { action => 'path' };
