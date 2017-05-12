use strict;
use warnings;
use Test::More tests => 28;
use lib 'lib';
use Forward::Routes;



#############################################################################
### add member route

# automatic controller and action defaults and naming
my $r = Forward::Routes->new;
my $photo = $r->add_singular_resources('photo');
$photo->add_member_route('search_form');
$photo->add_member_route('search')->via('post');

my $m = $r->match(get => 'photo/search_form');
is_deeply $m->[0]->params => {controller => 'Photo', action => 'search_form'};
is $m->[0]->name, 'photo_search_form';

$m = $r->match(post => 'photo/search_form');
is_deeply $m->[0]->params => {controller => 'Photo', action => 'search_form'};
is $m->[0]->name, 'photo_search_form';

$m = $r->match(get => 'photo/search');
is $m, undef;

$m = $r->match(post => 'photo/search');
is_deeply $m->[0]->params => {controller => 'Photo', action => 'search'};
is $m->[0]->name, 'photo_search';



# overwrite controller and action defaults
$photo->add_member_route('find')->to('Foo#bar');
$m = $r->match(get => 'photo/find');
is_deeply $m->[0]->params => {controller => 'Foo', action => 'bar'};
is $m->[0]->name, 'photo_find';


# overwrite name
$photo->add_member_route('find2')->name('hello_world2');
$m = $r->match(get => 'photo/find2');
is_deeply $m->[0]->params => {controller => 'Photo', action => 'find2'};
is $m->[0]->name, 'hello_world2';


# pass path instead of name
$photo->add_member_route('/find3');
$m = $r->match(get => 'photo/find3');
is_deeply $m->[0]->params => {controller => 'Photo', action => 'find3'};
is $m->[0]->name, 'photo_find3';


$photo->add_member_route('/find4/find5');
$m = $r->match(get => 'photo/find4/find5');
is_deeply $m->[0]->params => {controller => 'Photo', action => 'find4_find5'};
is $m->[0]->name, 'photo_find4_find5';


#############################################################################
# all other routes still work!

$m = $r->match(get => 'photo/new');
is_deeply $m->[0]->params => {controller => 'Photo', action => 'create_form'};

$m = $r->match(post => 'photo');
is_deeply $m->[0]->params => {controller => 'Photo', action => 'create'};

$m = $r->match(get => 'photo');
is_deeply $m->[0]->params => {controller => 'Photo', action => 'show'};

$m = $r->match(get => 'photo/edit');
is_deeply $m->[0]->params => {controller => 'Photo', action => 'update_form'};

$m = $r->match(put => 'photo');
is_deeply $m->[0]->params => {controller => 'Photo', action => 'update'};

$m = $r->match(delete => 'photo');
is_deeply $m->[0]->params => {controller => 'Photo', action => 'delete'};

is $r->find_route('photo_create_form')->name, 'photo_create_form';
is $r->find_route('photo_update')->name, 'photo_update';

is $r->build_path('photo_create_form')->{path} => 'photo/new';
is $r->build_path('photo_update', id => 987)->{path} => 'photo';




#############################################################################
### add member with namespace

$r = Forward::Routes->new;
$photo = $r->add_singular_resources('photo' => -namespace => 'Admin');
$photo->add_member_route('search_form');

$m = $r->match(get => 'photo/search_form');
is_deeply $m->[0]->params => {controller => 'Photo', action => 'search_form'};
is $m->[0]->name, 'admin_photo_search_form';
is $m->[0]->class, 'Admin::Photo';

