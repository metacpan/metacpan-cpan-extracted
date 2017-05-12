#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use File::Redirect qw(mount);

mount( 'Simple', { '/Foo.pm' => 'package Foo; sub foo { 42 }; 1' }, 'redirect:');

use lib qw(redirect:);

require Foo;

ok(1, 'require');

ok(42 == Foo::foo(), 'compiled');
