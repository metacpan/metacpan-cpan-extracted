
use strict;
use Test::More;
use lib 't/lib';
use Devel::Stub::lib active_if => 1, path => "t/stub",quiet => 1;
use Foo::Bar;


subtest 'original' => sub {
    plan  tests => 3;
    my $b = Foo::Bar->new;
    is $b->poo(1),"stubed!";
    is $b->poo(2),"original!";
    is $b->poo(3),"original!";
};

done_testing;
