#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep qw(cmp_details deep_diag bag);
use Data::Dump qw(pp);
use Test::Exception;
use Elastic::Model::SearchBuilder;

my $a = Elastic::Model::SearchBuilder->new;

test_filters(
    "UNARY OPERATOR: all",

    "all: 0",
    { -all      => 0 },
    { match_all => {} },

    "all: 1",
    { -all      => 1 },
    { match_all => {} },

    "all: []",
    { -all      => [] },
    { match_all => {} },

    "all: {}",
    { -all      => {} },
    { match_all => {} },

    "all: {kv}",
    { -all => { boost => 1 } },
    qr/Unknown param/

);

test_filters(
    "UNARY OPERATORS: missing/exists",

    "exists: k",
    { -exists => 'k' },
    { exists => { field => 'k' } },

    "missing: k",
    { -missing => 'k' },
    { missing => { field => 'k' } },

    "missing: %V",
    { -missing => { field => 'k', null_value => 1, existence => 1 } },
    { missing  => { field => 'k', null_value => 1, existence => 1 } },

);

test_filters(
    'UNARY OPERATOR: limit',
    'LIMIT: V',
    { -limit => 10 },
    { limit => { value => 10 } },

    'LIMIT: @V',
    { -limit => [10] },
    qr/SCALAR/
);

test_filters(
    'UNARY OPERATOR: script',
    'SCRIPT: V',
    { -script => 'v' },
    { script => { script => 'v' } },

    'SCRIPT: %V',
    {   -script => {
            script => 'script',
            lang   => 'lang',
            params => { foo => 'bar' }
        }
    },
    {   script => {
            script => 'script',
            lang   => 'lang',
            params => { foo => 'bar' }
        }
    },

    'SCRIPT: @V',
    { -script => ['v'] },
    qr/HASHREF, SCALAR/

);

test_filters(
    'UNARY OPERATOR: type, not_type',
    'TYPE: foo',
    { -type => 'foo' },
    { type => { value => 'foo' } },

    'TYPE: @foo',
    { -type => [ 'foo', 'bar' ] },
    {   or => [
            { type => { value => 'foo' } }, { type => { value => 'bar' } }
        ]
    },

    'TYPE: UNDEF',
    { -type => undef },
    qr/ ARRAYREF, SCALAR/,

    'NOT_TYPE: foo',
    { -not_type => 'foo' },
    { not => { filter => { type => { value => 'foo' } } } },

    'NOT_TYPE: @foo',
    { -not_type => [ 'foo', 'bar' ] },
    {   not => {
            filter => {
                or => [
                    { type => { value => 'foo' } },
                    { type => { value => 'bar' } }
                ]
            }
        }
    },
);

test_filters(
    'UNARY OPERATOR: -indices',

    '-indices: V',
    { -indices => 'V' },
    qr/HASHREF/,

    '-indices: {}',
    { -indices => { indices => 'foo', filter => { foo => 1 } } },
    { indices => { indices => ['foo'], filter => { term => { foo => 1 } } } },

    '-indices: {""}',
    {   -indices => {
            indices         => 'foo',
            filter          => { foo => 1 },
            no_match_filter => ''
        }
    },
    { indices => { indices => ['foo'], filter => { term => { foo => 1 } } } },

    '-indices: {none}',
    {   -indices => {
            indices         => 'foo',
            filter          => { foo => 1 },
            no_match_filter => 'none'
        }
    },
    {   indices => {
            indices         => ['foo'],
            filter          => { term => { foo => 1 } },
            no_match_filter => 'none'
        }
    },

    '-indices: {all}',
    {   -indices => {
            indices         => 'foo',
            filter          => { foo => 1 },
            no_match_filter => 'all'
        }
    },
    {   indices => {
            indices         => ['foo'],
            filter          => { term => { foo => 1 } },
            no_match_filter => 'all'
        }
    },

    '-indices: {filter}',
    {   -indices => {
            indices         => 'foo',
            filter          => { foo => 1 },
            no_match_filter => { foo => 2 }
        }
    },
    {   indices => {
            indices         => ['foo'],
            filter          => { term => { foo => 1 } },
            no_match_filter => { term => { foo => 2 } }
        }
    },
);

test_filters(
    'UNARY OPERATOR: ids, not_ids',
    'IDS: 1',
    { -ids => 1 },
    { ids => { values => [1] } },

    'IDS: [1]',
    { -ids => [1] },
    { ids => { values => [1] } },

    'IDS: {V:1,T:foo}',
    { -ids => { values => 1,     type   => 'foo' } },
    { ids  => { type   => 'foo', values => [1] } },

    'IDS: {V:[1],T:[foo]}',
    { -ids => { values => [1],     type   => ['foo'] } },
    { ids  => { type   => ['foo'], values => [1] } },

    'NOT_IDS: 1',
    { -not_ids => 1 },
    { not => { filter => { ids => { values => [1] } } } },

    'NOT_IDS: [1]',
    { -not_ids => [1] },
    { not => { filter => { ids => { values => [1] } } } },

    'NOT_IDS: {V:1,T:foo}',
    { -not_ids => { values => 1, type => 'foo' } },
    { not => { filter => { ids => { type => 'foo', values => [1] } } } },

    'NOT_IDS: {V:[1],T:[foo]}',
    { -not_ids => { values => [1], type => ['foo'] } },
    { not => { filter => { ids => { type => ['foo'], values => [1] } } } },

);

test_filters(
    'UNARY OPERATOR: has_parent, not_has_parent',

    'HAS_PARENT: V',
    { -has_parent => 'V' },
    qr/HASHREF/,

    'HAS_PARENT: %V',
    {   -has_parent =>
            { query => { foo => 'bar' }, type => 'foo', _scope => 'scope' }
    },
    {   has_parent => {
            query  => { match => { foo => 'bar' } },
            _scope => 'scope',
            type   => 'foo'
        }
    },

    'NOT_HAS_PARENT: %V',
    {   -not_has_parent =>
            { query => { foo => 'bar' }, type => 'foo', _scope => 'scope' }
    },
    {   not => {
            filter => {
                has_parent => {
                    query  => { match => { foo => 'bar' } },
                    _scope => 'scope',
                    type   => 'foo'
                }
            }
        }
    },

);

test_filters(
    'UNARY OPERATOR: has_child, not_has_child',

    'HAS_CHILD: V',
    { -has_child => 'V' },
    qr/HASHREF/,

    'HAS_CHILD: %V',
    {   -has_child =>
            { query => { foo => 'bar' }, type => 'foo', _scope => 'scope' }
    },
    {   has_child => {
            query  => { match => { foo => 'bar' } },
            _scope => 'scope',
            type   => 'foo'
        }
    },

    'NOT_HAS_CHILD: %V',
    {   -not_has_child =>
            { query => { foo => 'bar' }, type => 'foo', _scope => 'scope' }
    },
    {   not => {
            filter => {
                has_child => {
                    query  => { match => { foo => 'bar' } },
                    _scope => 'scope',
                    type   => 'foo'
                }
            }
        }
    },

);

test_filters(
    'UNARY OPERATOR: query, not_query',
    'QUERY: {}',
    { -query => { k => 'v' } },
    { query => { match => { k => 'v' } } },

    'NOT_QUERY: {}',
    { -not_query => { k => 'v' } },
    { not => { filter => { query => { match => { k => 'v' } } } } },

);

test_filters(
    'UNARY OPERATOR: cache, nocache',

    'CACHE: {}',
    { -cache => { k => 'v' } },
    { term => { _cache => 1, k => 'v' } },

    'NOCACHE: {}',
    { -nocache => { k => 'v' } },
    { term => { _cache => 0, k => 'v' } },

    'CACHE: []',
    { -cache => [ k => 'v' ] },
    { term => { _cache => 1, k => 'v' } },

    'NOCACHE: []',
    { -nocache => [ k => 'v' ] },
    { term => { _cache => 0, k => 'v' } },

    'CACHE WITH RANGES',
    { -cache => { k => { 'gt' => 5, 'lt' => 10 } } },
    { range => { _cache => 1, k => { gt => 5, lt => 10 } } },

    'RANGES WITH CACHE',
    { k => { gt => 5 }, -cache => { k => { lt => 10 } } },
    {   and => bag(
            { range => { _cache => 1, k => { lt => 10 } } },
            { range => { k => { gt => 5 } } }
        )
    },

    'CACHE WITH QUERY',
    { -cache => { -query => { k => 'v' } } },
    { fquery => { _cache => 1, query => { match => { k => 'v' } } } },

    'CACHE WITH AND',
    { -cache => { foo => 1, bar => 2 } },
    {   and => {
            _cache => 1,
            filters =>
                bag( { term => { bar => 2 } }, { term => { foo => 1 } } )
        }
    },

    'CACHE WITH OR',
    { -cache => [ foo => 1, bar => 2 ] },
    {   or => {
            _cache  => 1,
            filters => [ { term => { foo => 1 } }, { term => { bar => 2 } } ]
        }
    },

    'NOT_CACHE',
    { -not_cache => {} },
    qr/Invalid op 'not_cache'/,

    'NOT_NOCACHE',
    { -not_nocache => {} },
    qr/Invalid op 'not_nocache'/,

);

test_filters(
    'UNARY OPERATOR: -cache_key',
    '-cache_key: V',
    { -cache_key => 'V' },
    qr/HASHREF|ARRAYREF/,

    '-cache_key: {}',
    {   -cache_key => {
            foo => { a => 1 },
            bar => { b => 1 }
        }
    },
    {   and => bag(
            { term => { _cache_key => 'bar', b => 1 } },
            { term => { _cache_key => 'foo', a => 1 } }
        )
    },

    '-cache_key: []',
    {   -cache_key => [
            foo => { a => 1 },
            bar => { b => 1 }
        ]
    },
    {   or => [
            { term => { _cache_key => 'foo', a => 1 } },
            { term => { _cache_key => 'bar', b => 1 } }
        ]
    },

);

test_filters(
    'UNARY OPERATOR: -nested -not_nested',

    '-nested: V',
    { -nested => 'V' },
    qr/HASHREF/,

    '-nested: %V',
    {   -nested => {
            path   => 'foo',
            filter => { foo => 'bar' },
            _cache => 1,
            _name  => 'name'
        }
    },
    {   nested => {
            path   => 'foo',
            filter => { term => { foo => 'bar' } },
            _cache => 1,
            _name  => 'name',
        }
    },

    '-not_nested: %V',
    {   -not_nested => {
            path   => 'foo',
            filter => { foo => 'bar' },
            _cache => 1,
            _name  => 'name'
        }
    },
    {   not => {
            filter => {
                nested => {
                    path   => 'foo',
                    filter => { term => { foo => 'bar' } },
                    _cache => 1,
                    _name  => 'name',
                }
                }

        }
    },

);

done_testing();

#===================================
sub test_filters {
#===================================
    note "\n" . shift();
    while (@_) {
        my $name = shift;
        my $in   = shift;
        my $out  = shift;
        if ( ref $out eq 'Regexp' ) {
            throws_ok { $a->filter($in) } $out, $name;
            next;
        }

        my $got = $a->filter($in);
        my $expect = { filter => $out };
        my ( $ok, $stack ) = cmp_details( $got, $expect );

        if ($ok) {
            pass $name;
            next;
        }

        fail($name);

        note("Got:");
        note( pp($got) );
        note("Expected:");
        note( pp($expect) );

        diag( deep_diag($stack) );

    }
}
