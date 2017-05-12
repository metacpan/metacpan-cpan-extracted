use strict;
use warnings;
use Test::More tests => 29;
use lib 'lib';
use Forward::Routes;



#############################################################################
### nested routes with method inheritance

my $root = Forward::Routes->new->via('post');
my $nested = $root->add_route('foo')->via('put');
$nested->add_route('bar')->name('one');
$root->add_route('baz')->name('two');
$root->add_route('buz')->name('three')->via('delete');


my $m = $root->match(get => 'foo/bar');
is $m, undef;

$m = $root->match(post => 'foo/bar');
is $m, undef;

$m = $root->match(put => 'foo/bar');
is_deeply $m->[0]->params => {};


$m = $root->match(get => '/baz');
is $m, undef;

$m = $root->match(post => '/baz');
is_deeply $m->[0]->params => {};


$m = $root->match(get => '/buz');
is $m, undef;

$m = $root->match(post => '/buz');
is $m, undef;

$m = $root->match(delete => '/buz');
is_deeply $m->[0]->params => {};


# build path
my $path = $root->build_path('one');
is $path->{method}, 'put';

$path = $root->build_path('two');
is $path->{method}, 'post';

$path = $root->build_path('three');
is $path->{method}, 'delete';


#############################################################################
### multiple values
$root = Forward::Routes->new->via('post','get');
$nested = $root->add_route('foo')->via('put');
$nested->add_route('bar')->name('one');
$root->add_route('baz')->name('two');
$root->add_route('buz')->name('three')->via('delete','put');


$m = $root->match(get => 'foo/bar');
is $m, undef;

$m = $root->match(post => 'foo/bar');
is $m, undef;

$m = $root->match(put => 'foo/bar');
is_deeply $m->[0]->params => {};


$m = $root->match(put => '/baz');
is $m, undef;

$m = $root->match(get => '/baz');
is_deeply $m->[0]->params => {};

$m = $root->match(post => '/baz');
is_deeply $m->[0]->params => {};


$m = $root->match(get => '/buz');
is $m, undef;

$m = $root->match(post => '/buz');
is $m, undef;

$m = $root->match(delete => '/buz');
is_deeply $m->[0]->params => {};

$m = $root->match(put => '/buz');
is_deeply $m->[0]->params => {};


# build path
$path = $root->build_path('one');
is $path->{method}, 'put';

$path = $root->build_path('two');
is $path->{method}, 'post';

$path = $root->build_path('three');
is $path->{method}, 'delete';


#############################################################################
### back to undef

my $r = Forward::Routes->new;
my $hello = $r->add_route('hello')->via('post');
ok $r->match(post => '/hello');
ok !$r->match(get => '/hello');
my $world = $hello->add_route('world')->via(undef);
ok $r->match(post => '/hello/world');
ok $r->match(get => '/hello/world');
ok $r->match(put => '/hello/world');
