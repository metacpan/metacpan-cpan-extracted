use strict;
use warnings;
use Test::More tests => 10;
use lib 'lib';
use Forward::Routes;



#############################################################################
### defaults method

my $r = Forward::Routes->new;

# set
my $route = $r->add_route('articles')->defaults(first_name => 'foo', last_name => 'bar');
is_deeply $route->{defaults}, {first_name => 'foo', last_name => 'bar'};

# get
is_deeply $route->defaults, {first_name => 'foo', last_name => 'bar'};

# add
$route->defaults(city => 'ny', country => 'us');
is_deeply $route->{defaults}, {first_name => 'foo', last_name => 'bar', city => 'ny', country => 'us'};

# get
is_deeply $route->defaults, {first_name => 'foo', last_name => 'bar', city => 'ny', country => 'us'};


#############################################################################
# return value

$r = Forward::Routes->new;
$route = $r->add_route('articles');
my $rv = $route->defaults(first_name => 'foo', last_name => 'bar');
is $route, $rv;


#############################################################################
# initialize

$r = Forward::Routes->new;
$route = $r->add_route('articles');
$route->defaults;
my $defaults1 = $route->{defaults};
$route->defaults(first_name => 'foo', last_name => 'bar');
my $defaults2 = $route->{defaults};
is $defaults1, $defaults2;


#############################################################################
### defaults method - hash format

$r = Forward::Routes->new;

# set
$route = $r->add_route('articles')->defaults({first_name => 'foo', last_name => 'bar'});
is_deeply $route->{defaults}, {first_name => 'foo', last_name => 'bar'};

# get
is_deeply $route->defaults, {first_name => 'foo', last_name => 'bar'};

# add
$route->defaults({city => 'ny', country => 'us'});
is_deeply $route->{defaults}, {first_name => 'foo', last_name => 'bar', city => 'ny', country => 'us'};

# get
is_deeply $route->defaults, {first_name => 'foo', last_name => 'bar', city => 'ny', country => 'us'};



