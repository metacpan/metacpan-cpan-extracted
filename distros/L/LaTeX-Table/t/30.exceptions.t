use Test::More tests => 35;
use Test::NoWarnings;

use LaTeX::Table;
use English qw( -no_match_vars );

my $table = LaTeX::Table->new();

# font family test 1
eval { $table->_add_font_family( { value => 'test' }, 'test' ) };
ok( $EVAL_ERROR, 'unknown font family' );

#font family test 2
eval { $table->_add_font_family( { value => 'test' }, 'bf' ) };
ok( !$EVAL_ERROR, 'known font family' );

# callback test 1
my $header = [ [ 'a', 'b' ] ];
my $data   = [ [ '1', '2' ] ];

eval {
    $table = LaTeX::Table->new(
        {   header   => $header,
            data     => $data,
            callback => [],
        }
    );
};
like(
    $EVAL_ERROR,
    qr{Attribute \(callback\)},
    'callback not a code reference'
) || diag $EVAL_ERROR;

# callback test 2
$table->set_callback( sub { return 'a'; } );

eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no error with valid callback' ) || diag $EVAL_ERROR;

# xentrystretch test 1
eval {
$table = LaTeX::Table->new(
    {   header        => $header,
        data          => $data,
        type          => 'xtab',
        xentrystretch => 'a',
    }
);
};

like(
    $EVAL_ERROR,
    qr{Attribute \(xentrystretch\)},
    'xentrystretch not a number'
) || diag $EVAL_ERROR;

# xentrystretch test 2
$table->set_xentrystretch(0.8);
eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no error with valid xentrystretch' ) || diag $EVAL_ERROR;

# theme test 1
# xentrystretch test 1
$table = LaTeX::Table->new(
    {   header => $header,
        data   => $data,
        theme  => 'Leipzig',
    }
);

eval { $table->generate_string; };
like(
    $EVAL_ERROR,
    qr{Invalid usage of option theme: Not known: Leipzig\.},
    'unknown theme'
) || diag $EVAL_ERROR;

$table->set_theme('Dresden');
eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no error with valid theme' ) || diag $EVAL_ERROR;

# size tests

eval {
    $table = LaTeX::Table->new(
        {   header   => $header,
            data     => $data,
            fontsize => 'HUGE',
        }
    );
};
like( $EVAL_ERROR, qr{^Attribute \(fontsize\)}, 'unknown size' )
    || diag $EVAL_ERROR;

eval { $table->set_fontsize('Huge'); };
ok( !$EVAL_ERROR, 'no error with valid size' ) || diag $EVAL_ERROR;

# header tests
eval { $table = LaTeX::Table->new( { header => 'A, B', data => $data, } ); };
like(
    $EVAL_ERROR,
    qr{Attribute \(header\)},
    'header is not an array reference'
) || diag $EVAL_ERROR;
eval { $table->set_header( [ 'A', 'B' ] ); };
like(
    $EVAL_ERROR,
    qr{Attribute \(header\)},
    'header[0] is not an array reference'
) || diag $EVAL_ERROR;

eval { $table->set_header( [ [ 'A', ['B'] ] ] ); };
like( $EVAL_ERROR, qr{Attribute \(header\)}, 'header[0][1] is not a scalar' )
    || diag $EVAL_ERROR;

# data tests
eval {
    $table = LaTeX::Table->new(
        {   header => $header,
            data   => { 'A' => 1, 'B' => 1 },
        }
    );
};
like( $EVAL_ERROR, qr{Attribute \(data\)}, 'data is not an array reference' )
    || diag $EVAL_ERROR;

eval { $table->set_data( [ [ 'A', 'B' ], { 'A' => 1, 'B' => 1 } ] ); };
like(
    $EVAL_ERROR,
    qr{Attribute \(data\)},
    'data[1] is not an array reference'
) || diag $EVAL_ERROR;

eval { $table->set_data( [ [ 'A', 'B' ], [ 'A', undef ] ] ); };
like( $EVAL_ERROR, qr{Attribute \(data\)}, 'undef value' )
    || diag $EVAL_ERROR;

$table->set_data($data);
eval { $table->set_coldef_strategy(1); };
like(
    $EVAL_ERROR,
    qr{Attribute \(coldef_strategy\)},
    'coldef_strategy not a hash'
) || diag $EVAL_ERROR;

eval { $table->set_coldef_strategy( [ 'a', 'b' ] ); };
like(
    $EVAL_ERROR,
    qr{Attribute \(coldef_strategy\)},
    'coldef_strategy not a hash'
) || diag $EVAL_ERROR;

$table->set_coldef_strategy( { URL => qr{ \A \s* http }xms, } );

eval { $table->generate_string; };
like(
    $EVAL_ERROR,
    qr{^Invalid usage of option coldef_strategy: Missing column attribute URL_COL for URL\.},
    'Missing column attribute URL_COL for URL.'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header            => $header,
        data              => $data,
        width_environment => 'tabularx',
    }
);

eval { $table->generate_string; };
like(
    $EVAL_ERROR,
    qr{Invalid usage of option width_environment: Is tabularx and width is unset\. },
    'unknown width environment'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header            => $header,
        data              => $data,
        width_environment => 'tabulary',
    }
);

eval { $table->generate_string; };
like(
    $EVAL_ERROR,
    qr{Invalid usage of option width_environment: Is tabulary and width is unset\. },
    'unknown width environment'
) || diag $EVAL_ERROR;

eval {
    $table = LaTeX::Table->new(
        {   header              => $header,
            data                => $data,
            columns_like_header => 2,
        }
    );
};
like(
    $EVAL_ERROR,
    qr{Attribute \(columns_like_header\)},
    'columns_like_header not an array reference'
) || diag $EVAL_ERROR;

eval {
    $table = LaTeX::Table->new(
        {   header              => $header,
            data                => $data,
            columns_like_header => { 1 => 2 },
        }
    );
};

like(
    $EVAL_ERROR,
    qr{Attribute \(columns_like_header\)},
    'columns_like_header not an array reference'
) || diag $EVAL_ERROR;

eval { $table = LaTeX::Table->new( { header => $header, data => $data, } ); };
ok( !$EVAL_ERROR, 'columns_like_header 0 is ok' ) || diag $EVAL_ERROR;

## resizebox

eval {
    $table = LaTeX::Table->new(
        {   header    => $header,
            data      => $data,
            resizebox => 2,
        }
    );
};
like(
    $EVAL_ERROR,
    qr{Attribute \(resizebox\)},
    'resizebox not an array reference'
) || diag $EVAL_ERROR;

eval {
    $table = LaTeX::Table->new(
        {   header    => $header,
            data      => $data,
            resizebox => { 1 => 2 },
        }
    );
};
like(
    $EVAL_ERROR,
    qr{Attribute \(resizebox\)},
    'resizebox not an array reference'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header => $header,
        data   => $data,
    }
);

eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no resizeboxis ok' ) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header      => $header,
        data        => $data,
        environment => 0,
        type        => 'xtab',
    }
);

eval { $table->generate_string; };

like(
    $EVAL_ERROR,
    qr{Invalid usage of option environment: xtab is non-floating and requires an environment\.},
    'xtab requires environment'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header      => $header,
        data        => $data,
        environment => 0,
        type        => 'longtable',
    }
);

eval { $table->generate_string; };

like(
    $EVAL_ERROR,
    qr{Invalid usage of option environment: longtable is non-floating and requires an environment\.},
    'longtable requires environment'
) || diag $EVAL_ERROR;
$table = LaTeX::Table->new(
    {   header   => $header,
        data     => $data,
        position => 'htb',
        type     => 'xtab',
    }
);

eval { $table->generate_string; };

like(
    $EVAL_ERROR,
    qr{Invalid usage of option position: xtab is non-floating and thus does not support position\.},
    'xtab/longtable does not support position'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header => $header,
        data   => $data,
        left   => 1,
        center => 1,
    }
);

eval { $table->generate_string; };

like(
    $EVAL_ERROR,
    qr{Invalid usage of option center, left, right},
    'only one allowed'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header       => $header,
        data         => $data,
        shortcaption => 'short',
        maincaption  => 'main',
    }
);

eval { $table->generate_string; };

like(
    $EVAL_ERROR,
    qr{Invalid usage of option maincaption, shortcaption},
    'only one allowed'
) || diag $EVAL_ERROR;

eval {
    $table = LaTeX::Table->new(
        {   header     => $header,
            data       => $data,
            fontfamily => 'Roman',
        }
    );
};

like( $EVAL_ERROR, qr{Attribute \(fontfamily\)}, 'wrong fontfamily' )
    || diag $EVAL_ERROR;

eval {
    $table = LaTeX::Table->new(
        {   header     => $header,
            data       => $data,
            fontfamily => 'rm',
        }
    );
};
ok( !$EVAL_ERROR, 'correct fontfamily' ) || diag $EVAL_ERROR;

