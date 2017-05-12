#!./perl -w

use strict;
use Test; plan tests => 1;
use Event 0.40 qw(loop unloop);

package Foo;

my $foo=0;
sub DESTROY { ++$foo }

package main;

my $e = Event->timer(after => 0,
		     cb => sub { delete shift->w->{foo}; unloop });
$e->{foo} = bless [], 'Foo';

loop();
ok $foo;
