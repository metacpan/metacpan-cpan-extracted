use strict;
use warnings;
use Test::More tests => 8;
use lib 'lib';
use Forward::Routes;


### via
my $r = Forward::Routes->new;
$r->add_route('logout', via => 'put');

ok $r->match(put => 'logout');
ok !$r->match(post => 'logout');


### via with inheritance
$r = Forward::Routes->new;
my $base = $r->add_route->via('post');
$base->add_route('logout', via => 'put');

ok $r->match(put => 'logout');
ok !$r->match(post => 'logout');


### format
$r = Forward::Routes->new;
$r->add_route('logout', format => 'html');

ok !$r->match(get => 'logout');
ok $r->match(get => 'logout.html');


### format with inheritance
$r = Forward::Routes->new;
$base = $r->add_route->format('html');
$base->add_route('logout', format => 'xml');

ok !$r->match(get => 'logout.html');
ok $r->match(get => 'logout.xml');
