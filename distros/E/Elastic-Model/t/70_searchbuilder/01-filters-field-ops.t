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
    'SCALAR',

    'V',
    'v',
    { term => { _all => 'v' } },

    '\\V',
    \'v',
    'v',

);

test_filters(
    'KEY-VALUE PAIRS',

    'K: V',
    { k    => 'v' },
    { term => { k => 'v' } },

    'K: UNDEF',
    { k       => undef },
    { missing => { field => 'k' } },

    'K: \\V',
    { k => \'v' },
    { k => 'v' },

    'K: []',
    { k       => [] },
    { missing => { field => 'k' } },

    'K: [V]',
    { k    => ['v'] },
    { term => { k => 'v' } },

    'K: [V,V]',
    { k => [ 'v', 'v' ] },
    { terms => { k => [ 'v', 'v' ] } },

    'K: [UNDEF]',
    { k       => [undef] },
    { missing => { field => 'k' } },

    'K: [V,UNDEF]',
    { k  => [ 'v', undef ] },
    { or => [
            { term    => { k     => 'v' } },
            { missing => { field => 'k' } },
        ]
    },

    'K: [-and,V,UNDEF]',
    { k => [ '-and', 'v', undef ] },
    {   and =>
            bag( { missing => { field => 'k' } }, { term => { k => 'v' } }, )
    },

);

for my $op (qw(= term terms)) {
    test_filters(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k    => { $op => 'v' } },
        { term => { k   => 'v' } },

        "K: $op UNDEF",
        { k       => { $op   => undef } },
        { missing => { field => 'k' } },

        "K: $op [V]",
        { k    => { $op => ['v'] } },
        { term => { k   => 'v' } },

        "K: $op [V,V]",
        { k     => { $op => [ 'v', 'v' ] } },
        { terms => { k   => [ 'v', 'v' ] } },

        "K: $op [UNDEF]",
        { k       => { $op   => [undef] } },
        { missing => { field => 'k' } },

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        {   or => [
                { term => { k => 'v' } }, { missing => { field => 'k' } },
            ]
        },

        'K: = [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        {   or => [
                { term    => { k     => '-and' } },
                { term    => { k     => 'v' } },
                { missing => { field => 'k' } },
            ]
        },

        'K: {VV,ex}',
        { k => { $op => { value => [ 1, 2 ], execution => 'bool' } } },
        {   terms => {
                k         => [ 1, 2 ],
                execution => 'bool'
            }
        },

        'K: {V,ex}',
        { k    => { $op => { value => [1], execution => 'bool' } } },
        { term => { k   => 1 } },
    );
}

for my $op (qw(!= <> not_term not_terms)) {
    test_filters(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        { not => { filter => { term => { k => 'v' } } } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        { not => { filter => { missing => { field => 'k' } } } },

        "K: $op [V]",
        { k => { $op => ['v'] } },
        { not => { filter => { term => { k => 'v' } } } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        { not => { filter => { terms => { k => [ 'v', 'v' ] } } } },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        { not => { filter => { missing => { field => 'k' } } } },

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        {   not => {
                filter => {
                    or => [
                        { term    => { k     => 'v' } },
                        { missing => { field => 'k' } },
                    ]
                }
            }
        },

        'K: = [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        {   not => {
                filter => {
                    or => [
                        { term    => { k     => '-and' } },
                        { term    => { k     => 'v' } },
                        { missing => { field => 'k' } },
                    ]
                }
            }
        },

    );
}

for my $op (qw(^ prefix)) {
    test_filters(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k      => { $op => 'v' } },
        { prefix => { k   => 'v' } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, SCALAR/,

        "K: $op [V]",
        { k      => { $op => ['v'] } },
        { prefix => { k   => 'v' } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        { or => [ { prefix => { k => 'v' } }, { prefix => { k => 'v' } } ] },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, SCALAR/,

        'K: = [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, SCALAR/,
    );
}

test_filters(
    "FIELD OPERATOR: not_prefix",

    "K: not_prefix V",
    { k   => { not_prefix => 'v' } },
    { not => { filter     => { prefix => { k => 'v' } } } },

    "K: not_prefix UNDEF",
    { k => { not_prefix => undef } },
    qr/ARRAYREF, SCALAR/,

    "K: not_prefix [V]",
    { k   => { not_prefix => ['v'] } },
    { not => { filter     => { prefix => { k => 'v' } } } },

    "K: not_prefix [V,V]",
    { k => { not_prefix => [ 'v', 'v' ] } },
    {   not => {
            filter => {
                or => [
                    { prefix => { k => 'v' } }, { prefix => { k => 'v' } }
                ]
            }
        }
    },

    "K: not_prefix [UNDEF]",
    { k => { not_prefix => [undef] } },
    qr/ARRAYREF, SCALAR/,

    "K: not_prefix [V,UNDEF]",
    { k => { not_prefix => [ 'v', undef ] } },
    qr/ARRAYREF, SCALAR/,

    'K: = [-and,V,UNDEF]',
    { k => { not_prefix => [ '-and', 'v', undef ] } },
    qr/ARRAYREF, SCALAR/,
);

my %range_map = (
    '<'  => 'lt',
    '<=' => 'lte',
    '>'  => 'gt',
    '>=' => 'gte'
);

for my $op (qw(< <= >= > gt gte lt lte)) {
    my ( $type, $es_op );

    if ( $es_op = $range_map{$op} ) {
        $type = 'numeric_range';
    }
    else {
        $type  = 'range';
        $es_op = $op;
    }

    test_filters(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        { $type => { k => { $es_op => 'v' } } },

        "K: $op UNDEF",
        { $type => { $op => undef } },
        qr/SCALAR/,

        "K: $op [V]",
        { k => { $op => ['v'] } },
        qr/SCALAR/,

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        qr/SCALAR/,

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/SCALAR/,

        'K: = [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/SCALAR/,

        'K[$op 5],K[$op 10]',
        { k => [ -and => { '>' => 5 }, { '>' => 10 } ] },
        qr/Duplicate/,
    );
}

test_filters(
    "COMBINED RANGE OPERATORS",

    "K: gt gte lt lte < <= > >= V",
    {   k => {
            gt   => 'v',
            gte  => 'v',
            lt   => 'v',
            lte  => 'v',
            '>'  => 'V',
            '>=' => 'V',
            '<'  => 'V',
            '<=' => 'V'
        }
    },
    {   and => bag( {
                numeric_range =>
                    { k => { gt => 'V', gte => 'V', lt => 'V', lte => 'V' } }
            },
            {   range =>
                    { k => { gt => 'v', gte => 'v', lt => 'v', lte => 'v' } }
            },
        )
    },

    "K: [gt gte lt lte < <= > >=] V",
    {   k => [
            { gt   => 'v' },
            { gte  => 'v' },
            { lt   => 'v' },
            { lte  => 'v' },
            { '>'  => 'V' },
            { '>=' => 'V' },
            { '<'  => 'V' },
            { '<=' => 'V' }
        ]
    },
    {   or => [
            { range         => { k => { gt  => "v" } } },
            { range         => { k => { gte => "v" } } },
            { range         => { k => { lt  => "v" } } },
            { range         => { k => { lte => "v" } } },
            { numeric_range => { k => { gt  => "V" } } },
            { numeric_range => { k => { gte => "V" } } },
            { numeric_range => { k => { lt  => "V" } } },
            { numeric_range => { k => { lte => "V" } } },
        ],
    },

);

test_filters(
    "FIELD OPERATORS: missing/exists",

    "K: exists 1",
    { k      => { exists => 1 } },
    { exists => { field  => 'k' } },

    "K: exists 0",
    { k       => { exists => 0 } },
    { missing => { field  => 'k' } },

    "K: exists UNDEF",
    { k       => { exists => undef } },
    { missing => { field  => 'k' } },

    "K: missing 1",
    { k       => { missing => 1 } },
    { missing => { field   => 'k' } },

    "K: missing 0",
    { k      => { missing => 0 } },
    { exists => { field   => 'k' } },

    "K: missing UNDEF",
    { k      => { missing => undef } },
    { exists => { field   => 'k' } },

    "K: not_missing HASH",
    { k => { missing => { null_value => 1, existence => 1 } } },
    { missing => { field => 'k', null_value => 1, existence => 1 } },

    "K: not_exists 1",
    { k       => { not_exists => 1 } },
    { missing => { field      => 'k' } },

    "K: not_exists 0",
    { k      => { not_exists => 0 } },
    { exists => { field      => 'k' } },

    "K: not_exists UNDEF",
    { k      => { not_exists => undef } },
    { exists => { field      => 'k' } },

    "K: not_missing 1",
    { k   => { not_missing => 1 } },
    { not => { filter      => { missing => { field => 'k' } } } },

    "K: not_missing 0",
    { k   => { not_missing => 0 } },
    { not => { filter      => { exists => { field => 'k' } } } },

    "K: not_missing UNDEF",
    { k   => { not_missing => undef } },
    { not => { filter      => { exists => { field => 'k' } } } },

    "K: not_missing HASH",
    { k => { not_missing => { null_value => 1, existence => 1 } } },
    {   not => {
            filter => {
                missing => { field => 'k', null_value => 1, existence => 1 }
            }
        }
    },

);

test_filters(
          "FIELD OPERATORS: geo_distance, geo_distance_range, "
        . "geo_bounding_box, geo_polygon",

    'K: geo_distance %V',
    {   k => {
            geo_distance => {
                location      => 'LAT,LON',
                distance      => '10km',
                normalize     => 0,
                optimize_bbox => 'indexed',
            }
        }
    },
    {   geo_distance => {
            k             => 'LAT,LON',
            distance      => '10km',
            normalize     => 0,
            optimize_bbox => 'indexed'
        }
    },

    'K: geo_distance FOO',
    { k => { geo_distance => 'FOO' } },
    qr/hashref/,

    'K: geo_distance_range %V',
    {   k => {
            geo_distance_range => {
                location      => 'LAT,LON',
                'gt'          => '10km',
                'lt'          => '10km',
                normalize     => 0,
                optimize_bbox => 'indexed',
            },
        }
    },
    {   geo_distance_range => {
            k             => 'LAT,LON',
            gt            => '10km',
            lt            => '10km',
            normalize     => 0,
            optimize_bbox => 'indexed',
        }
    },

    'K: geo_distance_range FOO',
    { k => { geo_distance => 'FOO' } },
    qr/hashref/,

    'K: geo_bbox %V',
    {   k => {
            geo_bbox => {
                top_left     => 'LAT,LON',
                bottom_right => 'LAT,LON',
                normalize    => 0,
                type         => 'indexed',
            },
        }
    },
    {   geo_bounding_box => {
            k => {
                bottom_right => 'LAT,LON',
                top_left     => 'LAT,LON',
                normalize    => 0,
                type         => 'indexed',
            }
        }
    },

    'K: geo_bbox FOO',
    { k => { geo_bbox => 'FOO' } },
    qr/hashref/,

    'K: geo_bounding_box %V',
    {   k => {
            geo_bounding_box => {
                top_left     => 'LAT,LON',
                bottom_right => 'LAT,LON',
                normalize    => 0,
                type         => 'indexed',
            },
        }
    },
    {   geo_bounding_box => {
            k => {
                bottom_right => 'LAT,LON',
                top_left     => 'LAT,LON',
                normalize    => 0,
                type         => 'indexed',
            }
        }
    },

    'K: geo_bounding_box FOO',
    { k => { geo_bounding_box => 'FOO' } },
    qr/hashref/,

    'K: geo_polygon @V',
    { k => { geo_polygon => [ 'LAT,LON', 'LAT,LON' ] } },
    { geo_polygon => { k => { points => [ 'LAT,LON', 'LAT,LON' ] } } },

    'K: geo_polygon {}',
    {   k => {
            geo_polygon =>
                { points => [ 'LAT,LON', 'LAT,LON' ], normalize => 0 }
        }
    },
    {   geo_polygon =>
            { k => { points => [ 'LAT,LON', 'LAT,LON' ], normalize => 0 } }
    },

    'K: geo_polygon FOO',
    { k => { geo_polygon => 'FOO' } },
    qr/ARRAYREF/,

);

test_filters(
          "FIELD OPERATORS: not_geo_distance, not_geo_distance_range, "
        . "not_geo_bounding_box, not_geo_polygon",

    'K: not_geo_distance %V',
    {   k => {
            not_geo_distance => {
                location      => 'LAT,LON',
                distance      => '10km',
                normalize     => 0,
                optimize_bbox => 'indexed',
            }
        }
    },
    {   not => {
            filter => {
                geo_distance => {
                    k             => 'LAT,LON',
                    distance      => '10km',
                    normalize     => 0,
                    optimize_bbox => 'indexed'
                }
            }
        }
    },

    'K: not_geo_distance_range %V',
    {   k => {
            not_geo_distance_range => {
                location      => 'LAT,LON',
                'gt'          => '10km',
                'lt'          => '10km',
                normalize     => 0,
                optimize_bbox => 'indexed'
            },
        }
    },
    {   not => {
            filter => {
                geo_distance_range => {
                    k             => 'LAT,LON',
                    gt            => '10km',
                    lt            => '10km',
                    normalize     => 0,
                    optimize_bbox => 'indexed'
                }
            }
        }
    },

    'K: not_geo_bounding_box %V',
    {   k => {
            not_geo_bounding_box => {
                top_left     => 'LAT,LON',
                bottom_right => 'LAT,LON',
                normalize    => 0,
                type         => 'indexed',
            },
        }
    },
    {   not => {
            filter => {
                geo_bounding_box => {
                    k => {
                        bottom_right => 'LAT,LON',
                        top_left     => 'LAT,LON',
                        normalize    => 0,
                        type         => 'indexed',
                    }
                }
            }
        }
    },

    'K: not_geo_polygon @V',
    { k => { not_geo_polygon => [ 'LAT,LON', 'LAT,LON' ] } },
    {   not => {
            filter => {
                geo_polygon => { k => { points => [ 'LAT,LON', 'LAT,LON' ] } }
            }
        }
    },

    'K: not_geo_polygon {}',
    {   k => {
            not_geo_polygon =>
                { points => [ 'LAT,LON', 'LAT,LON' ], normalize => 0 }
        }
    },
    {   not => {
            filter => {
                geo_polygon => {
                    k => {
                        points    => [ 'LAT,LON', 'LAT,LON' ],
                        normalize => 0
                    }
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
