use strict;
use warnings;
use Test::More tests => 35;
use lib 'lib';
use Forward::Routes;



#############################################################################
### resources with custom path naming

my $r = Forward::Routes->new;
$r->add_resources(
    'photos',
    'customers' => -as => 'users',
    'prices'
);


# NO adjusted path name
my $m = $r->match(get => 'photos');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'index'};
$m = $r->match(get => 'photos/new');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'create_form'};
$m = $r->match(post => 'photos');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'create'};


is $r->build_path('photos_index')->{path} => 'photos';
is $r->build_path('photos_create_form')->{path} => 'photos/new';
is $r->build_path('photos_create')->{path} => 'photos';


is $r->build_path('photos_index')->{method} => 'get';
is $r->build_path('photos_create_form')->{method} => 'get';
is $r->build_path('photos_create')->{method} => 'post';



# adjusted path name
$m = $r->match(get => 'customers');
is_deeply $m->[0]->params => {controller => 'Users', action => 'index'};

$m = $r->match(get => 'customers/new');
is_deeply $m->[0]->params => {controller => 'Users', action => 'create_form'};

$m = $r->match(post => 'customers');
is_deeply $m->[0]->params => {controller => 'Users', action => 'create'};

$m = $r->match(get => 'customers/1');
is_deeply $m->[0]->params => {controller => 'Users', action => 'show', id => 1};

$m = $r->match(get => 'customers/1/edit');
is_deeply $m->[0]->params => {controller => 'Users', action => 'update_form', id => 1};

$m = $r->match(get => 'customers/1/delete');
is_deeply $m->[0]->params => {controller => 'Users', action => 'delete_form', id => 1};

$m = $r->match(put => 'customers/1');
is_deeply $m->[0]->params => {controller => 'Users', action => 'update', id => 1};

$m = $r->match(delete => 'customers/1');
is_deeply $m->[0]->params => {controller => 'Users', action => 'delete', id => 1};


# path building with adjusted path name
is $r->build_path('users_index')->{path} => 'customers';
is $r->build_path('users_create_form')->{path} => 'customers/new';
is $r->build_path('users_create')->{path} => 'customers';
is $r->build_path('users_show', id => 456)->{path} => 'customers/456';
is $r->build_path('users_update_form', id => 789)->{path} => 'customers/789/edit';
is $r->build_path('users_update', id => 987)->{path} => 'customers/987';
is $r->build_path('users_delete', id => 654)->{path} => 'customers/654';
is $r->build_path('users_delete_form', id => 222)->{path} => 'customers/222/delete';


# NO adjusted path name for prices
$m = $r->match(get => 'prices');
is_deeply $m->[0]->params => {controller => 'Prices', action => 'index'};
$m = $r->match(get => 'prices/new');
is_deeply $m->[0]->params => {controller => 'Prices', action => 'create_form'};
$m = $r->match(post => 'prices');
is_deeply $m->[0]->params => {controller => 'Prices', action => 'create'};


is $r->build_path('prices_index')->{path} => 'prices';
is $r->build_path('prices_create_form')->{path} => 'prices/new';
is $r->build_path('prices_create')->{path} => 'prices';


is $r->build_path('prices_index')->{method} => 'get';
is $r->build_path('prices_create_form')->{method} => 'get';
is $r->build_path('prices_create')->{method} => 'post';



#############################################################################
### empty options
$r = Forward::Routes->new;
$r->add_resources(
    'photos',
    'users' => {},
    'prices'
);

$m = $r->match(get => 'users');
is_deeply $m->[0]->params => {controller => 'Users', action => 'index'};
