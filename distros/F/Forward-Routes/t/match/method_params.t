#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 10;


#############################################################################
### method tests

my $m = Forward::Routes::Match->new;
is ref $m->params, 'HASH';
is_deeply $m->params, {};

is $m->_add_params({one => 1, two => 2}), $m;
is_deeply $m->params, {one => 1, two => 2};

# hash elements are added, hash not replaced
$m->_add_params({three => 3, four => 4});
is_deeply $m->params, {one => 1, two => 2, three => 3, four => 4};

# older params have precedence over newer params
$m->_add_params({one => 'ONE'});
is_deeply $m->params, {one => 1, two => 2, three => 3, four => 4};

is $m->_add_params({0 => 'ZERO'}), $m;
is_deeply $m->params, {one => 1, two => 2, three => 3, four => 4, 0 => 'ZERO'};


#############################################################################
### Forward::Routes

my $r = Forward::Routes->new;
$r->add_route('articles/:id')->defaults(first_name => 'foo', last_name => 'bar')->name('one');

$m = $r->match(get => 'articles/2');

# get hash
is_deeply $m->[0]->params => {first_name => 'foo', last_name => 'bar', id => 2};

# get hash value
is $m->[0]->params('first_name'), 'foo';

