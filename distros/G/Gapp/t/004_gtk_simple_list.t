#!/usr/bin/perl -w
use strict;
use warnings;

use lib 'lib';
use lib 't/lib';
use Test::More tests => 9;

use_ok 'Gapp::Gtk2::Model::SimpleList';

my $model = Gapp::Gtk2::Model::SimpleList->new;
my $iter = $model->append( 'value 1' );
is $model->get( $iter ), 'value 1', 'value set/retrieved';

$model->set( $iter, 'updated' );
is $model->get( $iter ), 'updated', 'value set/updated';



$model->append( 'value 2' );

$iter = undef;
$iter = $model->get_iter_first;
ok $iter, 'got first iter';
is $model->get( $iter ), 'updated', 'got value from iter first';

my $iter_next = $model->iter_next( $iter );
ok $iter_next, 'got next iter';
is $model->get( $iter_next ), 'value 2', 'got value from iter next';


$iter_next = undef;
$iter_next = $model->remove( $iter );
ok $iter_next, 'removed row';
is $model->get( $iter_next ), 'value 2', 'got value of next row';
