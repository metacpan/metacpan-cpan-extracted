#!perl
use strict;
use warnings;

use Test::More tests => 11;

use HBase::JSONRest;
use HBase::JSONRest::Scanner;

# 1. simple get (no column spec, no version spec)
ok(
    HBase::JSONRest::_build_get_uri({
        'table' => 'my_table',
        'where' => {
                   'key_equals' => 1234567890
        },
    })->[0]->{url} eq q|/my_table/1234567890|
    ,
    q|Test simple get|
);

# 2. get with versions
ok(
    HBase::JSONRest::_build_get_uri({
        'table' => 'my_table',
        'where' => {
            'key_equals' => 1234567890
        },
        'versions' => 100,
    })->[0]->{url} eq q|/my_table/1234567890?v=100|
    ,
    q|Test versions|
);

# 3. get, specify columns, no versions (defaults to last version)
ok(
    HBase::JSONRest::_build_get_uri({
        'table' => 'my_table',
        'where' => {
            'key_equals' => 1234567890
        },
        'columns' => [
            'd:some_column_name',
            'd:some_other_column_name'
        ]
    })->[0]->{url} eq q|/my_table/1234567890/d%3Asome_column_name,d%3Asome_other_column_name|
    ,
    q|Test columns|
);

# 4. get with versions and columns
ok(
    HBase::JSONRest::_build_get_uri({
        'table' => 'my_table',
        'where' => {
            'key_equals' => 1234567890
        },
        'versions' => 100,
        'columns' => [
            'd:some_column_name',
            'd:some_other_column_name'
        ]
    })->[0]->{url} eq q|/my_table/1234567890/d%3Asome_column_name,d%3Asome_other_column_name?v=100|
    ,
    q|Test versions and columns|
);

# 5. get: columns, versions, timestamp range
ok(
    HBase::JSONRest::_build_get_uri({
        'table' => 'my_table',
        'where' => {
            'key_equals' => 1234567890
        },
        'versions' => 100,
        'columns' => [
            'd:some_column_name',
            'd:some_other_column_name'
        ],
        timestamp_range => {
            from  => 1415000000000,
            until => 1415300000000,
        }
    })->[0]->{url} eq q|/my_table/1234567890/d%3Asome_column_name,d%3Asome_other_column_name/1415000000000,1415300000000?v=100|
    ,
    q|Test versions, columns and timestamp range|
); 

# 6. get: timestamp range specified without columns
ok(
    HBase::JSONRest::_build_get_uri({
        'table' => 'my_table',
        'where' => {
            'key_equals' => 1234567890
        },
        'versions' => 100,
        timestamp_range => {
            from  => 1415000000000,
            until => 1415300000000,
        }
    })->[0]->{url} eq q|/my_table/1234567890?v=100|
    ,
    q|Test timestamp range without columns specified|
);

# 7. multiget: simple (no version spec)
ok(
    HBase::JSONRest::_build_multiget_uri({
        'table' => 'my_table',
        'where' => {
            'key_in' => [
                '12;34567890',
                1234567891,
                1234567892,
                '12345678;93',
                1234567894,
            ]
        },
    })->[0]->{url} eq q|/my_table/multiget?row=12%3B34567890&row=1234567891&row=1234567892&row=12345678%3B93&row=1234567894|
    ,
    q|Test simple multiget|
);

# 8. multiget: version spec
ok(
    HBase::JSONRest::_build_multiget_uri({
        'table' => 'my_table',
        'where' => {
            'key_in' => [
                1234567890,
                1234567891,
                1234567892,
                1234567893,
                1234567894,
            ]
        },
        'versions' => 3,
    })->[0]->{url} eq
    q|/my_table/multiget?row=1234567890&row=1234567891&row=1234567892&row=1234567893&row=1234567894&v=3|
    ,
    q|Test multiget with versions|
);

# 9. scan: start row
ok(
    HBase::JSONRest::Scanner::_build_scan_uri({
        'limit' => 1000,
        'startrow' => '12345;2014-12-19;15;100587301;0;83547926;0;0',
        'table' => 'my_namespace:my_table',
    }) eq q|/my_namespace%3Amy_table/*?startrow=12345%3B2014-12-19%3B15%3B100587301%3B0%3B83547926%3B0%3B0&limit=1000|
    ,
    q|Test startrow scan|
);

# 10. multiget: long keys
is_deeply(
    [
        map { $_->{url} }
        @{ HBase::JSONRest::_build_multiget_uri({
            'table' => 'my_table',
            'where' => {
                'key_in' => [
                    1 x 1600,
                    2 x 1600,
                    3 x 800,
                    4 x 800,
                    5 x 800,
                ]
            },
        }) }
    ],
    [
        '/my_table/multiget?row=' . ( 1 x 1600 ),
        '/my_table/multiget?row=' . ( 2 x 1600 ),
        '/my_table/multiget?row=' . ( 3 x 800 ) . '&row=' . (4 x 800),
        '/my_table/multiget?row=' . ( 5 x 800 ),
    ],
    q|Test multiget with long ids|
);

# 11. get with long columns names
is_deeply(
    [
        map { $_->{url} }
        @{ HBase::JSONRest::_build_get_uri({
            'table' => 'my_table',
            'where' => {
                'key_equals' => 1234567890
            },
            'columns' => [
                1 x 1000,
                2 x 1000,
                3 x 500,
                4 x 500,
                5 x 500,
            ]
        }) }
    ],
    [
        '/my_table/1234567890/' . ( 1 x 1000 ),
        '/my_table/1234567890/' . ( 2 x 1000 ),
        '/my_table/1234567890/' . ( 3 x 500 ) . ',' . (4 x 500),
        '/my_table/1234567890/' . ( 5 x 500 ),
    ],
    q|Test get with long columns names|
);
