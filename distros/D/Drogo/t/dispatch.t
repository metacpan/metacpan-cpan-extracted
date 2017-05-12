#!/usr/bin/perl
use strict;
use warnings;

use lib 't/lib';
use lib 'lib';

use Foo;
use Drogo::Server::Test;

use Test::More tests => 15;

my $server = Drogo::Server::Test->new;

# check if we present an index
cmp_ok( Foo->handler( uri => '/' )->{output}, 'eq', 'howdy friend', 'output correct');
cmp_ok( Foo->handler( uri => '/' )->{status}, '==', 200, 'default status correct');
cmp_ok( Foo->handler( uri => '/' )->{http_header}, 'eq', 'text/html', 'default header is correct');

cmp_ok( Foo->handler( uri => '/beaver' )->{output}, 'eq', 'unicorns', 'output correct for /beaver');
cmp_ok( Foo->handler( uri => '/beaver/' )->{output}, 'eq', 'unicorns', 'output correct for /beaver/');

# test action matching
cmp_ok( Foo->handler( uri => '/waffle' )->{output}, 'eq', '', 'empty action match works');
cmp_ok( Foo->handler( uri => '/waffle/queen' )->{output}, 'eq', 'queen', 'single item action match works');
cmp_ok( Foo->handler( uri => '/waffle/queen/cd' )->{output}, 'eq', 'queen/cd', 'double item action match works');
cmp_ok( Foo->handler( uri => '/waffle' )->{output}, 'eq', '', 'empty action match works');
cmp_ok( Foo->handler( uri => '/wafflesforsale' )->{status}, '==', '404', 'action matching stays in boundaries');

# test dispatches to other pages
cmp_ok( Foo->handler( uri => '/bar' )->{output}, 'eq', "Foo::bar's index", 'cross-module dispatch works for index');
cmp_ok( Foo->handler( uri => '/bar/moo' )->{output}, 'eq', 'cows go moo', 'cross-module dispatch works for action');
cmp_ok( Foo->handler( uri => '/bar/mood' )->{output}, 'eq', 'cows go moo', 'cross-module dispatch works for actionmatch');

# test 404
cmp_ok( Foo->handler( uri => '/badpage' )->{status}, '==', '404', 'bad dispatching uses error sub');

# test regex dispatching
cmp_ok( Foo->handler( uri => '/har/waffle/roop' )->{output}, 'eq', 'waffle', 'regex matching works');
