#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Forward::Routes;

use Test::More tests => 9;


#############################################################################
### match: is_bridge

my $m = Forward::Routes::Match->new;
is $m->is_bridge, undef;
is $m->is_bridge(0), $m;
is $m->is_bridge, 0;
is $m->is_bridge(undef), $m;
is $m->is_bridge, undef;
is $m->is_bridge(1), $m;
is $m->is_bridge, 1;


#############################################################################
### Forward::Routes

my $r = Forward::Routes->new;
$r->bridge('admin');
$m = $r->match(get => 'admin');

is_deeply $m->[0]->is_bridge, 1;


$r = Forward::Routes->new;
$r->add_route('admin');
$m = $r->match(get => 'admin');

is_deeply $m->[0]->is_bridge, undef;
