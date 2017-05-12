use strict;
use warnings;
use Test::More tests => 30;
use lib 'lib';
use Forward::Routes;



#############################################################################
# singular resources with namespace prefix

my $r = Forward::Routes->new;

$r->add_singular_resources(
    'geocoder',
    'contact' => -namespace => 'Admin',
    'test' => -namespace => 'Admin',
    'member'
);

my $m = $r->match(get => 'geocoder/new');
is_deeply $m->[0]->params => {controller => 'Geocoder', action => 'create_form'};

$m = $r->match(post => 'geocoder');
is_deeply $m->[0]->params => {controller => 'Geocoder', action => 'create'};

$m = $r->match(get => 'geocoder');
is_deeply $m->[0]->params => {controller => 'Geocoder', action => 'show'};


is $r->build_path('geocoder_create_form')->{path} => 'geocoder/new';
is $r->build_path('geocoder_create')->{path} => 'geocoder';
is $r->build_path('geocoder_show', id => 456)->{path} => 'geocoder';



### now contact

$m = $r->match(get => 'contact/new');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'create_form'};
is $m->[0]->class, 'Admin::Contact';

$m = $r->match(post => 'contact');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'create'};
is $m->[0]->class, 'Admin::Contact';

$m = $r->match(get => 'contact');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'show'};
is $m->[0]->class, 'Admin::Contact';

$m = $r->match(get => 'contact/edit');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'update_form'};
is $m->[0]->class, 'Admin::Contact';

$m = $r->match(put => 'contact');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'update'};
is $m->[0]->class, 'Admin::Contact';

$m = $r->match(delete => 'contact');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'delete'};
is $m->[0]->class, 'Admin::Contact';


is $r->build_path('admin_contact_create_form')->{path} => 'contact/new';
is $r->build_path('admin_contact_create')->{path} => 'contact';
is $r->build_path('admin_contact_show', id => 456)->{path} => 'contact';
is $r->build_path('admin_contact_update_form', id => 789)->{path} => 'contact/edit';
is $r->build_path('admin_contact_update', id => 987)->{path} => 'contact';
is $r->build_path('admin_contact_delete', id => 654)->{path} => 'contact';


# make sure that admin does not match (it is just the namespace value):
$m = $r->match(get => 'admin');
is $m, undef;


### now "test"
$m = $r->match(get => 'test/new');
is_deeply $m->[0]->params => {controller => 'Test', action => 'create_form'};
is $m->[0]->class, 'Admin::Test';

is $r->build_path('admin_test_create_form')->{path} => 'test/new';


### now "member" (no namespace)
$m = $r->match(get => 'member/new');
is_deeply $m->[0]->params => {controller => 'Member', action => 'create_form'};

is $r->build_path('member_create_form')->{path} => 'member/new';

