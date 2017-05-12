use strict;
use warnings;
use Test::More tests => 42;
use lib 'lib';
use Forward::Routes;



#############################################################################
### only selected resourceful routes

# show
my $r = Forward::Routes->new;
$r->add_singular_resources(
    'photo',
    'contact' => -only => ['show'],
    'location'
);

my $m = $r->match(get => 'contact');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'show'};

$m = $r->match(post => 'contact');
is $m, undef;

$m = $r->match(put => 'contact');
is $m, undef;

$m = $r->match(delete => 'contact');
is $m, undef;

$m = $r->match(get => 'contact/edit');
is $m, undef;

$m = $r->match(get => 'contact/new');
is $m, undef;



# create
$r = Forward::Routes->new;
$r->add_singular_resources(
    'photo',
    'contact' => -only => ['create'],
    'location'
);

$m = $r->match(get => 'contact');
is $m, undef;

$m = $r->match(post => 'contact');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'create'};

$m = $r->match(put => 'contact');
is $m, undef;

$m = $r->match(delete => 'contact');
is $m, undef;

$m = $r->match(get => 'contact/edit');
is $m, undef;

$m = $r->match(get => 'contact/new');
is $m, undef;



# update
$r = Forward::Routes->new;
$r->add_singular_resources(
    'photo',
    'contact' => -only => ['update'],
    'location'
);

$m = $r->match(get => 'contact');
is $m, undef;

$m = $r->match(post => 'contact');
is $m, undef;

$m = $r->match(put => 'contact');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'update'};

$m = $r->match(delete => 'contact');
is $m, undef;

$m = $r->match(get => 'contact/edit');
is $m, undef;

$m = $r->match(get => 'contact/new');
is $m, undef;



# delete
$r = Forward::Routes->new;
$r->add_singular_resources(
    'photo',
    'contact' => -only => ['delete'],
    'location'
);

$m = $r->match(get => 'contact');
is $m, undef;

$m = $r->match(post => 'contact');
is $m, undef;

$m = $r->match(put => 'contact');
is $m, undef;

$m = $r->match(delete => 'contact');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'delete'};


$m = $r->match(get => 'contact/edit');
is $m, undef;

$m = $r->match(get => 'contact/new');
is $m, undef;



# update form
$r = Forward::Routes->new;
$r->add_singular_resources(
    'photo',
    'contact' => -only => ['update_form'],
    'location'
);

$m = $r->match(get => 'contact');
is $m, undef;

$m = $r->match(post => 'contact');
is $m, undef;

$m = $r->match(put => 'contact');
is $m, undef;

$m = $r->match(delete => 'contact');
is $m, undef;

$m = $r->match(get => 'contact/edit');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'update_form'};

$m = $r->match(get => 'contact/new');
is $m, undef;



# create form
$r = Forward::Routes->new;
$r->add_singular_resources(
    'photo',
    'contact' => -only => ['create_form'],
    'location'
);

$m = $r->match(get => 'contact');
is $m, undef;

$m = $r->match(post => 'contact');
is $m, undef;

$m = $r->match(put => 'contact');
is $m, undef;

$m = $r->match(delete => 'contact');
is $m, undef;

$m = $r->match(get => 'contact/edit');
is $m, undef;

$m = $r->match(get => 'contact/new');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'create_form'};



# more than one route
# create and show
$r = Forward::Routes->new;
$r->add_singular_resources(
    'photo',
    'contact' => -only => ['create', 'show'],
    'location'
);

$m = $r->match(get => 'contact');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'show'};

$m = $r->match(post => 'contact');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'create'};

$m = $r->match(put => 'contact');
is $m, undef;

$m = $r->match(delete => 'contact');
is $m, undef;

$m = $r->match(get => 'contact/edit');
is $m, undef;

$m = $r->match(get => 'contact/new');
is $m, undef;
