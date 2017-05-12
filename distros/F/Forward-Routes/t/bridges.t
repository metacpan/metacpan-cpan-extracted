use strict;
use warnings;
use Test::More tests => 23;
use lib 'lib';
use Forward::Routes;



#############################################################################
### bridges

my $r = Forward::Routes->new;
my $bridge = $r->bridge('admin')->to('check#authentication');
$bridge->add_route('foo')->to('no#placeholders')->name('foo');
$bridge->add_route(':foo/:bar')->to('two#placeholders')->name('foo_bar');

my $m = $r->match(get => 'foo');
is $m, undef;

$m = $r->match(get => 'admin/foo');

is $m->[0]->is_bridge, 1;
is $m->[1]->is_bridge, undef;

is_deeply $m->[0]->params, {controller => 'check', action => 'authentication'};
is_deeply $m->[1]->params, {controller => 'no', action => 'placeholders'};




$m = $r->match(get => '/hello/there');
is $m, undef;

$m = $r->match(get => '/admin/hello/there');

is $m->[0]->is_bridge, 1;
is $m->[1]->is_bridge, undef;

is_deeply $m->[0]->params, {controller => 'check', action => 'authentication',
  foo => 'hello', bar => 'there'};
is_deeply $m->[1]->params, {controller => 'two', action => 'placeholders',
  foo => 'hello', bar => 'there'};

is_deeply $m->[0]->captures, {foo => 'hello', bar => 'there'};
is_deeply $m->[1]->captures, {foo => 'hello', bar => 'there'};

is $m->[0]->name, 'foo_bar';
is $m->[1]->name, 'foo_bar';


#############################################################################
# make sure that defaults and captures are available in all match objects
# except controller and action defaults which are set individually

$r = Forward::Routes->new;
my $first = $r->add_route('/first/:first')->name('one')->defaults(a => 1);
my $second = $first->bridge('/second/:second')->name('two')->defaults(b => 2)->to('Authentication#validate1');
my $third = $second->add_route('/third/:third')->name('three')->defaults(c => 3);
my $fourth = $third->bridge('/fourth/:fourth')->name('four')->defaults(d => 4)->to('Authorization#validate2');
$fourth->add_route('final')->defaults(e => 5)->to('Foo#bar');

$m = $r->match(get => '/first/1/second/2/third/3/fourth/4/final');

is_deeply $m->[0]->is_bridge, 1;
is_deeply $m->[1]->is_bridge, 1;
is_deeply $m->[2]->is_bridge, undef;

is_deeply $m->[0]->captures, {first => 1, second => 2, third => 3, fourth => 4};
is_deeply $m->[1]->captures, {first => 1, second => 2, third => 3, fourth => 4};
is_deeply $m->[2]->captures, {first => 1, second => 2, third => 3, fourth => 4};

is_deeply $m->[0]->params, {controller => 'Authentication', action => 'validate1', first => 1, second => 2, third => 3, fourth => 4, a => 1, b => 2, c => 3, d => 4, e =>5};
is_deeply $m->[1]->params, {controller => 'Authorization',  action => 'validate2', first => 1, second => 2, third => 3, fourth => 4, a => 1, b => 2, c => 3, d => 4, e =>5};
is_deeply $m->[2]->params, {controller => 'Foo',            action => 'bar',       first => 1, second => 2, third => 3, fourth => 4, a => 1, b => 2, c => 3, d => 4, e =>5};
