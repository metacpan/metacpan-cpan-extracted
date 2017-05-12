#!/usr/bin/perl
# base.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 2;
use File::Attributes::Base;
use File::Attributes::Simple;

my $foo;
eval {
    $foo = File::Attributes::Base->new;
};
is($foo->applicable, 0, 'base is not applicable');

eval {
    $foo = File::Attributes::Simple->new;
};
is($foo->applicable, 1, 'Simple is applicable');

