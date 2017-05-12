#!/usr/bin/perl -w
use strict;
use warnings;

use lib 'lib';
use lib 't/lib';
use Test::More tests => 5;

use_ok 'Gapp::Gtk2::Model::List';

my $model = Gapp::Gtk2::Model::List->new;
my $iter  = $model->append( 0 => 'Object', 1 => 'Bool' );
is $model->get( $iter, 0 ), 'Object', 'value set/retrieved';
is $model->get( $iter, 1 ), 'Bool', 'value set/retrieved';

$model->set( $iter, 0 => 'updated' );
is $model->get( $iter, 0 ), 'updated', 'value set/updated';


$iter = undef;
$iter = $model->append_record( 'Object #2', 0 );
is $model->get( $iter, 0 ), 'Object #2', 'value set/retrieved';
