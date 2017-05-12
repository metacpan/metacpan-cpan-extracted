use strict;
use warnings;
use Test::More tests => 26;
use lib 'lib';
use Forward::Routes;



#############################################################################
### optional placeholders with default values

my $r = Forward::Routes->new;
$r->add_route(':year(/:month)?/:day')->defaults(month => 1)->name('foo');

my $m = $r->match(get => '2009');
ok not defined $m;

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, month => 1, day => 12};

$m = $r->match(get => '2009/2/3');
is_deeply $m->[0]->params => {year => 2009, month => 2, day => 3};

# build path
my $e = eval {$r->build_path('foo', year => 2009)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, month => 2, day => 12)->{path}, '2009/2/12';
is $r->build_path('foo', year => 2009, day => 12)->{path}, '2009/1/12';



$r = Forward::Routes->new;
$r->add_route(':year/(:month)?/:day')->defaults(month => 1)->name('foo');

$m = $r->match(get => '2009');
ok not defined $m;

$m = $r->match(get => '2009//12');
is_deeply $m->[0]->params => {year => 2009, month => 1, day => 12};

$m = $r->match(get => '2009/2/3');
is_deeply $m->[0]->params => {year => 2009, month => 2, day => 3};

# build path
$e = eval {$r->build_path('foo', year => 2009)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('foo')->{path}; };
like $@ => qr/Required param 'year' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, month => 2, day => 12)->{path}, '2009/2/12';
is $r->build_path('foo', year => 2009, day => 12)->{path}, '2009/1/12';



$r = Forward::Routes->new;
$r->add_route('world/(:country)?-(:cities)?')
  ->defaults(country => 'foo', cities => 'baz')->name('hello');

$m = $r->match(get => 'world/us-');
is_deeply $m->[0]->params => {country => 'us', cities => 'baz'};

$m = $r->match(get => 'world/-new_york');
is_deeply $m->[0]->params => {country => 'foo', cities => 'new_york'};

$m = $r->match(get => 'world/us-new_york');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
is $r->build_path('hello', country => 'us', cities => 'new_york')->{path}, 'world/us-new_york';
is $r->build_path('hello', cities => 'new_york')->{path}, 'world/foo-new_york';
is $r->build_path('hello', country => 'us')->{path}, 'world/us-baz';
is $r->build_path('hello')->{path}, 'world/foo-baz';



$r = Forward::Routes->new;
$r->add_route(':year(/:month/:day)?')->defaults(month => 5)->name('foo');

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009, month => 5};

$m = $r->match(get => '2009/12');
ok !defined $m;

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};


# build path
# TO DO: currently day param required because of month default, is this the expected behaviour?
# is $r->build_path('foo', year => 2009)->{path}, '2009';

$e = eval {$r->build_path('foo', year => 2009, month => 12)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';
is $r->build_path('foo', year => 2009, day => 10)->{path}, '2009/5/10';
