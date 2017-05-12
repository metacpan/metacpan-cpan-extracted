use strict;
use warnings;
use Test::More tests => 39;
use lib 'lib';
use Forward::Routes;



#############################################################################
### nested resources

my $r = Forward::Routes->new;

my $ads = $r->add_resources('magazines')->add_singular_resources('manager');


# magazine routes work
my $m = $r->match(get => 'magazines');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'index'};

$m = $r->match(get => 'magazines/new');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'create_form'};

$m = $r->match(post => 'magazines');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'create'};

$m = $r->match(get => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'show', id => 1};

$m = $r->match(get => 'magazines/1/edit');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'update_form', id => 1};

$m = $r->match(get => 'magazines/1/delete');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'delete_form', id => 1};

$m = $r->match(put => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'update', id => 1};

$m = $r->match(delete => 'magazines/1');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'delete', id => 1};



# nested manager routes work
$m = $r->match(get => 'magazines/1/manager');
is_deeply $m->[0]->params => {controller => 'Manager', action => 'show', magazine_id => 1};

$m = $r->match(get => 'magazines/1/manager/new');
is_deeply $m->[0]->params => {controller => 'Manager', action => 'create_form', magazine_id => 1};

$m = $r->match(post => 'magazines/1/manager');
is_deeply $m->[0]->params => {controller => 'Manager', action => 'create', magazine_id => 1};

$m = $r->match(get => 'magazines/15/manager/edit');
is_deeply $m->[0]->params => {controller => 'Manager', action => 'update_form', magazine_id => 15};

$m = $r->match(put => 'magazines/1/manager');
is_deeply $m->[0]->params => {controller => 'Manager', action => 'update', magazine_id => 1};

$m = $r->match(delete => 'magazines/0/manager');
is_deeply $m->[0]->params => {controller => 'Manager', action => 'delete', magazine_id => 0};

$m = $r->match(post => 'magazines/1.2/manager');
is $m, undef;



# build path
is $r->build_path('magazines_manager_create_form', magazine_id => 4)->{path} => 'magazines/4/manager/new';
is $r->build_path('magazines_manager_create_form', magazine_id => 4)->{method} => 'get';

is $r->build_path('magazines_manager_create', magazine_id => 5)->{path} => 'magazines/5/manager';
is $r->build_path('magazines_manager_create', magazine_id => 5)->{method} => 'post';

is $r->build_path('magazines_manager_show', magazine_id => 3)->{path} => 'magazines/3/manager';
is $r->build_path('magazines_manager_show', magazine_id => 3)->{method} => 'get';

is $r->build_path('magazines_manager_update', magazine_id => 0)->{path} => 'magazines/0/manager';
is $r->build_path('magazines_manager_update', magazine_id => 0)->{method} => 'put';

is $r->build_path('magazines_manager_delete', magazine_id => 4)->{path} => 'magazines/4/manager';
is $r->build_path('magazines_manager_delete', magazine_id => 4)->{method} => 'delete';

is $r->build_path('magazines_manager_update_form', magazine_id => 3)->{path} => 'magazines/3/manager/edit';
is $r->build_path('magazines_manager_update_form', magazine_id => 3)->{method} => 'get';


my $e = eval {$r->build_path('magazines_manager_show')->{path}; };
like $@ => qr/Required param 'magazine_id' was not passed when building a path/;
undef $e;


# constraint for parent id
$r = Forward::Routes->new;

$ads = $r->add_resources('magazines' => -constraints => {id => qr/[\d]{2}/})
  ->add_singular_resources('manager');

$m = $r->match(get => 'magazines/1');
is $m, undef;

$m = $r->match(get => 'magazines/22');
is_deeply $m->[0]->params => {controller => 'Magazines', action => 'show', id => 22};

$m = $r->match(get => 'magazines/1/manager');
is $m, undef;

$m = $r->match(get => 'magazines/22/manager');
is_deeply $m->[0]->params => {controller => 'Manager', action => 'show', magazine_id => 22};



#############################################################################
### test with -as option
$r = Forward::Routes->new;
$r->add_resources('magazines')->add_singular_resources('management', -as => 'manager');


# nested manager routes work
$m = $r->match(get => 'magazines/1/management');
is_deeply $m->[0]->params => {controller => 'Manager', action => 'show', magazine_id => 1};

$m = $r->match(get => 'magazines/1/management/new');
is_deeply $m->[0]->params => {controller => 'Manager', action => 'create_form', magazine_id => 1};



# build path
is $r->build_path('magazines_manager_show', magazine_id => 3)->{path} => 'magazines/3/management';
is $r->build_path('magazines_manager_show', magazine_id => 3)->{method} => 'get';

is $r->build_path('magazines_manager_create_form', magazine_id => 4)->{path} => 'magazines/4/management/new';
is $r->build_path('magazines_manager_create_form', magazine_id => 4)->{method} => 'get';


$e = eval {$r->build_path('magazines_manager_show')->{path}; };
like $@ => qr/Required param 'magazine_id' was not passed when building a path/;
undef $e;
