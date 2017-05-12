use strict;
use warnings;
use Test::More tests => 67;
use lib 'lib';
use Forward::Routes;



#############################################################################
### one placeholder marked as optional, excluding slash (just the placeholder
### is optional)

my $r = Forward::Routes->new;
$r->add_route(':year/(:month)?/:day')->name('foo');

my $m = $r->match(get => '2009/12');
is $m, undef;

$m = $r->match(get => '2009/12/2');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 2};

$m = $r->match(get => '2009//2');
is_deeply $m->[0]->params => {year => 2009, day => 2};

# build path
my $e = eval{$r->build_path('foo', year => 2009, month => 12)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, month => 12, day => 2)->{path}, '2009/12/2';

is $r->build_path('foo', year => 2009, day => 2)->{path}, '2009//2';



#############################################################################
### one placeholder with slash marked as optional

$r = Forward::Routes->new;
$r->add_route(':year(/:month)?/:day')->name('foo');

$m = $r->match(get => '2009');
is $m, undef;

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, day => 12};

$m = $r->match(get => '2009/12/2');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 2};

# build path
$e = eval {$r->build_path('foo', year => 2009)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, day => 12)->{path}, '2009/12';

is $r->build_path('foo', year => 2009, month => 12, day => 2)->{path}, '2009/12/2';


#############################################################################
### empty value -> same behavior as undef

$r = Forward::Routes->new;
$r->add_route(':year(/:month)?/:day')->name('foo');

$m = $r->match(get => '2009//2');
is $m, undef;

is $r->build_path('foo', year => 2009, month => '', day => 12)->{path}, '2009/12';


#############################################################################
### multiple placeholders with slashes marked as optional at once

$r = Forward::Routes->new;

$r->add_route(':year(/:month/:day)?')->name('foo');

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => '2009/12');
ok !defined $m;

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};


# build path
is $r->build_path('foo', year => 2009)->{path}, '2009';

$e = eval {$r->build_path('foo', year => 2009, month => 12)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;
undef $e;

is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';



#############################################################################
### placeholder marked as optional, with preceding text

$r = Forward::Routes->new;
$r->add_route(':year/month(:month)?/:day')->name('foo');

$m = $r->match(get => '2009/12/2');
is $m, undef;

$m = $r->match(get => '2009//2');
is $m, undef;

$m = $r->match(get => '2009/month/2');
is_deeply $m->[0]->params => {year => 2009, day => 2};

$m = $r->match(get => '2009/month08/2');
is_deeply $m->[0]->params => {year => 2009, month => '08', day => 2};

# build path
is $r->build_path('foo', year => 2009, month => 12, day => 2)->{path}, '2009/month12/2';

is $r->build_path('foo', year => 2009, day => 2)->{path}, '2009/month/2';

is $r->build_path('foo', year => 2009, month => '08', day => 2)->{path}, '2009/month08/2';


#############################################################################
### placeholder and hyphen marked as optional, with preceding text

$r = Forward::Routes->new;
$r->add_route('/hello/world(-:city)?')->name('foo');

$m = $r->match(get => 'hello/world');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'hello/world-paris');
is_deeply $m->[0]->params => {city => 'paris'};

# build path
is $r->build_path('foo')->{path}, 'hello/world';

is $r->build_path('foo', city => "berlin")->{path}, 'hello/world-berlin';


#############################################################################
### grouped placeholder and hyphen marked as optional, with preceding text

$r = Forward::Routes->new;
$r->add_route('/hello/world(-(:city))?')->name('foo');

$m = $r->match(get => 'hello/world');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'hello/world-paris');
is_deeply $m->[0]->params => {city => 'paris'};

# build path
is $r->build_path('foo')->{path}, 'hello/world';

is $r->build_path('foo', city => "berlin")->{path}, 'hello/world-berlin';


#############################################################################
### multiple grouped placeholders and text (hyphen) marked as optional
### (two captures in one optional group, no defaults)

$r = Forward::Routes->new;
$r->add_route('world/((((:country)))-(:cities))?')->name('hello');

$m = $r->match(get => 'world/');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'world/us-');
ok not defined $m;

$m = $r->match(get => 'world/-new_york');
ok not defined $m;

$m = $r->match(get => 'world/us-new_york');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
is $r->build_path('hello')->{path}, 'world/';

$e = eval {$r->build_path('hello', country => 'us')->{path}; };
like $@ => qr/Required param 'cities' was not passed when building a path/;
undef $e;

$e = eval {$r->build_path('hello', cities => 'new_york')->{path}; };
like $@ => qr/Required param 'country' was not passed when building a path/;
undef $e;

is $r->build_path('hello', country => 'us', cities => 'new_york')->{path}, 'world/us-new_york';


#############################################################################
### grouped text between optional placeholders
$r = Forward::Routes->new;
$r->add_route('world/(:country)?(-and-)(:cities)?')->name('hello');

$m = $r->match(get => 'world/-and-');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'world/us-and-');
is_deeply $m->[0]->params => {country => 'us'};

$m = $r->match(get => 'world/-and-new_york');
is_deeply $m->[0]->params => {cities => 'new_york'};

$m = $r->match(get => 'world/us-and-new_york');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
is $r->build_path('hello', country => 'us')->{path}, 'world/us-and-';

is $r->build_path('hello', cities => 'new_york')->{path}, 'world/-and-new_york';

is $r->build_path('hello', country => 'us', cities => 'new_york')->{path}, 'world/us-and-new_york';

is $r->build_path('hello')->{path}, 'world/-and-';


#############################################################################
### ungrouped text after optional placeholders

$r = Forward::Routes->new;
$r->add_route('world/(:country)?(-and-)(:cities)?-text')->name('hello');

$m = $r->match(get => 'world/-and--text');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'world/us-and--text');
is_deeply $m->[0]->params => {country => 'us'};

$m = $r->match(get => 'world/-and-new_york-text');
is_deeply $m->[0]->params => {cities => 'new_york'};

$m = $r->match(get => 'world/us-and-new_york-text');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
is $r->build_path('hello')->{path}, 'world/-and--text';

is $r->build_path('hello', country => 'us')->{path}, 'world/us-and--text';

is $r->build_path('hello', cities => 'new_york')->{path}, 'world/-and-new_york-text';

is $r->build_path('hello', country => 'us', cities => 'new_york')->{path}, 'world/us-and-new_york-text';


#############################################################################
### multiple placeholders within slashes marked as optional

$r = Forward::Routes->new;
$r->add_route('world/(:country)?-(:cities)?')->name('hello');

$m = $r->match(get => 'world/-');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'world/us-');
is_deeply $m->[0]->params => {country => 'us'};

$m = $r->match(get => 'world/-new_york');
is_deeply $m->[0]->params => {cities => 'new_york'};

$m = $r->match(get => 'world/us-new_york');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
is $r->build_path('hello')->{path}, 'world/-';

is $r->build_path('hello', country => 'us')->{path}, 'world/us-';

is $r->build_path('hello', cities => 'new_york')->{path}, 'world/-new_york';

is $r->build_path('hello', country => 'us', cities => 'new_york')->{path}, 'world/us-new_york';

