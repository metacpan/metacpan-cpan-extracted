use strict;
use warnings;
use Test::More tests => 173;
use lib 'lib';
use Forward::Routes;



#############################################################################
### empty

my $r = Forward::Routes->new;
ok $r;
ok $r->isa('Forward::Routes');


#############################################################################
### add_route

$r = Forward::Routes->new;
$r = $r->add_route('foo');
is ref $r, 'Forward::Routes';


#############################################################################
### initialize

$r = Forward::Routes->new;

is $r->{method}, undef;
is $r->{defaults}, undef;
is $r->{name}, undef;
is $r->{to}, undef;
is $r->{pattern}, undef;


#############################################################################
### match
$r = Forward::Routes->new;
$r->add_route('foo');

my $m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {};

# match again (params empty again)
$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {};


#############################################################################
### match_root

$r = Forward::Routes->new(defaults => {foo => 1});
$m = $r->match(get => 'hello');
ok not defined $m;


#############################################################################
### match_nested_routes
$r = Forward::Routes->new;
my $pattern = $r->add_route('foo');
$pattern->add_route('bar');

$pattern = $r->add_route(':foo');
$pattern->add_route(':bar');

$m = $r->match(get => 'foo/bar');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'hello/there');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there'};

$m = $r->match(get => 'foo/bar/baz');
is $m, undef;

$m = $r->match(get => 'foo');
is $m, undef;

# match again (params empty again)
$m = $r->match(get => 'foo/bar');
is_deeply $m->[0]->params => {};


#############################################################################
### match_with_to_defaults
$r = Forward::Routes->new;
$r->add_route('articles')->to('foo#bar');
$r->add_route(':controller/:action')->to('foo#bar');

$m = $r->match(get => 'articles');
is_deeply $m->[0]->params => {controller => 'foo', action => 'bar'};

# overwrite defaults
$m = $r->match(get => 'foo/baz');
is_deeply $m->[0]->params => {controller => 'foo', action => 'baz'};

$m = $r->match(get => 'hello/baz');
is_deeply $m->[0]->params => {controller => 'hello', action => 'baz'};


#############################################################################
### match_with_grouping

$r = Forward::Routes->new;
$r->add_route('world/(:country)-(((:cities)))')->name('foo');

$m = $r->match(get => 'world/us-');
is $m, undef;

$m = $r->match(get => 'world/-new_york');
is $m, undef;

$m = $r->match(get => 'world/us-new_york');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
my $e = eval {$r->build_path('foo')->{path}; };
like $@ => qr/Required param 'country' was not passed when building a path/;

$e = eval {$r->build_path('foo', country => 'us')->{path}; };
like $@ => qr/Required param 'cities' was not passed when building a path/;

$e = eval {$r->build_path('foo', cities => 'new_york')->{path}; };
like $@ => qr/Required param 'country' was not passed when building a path/;

is $r->build_path('foo', country => 'us', cities => 'new_york')->{path}, 'world/us-new_york';



$r = Forward::Routes->new;
$r->add_route('world/((((((((:country)))-(((:cities)))-(:street))))))')->name('foo');

$m = $r->match(get => 'world/us-new_york');
is $m, undef;

$m = $r->match(get => 'world/us-new_york-');
is $m, undef;

$m = $r->match(get => 'world/us-new_york-52_str');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york', street => '52_str'};

$e = eval {$r->build_path('foo', country => 'us', cities => 'new_york')->{path}; };
like $@ => qr/Required param 'street' was not passed when building a path/;

$e = eval {$r->build_path('foo', country => 'us', street => '52_str')->{path}; };
like $@ => qr/Required param 'cities' was not passed when building a path/;

$e = eval {$r->build_path('foo', cities => 'new_york', street => 'baker_str')->{path}; };
like $@ => qr/Required param 'country' was not passed when building a path/;

is $r->build_path('foo', country => 'us', cities => 'new_york', street => '52_str')->{path}, 'world/us-new_york-52_str';


#############################################################################
### match_with_grouping_and_defaults

$r = Forward::Routes->new;
$r->add_route('world/(:country)-(:cities)')
  ->defaults(country => 'foo', cities => 'baz')->name('hello');

$m = $r->match(get => 'world/');
is $m, undef;

$m = $r->match(get => 'world/us-');
is $m, undef;

$m = $r->match(get => 'world/-new_york');
is $m, undef;

$m = $r->match(get => 'world/us-new_york');
is_deeply $m->[0]->params => {country => 'us', cities => 'new_york'};

# build path
is $r->build_path('hello', country => 'us', cities => 'new_york')->{path}, 'world/us-new_york';
is $r->build_path('hello', cities => 'new_york')->{path}, 'world/foo-new_york';
is $r->build_path('hello', country => 'us')->{path}, 'world/us-baz';




#############################################################################
### match_with_nestedoptional

$r = Forward::Routes->new;
$r->add_route(':year(/:month(/:day)?)?')->name('foo');

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, month => 12};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
is $r->build_path('foo', year => 2009)->{path}, '2009';
is $r->build_path('foo', year => 2009, month => 12)->{path}, '2009/12';
is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';

$e = eval {$r->build_path('foo', year => 2009, day => 12)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;

$e = eval {$r->build_path('foo')->{path}; };
like $@ => qr/Required param 'year' was not passed when building a path/;



$r = Forward::Routes->new;
$r->add_route(':year(/:month(/:day)?)?-text')->name('foo');

$m = $r->match(get => '2009-text');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => '2009/12-text');
is_deeply $m->[0]->params => {year => 2009, month => 12};

$m = $r->match(get => '2009/12/10-text');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
is $r->build_path('foo', year => 2009)->{path}, '2009-text';
is $r->build_path('foo', year => 2009, month => 12)->{path}, '2009/12-text';
is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10-text';

$e = eval {$r->build_path('foo', year => 2009, day => 12)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;

$e = eval {$r->build_path('foo')->{path}; };
like $@ => qr/Required param 'year' was not passed when building a path/;



$r = Forward::Routes->new;
$r->add_route(':year((/:month)?/:day)?')->name('foo');

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, day => 12};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
is $r->build_path('foo', year => 2009)->{path}, '2009';
is $r->build_path('foo', year => 2009, day => 12)->{path}, '2009/12';
is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';

$e = eval {$r->build_path('foo', year => 2009, month => 3)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;



# more complex test 3 levels and text surrounding placeholders
$r = Forward::Routes->new;
$r->add_route('year(:year)(/month(:month)-monthend(/day(:day)(hour-(:hour)-hourend)?-dayend)?)?-text')->name('foo');

$m = $r->match(get => 'year2009-text');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => 'year2009/month11-monthend-text');
is_deeply $m->[0]->params => {year => 2009, month => 11};

$m = $r->match(get => 'year2009/month11-monthend/day3-text');
is $m, undef;

$m = $r->match(get => 'year2009/month11-monthend/day3-dayend-text');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3};

$m = $r->match(get => 'year2009/month11-monthend/day3hour-5-dayend-text');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => "3hour-5"};

#$m = $r->match(get => 'year2009/month11-monthend/day3hour-5-hourend-dayend-text');
#is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3};

# build path
is $r->build_path('foo', year => 2009)->{path}, 'year2009-text';
is $r->build_path('foo', year => 2009, month => 11)->{path}, 'year2009/month11-monthend-text';
is $r->build_path('foo', year => 2009, month => 11, day => 3)->{path}, 'year2009/month11-monthend/day3-dayend-text';



# same test, but hour not optional
$r = Forward::Routes->new;
$r->add_route('year(:year)(/month(:month)-monthend(/day(:day)(hour-(:hour)-hourend)-dayend)?)?-text')->name('foo');

$m = $r->match(get => 'year2009-text');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => 'year2009/month11-monthend-text');
is_deeply $m->[0]->params => {year => 2009, month => 11};

$m = $r->match(get => 'year2009/month11-monthend/day3-text');
is $m, undef;

$m = $r->match(get => 'year2009/month11-monthend/day3-dayend-text');
is $m, undef;

$m = $r->match(get => 'year2009/month11-monthend/day3hour-5-hourend-dayend-text');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3, hour => 5};

$m = $r->match(get => 'year2009/month11-monthend/day3hour-5--dayend-text');
is $m, undef;

# build path
is $r->build_path('foo', year => 2009)->{path}, 'year2009-text';
is $r->build_path('foo', year => 2009, month => 11)->{path}, 'year2009/month11-monthend-text';
is $r->build_path('foo', year => 2009, month => 11, day => 3, hour => 5)->{path}, 'year2009/month11-monthend/day3hour-5-hourend-dayend-text';

$e = eval {$r->build_path('foo', year => 2009, month => 3, day => 2)->{path}; };
like $@ => qr/Required param 'hour' was not passed when building a path/;

$e = eval {$r->build_path('foo', year => 2009, month => 3, hour => 2)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;



# same test, but hour is nested
$r = Forward::Routes->new;
$r->add_route('year(:year)(/month(:month)m(/day(:day)d(((((/hours-(:hours)h-minutes-(:minutes)m-seconds(:seconds)s)?)?)?)))?)?-location(-country-(:country)(/city-(:city)(/street-(:street))?)?)?')->name('foo');

$m = $r->match(get => 'year2009-location');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => 'year2009/month11m-location');
is_deeply $m->[0]->params => {year => 2009, month => 11};

$m = $r->match(get => 'year2009/month11m/day3-location');
is $m, undef;

$m = $r->match(get => 'year2009/month11m/day3d-location');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3};

$m = $r->match(get => 'year2009/month11m/day3d-location-country-france');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3, country => 'france'};

$m = $r->match(get => 'year2009/month11m/day3d-location-country-france/city-paris');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3, country => 'france', city => 'paris'};

$m = $r->match(get => 'year2009/month11m/day3d-location-country-france/city-paris/street-test');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3, country => 'france', city => 'paris', street => 'test'};

$m = $r->match(get => 'year2009/month11m/day3d/hours-5h-minutes-27m-seconds33s-location-country-france/city-paris/street-test');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3, hours => 5, minutes => 27, seconds => 33, country => 'france', city => 'paris', street => 'test'};

$m = $r->match(get => 'year2009/month11m/day3d/hours-5h-minutes-27m-seconds33s-location');
is_deeply $m->[0]->params => {year => 2009, month => 11, day => 3, hours => 5, minutes => 27, seconds => 33};

$m = $r->match(get => 'year2009/month11m/day3d/hours-5h-location');
is $m, undef;

$m = $r->match(get => 'year2009/month11m/day3d/minutes-27m-seconds33s-location');
is $m, undef;

# build path
is $r->build_path('foo', year => 2009)->{path}, 'year2009-location';
is $r->build_path('foo', year => 2009, month => 11)->{path}, 'year2009/month11m-location';
is $r->build_path('foo', year => 2009, month => 11, day => 3)->{path}, 'year2009/month11m/day3d-location';
is $r->build_path('foo', year => 2009, month => 11, day => 3, hours => 5, minutes => 27, seconds => 33)->{path}, 'year2009/month11m/day3d/hours-5h-minutes-27m-seconds33s-location';

$e = eval {$r->build_path('foo', year => 2009, month => 11, day => 3, hours => 5, minutes => 27)->{path}; };
like $@ => qr/Required param 'seconds' was not passed when building a path/;

$e = eval {$r->build_path('foo', year => 2009, month => 11, day => 3, minutes => 27, seconds => 33)->{path}; };
like $@ => qr/Required param 'hours' was not passed when building a path/;

is $r->build_path('foo', year => 2009, month => 11, day => 3, country => 'france', city => 'paris', street => 'test')->{path}, 'year2009/month11m/day3d-location-country-france/city-paris/street-test';
is $r->build_path('foo', year => 2009, month => 11, day => 3, hours => 5, minutes => 27, seconds => 33, country => 'france', city => 'paris', street => 'test')->{path}, 'year2009/month11m/day3d/hours-5h-minutes-27m-seconds33s-location-country-france/city-paris/street-test';

$e = eval {$r->build_path('foo', year => 2009, month => 11, day => 3, hours => 5, seconds => 33, country => 'france', city => 'paris', street => 'test')->{path}; };
like $@ => qr/Required param 'minutes' was not passed when building a path/;


#############################################################################
### match_with_nestedoptional_and_grouping

$r = Forward::Routes->new;
$r->add_route(':year(/:month/((((:day)))))?')->name('foo');

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009};

$m = $r->match(get => '2009/12');
is $m, undef;

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
is $r->build_path('foo', year => 2009)->{path}, '2009';
is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';

$e = eval {$r->build_path('foo', year => 2009, month => 12)->{path}; };
like $@ => qr/Required param 'day' was not passed when building a path/;


#############################################################################
### match_with_nestedoptional_and_defaults

$r = Forward::Routes->new;
$r->add_route(':year(/:month(/:day)?)?')->name('foo')->defaults(month => 1);

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009, month => 1};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, month => 12};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
is $r->build_path('foo', year => 2009, month => 1)->{path}, '2009/1';
is $r->build_path('foo', year => 2009)->{path}, '2009/1';
is $r->build_path('foo', year => 2009, month => 12)->{path}, '2009/12';
is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';
is $r->build_path('foo', year => 2009, day => 10)->{path}, '2009/1/10';



$r = Forward::Routes->new;
$r->add_route(':year(/:month(/:day)?)?')->name('foo')->defaults(day => 2);

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009, day => 2};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 2};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
$e = eval {$r->build_path('foo', year => 2009, day => 2)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;

$e = eval {$r->build_path('foo', year => 2009)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;

is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';
is $r->build_path('foo', year => 2009, month => 12)->{path}, '2009/12/2';



# same test, but optional surrounded by grouping plus some more optional grouping
$r = Forward::Routes->new;
$r->add_route(':year(/:month(((((((/:day)?)))?)?)))?')->name('foo')->defaults(day => 2);
# same as $r->add_route(':year(/:month(/:day)?)?')->name('foo')->defaults(day => 2);

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009, day => 2};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 2};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path

$e = eval {$r->build_path('foo', year => 2009, day => 2)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;

$e = eval {$r->build_path('foo', year => 2009)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;

is $r->build_path('foo', year => 2009, month => 12, day => 10)->{path}, '2009/12/10';
is $r->build_path('foo', year => 2009, month => 12)->{path}, '2009/12/2';



$r = Forward::Routes->new;
$r->add_route(':year(/:month(/:day))?')->defaults(day => 2)->name('foo');

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009, day => 2};

$m = $r->match(get => '2009/12');
is $m, undef;

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};

# build path
$e = eval {$r->build_path('foo')->{path}; };
like $@ => qr/Required param 'year' was not passed when building a path/;

$e = eval {$r->build_path('foo', year => 2009)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;

$e = eval {$r->build_path('foo', year => 2009, day => 1)->{path}; };
like $@ => qr/Required param 'month' was not passed when building a path/;

is $r->build_path('foo', year => 2009, month => 1)->{path}, '2009/1/2';
is $r->build_path('foo', year => 2009, month => 1, day => 3)->{path}, '2009/1/3';



$r = Forward::Routes->new;
$r->add_route(':year((/:month)?/:day)?')->defaults(month => 1);

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009, month => 1};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, month => 1, day => 12};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};



$r = Forward::Routes->new;
$r->add_route(':year((/:month)?/:day)?')->defaults(day => 2);

$m = $r->match(get => '2009');
is_deeply $m->[0]->params => {year => 2009, day => 2};

$m = $r->match(get => '2009/12');
is_deeply $m->[0]->params => {year => 2009, day => 12};

$m = $r->match(get => '2009/12/10');
is_deeply $m->[0]->params => {year => 2009, month => 12, day => 10};


#############################################################################
### globbing

$r = Forward::Routes->new;
$r->add_route('photos/*other');
$r->add_route('books/*section/:title');
$r->add_route('*a/foo/*b');

$m = $r->match(get => 'photos/foo/bar/baz');
is_deeply $m->[0]->params => {other => 'foo/bar/baz'};

$m = $r->match(get => 'books/some/section/last-words-a-memoir');
is_deeply $m->[0]->params =>
  {section => 'some/section', title => 'last-words-a-memoir'};

$m = $r->match(get => 'zoo/woo/foo/bar/baz');
is_deeply $m->[0]->params => {a => 'zoo/woo', b => 'bar/baz'};



#############################################################################
### via (no chaining)

$r = Forward::Routes->new;
$r->add_route('logout', via => 'put');

ok $r->match(put => 'logout');
ok !$r->match(post => 'logout');


#############################################################################
### chained

# Simple
$r = Forward::Routes->new;

my $articles = $r->add_route('articles/:id')
  ->defaults(first_name => 'foo', last_name => 'bar')
  ->constraints(id => qr/\d+/)
  ->name('hot')
  ->to('hello#world')
  ->via('get','post');

is ref $articles, 'Forward::Routes';

$m = $r->match(post => 'articles/123');
is_deeply $m->[0]->params => {first_name => 'foo', last_name => 'bar', id => 123,
  controller => 'hello', action => 'world'};
is $r->build_path('hot', id => 234)->{path}, 'articles/234';

$m = $r->match(get => 'articles/abc');
ok not defined $m;

$m = $r->match(put => 'articles/123');
ok not defined $m;


# Passing hash and array refs (using method instead of via)
$r = Forward::Routes->new;

$articles = $r->add_route('articles/:id')
  ->defaults({first_name => 'foo', last_name => 'bar'})
  ->constraints({id => qr/\d+/})
  ->via(['get','post']);

is ref $articles, 'Forward::Routes';

$m = $r->match(post => 'articles/123');
is_deeply $m->[0]->params => {first_name => 'foo', last_name => 'bar', id => 123};

$m = $r->match(get => 'articles/abc');
ok not defined $m;

$m = $r->match(put => 'articles/123');
ok not defined $m;



#############################################################################
### index_routes_by_name

$r = Forward::Routes->new;
$r->add_resources('photos');

is $r->find_route('photos_foo'), undef;
is $r->routes_by_name->{photos_foo}, undef;

is $r->routes_by_name->{photos_index}, undef;
is $r->find_route('photos_index')->name, 'photos_index';
is $r->routes_by_name->{photos_index}->name, 'photos_index';



#############################################################################
### build_path

$r = Forward::Routes->new;
$r->add_route('foo',       name => 'one');
$r->add_route(':foo/:bar', name => 'two');
$r->add_route('photos/*other',                   name => 'glob1');
$r->add_route('books/*section/:title',           name => 'glob2');
$r->add_route('*a/foo/*b',                       name => 'glob3');
$r->add_route('archive/:year(/:month(/:day)?)?', name => 'optional2');


$e = eval {$r->build_path('unknown')->{path}; };
like $@ => qr/Unknown name 'unknown' used to build a path/;

$e = eval {$r->build_path('glob2')->{path}; };
like $@ =>
  qr/Required glob param 'section' was not passed when building a path/;

is $r->build_path('one')->{path} => 'foo';
is $r->build_path('two', foo => 'foo', bar => 'bar')->{path} => 'foo/bar';
is $r->build_path('glob1', other => 'foo/bar/baz')->{path} =>
  'photos/foo/bar/baz';
is $r->build_path(
    'glob2',
    section => 'fiction/fantasy',
    title   => 'hello'
)->{path} => 'books/fiction/fantasy/hello';
is $r->build_path('glob3', a => 'foo/bar', b => 'baz/zab')->{path} =>
  'foo/bar/foo/baz/zab';

is $r->build_path('optional2', year => 2010)->{path} => 'archive/2010';
is $r->build_path('optional2', year => 2010, month => 3)->{path} =>
  'archive/2010/3';
is $r->build_path('optional2', year => 2010, month => 3, day => 4)->{path} =>
  'archive/2010/3/4';


1;
