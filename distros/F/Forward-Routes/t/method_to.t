use strict;
use warnings;
use Test::More tests => 8;
use lib 'lib';
use Forward::Routes;



#############################################################################
### to method

my $r = Forward::Routes->new;

# set
my $route = $r->add_route('articles')->to('Hello#world');
is_deeply $route->{defaults}, {controller => 'Hello', action => 'world'};

# no getter
is $route->to, undef;

# Match->class and Match->action
my $matches = $r->match(get => 'articles');
is $matches->[0]->class, 'Hello';
is $matches->[0]->action, 'world';

# overwrite
$route->to('Country#city');
is_deeply $route->{defaults}, {controller => 'Country', action => 'city'};



#############################################################################
# return value

$r = Forward::Routes->new;
$route = $r->add_route('articles');
my $rv = $route->to('Hello#world');
is $route, $rv;


#############################################################################
### to method - partial

$r = Forward::Routes->new;
$route = $r->add_route('articles')->to('#world');
is_deeply $route->{defaults}, {controller => undef, action => 'world'};

$r = Forward::Routes->new;
$route = $r->add_route('articles')->to('Hello#');
is_deeply $route->{defaults}, {controller => 'Hello', action => undef};
