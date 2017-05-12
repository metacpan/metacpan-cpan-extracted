#!perl -w
# for RT #52073

use strict;
use Test::More tests => 2;

eval {
    package Foo;

    use Hash::FieldHash qw(:all);

    use warnings FATAL => 'redefine';

    fieldhash my %marine => 'marine';

    sub new { bless {}, shift }
    sub marine { 42 }
};
like $@, qr/Subroutine .+ redefined/xms;

my $o = Foo->new;
is $o->marine, 42;
