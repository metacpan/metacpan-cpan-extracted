use strict;
use warnings;
use Test::More tests => 22;
use lib 'lib';
use Forward::Routes;


#############################################################################
### singular resources

my $r = Forward::Routes->new;

my $resource = $r->add_singular_resources('geocoder');

is $resource->_is_singular_resource, 1;

my $m = $r->match(get => 'geocoder/new');
is_deeply $m->[0]->params => {controller => 'Geocoder', action => 'create_form'};

$m = $r->match(post => 'geocoder');
is_deeply $m->[0]->params => {controller => 'Geocoder', action => 'create'};

$m = $r->match(get => 'geocoder');
is_deeply $m->[0]->params => {controller => 'Geocoder', action => 'show'};

$m = $r->match(get => 'geocoder/edit');
is_deeply $m->[0]->params => {controller => 'Geocoder', action => 'update_form'};

$m = $r->match(put => 'geocoder');
is_deeply $m->[0]->params => {controller => 'Geocoder', action => 'update'};

$m = $r->match(delete => 'geocoder');
is_deeply $m->[0]->params => {controller => 'Geocoder', action => 'delete'};

is $resource->name, 'geocoder';

is ref $r->find_route('geocoder_create_form'), 'Forward::Routes';
is $r->find_route('geocoder_foo'), undef;
is $r->find_route('geocoder_create_form')->name, 'geocoder_create_form';
is $r->find_route('geocoder_create')->name, 'geocoder_create';
is $r->find_route('geocoder_show')->name, 'geocoder_show';
is $r->find_route('geocoder_update_form')->name, 'geocoder_update_form';
is $r->find_route('geocoder_update')->name, 'geocoder_update';
is $r->find_route('geocoder_delete')->name, 'geocoder_delete';

is $r->build_path('geocoder_create_form')->{path} => 'geocoder/new';
is $r->build_path('geocoder_create')->{path} => 'geocoder';
is $r->build_path('geocoder_show', id => 456)->{path} => 'geocoder';
is $r->build_path('geocoder_update_form', id => 789)->{path} => 'geocoder/edit';
is $r->build_path('geocoder_update', id => 987)->{path} => 'geocoder';
is $r->build_path('geocoder_delete', id => 654)->{path} => 'geocoder';
