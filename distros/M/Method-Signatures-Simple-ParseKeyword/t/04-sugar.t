
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use_ok 'UseSugar';
use_ok 'sugar';
my $s = UseSugar->make(stuff => 42);
is $s->stuff(4), 46;
is $s->stuff, 44;

done_testing;


