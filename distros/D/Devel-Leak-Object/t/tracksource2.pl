#!perl

use strict;

use Devel::Leak::Object qw(GLOBAL_bless);
$Devel::Leak::Object::TRACKSOURCELINES = 1;

use t::tracksource;

my $foo = bless({}, 'FOO'); # this is line 8
$foo->{foo}=$foo;
my $bar = bless({}, 'FOO'); # this is line 10
$bar->{foo}=$bar;
my $baz = Devel::Leak::Object::Tests::tracksource->new();

for (1..3) {
    Devel::Leak::Object::checkpoint();
    my $foo = bless({}, 'LOOPYFOO');
    $foo->{foo} = $foo;
}
