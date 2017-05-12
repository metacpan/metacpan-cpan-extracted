#!perl
#
# This file is part of Method-Extension
#
# This software is Copyright (c) 2015 by Tiago Peczenyj.
#
# This is free software, licensed under:
#
#   The MIT (X11) License
#
use Test::More;
use t::lib::Foo;
use t::lib::Bar;

my $foo = Foo->new;

can_ok $foo, 'baz';

is $foo->baz, 'Baz from extension method', 'should call baz';

done_testing;
