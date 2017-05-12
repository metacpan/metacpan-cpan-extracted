use strict;
use warnings;
use Test::More tests => 55;
use lib 'lib';
use Forward::Routes;



#############################################################################
### format

### no format constraint, but format passed
my $r = Forward::Routes->new;
$r->add_route('foo')->name('one');
$r->add_route(':foo/:bar')->name('two');

my $m = $r->match(get => 'foo.html');
is $m, undef;

$m = $r->match(get => 'hello/there.html');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there.html'};

is eval {$r->build_path('one', format => 'html')}, undef;
like $@, qr/Invalid format 'html' used to build a path/;
is eval {$r->build_path('two', foo => 'hello', bar => 'there', format => 'html')}, undef;
like $@, qr/Invalid format 'html' used to build a path/;


### format constraint
$r = Forward::Routes->new;
$r->add_route('foo')->name('one')->format('html');
$r->add_route(':foo/:bar')->name('two')->format('html');

$m = $r->match(get => 'foo.html');
is_deeply $m->[0]->params => {format => 'html'};

$m = $r->match(get => 'hello/there.html');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there', format => 'html'};

# match again (params empty again)
$m = $r->match(get => 'foo.html');
is_deeply $m->[0]->params => {format => 'html'};

# now paths without format
$m = $r->match(get => 'foo');
is $m, undef;

$m = $r->match(get => 'hello/there');
is $m, undef;

# now paths with wrong format
$m = $r->match(get => 'foo.xml');
is $m, undef;

$m = $r->match(get => 'hello/there.xml');
is $m, undef;


# build path
is $r->build_path('one')->{path}, 'foo.html';
is $r->build_path('two', foo => 1, bar => 2)->{path}, '1/2.html';
is $r->build_path('two', foo => 0, bar => 2)->{path}, '0/2.html';



### pass empty format explicitly
$r = Forward::Routes->new;
$r->add_route('foo')->name('one')->format('');
$r->add_route(':foo/:bar')->name('two')->format('');

$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {format => ''};

$m = $r->match(get => 'hello/there');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there', format => ''};

# match again (params empty again)
$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {format => ''};


# now paths with format
$m = $r->match(get => 'foo.html');
is $m, undef;

$m = $r->match(get => 'hello/there.html');
is $m, undef;


# build path
is $r->build_path('one')->{path}, 'foo';
is $r->build_path('two', foo => 1, bar => 2)->{path}, '1/2';



### pass undef format (no contraint validation)
$r = Forward::Routes->new;
$r->add_route('foo')->name('one')->format(undef);
$r->add_route(':foo/:bar')->name('two')->format(undef);

$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {};

$m = $r->match(get => 'hello/there');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there'};

# now paths with format
$m = $r->match(get => 'foo.html');
is $m, undef;

$m = $r->match(get => 'hello/there.html');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there.html'};


# build path
is $r->build_path('one')->{path}, 'foo';
is $r->build_path('two', foo => 1, bar => 2)->{path}, '1/2';



### multiple format constraints
$r = Forward::Routes->new;
$r->add_route('foo')->name('one')->format('html','xml');
$r->add_route(':foo/:bar')->name('two')->format('html','xml');

$m = $r->match(get => 'foo.html');
is_deeply $m->[0]->params => {format => 'html'};

$m = $r->match(get => 'hello/there.html');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there', format => 'html'};

$m = $r->match(get => 'foo.xml');
is_deeply $m->[0]->params => {format => 'xml'};

$m = $r->match(get => 'hello/there.xml');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there', format => 'xml'};

# match again (params empty again)
$m = $r->match(get => 'foo.xml');
is_deeply $m->[0]->params => {format => 'xml'};

# now paths without format
$m = $r->match(get => 'foo');
is $m, undef;

$m = $r->match(get => 'hello/there');
is $m, undef;

# now paths with wrong format
$m = $r->match(get => 'foo.jpeg');
is $m, undef;

$m = $r->match(get => 'hello/there.jpeg');
is $m, undef;


# build path
is $r->build_path('one')->{path}, 'foo.html';
is $r->build_path('two', foo => 1, bar => 2)->{path}, '1/2.html';

# build path with format => xml
is $r->build_path('one', format => 'xml')->{path}, 'foo.xml';
is $r->build_path('two', foo => 1, bar => 2, format => 'xml')->{path}, '1/2.xml';

# build path with invalid format => jpeg
is eval{$r->build_path('one', format => 'jpeg')}, undef;
like $@, qr/Invalid format 'jpeg' used to build a path/;
is eval{$r->build_path('two', foo => 1, bar => 2, format => 'jpeg')}, undef;
like $@, qr/Invalid format 'jpeg' used to build a path/;



### multiple format constraints, with empty format allowed
$r = Forward::Routes->new;
$r->add_route('foo')->name('one')->format('html','');
$r->add_route(':foo/:bar')->name('two')->format('html','');

$m = $r->match(get => 'foo.html');
is_deeply $m->[0]->params => {format => 'html'};

$m = $r->match(get => 'hello/there.html');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there', format => 'html'};

$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {format => ''};

$m = $r->match(get => 'hello/there');
is_deeply $m->[0]->params => {foo => 'hello', bar => 'there', format => ''};

# match again (params empty again)
$m = $r->match(get => 'foo');
is_deeply $m->[0]->params => {format => ''};

# now paths with wrong format
$m = $r->match(get => 'foo.jpeg');
is $m, undef;

$m = $r->match(get => 'hello/there.jpeg');
is $m, undef;


# build path
is $r->build_path('one')->{path}, 'foo.html';
is $r->build_path('two', foo => 1, bar => 2)->{path}, '1/2.html';
