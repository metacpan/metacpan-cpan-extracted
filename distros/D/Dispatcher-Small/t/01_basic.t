use strict;
use warnings;
use Test::More;
use Dispatcher::Small;

my $r = Dispatcher::Small->new(
    GET => [
        qr'^/geo/([0-9]+)/([0-9]+)' => { action => 'Geo::index'    },
        qr'^/user/([0-9a-zA-Z_]+)'  => { action => 'User::index'   },
        qr'^/item/(?<id>[0-9]+)'    => { action => 'Item::index'   },
        qr'^/([0-9]+)'              => { action => 'Number::index' },
        qr'^/'                      => { action => 'Root::index'   },
    ],
    POST => [
        qr'^/user/([0-9a-zA-Z_]+)'  => { action => 'User::set' },
        qr'^/item/(?<id>[0-9]+)'    => { action => 'Item::set' },
    ],
);

sub get {
    my $path = shift;
    { REQUEST_METHOD => 'GET', PATH_INFO => $path };
}

sub post {
    my $path = shift;
    { REQUEST_METHOD => 'POST', PATH_INFO => $path };
}

isa_ok $r, 'Dispatcher::Small';
is_deeply $r->match(get('/')), +{ action => 'Root::index', capture => [ 1 ] };
is_deeply $r->match(get('/12345')), +{ action => 'Number::index', capture => [ 12345 ] };
is_deeply $r->match(get('/user/ytnobody1234')), +{ action => 'User::index', capture => [ 'ytnobody1234' ] };
is_deeply $r->match(get('/geo/100/200')), +{ action => 'Geo::index', capture => [ 100, 200 ] };
is_deeply $r->match(get('/fjkafjgsdk')), +{ action => 'Root::index', capture => [ 1 ] };
is_deeply $r->match(get('geo/100/200')), undef;
is_deeply $r->match(get('/item/123')), +{ action => 'Item::index', id => 123 };
is_deeply $r->match(post('/item/123')), +{ action => 'Item::set', id => 123 };
is_deeply $r->match(post('/user/ytnobody')), +{ action => 'User::set', capture => ['ytnobody'] };
is_deeply $r->match(post('/item/')), undef;

done_testing;
