use Test::More 'no_plan';
use warnings;
use strict;

package Foo::Bar;
use Gapp::Moose;

widget 'window' => (
    is => 'rw',
    gclass => 'Gapp::Window',
    construct => [
        title => 'Gapp Application',
    ]
);


package main;

my $o = Foo::Bar->new;
ok $o, 'created object';


1;
