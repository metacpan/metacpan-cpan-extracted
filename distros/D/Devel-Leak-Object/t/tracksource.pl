#!perl

use strict;

use Devel::Leak::Object qw(GLOBAL_bless);
$Devel::Leak::Object::TRACKSOURCELINES = 1;

my $foo = bless({}, 'FOO'); # this is line 8
$foo->{foo}=$foo;
