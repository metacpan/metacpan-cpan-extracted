use strict;
use warnings;
use Test::More tests => 20;
use lib 'lib';
use Forward::Routes;



#############################################################################
# singular resources with format constraint: as parameter

my $r = Forward::Routes->new;

$r->add_singular_resources(
    'contact' => -format => 'html',
    'location'
);

my $m = $r->match(get => 'contact/new.html');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'create_form', format => 'html'};

$m = $r->match(post => 'contact.html');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'create', format => 'html'};


$m = $r->match(get => 'contact/new');
is $m, undef;

$m = $r->match(post => 'contact');
is $m, undef;



$m = $r->match(get => 'location/new');
is_deeply $m->[0]->params => {controller => 'Location', action => 'create_form'};

$m = $r->match(post => 'location');
is_deeply $m->[0]->params => {controller => 'Location', action => 'create'};


$m = $r->match(get => 'location/new.html');
is $m, undef;

$m = $r->match(post => 'location.html');
is $m, undef;



### emtpy format param, parent has format

$r = Forward::Routes->new->format('html');

$r->add_singular_resources(
    'contact' => -format => '',
    'location'
);

$m = $r->match(get => 'contact/new');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'create_form', format => ''};

$m = $r->match(post => 'contact');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'create', format => ''};


$m = $r->match(get => 'contact/new.html');
is $m, undef;

$m = $r->match(post => 'contact.html');
is $m, undef;


$m = $r->match(get => 'location/new.html');
is_deeply $m->[0]->params => {controller => 'Location', action => 'create_form', format => 'html'};

$m = $r->match(post => 'location.html');
is_deeply $m->[0]->params => {controller => 'Location', action => 'create', format => 'html'};



# should also work with undef
$r = Forward::Routes->new->format('html');

$r->add_singular_resources(
    'contact' => -format => undef,
    'location'
);

$m = $r->match(get => 'contact/new');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'create_form'};

$m = $r->match(post => 'contact');
is_deeply $m->[0]->params => {controller => 'Contact', action => 'create'};


$m = $r->match(get => 'contact/new.html');
is $m, undef;

$m = $r->match(post => 'contact.html');
is $m, undef;


$m = $r->match(get => 'location/new.html');
is_deeply $m->[0]->params => {controller => 'Location', action => 'create_form', format => 'html'};

$m = $r->match(post => 'location.html');
is_deeply $m->[0]->params => {controller => 'Location', action => 'create', format => 'html'};

