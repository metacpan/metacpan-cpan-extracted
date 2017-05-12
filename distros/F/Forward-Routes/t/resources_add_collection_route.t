use strict;
use warnings;
use Test::More tests => 55;
use lib 'lib';
use Forward::Routes;



#############################################################################
### add member route

# automatic controller and action defaults and naming
my $r = Forward::Routes->new;
my $photos = $r->add_resources('photos');
$photos->add_collection_route('search_form');
$photos->add_collection_route('search')->via('post');

my $m = $r->match(get => 'photos/search_form');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'search_form'};
is $m->[0]->name, 'photos_search_form';
is $r->build_path('photos_search_form')->{path} => 'photos/search_form';
is $r->build_path('photos_search_form')->{method} => undef;

$m = $r->match(post => 'photos/search_form');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'search_form'};
is $m->[0]->name, 'photos_search_form';


$m = $r->match(get => 'photos/search');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'show', id => 'search'};
my $re = '(?!new\Z)(?!search_form\Z)(?!search\Z)';
like $photos->{members}->pattern->pattern, qr/$re/;



$m = $r->match(post => 'photos/search');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'search'};
is $m->[0]->name, 'photos_search';
is $r->build_path('photos_search')->{path} => 'photos/search';
is $r->build_path('photos_search')->{method} => 'post';


# overwrite controller and action defaults
$photos->add_collection_route('find')->to('Foo#bar');
$m = $r->match(get => 'photos/find');
is_deeply $m->[0]->params => {controller => 'Foo', action => 'bar'};
is $m->[0]->name, 'photos_find';


# overwrite name
$photos->add_collection_route('find2')->name('hello_world2');
$m = $r->match(get => 'photos/find2');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'find2'};
is $m->[0]->name, 'hello_world2';


# pass path instead of name
$photos->add_collection_route('/find3');
$m = $r->match(get => 'photos/find3');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'find3'};
is $m->[0]->name, 'photos_find3';
is $r->build_path('photos_find3')->{path} => 'photos/find3';
is $r->build_path('photos_find3')->{method} => undef;


$photos->add_collection_route('/find4/find5');
$m = $r->match(get => 'photos/find4/find5');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'find4_find5'};
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
$photos->add_collection_route('search_form');

$m = $r->match(get => 'photos/search_form');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'search_form'};
is $m->[0]->class, 'Admin::Photos';
is $m->[0]->name, 'admin_photos_search_form';


#############################################################################
# with only option
# no default collection routes

$r = Forward::Routes->new;
$photos = $r->add_resources('photos' => -only => [qw/show/]);
isa_ok $photos->add_collection_route('search_form'), 'Forward::Routes';


#############################################################################
# with only option

$r = Forward::Routes->new;
$photos = $r->add_resources('photos' => -only => [qw/show/]);
$photos->add_collection_route('search_form');
$photos->add_collection_route('search');

$m = $r->match(get => 'photos/search_form');
ok $m;
$m = $r->match(get => 'photos/search');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'show', id => 'search'};
$m = $r->match(get => 'photos/new');
is_deeply $m->[0]->params => {controller => 'Photos', action => 'show', id => 'new'};


$r = Forward::Routes->new;
$photos = $r->add_resources('photos' => -only => [qw/show/], -constraints => {id => qr/\d+/});
$photos->add_collection_route('search_form');
$photos->add_collection_route('search')->via('post');

$m = $r->match(get => 'photos/search_form');
ok $m;
$m = $r->match(get => 'photos/search');
is $m, undef;
$m = $r->match(get => 'photos/new');
is $m, undef;
