use strict;
use warnings;
use Test::More tests => 32;
use lib 'lib';
use Forward::Routes;


##############################################################################
### constraints

### simple route
my $r = Forward::Routes->new;
$r->add_route('articles/:id')->constraints(id => qr/\d+/)->name('article');


# match
my $m = $r->match(get => 'articles/abc');
ok not defined $m;

$m = $r->match(get => 'articles/abc1');
ok not defined $m;

$m = $r->match(get => 'articles/123');
is_deeply $m->[0]->params => {id => 123};


# path building
is eval {$r->build_path('article')->{path}}, undef;
like $@ => qr/Required param 'id' was not passed when building a path/;

is eval {$r->build_path('article', id => 'abc')->{path}}, undef;
like $@ => qr/Param 'id' fails a constraint/;

is $r->build_path('article', id => 123)->{path} => 'articles/123';


##############################################################################
### multiple placeholder constraints, one call to constraint method
$r = Forward::Routes->new;
$r->add_route('articles/:id/:comment')
  ->constraints(id => qr/\d+/, comment => qr/[a-z]{1,2}/)
  ->name('article');

$m = $r->match(get => 'articles/abc/abc');
is $m, undef;

$m = $r->match(get => 'articles/123/abc');
is $m, undef;

$m = $r->match(get => 'articles/abc/ab');
is $m, undef;

$m = $r->match(get => 'articles/123/ab');
is_deeply $m->[0]->params => {id => 123, comment => 'ab'};


# path building
is eval {$r->build_path('article')->{path}}, undef;
like $@ => qr/Required param 'id' was not passed when building a path/;

is eval {$r->build_path('article', id => '123')->{path}}, undef;
like $@ => qr/Required param 'comment' was not passed when building a path/;

is eval {$r->build_path('article', comment => 'ab')->{path}}, undef;
like $@ => qr/Required param 'id' was not passed when building a path/;

is eval {$r->build_path('article', id => 'abc', comment => 'ab')->{path}}, undef;
like $@ => qr/Param 'id' fails a constraint/;

is eval {$r->build_path('article', id => '123', comment => 'abc')->{path}}, undef;
like $@ => qr/Param 'comment' fails a constraint/;

is $r->build_path('article', id => 123, comment => 'ab')->{path} => 'articles/123/ab';


##############################################################################
### multiple constraint calls should not reset previously set constraints

$r = Forward::Routes->new;
$r->add_route('articles/:id/:comment')
  ->constraints(id => qr/\d+/)
  ->constraints(comment => qr/\w+/)
  ->name('article');

$m = $r->match(get => 'articles/abc/a-b');
is $m, undef;

$m = $r->match(get => 'articles/123/a-b');
is $m, undef;

$m = $r->match(get => 'articles/abc/a_b_c');
is $m, undef;

$m = $r->match(get => 'articles/123/a_b_c');
is_deeply $m->[0]->params, {id => 123, comment => 'a_b_c'};



is eval {$r->build_path('article', id => 'abc', comment => 'a_b_c')->{path}}, undef;
like $@ => qr/Param 'id' fails a constraint/;

is eval {$r->build_path('article', id => '123', comment => 'a-b')->{path}}, undef;
like $@ => qr/Param 'comment' fails a constraint/;

is $r->build_path('article', id => 123, comment => 'a_b_c')->{path} => 'articles/123/a_b_c';
