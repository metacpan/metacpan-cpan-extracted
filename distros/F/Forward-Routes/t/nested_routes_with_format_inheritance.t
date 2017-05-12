use strict;
use warnings;
use Test::More tests => 93;
use lib 'lib';
use Forward::Routes;


#############################################################################
# base format and empty route

my $r = Forward::Routes->new;
    my $html = $r->add_route->format('html'); # base format
        my $nested = $html->add_route('hello/:id');
            $nested->add_route->name('one'); # emtpy route
            $nested->add_route('foo')->name('two');

my $m = $r->match(get => 'hello/1.html');
is_deeply $m->[0]->params => {id => 1, format => 'html'};
is $m->[0]->name, 'one';

$m = $r->match(get => 'hello/1.xml');
is $m, undef;

$m = $r->match(get => 'hello/1/foo.html');
is_deeply $m->[0]->params => {id => 1, format => 'html'};
is $m->[0]->name, 'two';

$m = $r->match(get => 'hello/1/foo.xml');
is $m, undef;

# build path
is $r->build_path('one', id => 1)->{path}, 'hello/1.html';
is $r->build_path('two', id => 1)->{path}, 'hello/1/foo.html';


#############################################################################
# set format after pattern match

$r = Forward::Routes->new;
$nested = $r->add_route('hello/:id');
    $nested->add_route->format('html')->name('one');
    $nested->add_route->format('xml')->name('two');
    my $name = $nested->add_route(':name');
        $name->add_route->format('html')->name('three');
        $name->add_route->format('xml')->name('four');

$m = $r->match(get => 'hello/1.html');
is_deeply $m->[0]->params => {id => 1, format => 'html'};
is $m->[0]->name, 'one';

$m = $r->match(get => 'hello/1.xml');
is_deeply $m->[0]->params => {id => 1, format => 'xml'};
is $m->[0]->name, 'two';

$m = $r->match(get => 'hello/1');
is $m, undef;

$m = $r->match(get => 'hello/1/foo.html');
is_deeply $m->[0]->params => {id => 1, name => 'foo', format => 'html'};
is $m->[0]->name, 'three';

$m = $r->match(get => 'hello/1/foo.xml');
is_deeply $m->[0]->params => {id => 1, name => 'foo', format => 'xml'};
is $m->[0]->name, 'four';

$m = $r->match(get => 'hello/1/foo');
is $m, undef;

$m = $r->match(get => 'hello/1/foo.jpeg');
is $m, undef;



#############################################################################
# redefine format after pattern match

$r = Forward::Routes->new;
    $html = $r->format('html');
        $nested = $html->add_route('hello/:id'); # pattern
            $nested->add_route->format('jpeg')->name('one');
            $nested->add_route->format('xml')->name('two');
            my $foo = $nested->add_route('/my/:name');
                $foo->add_route->name('three');
                $foo->add_route->format('xml')->name('four');

$m = $r->match(get => 'hello/1.jpeg');
is_deeply $m->[0]->params => {id => '1', format => 'jpeg'};
is $m->[0]->name, 'one';

$m = $r->match(get => 'hello/1');
is $m, undef;

$m = $r->match(get => 'hello/1.xml');
is_deeply $m->[0]->params => {id => '1', format => 'xml'};
is $m->[0]->name, 'two';

$m = $r->match(get => 'hello/1/my/foo.xml');
is_deeply $m->[0]->params => {id => '1', name => 'foo', format => 'xml'};
is $m->[0]->name, 'four';

$m = $r->match(get => 'hello/1/my/foo.html');
is_deeply $m->[0]->params => {id => '1', name => 'foo', format => 'html'};
is $m->[0]->name, 'three';

$m = $r->match(get => 'hello/1/my/foo.jpeg');
is $m, undef;


#############################################################################
# redefine format after pattern match to undef

$r = Forward::Routes->new;
    $html = $r->format('html');
        $nested = $html->add_route('hello/:id');
            $nested->add_route->format('xml')->name('one');
            $nested->add_route->format(undef)->name('two');
            $foo = $nested->add_route('/my/:name');
                $foo->add_route->name('three');
                $foo->add_route->format(undef)->name('four');

$m = $r->match(get => 'hello/1.html');
is_deeply $m->[0]->params => {id => '1.html'};
is $m->[0]->name, 'two';

$m = $r->match(get => 'hello/1.jpeg');
is_deeply $m->[0]->params => {id => '1.jpeg'};
is $m->[0]->name, 'two';

$m = $r->match(get => 'hello/1');
is_deeply $m->[0]->params => {id => '1'};
is $m->[0]->name, 'two';

$m = $r->match(get => 'hello/1.xml');
is_deeply $m->[0]->params => {id => '1', format => 'xml'};
is $m->[0]->name, 'one';


$m = $r->match(get => 'hello/1/my/foo.html');
is_deeply $m->[0]->params => {id => '1', name => 'foo', format => 'html'};
is $m->[0]->name, 'three';

$m = $r->match(get => 'hello/1/my/foo.xml');
is_deeply $m->[0]->params => {id => '1', name => 'foo.xml'};
is $m->[0]->name, 'four';


#############################################################################
# redefine format before pattern match

$r = Forward::Routes->new;
    $html = $r->format('html');
        $nested = $html->add_route('hello/:id');
            my $xml = $nested->add_route->format('xml');
                $xml->add_route('one/:first')->name('one');
            my $jpeg = $nested->add_route->format('jpeg');
                $jpeg->add_route('two/:second')->name('two');
            $nested->add_route('three/:third');

$m = $r->match(get => 'hello/1.html');
is $m, undef;

$m = $r->match(get => 'hello/1.xml');
is $m, undef;

$m = $r->match(get => 'hello/1.jpeg');
is $m, undef;

$m = $r->match(get => 'hello/1');
is $m, undef;



$m = $r->match(get => 'hello/1/one/2.html');
is $m, undef;

$m = $r->match(get => 'hello/1/one/2');
is $m, undef;

$m = $r->match(get => 'hello/1/one/2.xml');
is_deeply $m->[0]->params => {id => '1', first => '2', format => 'xml'};
is $m->[0]->name, 'one';



$m = $r->match(get => 'hello/1/two/2');
is $m, undef;

$m = $r->match(get => 'hello/1/two/2.xml');
is $m, undef;

$m = $r->match(get => 'hello/1/two/2.jpeg');
is_deeply $m->[0]->params => {id => '1', second => '2', format => 'jpeg'};
is $m->[0]->name, 'two';



$m = $r->match(get => 'hello/1/three/2');
is $m, undef;

$m = $r->match(get => 'hello/1/three/2.xml');
is $m, undef;

$m = $r->match(get => 'hello/1/three/2.jpeg');
is $m, undef;

$m = $r->match(get => 'hello/1/three/2.html');
is_deeply $m->[0]->params => {id => '1', third => '2', format => 'html'};


#############################################################################
# redefine format before pattern match -> to undef (TO DO)



#############################################################################
### (re)define pattern and format at same time

$r = Forward::Routes->new;
$html = $r->format('html'); # base format
    $xml = $html->add_route('foo')->format('xml'); # add to pattern and override base format
        $xml->add_route(':name')->name('one');
$html->add_route('baz')->name('two');
$html->add_route('buz')->name('three')->format('jpeg'); # add to pattern and override base format


$m = $r->match(get => 'foo/bar');
is $m, undef;

$m = $r->match(get => 'foo/bar.html');
is $m, undef;

$m = $r->match(get => 'foo/bar.xml');
is_deeply $m->[0]->params => {name => 'bar', format => 'xml'};
is $m->[0]->name, 'one';


$m = $r->match(get => '/baz');
is $m, undef;

$m = $r->match(get => '/baz.xml');
is $m, undef;

$m = $r->match(get => '/baz.html');
is_deeply $m->[0]->params => {format => 'html'};
is $m->[0]->name, 'two';


$m = $r->match(get => '/buz');
is $m, undef;

$m = $r->match(get => '/buz.html');
is $m, undef;

$m = $r->match(get => '/buz.jpeg');
is_deeply $m->[0]->params => {format => 'jpeg'};
is $m->[0]->name, 'three';


# build path
is $r->build_path('one', name => 'bar')->{path}, 'foo/bar.xml';
is $r->build_path('two')->{path}, 'baz.html';
is $r->build_path('three')->{path}, 'buz.jpeg';



#############################################################################
### (re)define pattern and format at same time -> to undef

$r = Forward::Routes->new;
$html = $r->format('html'); # base format
    my $undef = $html->add_route('foo')->format(undef); # add to pattern and override base format
        $undef->add_route(':name')->name('one');
$r->add_route('baz')->name('two');
$r->add_route('buz')->name('three')->format(undef); # add to pattern and override base format


$m = $r->match(get => 'foo/bar');
is_deeply $m->[0]->params => {name => 'bar'};
is $m->[0]->name, 'one';

$m = $r->match(get => 'foo/bar.html');
is_deeply $m->[0]->params => {name => 'bar.html'};
is $m->[0]->name, 'one';


$m = $r->match(get => '/baz');
is $m, undef;

$m = $r->match(get => '/baz.xml');
is $m, undef;

$m = $r->match(get => '/baz.html');
is_deeply $m->[0]->params => {format => 'html'};
is $m->[0]->name, 'two';


$m = $r->match(get => '/buz');
is_deeply $m->[0]->params => {};
is $m->[0]->name, 'three';

$m = $r->match(get => '/buz.html');
is $m, undef;



#############################################################################
### (re)define pattern and format at same time -> to empty

$r = Forward::Routes->new;
$html = $r->format('html'); # base format
    my $empty = $html->add_route('foo')->format(''); # add to pattern and override base format
        $empty->add_route(':name')->name('one');
$html->add_route('baz')->name('two');
$html->add_route('buz')->name('three')->format(''); # add to pattern and override base format


$m = $r->match(get => 'foo/bar');
is_deeply $m->[0]->params => {name => 'bar', format => ''};
is $m->[0]->name, 'one';

$m = $r->match(get => 'foo/bar.html');
is $m, undef;


$m = $r->match(get => '/baz');
is $m, undef;

$m = $r->match(get => '/baz.xml');
is $m, undef;

$m = $r->match(get => '/baz.html');
is_deeply $m->[0]->params => {format => 'html'};
is $m->[0]->name, 'two';


$m = $r->match(get => '/buz');
is_deeply $m->[0]->params => {format => ''};
is $m->[0]->name, 'three';

$m = $r->match(get => '/buz.html');
is $m, undef;

