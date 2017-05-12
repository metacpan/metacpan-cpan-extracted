#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;
use Test::Deep;

use lib 't/lib';

our ( $es, $store );
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
ok my $ns = $model->namespace('myapp'), 'Got ns';

create_users($model);

isa_ok my $view = $model->view( domain => 'myapp' ), 'Elastic::Model::View',
    'View';
isa_ok my $scroll = $view->scroll, 'Elastic::Model::Results::Scrolled',
    'Scroll';
isa_ok my $scan = $view->scan, 'Elastic::Model::Results::Scrolled', 'Scan';

is $scroll->size, 196, 'Scroll size';
is $scan->size,   196, 'Scan size';

my $count = 0;
while ( $scroll->next ) { $count++ }
is $count, 196, 'Scroll next';

$count = 0;
while ( $scan->next ) { $count++ }
is $count, 196, 'Scan next';

$scroll = $view->sort('name.untouched')->scroll;
$scan   = $view->scan;

is $scroll->prev->id, 196, 'Scroll prev';

$scan->prev;
is @{ $scan->elements }, 196, 'Scan prev';

$scroll = $view->scroll;
$scan   = $view->scan;

is $scroll->all_elements, 196, 'Scroll all';
is $scan->all_elements,   196, 'Scan all';

$scroll = $view->sort('name.untouched')->scroll;
$scan   = $view->scan;

$scroll->index(60);
$scan->index(60);

is $scroll->current->id, 60, 'Scroll index 60';
ok 60 <= @{ $scan->elements } && 196 > @{ $scan->elements }, 'Scan index 60';

$count = 0;
while ( $scroll->shift ) { $count++ }
is $count, 196, 'Scroll shift';

$count = 0;
while ( $scan->shift ) { $count++ }
is $count, 196, 'Scan shift';

$scroll = $view->scroll;
$scan   = $view->scan;

is $scroll->slice( 60, 10 ), 10, 'Scroll slice';
ok @{ $scroll->elements } >= 70 && @{ $scroll->elements } < 196,
    'Scroll slice elements';

is $scan->slice( 60, 10 ), 10, 'Scan slice';
ok @{ $scan->elements } >= 70 && @{ $scan->elements } < 196,
    'Scan slice elements';

$scroll = $view->scroll;
$scan   = $view->scan;
$scroll->_fetch_until(1000);
$scan->_fetch_until(1000);

is @{ $scroll->elements }, 196, 'Scroll fetch 1000';
is @{ $scan->elements },   196, 'Scan fetch 1000';

done_testing;

__END__
