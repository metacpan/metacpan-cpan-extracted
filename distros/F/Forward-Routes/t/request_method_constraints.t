use strict;
use warnings;
use Test::More tests => 38;
use lib 'lib';
use Forward::Routes;



#############################################################################
### no method constraint

my $r = Forward::Routes->new;
my $nested = $r->add_route('foo')->defaults(test => 1)->name('foo');

my $m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {test => 1};

$m = $r->match(post => 'foo');
is_deeply $m->[0]->params => {test => 1};

$m = $r->match(put => 'foo');
is_deeply $m->[0]->params => {test => 1};

$m = $r->match(delete => 'foo');
is_deeply $m->[0]->params => {test => 1};


# build path
is $r->build_path('foo')->{method}, undef;


#############################################################################
### multiple method constraints

$r = Forward::Routes->new;
$nested = $r->add_route('foo')->via('post','put')->defaults(test => 1)->name('foo');

$m = $r->match(get => 'foo');
is $m, undef;

$m = $r->match(post => 'foo');
is_deeply $m->[0]->params => {test => 1};

$m = $r->match(put => 'foo');
is_deeply $m->[0]->params => {test => 1};

$m = $r->match(delete => 'foo');
is $m, undef;

# build path
is $r->build_path('foo')->{method}, 'post';



#############################################################################
### method constraints and nested routes

$r = Forward::Routes->new;
$nested = $r->add_route('foo');
$nested->add_route->via('get')->defaults(test => 1)->to('foo#get')->name('one');
$nested->add_route->via('post')->to('foo#post')->defaults( test => 2)->name('two');
$nested->add_route->via('put')->to('foo#put')->name('three');

$m = $r->match(post => 'foo');
is_deeply $m->[0]->params => {controller => 'foo', action => 'post', test => 2};

$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {controller => 'foo', action => 'get', test => 1};

$m = $r->match(delete => 'foo');
is $m, undef;


# build path
is $r->build_path('one')->{method}, 'get';
is $r->build_path('two')->{method}, 'post';
is $r->build_path('three')->{method}, 'put';


#############################################################################
### upper case vs. lower case

$r = Forward::Routes->new;
$r->add_route('logout')->via('GET')->name('one');
ok $r->match(get => 'logout');
ok $r->match(GET => 'logout');
ok !$r->match(post => 'logout');


# build path
is $r->build_path('one')->{method}, 'get';


$r = Forward::Routes->new;
$r->add_route('logout')->via('get');
ok $r->match(GET => 'logout');
ok !$r->match(POST => 'logout');

$r = Forward::Routes->new;
$r->add_route('logout')->via('get','post');
ok $r->match(GET => 'logout');
ok $r->match(POST => 'logout');
ok !$r->match(PUT => 'logout');

$r = Forward::Routes->new;
$r->add_route('logout')->via('GET','POST')->name('one');
ok $r->match(get => 'logout');
ok $r->match(GET => 'logout');
ok $r->match(post => 'logout');
ok $r->match(POST => 'logout');
ok !$r->match(put => 'logout');
ok !$r->match(PUT => 'logout');

# build path
is $r->build_path('one')->{method}, 'get';


#############################################################################
### pass array ref

$r = Forward::Routes->new;
$r->add_route('photos/:id')->via([qw/get post PUT/])->name('oo');
ok $r->match(get => 'photos/1');
ok $r->match(POST => 'photos/1');
ok !$r->match(head => 'photos/1');
ok $r->match(put => 'photos/1');
ok $r->match(PUT => 'photos/1');

# build path
is $r->build_path('oo', id => 43)->{method}, 'get';