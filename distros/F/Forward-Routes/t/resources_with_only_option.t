use strict;
use warnings;
use Test::More tests => 74;
use lib 'lib';
use Forward::Routes;



#############################################################################
### only selected resourceful routes

# index
my $r = Forward::Routes->new;
$r->add_resources(
    'photos',
    'users' => -only => ['index'],
    'prices'
);

my $m = $r->match(get => 'users');
is_deeply $m->[0]->params => {controller => 'Users', action => 'index'};

$m = $r->match(get => 'users/new');
is $m, undef;

$m = $r->match(post => 'users');
is $m, undef;

$m = $r->match(get => 'users/1');
is $m, undef;

$m = $r->match(get => 'users/1/edit');
is $m, undef;

$m = $r->match(get => 'users/1/delete');
is $m, undef;

$m = $r->match(put => 'users/1');
is $m, undef;

$m = $r->match(delete => 'users/1');
is $m, undef;


# create
$r = Forward::Routes->new;
$r->add_resources(
    'photos',
    'users' => -only => ['create'],
    'prices'
);

$m = $r->match(get => 'users');
is $m, undef;

$m = $r->match(get => 'users/new');
is $m, undef;

$m = $r->match(post => 'users');
is_deeply $m->[0]->params => {controller => 'Users', action => 'create'};

$m = $r->match(get => 'users/1');
is $m, undef;

$m = $r->match(get => 'users/1/edit');
is $m, undef;

$m = $r->match(get => 'users/1/delete');
is $m, undef;

$m = $r->match(put => 'users/1');
is $m, undef;

$m = $r->match(delete => 'users/1');
is $m, undef;



# show
$r = Forward::Routes->new;
$r->add_resources(
    'photos',
    'users' => -only => ['show'],
    'prices'
);

$m = $r->match(get => 'users');
is $m, undef;

$m = $r->match(get => 'users/new');
is_deeply $m->[0]->params, {id => 'new', controller => 'Users', action => 'show'};

$m = $r->match(post => 'users');
is $m, undef;

$m = $r->match(get => 'users/1');
is_deeply $m->[0]->params => {controller => 'Users', action => 'show', id => 1};

$m = $r->match(get => 'users/1new');
is_deeply $m->[0]->params => {controller => 'Users', action => 'show', id => '1new'};

$m = $r->match(get => 'users/new1');
is_deeply $m->[0]->params => {controller => 'Users', action => 'show', id => 'new1'};

$m = $r->match(get => 'users/1/edit');
is $m, undef;

$m = $r->match(get => 'users/1/delete');
is $m, undef;

$m = $r->match(put => 'users/1');
is $m, undef;

$m = $r->match(delete => 'users/1');
is $m, undef;



# update
$r = Forward::Routes->new;
$r->add_resources(
    'photos',
    'users' => -only => ['update'],
    'prices'
);

$m = $r->match(get => 'users');
is $m, undef;

$m = $r->match(get => 'users/new');
is $m, undef;

$m = $r->match(post => 'users');
is $m, undef;

$m = $r->match(get => 'users/1');
is $m, undef;

$m = $r->match(get => 'users/1/edit');
is $m, undef;

$m = $r->match(get => 'users/1/delete');
is $m, undef;

$m = $r->match(put => 'users/1');
is_deeply $m->[0]->params => {controller => 'Users', action => 'update', id => 1};

$m = $r->match(delete => 'users/1');
is $m, undef;



# delete
$r = Forward::Routes->new;
$r->add_resources(
    'photos',
    'users' => -only => ['delete'],
    'prices'
);

$m = $r->match(get => 'users');
is $m, undef;

$m = $r->match(get => 'users/new');
is $m, undef;

$m = $r->match(post => 'users');
is $m, undef;

$m = $r->match(get => 'users/1');
is $m, undef;

$m = $r->match(get => 'users/1/edit');
is $m, undef;

$m = $r->match(get => 'users/1/delete');
is $m, undef;

$m = $r->match(put => 'users/1');
is $m, undef;

$m = $r->match(delete => 'users/1');
is_deeply $m->[0]->params => {controller => 'Users', action => 'delete', id => 1};



# create_form
$r = Forward::Routes->new;
$r->add_resources(
    'photos',
    'users' => -only => ['create_form'],
    'prices'
);

$m = $r->match(get => 'users');
is $m, undef;

$m = $r->match(get => 'users/new');
is_deeply $m->[0]->params => {controller => 'Users', action => 'create_form'};

$m = $r->match(post => 'users');
is $m, undef;

$m = $r->match(get => 'users/1');
is $m, undef;

$m = $r->match(get => 'users/1/edit');
is $m, undef;

$m = $r->match(get => 'users/1/delete');
is $m, undef;

$m = $r->match(put => 'users/1');
is $m, undef;

$m = $r->match(delete => 'users/1');
is $m, undef;



# update_form
$r = Forward::Routes->new;
$r->add_resources(
    'photos',
    'users' => -only => ['update_form'],
    'prices'
);

$m = $r->match(get => 'users');
is $m, undef;

$m = $r->match(get => 'users/new');
is $m, undef;

$m = $r->match(post => 'users');
is $m, undef;

$m = $r->match(get => 'users/1');
is $m, undef;

$m = $r->match(get => 'users/1/edit');
is_deeply $m->[0]->params => {controller => 'Users', action => 'update_form', id => 1};

$m = $r->match(get => 'users/1/delete');
is $m, undef;

$m = $r->match(put => 'users/1');
is $m, undef;

$m = $r->match(delete => 'users/1');
is $m, undef;



# delete_form
$r = Forward::Routes->new;
$r->add_resources(
    'photos',
    'users' => -only => ['delete_form'],
    'prices'
);

$m = $r->match(get => 'users');
is $m, undef;

$m = $r->match(get => 'users/new');
is $m, undef;

$m = $r->match(post => 'users');
is $m, undef;

$m = $r->match(get => 'users/1');
is $m, undef;

$m = $r->match(get => 'users/1/edit');
is $m, undef;

$m = $r->match(get => 'users/1/delete');
is_deeply $m->[0]->params => {controller => 'Users', action => 'delete_form', id => 1};

$m = $r->match(put => 'users/1');
is $m, undef;

$m = $r->match(delete => 'users/1');
is $m, undef;


# more than one route
# create and show
$r = Forward::Routes->new;
$r->add_resources(
    'photos',
    'users' => -only => ['create', 'show'],
    'prices'
);

$m = $r->match(get => 'users');
is $m, undef;

$m = $r->match(get => 'users/new');
is_deeply $m->[0]->params, {id => 'new', controller => 'Users', action => 'show'};

$m = $r->match(post => 'users');
is_deeply $m->[0]->params => {controller => 'Users', action => 'create'};

$m = $r->match(get => 'users/1');
is_deeply $m->[0]->params => {controller => 'Users', action => 'show', id => 1};

$m = $r->match(get => 'users/1/edit');
is $m, undef;

$m = $r->match(get => 'users/1/delete');
is $m, undef;

$m = $r->match(put => 'users/1');
is $m, undef;

$m = $r->match(delete => 'users/1');
is $m, undef;
