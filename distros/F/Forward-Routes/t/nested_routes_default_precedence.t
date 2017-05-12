use strict;
use warnings;
use Test::More tests => 4;
use lib 'lib';
use Forward::Routes;



#############################################################################
### nested routes defaults precedence

# captures have precedence over defaults
my $r = Forward::Routes->new;
my $nested = $r->add_route(':author')->defaults(author => 'foo');
$nested->add_route(':articles')->defaults(articles => 'bar');

my $m = $r->match(get => 'hello/world');
is_deeply $m->[0]->params => {author => 'hello', articles => 'world'};



# default has precedence over capture in parent route
$r = Forward::Routes->new;
$nested = $r->add_route(':author');
$nested->add_route(':articles')->defaults(author => 'foo', articles => 'bar');

$m = $r->match(get => 'hello/world');
is_deeply $m->[0]->params => {author => 'foo', articles => 'world'};



# capture has precedence over default in parent route
$r = Forward::Routes->new;
$nested = $r->add_route('author')->defaults(articles => 'bar');
$nested->add_route(':articles');

$m = $r->match(get => 'author/world');
is_deeply $m->[0]->params => {articles => 'world'};



# defaults deeper in the chain have precedence over earlier defaults
$r = Forward::Routes->new;
$nested = $r->add_route('author')->defaults(comments => 'baz');
$nested->add_route('articles')->defaults(comments => 'foo');

$m = $r->match(get => 'author/articles');
is_deeply $m->[0]->params => {comments => 'foo'};
