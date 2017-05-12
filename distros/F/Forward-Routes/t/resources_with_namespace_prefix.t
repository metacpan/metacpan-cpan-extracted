use strict;
use warnings;
use Test::More tests => 42;
use lib 'lib';
use Forward::Routes;



#############################################################################
### plural resources with namespace prefix

my $r = Forward::Routes->new;
$r->add_resources(
    'photos',
    'users' => -namespace => 'Admin::Manage',
    'prices' => -namespace => 'Admin',
    'members'
);


# test routes withOUT namespace prefix
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



# adjusted controller
$m = $r->match(get => 'users');
is_deeply $m->[0]->params => {controller => 'Users', action => 'index'};
is $m->[0]->class, 'Admin::Manage::Users';

$m = $r->match(get => 'users/new');
is_deeply $m->[0]->params => {controller => 'Users', action => 'create_form'};
is $m->[0]->class, 'Admin::Manage::Users';

$m = $r->match(post => 'users');
is_deeply $m->[0]->params => {controller => 'Users', action => 'create'};
is $m->[0]->class, 'Admin::Manage::Users';

$m = $r->match(get => 'users/1');
is_deeply $m->[0]->params => {controller => 'Users', action => 'show', id => 1};
is $m->[0]->class, 'Admin::Manage::Users';

$m = $r->match(get => 'users/1/edit');
is_deeply $m->[0]->params => {controller => 'Users', action => 'update_form', id => 1};
is $m->[0]->class, 'Admin::Manage::Users';

$m = $r->match(get => 'users/1/delete');
is_deeply $m->[0]->params => {controller => 'Users', action => 'delete_form', id => 1};
is $m->[0]->class, 'Admin::Manage::Users';

$m = $r->match(put => 'users/1');
is_deeply $m->[0]->params => {controller => 'Users', action => 'update', id => 1};
is $m->[0]->class, 'Admin::Manage::Users';

$m = $r->match(delete => 'users/1');
is_deeply $m->[0]->params => {controller => 'Users', action => 'delete', id => 1};
is $m->[0]->class, 'Admin::Manage::Users';


# path building with name prefix
is $r->build_path('admin_manage_users_index')->{path} => 'users';
is $r->build_path('admin_manage_users_create_form')->{path} => 'users/new';
is $r->build_path('admin_manage_users_create')->{path} => 'users';
is $r->build_path('admin_manage_users_show', id => 456)->{path} => 'users/456';
is $r->build_path('admin_manage_users_update_form', id => 789)->{path} => 'users/789/edit';
is $r->build_path('admin_manage_users_update', id => 987)->{path} => 'users/987';
is $r->build_path('admin_manage_users_delete', id => 654)->{path} => 'users/654';
is $r->build_path('admin_manage_users_delete_form', id => 222)->{path} => 'users/222/delete';


# also works for prices
$m = $r->match(get => 'prices');
is_deeply $m->[0]->params => {controller => 'Prices', action => 'index'};
is $m->[0]->class, 'Admin::Prices';

is $r->build_path('admin_prices_index')->{path} => 'prices';


# just make sure:
$m = $r->match(get => 'admin');
is $m, undef;


# also works for members (no namespace)
$m = $r->match(get => 'members');
is_deeply $m->[0]->params => {controller => 'Members', action => 'index'};
is $r->build_path('members_index')->{path} => 'members';



#############################################################################
### customized format_resource_controller method

$r = Forward::Routes->new;

$r->format_resource_controller(
    sub {
        return $_[0];
    }
);

$r->add_resources(
    'photos',
    'users' => -namespace => 'Admin',
    'prices' => -namespace => 'Admin'
);

$m = $r->match(get => 'photos');
is_deeply $m->[0]->params => {controller => 'photos', action => 'index'};

$m = $r->match(get => 'users');
is_deeply $m->[0]->params => {controller => 'users', action => 'index'};
is $m->[0]->class, 'Admin::users';
