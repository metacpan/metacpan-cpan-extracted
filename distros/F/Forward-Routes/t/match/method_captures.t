#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 16;


#############################################################################
### method tests

my $m = Forward::Routes::Match->new;
is ref $m->captures, 'HASH';
is_deeply $m->captures, {};

is $m->_add_captures({one => 1, two => 2}), $m;
is_deeply $m->captures, {one => 1, two => 2};

# hash elements are added, hash not replaced
$m->_add_captures({three => 3, four => 4});
is_deeply $m->captures, {one => 1, two => 2, three => 3, four => 4};

# older captures have precedence over newer captures
$m->_add_captures({one => 'ONE'});
is_deeply $m->captures, {one => 1, two => 2, three => 3, four => 4};

is $m->_add_captures({0 => 'ZERO'}), $m;
is_deeply $m->captures, {one => 1, two => 2, three => 3, four => 4, 0 => 'ZERO'};

#############################################################################
### captures

my $r = Forward::Routes->new;
$r->add_route('articles/:id')->defaults(first_name => 'foo', last_name => 'bar')->name('one');
$m = $r->match(get => 'articles/2');

# get hash
is_deeply $m->[0]->captures => {id => 2};

# get hash value
is $m->[0]->captures('id'), 2;



#############################################################################
### no caputures

$r = Forward::Routes->new;
$r->add_route('articles')->defaults(first_name => 'foo', last_name => 'bar')->name('one');
$m = $r->match(get => 'articles');

# get hash
is_deeply $m->[0]->captures => {};

# get hash value
is $m->[0]->captures('id'), undef;



#############################################################################
### nested routes

$r = Forward::Routes->new;
my $nested = $r->add_route('foo/:id');
$nested->add_route('bar/:id2');
$m = $r->match(get => 'foo/1/bar/4');

# get hash
is_deeply $m->[0]->captures => {id => 1, id2 => 4};



#############################################################################
### optional placeholders

$r = Forward::Routes->new;
$r->add_route('articles/(:id)?');

$m = $r->match(get => 'articles/2');
is_deeply $m->[0]->captures => {id => 2};

$m = $r->match(get => 'articles/');
is_deeply $m->[0]->captures => {};



#############################################################################
### defaults and optional placeholders

$r = Forward::Routes->new;
$r->add_route('articles/(:id)?')->defaults(id => 3, last_name => 'bar')->name('one');
$m = $r->match(get => 'articles/');

# get hash
is_deeply $m->[0]->captures => {id => 3};

