#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 2;


package My::Trait;

use Moose::Role;

has 'foo' => (
    is => 'rw',
    isa => 'Str',
    default => 'bar',
);

package main;

use_ok 'Gapp::Object';

{   # object contruction
    my $o = Gapp::Object->new(
        gclass => 'Gtk2::TextView',
        traits => [qw( My::Trait )],
    );
    is $o->foo, 'bar', 'Applied trait to widget';
}


