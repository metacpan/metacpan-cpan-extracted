use strict;
use warnings;
use Test::More tests => 37;
use lib 'lib';
use Forward::Routes;



#############################################################################
### plural resources

my $r = Forward::Routes->new;
my $resource = $r->add_resources('users','photos','tags');

is $resource->_is_plural_resource, 1;

my $m = $r->match(get => 'photos');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'index'};

$m = $r->match(get => 'photos2');
is $m, undef;

$m = $r->match(get => 'photos/new');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'create_form'};

$m = $r->match(post => 'photos');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'create'};

$m = $r->match(get => 'photos/1');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'show', id => 1};

$m = $r->match(get => 'photos/1/edit');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'update_form', id => 1};

$m = $r->match(get => 'photos/1/delete');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'delete_form', id => 1};

$m = $r->match(put => 'photos/1');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'update', id => 1};

$m = $r->match(delete => 'photos/1');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'delete', id => 1};

is $resource->name, 'tags';

is ref $r->find_route('photos_index'), 'Forward::Routes';
is $r->find_route('photos_foo'), undef;
is $r->find_route('photos_index')->name, 'photos_index';
is $r->find_route('photos_create_form')->name, 'photos_create_form';
is $r->find_route('photos_create')->name, 'photos_create';
is $r->find_route('photos_show')->name, 'photos_show';
is $r->find_route('photos_update_form')->name, 'photos_update_form';
is $r->find_route('photos_update')->name, 'photos_update';
is $r->find_route('photos_delete')->name, 'photos_delete';
is $r->find_route('photos_delete_form')->name, 'photos_delete_form';

is $r->build_path('photos_index')->{path} => 'photos';
is $r->build_path('photos_create_form')->{path} => 'photos/new';
is $r->build_path('photos_create')->{path} => 'photos';
is $r->build_path('photos_show', id => 456)->{path} => 'photos/456';
is $r->build_path('photos_update_form', id => 789)->{path} => 'photos/789/edit';
is $r->build_path('photos_update', id => 987)->{path} => 'photos/987';
is $r->build_path('photos_delete', id => 654)->{path} => 'photos/654';
is $r->build_path('photos_delete_form', id => 222)->{path} => 'photos/222/delete';

is $r->build_path('photos_index')->{method} => 'get';
is $r->build_path('photos_create_form')->{method} => 'get';
is $r->build_path('photos_create')->{method} => 'post';
is $r->build_path('photos_show', id => 456)->{method} => 'get';
is $r->build_path('photos_update_form', id => 789)->{method} => 'get';
is $r->build_path('photos_update', id => 987)->{method} => 'put';
is $r->build_path('photos_delete', id => 654)->{method} => 'delete';
is $r->build_path('photos_delete_form', id => 222)->{method} => 'get';

