#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;
use Test::Deep;

use lib 't/lib';

our $es;
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
isa_ok my $domain = $model->domain('myapp'), 'Elastic::Model::Domain';

## Create view ##
isa_ok my $view = $model->view, 'Elastic::Model::View', 'Model view';
cmp_bag $view->domain,
    [ 'myapp', 'myapp1', 'myapp1_fixed' ],
    'Model view has all domains';

isa_ok $view = $domain->view, 'Elastic::Model::View', 'Domain view';

cmp_bag $view->domain, ['myapp'], 'Domain view has domain name';

## Domain ##
test_view(
    'New-domain-array',
    $domain->view( domain => [ 'foo', 'bar' ] ),
    { index => [ 'foo', 'bar' ] }
);

test_view(
    'New-domain-str',
    $domain->view( domain => 'foo' ),
    { index => ['foo'] }
);

test_view(
    'Set-domain-array',
    $view->domain( [ 'foo', 'bar' ] ),
    { index => [ 'foo', 'bar' ] }
);

test_view(
    'Set-domain-list',
    $view->domain( 'foo', 'baz' ),
    { index => [ 'foo', 'baz' ] }
);

test_view( 'Set-domain-str', $view->domain('foo'), { index => ['foo'] } );

## type ##
test_view(
    'New-type-array',
    $domain->view( type => [ 'foo', 'bar' ] ),
    { type => [ 'foo', 'bar' ] }
);

test_view( 'New-type-str', $domain->view( type => 'foo' ),
    { type => ['foo'] } );

test_view(
    'Set-type-array',
    $view->type( [ 'foo', 'bar' ] ),
    { type => [ 'foo', 'bar' ] }
);

test_view(
    'Set-type-list',
    $view->type( 'foo', 'baz' ),
    { type => [ 'foo', 'baz' ] }
);

test_view( 'Set-type-str', $view->type('foo'), { type => ['foo'] } );

## query ##
my $clause = { match => { foo => 'bar' } };
test_view(
    'New-query',
    $domain->view( query => $clause ),
    { query => $clause }
);

test_view( 'Set-query-hash', $view->query($clause), { query => $clause } );

test_view( 'Set-query-list', $view->query(%$clause), { query => $clause } );

## queryb ##
test_view(
    'New-queryb-hash',
    $domain->view( queryb => { foo => 'bar' } ),
    { query => $clause }
);

test_view(
    'New-queryb-str',
    $domain->view( queryb => 'foo' ),
    { query => { match => { _all => 'foo' } } }
);

test_view(
    'New-queryb-array',
    $domain->view( queryb => [ 'foo', 'bar', 'foo', 'baz' ] ),
    {   query => {
            bool => {
                should => [
                    { match => { foo => "bar" } },
                    { match => { foo => "baz" } }
                ],
            },
        }
    }
);

test_view(
    'Set-queryb-hash',
    $view->queryb( { foo => 'bar' } ),
    { query => $clause }
);

test_view(
    'Set-queryb-list',
    $view->queryb( foo => 'bar', foo => 'baz' ),
    { query => { match => { foo => 'baz' } } }
);

test_view(
    'Set-queryb-str',
    $view->queryb('foo'),
    { query => { match => { _all => 'foo' } } }
);

test_view(
    'Set-queryb-array',
    $view->queryb( [ foo => 'bar', foo => 'baz' ] ),
    {   query => {
            bool => {
                should => [
                    { match => { foo => "bar" } },
                    { match => { foo => "baz" } }
                ],
            },
        }
    }
);

test_view( 'Set-queryb-empty-list', $view->queryb(),
    { query => { match_all => {} } } );

test_view(
    'Set-queryb-empty-hashref',
    $view->queryb( {} ),
    { query => { match_all => {} } }
);

test_view(
    'Set-queryb-empty-arrayref',
    $view->queryb( [] ),
    { query => { match_all => {} } }
);

## filter ##
test_view(
    'New-filter',
    $domain->view( filter => { term => { foo => 'bar' } } ),
    {   query =>
            { constant_score => { filter => { term => { foo => 'bar' } } } }
    }
);

test_view(
    'Set-filter-hash',
    $view->filter( { term => { foo => 'bar' } } ),
    {   query =>
            { constant_score => { filter => { term => { foo => 'bar' } } } }
    }
);

test_view(
    'Set-filter-list',
    $view->filter( term => { foo => 'bar' } ),
    {   query =>
            { constant_score => { filter => { term => { foo => 'bar' } } } }
    }
);

## filterb ##
test_view(
    'New-filterb-hash',
    $domain->view( filterb => { foo => 'bar' } ),
    {   query =>
            { constant_score => { filter => { term => { foo => 'bar' } } } }
    }
);

test_view(
    'New-filterb-str',
    $domain->view( filterb => 'foo' ),
    {   query =>
            { constant_score => { filter => { term => { _all => 'foo' } } } }
    }
);

test_view(
    'New-filterb-array',
    $domain->view( filterb => [ 'foo', 'bar', 'foo', 'baz' ] ),
    {   query => {
            constant_score => {
                filter => {
                    or => [
                        { term => { foo => "bar" } },
                        { term => { foo => "baz" } },
                    ],
                }
            }
        }
    }
);

test_view(
    'Set-filterb-hash',
    $view->filterb( { foo => 'bar' } ),
    {   query =>
            { constant_score => { filter => { term => { foo => 'bar' } } } }
    }
);

test_view(
    'Set-filterb-list',
    $view->filterb( foo => 'bar', foo => 'baz' ),
    {   query =>
            { constant_score => { filter => { term => { foo => 'baz' } } } }
    }
);

test_view(
    'Set-filterb-str',
    $view->filterb('foo'),
    {   query =>
            { constant_score => { filter => { term => { _all => 'foo' } } } }
    }
);

test_view(
    'Set-filterb-array',
    $view->filterb( [ foo => 'bar', foo => 'baz' ] ),
    {   query => {
            constant_score => {
                filter => {
                    or => [
                        { term => { foo => "bar" } },
                        { term => { foo => "baz" } },
                    ],
                }
            }
        }
    }
);

## post_filterb ##
test_view(
    'New-post_filterb-hash',
    $domain->view( post_filterb => { foo => 'bar' } ),
    { post_filter => { term => { foo => 'bar' } } }
);

test_view(
    'New-post_filterb-str',
    $domain->view( post_filterb => 'foo' ),
    { post_filter => { term => { _all => 'foo' } } }
);

test_view(
    'New-post_filterb-array',
    $domain->view( post_filterb => [ 'foo', 'bar', 'foo', 'baz' ] ),
    {   post_filter => {
            or =>
                [ { term => { foo => "bar" } }, { term => { foo => "baz" } }, ],
        }
    }
);

test_view(
    'Set-post_filterb-hash',
    $view->post_filterb( { foo => 'bar' } ),
    { post_filter => { term => { foo => 'bar' } } }
);

test_view(
    'Set-post_filterb-list',
    $view->post_filterb( foo => 'bar', foo => 'baz' ),
    { post_filter => { term => { foo => 'baz' } } }
);

test_view(
    'Set-post_filterb-str',
    $view->post_filterb('foo'),
    { post_filter => { term => { _all => 'foo' } } }
);

test_view(
    'Set-post_filterb-array',
    $view->post_filterb( [ foo => 'bar', foo => 'baz' ] ),
    {   post_filter => {
            or =>
                [ { term => { foo => "bar" } }, { term => { foo => "baz" } }, ],
        }
    }
);

## Combine query/filter/post-filter ##
test_view(
    'Query, filter, post_filter',
    $view->queryb( foo => 1 )->filterb( bar => 1 )->post_filterb( baz => 1 ),
    {   query => {
            filtered => {
                query  => { match => { foo => 1 } },
                filter => { term  => { bar => 1 } }
            }
        },
        post_filter => { term => { baz => 1 } }
    }
);


## aggs ##
test_view(
    'New-aggs',
    $domain->view( aggs => { foo => { terms => { field => 'foo' } } } ),
    { aggs => { foo => { terms => { field => 'foo' } } } }
);

test_view(
    'Set-aggs-hash',
    $view->aggs( { bar => { terms => { field => 'bar' } } } ),
    { aggs => { bar => { terms => { field => 'bar' } } } }
);

test_view(
    'Set-aggs-list',
    my $new = $view->aggs( foo => { terms => { field => 'foo' } } ),
    { aggs => { foo => { terms => { field => 'foo' } } } }
);

test_view(
    'Add-agg',
    $new = $new->add_agg( bar => { terms => { field => 'bar' } } ),
    {   aggs => {
            bar => { terms => { field => 'bar' } },
            foo => { terms => { field => 'foo' } },
        }
    }
);

test_view(
    'Remove agg',
    $new->remove_agg('foo'),
    { aggs => { bar => { terms => { field => 'bar' } }, } }
);

## facets ##
test_view(
    'New-facets',
    $domain->view( facets => { foo => { terms => { field => 'foo' } } } ),
    { facets => { foo => { terms => { field => 'foo' } } } }
);

test_view(
    'Set-facets-hash',
    $view->facets( { bar => { terms => { field => 'bar' } } } ),
    { facets => { bar => { terms => { field => 'bar' } } } }
);

test_view(
    'Set-facets-list',
    $new = $view->facets( foo => { terms => { field => 'foo' } } ),
    { facets => { foo => { terms => { field => 'foo' } } } }
);

test_view(
    'Add-facet',
    $new = $new->add_facet( bar => { terms => { field => 'bar' } } ),
    {   facets => {
            bar => { terms => { field => 'bar' } },
            foo => { terms => { field => 'foo' } },
        }
    }
);

test_view(
    'Remove facet',
    $new->remove_facet('foo'),
    { facets => { bar => { terms => { field => 'bar' } }, } }
);

test_view(
    'Facet - facet_filterb',
    $domain->view(
        facets => {
            filterb => {
                filterb       => { foo => 'bar' },
                facet_filterb => { foo => 'baz' }
            },
            queryb => {
                queryb        => { foo => 'bar' },
                facet_filterb => { foo => 'baz' }
            },
        },
    ),
    {   facets => {
            filterb => {
                filter       => { term => { foo => 'bar' } },
                facet_filter => { term => { foo => 'baz' } }
            },
            queryb => {
                query        => { match => { foo => 'bar' } },
                facet_filter => { term  => { foo => 'baz' } }
            },
        }
    }
);

## fields ##
test_view(
    'New-fields-array',
    $domain->view( fields => [ 'foo', 'bar' ] ),
    { fields => [ "_parent", "_routing", 'foo', 'bar' ] }
);

test_view(
    'New-fields-str',
    $domain->view( fields => 'foo' ),
    { fields => [ "_parent", "_routing", 'foo' ] }
);

test_view(
    'Set-fields-array',
    $view->fields( [ 'foo', 'bar' ] ),
    { fields => [ "_parent", "_routing", 'foo', 'bar' ] }
);

test_view(
    'Set-fields-list',
    $view->fields( 'foo', 'baz' ),
    { fields => [ "_parent", "_routing", 'foo', 'baz' ] }
);

test_view(
    'Set-fields-str',
    $view->fields('foo'),
    { fields => [ "_parent", "_routing", 'foo' ] }
);

## from ##
test_view( 'New-from', $domain->view( from => 20 ), { from => 20 } );

test_view( 'Set-from', $view->from(20), { from => 20 } );

## size ##
test_view( 'New-size', $domain->view( size => 20 ), { size => 20 } );

test_view( 'Set-size', $view->size(20), { size => 20 } );

## sort ##
test_view(
    'New-sort-array',
    $domain->view( sort => [ 'foo', { bar => 'asc' } ] ),
    { sort => [ 'foo', { bar => 'asc' } ] }
);

test_view( 'New-sort-str', $domain->view( sort => 'foo' ),
    { sort => ['foo'] } );

test_view(
    'New-sort-hash',
    $domain->view( sort => { bar => 'asc' } ),
    { sort => [ { bar => 'asc' } ] }
);

test_view(
    'Set-sort-array',
    $view->sort( [ 'foo', { bar => 'asc' } ] ),
    { sort => [ 'foo', { bar => 'asc' } ] }
);

test_view(
    'Set-sort-list',
    $view->sort( 'foo', { bar => 'asc' } ),
    { sort => [ 'foo', { bar => 'asc' } ] }
);

## highlighting / highlight ##
test_view(
    'New-highlight-hash',
    $domain->view(
        highlighting => { x     => 'y' },
        highlight    => { 'foo' => {}, 'bar' => { x => 'z' } }
    ),
    { highlight => { x => 'y', fields => { foo => {}, bar => { x => 'z' } } } }
);

test_view(
    'New-highlight-array',
    $domain->view(
        highlighting => { x => 'y' },
        highlight => [ 'foo', 'bar' => { x => 'z' } ]
    ),
    { highlight => { x => 'y', fields => { foo => {}, bar => { x => 'z' } } } }
);

test_view(
    'New-highlight-str',
    $domain->view(
        highlighting => { x => 'y' },
        highlight    => 'foo',
    ),
    { highlight => { x => 'y', fields => { foo => {} } } }
);

test_view(
    'Set-highlight-hash-hash',
    $view->highlighting( { x => 'y' } )
        ->highlight( { foo => {}, bar => { x => 'z' } } ),
    { highlight => { x => 'y', fields => { foo => {}, bar => { x => 'z' } } } }
);

test_view(
    'Set-highlight-list-list',
    $view->highlighting( p => 'q' )->highlight( 'foo', bar => { p => 'r' } ),
    { highlight => { p => 'q', fields => { foo => {}, bar => { p => 'r' } } } }
);

test_view(
    'Set-highlight-str',
    $view->highlight('foo'),
    { highlight => { fields => { foo => {} } } }
);
test_view(
    'Set-highlight-array',
    $view->highlight( [ 'foo', 'bar', { x => 'y' } ] ),
    { highlight => { fields => { foo => {}, bar => { x => 'y' } } } }
);

throws_ok sub { $domain->view( highlighting => { fields => {} } ) },
    qr/set the fields/, 'New-highlighting-fields';
throws_ok sub { $view->highlighting( { fields => {} } ) }, qr/set the fields/,
    'Set-highlighting-fields';

test_view( 'New-highlighting', $domain->view( highlighting => { x => 'y' } ),
    {} );

test_view( 'Set-highlighting', $view->highlighting( { x => 'y' } ), {} );

test_view( 'New-highlighting-empty',
    $domain->view( highlighting => { x => 'y' }, highlight => {} ), {} );

test_view( 'Set-highlighting-empty',
    $view->highlighting( { x => 'y' } )->highlight( {} ), {} );

## index_boosts ##
test_view(
    'New-index_boosts-hash',
    $domain->view( index_boosts => { one => 1, two => 2 } ),
    { indices_boost => { one => 1, two => 2 } }
);

test_view(
    'Set-index_boosts-hash',
    $view->index_boosts( { one => 1, two => 2 } ),
    { indices_boost => { one => 1, two => 2 } }
);

test_view(
    'Set-index_boosts-list',
    $new = $view->index_boosts( one => 1, two => 2 ),
    { indices_boost => { one => 1, two => 2 } }
);

test_view(
    'Add-index_boost',
    $new = $new->add_index_boost( three => 3 ),
    { indices_boost => { one => 1, two => 2, three => 3 } }
);

test_view(
    'Remove-index_boost',
    $new->remove_index_boost('one'),
    { indices_boost => { two => 2, three => 3 } }
);

## min_score ##
test_view(
    'New-min_score',
    $domain->view( min_score => 2 ),
    { min_score => 2 }
);

test_view( 'Set-min_score', $view->min_score(4), { min_score => 4 } );

## preference ##
test_view(
    'New-preference',
    $domain->view( preference => 'foo' ),
    { preference => 'foo' }
);

test_view( 'Set-preference', $view->preference('bar'),
    { preference => 'bar' } );

## routing ##
test_view(
    'New-routing-array',
    $domain->view( routing => [ 'foo', 'bar' ] ),
    { routing => [ 'foo', 'bar' ] }
);

test_view(
    'New-routing-str',
    $domain->view( routing => 'foo' ),
    { routing => ['foo'] }
);

test_view(
    'Set-routing-array',
    $view->routing( [ 'foo', 'bar' ] ),
    { routing => [ 'foo', 'bar' ] }
);

test_view(
    'Set-routing-list',
    $view->routing( 'foo', 'baz' ),
    { routing => [ 'foo', 'baz' ] }
);

test_view( 'Set-routing-str', $view->routing('foo'), { routing => ['foo'] } );

## script_fields ##
test_view(
    'New-script_fields-hash',
    $domain->view( script_fields => { one => { script => 'xx' } } ),
    { script_fields => { one => { script => 'xx' } } }
);

test_view(
    'Set-script_fields-hash',
    $view->script_fields( { one => { script => 'xx' } } ),
    { script_fields => { one => { script => 'xx' } } }
);

test_view(
    'Set-script_fields-list',
    $new = $view->script_fields( one => { script => 'xx' } ),
    { script_fields => { one => { script => 'xx' } } }
);

test_view(
    'Add-script_field',
    $new = $new->add_script_field( two => { script => 'yy' } ),
    {   script_fields =>
            { one => { script => 'xx' }, two => { script => 'yy' } }
    }
);

test_view(
    'Remove-script_field',
    $new->remove_script_field('one'),
    { script_fields => { two => { script => 'yy' } } }
);

test_view(
    'Include paths',
    $view->include_paths('foo.*'),
    {   _source => { include => ['foo.*'] },
        fields => [ "_parent", "_routing" ],
    }
);

test_view(
    'Exclude paths',
    $view->exclude_paths('foo.*'),
    {   _source => { exclude => ['foo.*'] },
        fields => [ "_parent", "_routing" ],
    }
);

test_view(
    'Include and exclude paths',
    $view->include_paths( 'foo.*', 'fuz.*' )->exclude_paths( 'bar.*', 'baz.*' ),
    {   _source => {
            include => [ 'foo.*', 'fuz.*' ],
            exclude => [ 'bar.*', 'baz.*' ]
        },
        fields => [ "_parent", "_routing" ],
    }
);

## timeout ##
test_view(
    'New-timeout',
    $domain->view( timeout => '1s' ),
    { timeout => '1s' }
);

test_view( 'Set-timeout', $view->timeout('10s'), { timeout => '10s' } );

## explain ##
test_view( 'New-explain', $domain->view( explain => 1 ), { explain => 1 } );

test_view( 'Set-explain', $view->explain(1), { explain => 1 } );

## stats ##
test_view(
    'New-stats-array',
    $domain->view( stats => [ 'foo', 'bar' ] ),
    { stats => [ 'foo', 'bar' ] }
);

test_view(
    'New-stats-str',
    $domain->view( stats => 'foo' ),
    { stats => ['foo'] }
);

test_view(
    'Set-stats-array',
    $view->stats( [ 'foo', 'bar' ] ),
    { stats => [ 'foo', 'bar' ] }
);

test_view(
    'Set-stats-list',
    $view->stats( 'foo', 'baz' ),
    { stats => [ 'foo', 'baz' ] }
);

test_view( 'Set-stats-str', $view->stats('foo'), { stats => ['foo'] } );

## track_scores ##
test_view(
    'New-track_scores',
    $domain->view( track_scores => 1 ),
    { track_scores => 1 }
);

test_view( 'Set-track_scores', $view->track_scores(1), { track_scores => 1 } );

## consistency ##
test_view(
    'New-consistency',
    $domain->view( consistency => 'quorum' ),
    { consistency => 'quorum' }
);

test_view(
    'Set-consistency',
    $view->consistency('quorum'),
    { consistency => 'quorum' }
);

## replication ##
test_view(
    'New-replication',
    $domain->view( replication => 'async' ),
    { replication => 'async' }
);

test_view(
    'Set-replication',
    $view->replication('async'),
    { replication => 'async' }
);

#===================================
sub test_view {
#===================================
    my ( $name, $view, $results ) = @_;
    $results = {
        fields => [ "_parent", "_routing", "_source" ],
        from   => 0,
        index  => ["myapp"],
        query   => { match_all => {} },
        size    => 10,
        type    => [],
        version => 1,
        %$results
    };

    my %search = %$results;
    delete @search{ 'consistency', 'replication' };

    my %delete = map { $_ => $results->{$_} }
        grep { defined $results->{$_} }
        qw(index type query consistency replication routing);

    cmp_deeply( $view->_build_search, \%search, "Search - $name" );
    cmp_deeply( $view->_build_delete, \%delete, "Delete - $name" );

}

done_testing;
