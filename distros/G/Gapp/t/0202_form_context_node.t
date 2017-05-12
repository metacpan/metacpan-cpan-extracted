#!/usr/bin/perl -w
use strict;
use warnings;

package Employee;
use Moose;

has 'first_name' => (
    is => 'rw',
);

use Test::More tests => 2;

use Gtk2 '-init';

use Gapp;
use_ok 'Gapp::Form::Context::Node';

my $e = Employee->new( first_name => 'Homer' );
my $node = Gapp::Form::Context::Node->new( content => $e );

ok $node, 'created context node';

