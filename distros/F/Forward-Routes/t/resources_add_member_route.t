use strict;
use warnings;
use Test::More tests => 47;
use lib 'lib';
use Forward::Routes;



#############################################################################
### add member route

# automatic controller and action defaults and naming
my $r = Forward::Routes->new;
my $photos = $r->add_resources('photos');
$photos->add_member_route('search_form');
$photos->add_member_route('search')->via('post');

my $m = $r->match(get => 'photos/1/search_form');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'search_form', id => 1};
is $m->[0]->name, 'photos_search_form';

$m = $r->match(post => 'photos/1/search_form');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'search_form', id => 1};
is $m->[0]->name, 'photos_search_form';

$m = $r->match(get => 'photos/1/search');
is $m, undef;

$m = $r->match(post => 'photos/1/search');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'search', id => 1};
is $m->[0]->name, 'photos_search';



# overwrite controller and action defaults
$photos->add_member_route('find')->to('Foo#bar');
$m = $r->match(get => 'photos/0/find');
is_deeply $m->[0]->params => {controller => 'Foo', action => 'bar', id => 0};
is $m->[0]->name, 'photos_find';


# overwrite name
$photos->add_member_route('find2')->name('hello_world2');
$m = $r->match(get => 'photos/123/find2');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'find2', id => 123};
is $m->[0]->name, 'hello_world2';


# pass path instead of name
$photos->add_member_route('/find3');
$m = $r->match(get => 'photos/123/find3');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'find3', id => 123};
is $m->[0]->name, 'photos_find3';


$photos->add_member_route('/find4/find5');
$m = $r->match(get => 'photos/123/find4/find5');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'find4_find5', id => 123};
is $m->[0]->name, 'photos_find4_find5';


#############################################################################
# all other routes still work!

$m = $r->match(get => 'photos');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'index'};
is $m->[0]->name, 'photos_index';

$m = $r->match(get => 'photos2');
is $m, undef;

$m = $r->match(get => 'photos/new');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'create_form'};
is $m->[0]->name, 'photos_create_form';

$m = $r->match(post => 'photos');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'create'};
is $m->[0]->name, 'photos_create';

$m = $r->match(get => 'photos/1');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'show', id => 1};
is $m->[0]->name, 'photos_show';

$m = $r->match(get => 'photos/1/edit');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'update_form', id => 1};
is $m->[0]->name, 'photos_update_form';

$m = $r->match(get => 'photos/1/delete');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'delete_form', id => 1};
is $m->[0]->name, 'photos_delete_form';

$m = $r->match(put => 'photos/1');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'update', id => 1};
is $m->[0]->name, 'photos_update';

$m = $r->match(delete => 'photos/1');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'delete', id => 1};
is $m->[0]->name, 'photos_delete';


is $r->find_route('photos_index')->name, 'photos_index';
is $r->find_route('photos_update')->name, 'photos_update';

is $r->build_path('photos_index')->{path} => 'photos';
is $r->build_path('photos_update', id => 987)->{path} => 'photos/987';

is $r->build_path('photos_index')->{method} => 'get';
is $r->build_path('photos_update', id => 987)->{method} => 'put';



#############################################################################
### add member with namespace

$r = Forward::Routes->new;
$photos = $r->add_resources('photos' => -namespace => 'Admin');
$photos->add_member_route('search_form');

$m = $r->match(get => 'photos/1/search_form');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'search_form', id => 1};
is $m->[0]->class, 'Admin::Photos';
is $m->[0]->name, 'admin_photos_search_form';



#############################################################################
# with only option
# no default member routes

$r = Forward::Routes->new;
$photos = $r->add_resources('photos' => -only => [qw/index/]);
isa_ok $photos->add_member_route('search_form'), 'Forward::Routes';
$m = $r->match(get => 'photos/1/edit');
is $m, undef;
$m = $r->match(get => 'photos/1/search_form');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'search_form', id => 1};


# now with constraints and no default member routes
$r = Forward::Routes->new;
$photos = $r->add_resources(
  'photos' =>
      -only => [qw/index/], 
      -constraints => {id => qr/\d{6}/});
isa_ok $photos->add_member_route('search_form'), 'Forward::Routes';
$m = $r->match(get => 'photos/1/search_form');
is $m, undef;
$m = $r->match(get => 'photos/123456/search_form');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'search_form', id => 123456};

