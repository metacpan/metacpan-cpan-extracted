#!/usr/bin/perl -w
use strict;
use warnings;

package Employee;
use Moose;


has 'first_name' => (
    is => 'rw',
    reader => 'get_first_name',
    writer => 'set_first_name',
);

use Test::More tests => 9;

use Gtk2 '-init';

use Gapp;
use Gapp::Form::Context;

my $cx = Gapp::Form::Context->new;
ok $cx, 'created context';

$cx->set_reader_prefix('get_');
is $cx->reader_prefix, 'get_', 'set reader prefix';

$cx->set_writer_prefix('set_');
is $cx->writer_prefix, 'set_', 'set writer prefix';

my $e = Employee->new( first_name => 'Homer' );
my $node = $cx->add( 'employee',  $e );
is $cx->lookup( 'employee.first_name' ), 'Homer', 'lookup attribute';
is $e->get_first_name, 'Homer', 'object lookup';

$cx->modify( 'employee.first_name', 'Marge' );
is $cx->lookup( 'employee.first_name' ), 'Marge', 'modify attribute';
is $e->get_first_name, 'Marge', 'object modified';

my $stash = Gapp::Form::Stash->new;
$stash->store( 'employee.first_name', 'Lisa' );
$cx->update( $stash );
is $cx->lookup( 'employee.first_name' ), 'Lisa', 'modify attribute';
is $e->get_first_name, 'Lisa', 'object modified';



