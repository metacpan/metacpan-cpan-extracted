#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;
use Test::Deep;

use lib 't/lib';

our ( $es, $store );
do 'es.pl';

our $is_090 = $es->isa('Search::Elasticsearch::Client::0_90::Direct');

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
ok my $ns = $model->namespace('myapp'), 'Got ns';

create_users($model);

isa_ok my $view
    = $model->view( domain => 'myapp' )->sort('name.untouched')
    ->fields('_source')->include_paths('name'),
    'Elastic::Model::View', 'View';
isa_ok my $it = $view->search, 'Elastic::Model::Results', 'Iterator';

test_single( "First/Next:", [ first => 1,  next => 2 ] );
test_single( "First/Prev:", [ first => 1,  prev => undef ] );
test_single( "Last/Next",   [ last  => 10, next => undef ] );
test_single( "Last/Prev",   [ last  => 10, prev => 9 ] );

test_single( "Next wraparound:",
    [ next => 10, next => undef, next => 1, next => 2 ] );

test_single( "Prev wraparound:",
    [ prev => 1, prev => undef, prev => 10, prev => 9 ] );

test_single(
    "Current:",
    [   first   => 1,
        current => 1,
        last    => 10,
        current => 10,
        next    => undef,
        current => undef,
        next    => 1,
        current => 1,
        prev    => undef,
        current => undef,
        prev    => 10,
        current => 10
    ]
);

test_single(
    "Peek:",
    [   first     => 1,
        peek_next => 2,
        next      => 2,
        peek_next => 3,
        prev      => 1,
        peek_prev => undef,
        prev      => undef,
        peek_prev => 10,
        prev      => 10,
        peek_next => undef,
        next      => undef,
        peek_next => 1
    ]
);

test_single(
    "Shift:",
    [   'shift' => 1,
        'shift' => 2,
        'shift' => 3,
        'shift' => 4,
        'shift' => 5,
        'shift' => 6,
        'shift' => 7,
        'shift' => 8,
        'shift' => 9,
        'shift' => 10,
        'shift' => undef
    ],
    sub { $store = [ @{ $it->elements } ] },
    sub { $it->_set_elements( [@$store] ) },
);

## All / Slice ##
$it = $view->search;
test_multi( 'all',   [], [ 1 .. 10 ] );
test_multi( 'slice', [], [ 1 .. 10 ] );
test_multi( 'slice', [ 0,    5 ],  [ 1 .. 5 ] );
test_multi( 'slice', [ 5,    2 ],  [ 6 .. 7 ] );
test_multi( 'slice', [ 0,    15 ], [ 1 .. 10 ] );
test_multi( 'slice', [ 5,    15 ], [ 6 .. 10 ] );
test_multi( 'slice', [ -4,   3 ],  [ 7 .. 9 ] );
test_multi( 'slice', [ 5,    -2 ], [] );
test_multi( 'slice', [ -5,   -2 ], [] );
test_multi( 'slice', [ 1000, 10 ], [] );

## Size / Total ##
is $it->size,  10,  'Size';
is $it->total, 196, 'Total';

$it->shift;

is $it->size,  9,   'Size after shift';
is $it->total, 196, 'Total after shift';

## Index / Reset ##
$it = $view->search;

$it->index(undef);
is $it->_i,    -1,    'Index i undef';
is $it->index, undef, 'Index index undef';
$it->index(0);
is $it->_i,    '0', 'Index i 0';
is $it->index, '0', 'Index index 0';
$it->index(1);
is $it->_i,    1, 'Index i 1';
is $it->index, 1, 'Index index 1';
$it->index(-1);
is $it->_i,    9, 'Index i -1';
is $it->index, 9, 'Index index -1';

throws_ok sub { $it->index(-1000) }, qr/out of bounds/, 'Index out of bounds';

$it->reset;
is $it->_i, -1, 'Reset';

throws_ok sub { $it->index(20) }, qr/Values can be 0..9/, 'Index out of bounds';
$it->shift for 1 .. 10;
throws_ok sub { $it->index(0) }, qr/ No values/, 'Empty index out of bounds';

## Informational ##
$it = $view->search;

is $it->is_first, undef, 'Start: Is first';
is $it->is_last,  undef, 'Start: Is last';
is $it->even,     undef, 'Start: Is even';
is $it->odd,      undef, 'Start: Is odd';
is $it->parity,   undef, 'Start: Parity';
is $it->has_next, 1,     'Start: Has next';
is $it->has_prev, 1,     'Start: Has prev';

$it->first;

is $it->is_first, 1,     'First: Is first';
is $it->is_last,  '',    'First: Is last';
is $it->even,     '',    'First: Is even';
is $it->odd,      1,     'First: Is odd';
is $it->parity,   'odd', 'First: Parity';
is $it->has_next, 1,     'First: Has next';
is $it->has_prev, '',    'First: Has prev';

$it->next;

is $it->is_first, '',     'Next: Is first';
is $it->is_last,  '',     'Next: Is last';
is $it->even,     1,      'Next: Is even';
is $it->odd,      '',     'Next: Is odd';
is $it->parity,   'even', 'Next: Parity';
is $it->has_next, 1,      'Next: Has next';
is $it->has_prev, 1,      'Next: Has prev';

$it->last;

is $it->is_first, '',     'Last: Is first';
is $it->is_last,  1,      'Last: Is last';
is $it->even,     1,      'Last: Is even';
is $it->odd,      '',     'Last: Is odd';
is $it->parity,   'even', 'Last: Parity';
is $it->has_next, '',     'Last: Has next';
is $it->has_prev, 1,      'Last: Has prev';

$it->prev;
is $it->is_first, '',    'Prev: Is first';
is $it->is_last,  '',    'Prev: Is last';
is $it->even,     '',    'Prev: Is even';
is $it->odd,      1,     'Prev: Is odd';
is $it->parity,   'odd', 'Prev: Parity';
is $it->has_next, 1,     'Prev: Has next';
is $it->has_prev, 1,     'Prev: Has prev';

$it->shift for 1 .. 10;
is $it->is_first, undef, 'Empty: Is first';
is $it->is_last,  undef, 'Empty: Is last';
is $it->even,     undef, 'Empty: Is even';
is $it->odd,      undef, 'Empty: Is odd';
is $it->parity,   undef, 'Empty: Parity';
is $it->has_next, '',    'Empty: Has next';
is $it->has_prev, '',    'Empty: Has prev';

done_testing;

#===================================
sub test_single {
#===================================
    my ( $desc, $tests, $init, $reset ) = @_;

    $init ||= sub { $store = $it->_i };
    $reset ||= sub { $it->_i($store) };

    while (@$tests) {
        my $name      = shift @$tests;
        my $id        = shift @$tests;
        my $el_method = $name . '_element';
        my $ob_method = $name . '_object';
        my $re_method = $name . '_result';

        $init->();
        if ( defined $id ) {
            isa_ok my $r = $it->$el_method, 'HASH', "$desc $el_method - $id";
            is $r->{_id}, $id, "$desc $el_method ID - $id";
            $reset->();

            isa_ok $r = $it->$ob_method, 'MyApp::User',
                "$desc $ob_method - $id";
            is $r->uid->id, $id, "$desc $ob_method ID - $id";
            $reset->();

            isa_ok $r= $it->$re_method, 'Elastic::Model::Result',
                "$desc $re_method - $id";
            is $r->id, $id, "$desc $re_method ID - $id";
            $reset->();

            $it->as_elements;
            isa_ok $r= $it->$name, 'HASH', "$desc $name as elements - $id";
            is $r->{_id}, $id, "$desc $name as elements  ID - $id";
            $reset->();

            $it->as_objects;
            isa_ok $r= $it->$name, 'MyApp::User',
                "$desc $name as objects - $id";
            is $r->uid->id, $id, "$desc $name as objects ID - $id";
            $reset->();

            $it->as_results;
            isa_ok $r= $it->$name, 'Elastic::Model::Result',
                "$desc $name as results - $id";
            is $r->id, $id, "$desc $name as results ID - $id";
            $reset->();

            $it->as_partials;
            isa_ok $r= $it->$name, 'MyApp::User',
                "$desc $name as partials - $id";
            is $r->uid->is_partial, 1, "$desc $name as partials is partial";
            ok $r->name, "$desc $name as partials has name";

        SKIP: {
                skip "Partials not supported in 0.90", 1 if $is_090;
                ok !$r->{timestamp}, "$desc $name as partials has no timestamp";
            }
        }
        else {
            is my $r = $it->$el_method, undef, "$desc $el_method - undef";
            $reset->();

            is $r = $it->$ob_method, undef, "$desc $ob_method - undef";
            $reset->();

            is $r= $it->$re_method, undef, "$desc $re_method - undef";
            $reset->();

            $it->as_elements;
            is $r= $it->$name, undef, "$desc $name as elements - undef";
            $reset->();

            $it->as_objects;
            is $r= $it->$name, undef, "$desc $name as objects - undef";
            $reset->();

            $it->as_results;
            is $r= $it->$name, undef, "$desc $name as results - undef";
            $reset->();

            $it->as_partials;
            is $r= $it->$name, undef, "$desc $name as partials - undef";

        }

    }

}

#===================================
sub test_multi {
#===================================
    my ( $name, $args, $ids ) = @_;

    my $desc      = "(" . join( ',', @$args ) . ")";
    my $el_method = $name . '_elements';
    my $ob_method = $name . '_objects';
    my $re_method = $name . '_results';

    my @res;
    @res = $it->$el_method(@$args);
    cmp_deeply [ map { $_->{_id} } grep { ref eq 'HASH' } @res ], $ids,
        "$el_method$desc";

    @res = $it->$ob_method(@$args);
    cmp_deeply [ map { $_->uid->id } grep { $_->isa('MyApp::User') } @res ],
        $ids,
        "$ob_method$desc";

    @res = $it->$re_method(@$args);
    cmp_deeply [
        map  { $_->id }
        grep { $_->isa('Elastic::Model::Result') } @res
        ],
        $ids,
        "$re_method$desc";

    $it->as_elements;
    @res = $it->$name(@$args);
    cmp_deeply [ map { $_->{_id} } grep { ref eq 'HASH' } @res ], $ids,
        "$name$desc as elements ";

    $it->as_objects;
    @res = $it->$name(@$args);
    cmp_deeply [ map { $_->uid->id } grep { $_->isa('MyApp::User') } @res ],
        $ids,
        "$name$desc as objects";

    $it->as_results;
    @res = $it->$name(@$args);
    cmp_deeply [
        map  { $_->id }
        grep { $_->isa('Elastic::Model::Result') } @res
        ],
        $ids,
        "$name$desc as results";

}

__END__
