use Test::More 'no_plan';
use warnings;
use strict;

package Foo::Bar;
use Gapp::Moose;

widget 'window' => (
    is => 'rw',
    traits => [qw( GappWindow )],
    construct => [
        title => 'Gapp Application',
    ]
);


package main;

my $o = Foo::Bar->new;
ok $o, 'created object';
ok $o->window, 'created widget';
isa_ok $o->window, 'Gapp::Window', 'widget';


1;
