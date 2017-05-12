#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;

use lib 't/lib';

our $es;
do 'es.pl';

our $is_090 = $es->isa('Search::Elasticsearch::Client::0_90::Direct');

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
ok my $ns = $model->namespace('myapp'), 'Got ns';

create_users($model);

isa_ok my $view
    = $model->domain('myapp')->view->track_scores(1)
    ->facets( name => { terms => { field => 'name' } } ),
    'Elastic::Model::View',
    'View';

SKIP: {
    skip "aggs not supported in 0.90", 1 if $is_090;
    isa_ok $view = $view->aggs( name => { terms => { field => 'name' } } ),
        'Elastic::Model::View', 'View aggs';
}

isa_ok my $results = $view->search, 'Elastic::Model::Results', 'Search';

## SEARCH ##
is $results->total,     196, 'Search total ';
is $results->size,      10,  'Search size';
is $results->max_score, 1,   'Search max score';
ok $results->took > 0, 'Search took';
isa_ok $results->facets, 'HASH', 'Search facets';
isa_ok $results->facet('name'), 'HASH', 'Search named facet';
is 0 + ( $results->all ), 10, 'Search is finite';
isa_ok $results->first, 'Elastic::Model::Result', 'Search first';

SKIP: {
    skip "aggs not supported in 0.90", 2 if $is_090;
    isa_ok $results->aggs, 'HASH', 'Search aggs';
    isa_ok $results->agg('name'), 'HASH', 'Search named agg';
}

## SCROLL ##
isa_ok $results = $view->scroll, 'Elastic::Model::Results::Scrolled', 'Scroll';
is $results->_scroll->scroll, '1m', 'Scroll default time';
is $view->scroll('30s')->_scroll->scroll, '30s', 'Scroll manual time';
is $results->total,      196,    'Scroll total ';
is $results->size,       196,    'Scroll size';
is $results->max_score,  1,      'Scroll max score';
isa_ok $results->facets, 'HASH', 'Scroll facets';
isa_ok $results->facet('name'), 'HASH', 'Scroll named facet';
is 0 + ( $results->all ), 196, 'Scroll - all results';
isa_ok $results->first, 'Elastic::Model::Result', 'Scroll first';

SKIP: {
    skip "aggs not supported in 0.90", 2 if $is_090;
    isa_ok $results->aggs, 'HASH', 'Search aggs';
    isa_ok $results->agg('name'), 'HASH', 'Search named agg';
}

## SCAN ##

isa_ok $view
    = $model->domain('myapp')->view->track_scores(1),
    'Elastic::Model::View',
    'View';

isa_ok $results = $view->scan, 'Elastic::Model::Results::Scrolled', 'Scan';
is $results->_scroll->scroll, '1m', 'Scan default time';
is $view->scan('30s')->_scroll->scroll, '30s', 'Scan manual time';
is $results->total,     196, 'Scan total ';
is $results->size,      196, 'Scan size';
is $results->max_score, 0,   'Scan max score';
is 0 + ( $results->all ), 196, 'Scan - all results';
isa_ok $results->first, 'MyApp::User', 'Scan first';
ok $view->sort( [] )->scan, 'Scan empty sort';
throws_ok sub { $view->sort('_score')->scan }, qr/combined with sorting/,
    'Scan sort';

## FIRST ##
isa_ok $view->first, 'Elastic::Model::Result', 'First';

## TOTAL ##
is $view->total, 196, 'View total';

## DELETE ##
isa_ok $results = $view->delete, 'HASH', 'Delete';
ok $results->{_indices}{myapp2}
    && $results->{_indices}{myapp3},
    'Delete from both indices';
is $view->total, 0, 'Docs deleted';

done_testing;

__END__
