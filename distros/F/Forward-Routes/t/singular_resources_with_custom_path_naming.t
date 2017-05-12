use strict;
use warnings;
use Test::More tests => 20;
use lib 'lib';
use Forward::Routes;



#############################################################################
# singular resources with custom path naming

my $r = Forward::Routes->new;

$r->add_singular_resources(
    'geocoder',
    'contact_details' => -as => 'contact',
    'test'
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



### now contact as contact_details

$m = $r->match(get => 'contact_details/new');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'create_form'};

$m = $r->match(post => 'contact_details');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'create'};

$m = $r->match(get => 'contact_details');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'show'};

$m = $r->match(get => 'contact_details/edit');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'update_form'};

$m = $r->match(put => 'contact_details');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'update'};

$m = $r->match(delete => 'contact_details');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'delete'};


is $r->build_path('contact_create_form')->{path} => 'contact_details/new';
is $r->build_path('contact_create')->{path} => 'contact_details';
is $r->build_path('contact_show', id => 456)->{path} => 'contact_details';
is $r->build_path('contact_update_form', id => 789)->{path} => 'contact_details/edit';
is $r->build_path('contact_update', id => 987)->{path} => 'contact_details';
is $r->build_path('contact_delete', id => 654)->{path} => 'contact_details';



### "test" resource without custom path naming
$m = $r->match(get => 'test/new');
is_deeply $m->[0]->params => {controller => 'Test', action => 'create_form'};


is $r->build_path('test_create_form')->{path} => 'test/new';

