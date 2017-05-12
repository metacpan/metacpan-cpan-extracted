use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<'EOF';
  [Table caption]
| th1 | th2 |
+-----+-----+
| b1  | b2  |
| b3  | b4  |
EOF

    my $expect = [
        {
            type    => 'table',
            caption => 'Table caption',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th2',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b3',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'simple table with header and two body rows'
    );
}

{
    my $text = <<'EOF';
| th1 | th2 |
+=====+=====+
| b1  | b2  |
| b3  | b4  |
EOF

    my $expect = [
        {
            type => 'table',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th2',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b3',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'simple table with header and two body rows, header uses +===+'
    );
}

{
    my $text = <<'EOF';
+-----+-----+
| th1 | th2 |
+-----+-----+
| b1  | b2  |
| b3  | b4  |
+-----+-----+
EOF

    my $expect = [
        {
            type => 'table',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th2',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b3',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'simple MySQL-style table (header marker at start and end of table)'
    );
}

{
    my $text = <<'EOF';
| b1  | b2  |
| b3  | b4  |
EOF

    my $expect = [
        {
            type => 'table',
        },
        [
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b3',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'simple table with no header'
    );
}

{
    my $text = <<'EOF';
| th1 | th2 |
+-----+-----+
| b1  | b2  |
| b3  | b4  |
  [Table caption]
EOF

    my $expect = [
        {
            type    => 'table',
            caption => 'Table caption',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th2',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b3',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'simple table with header and two body rows - caption on the bottom'
    );
}

{
    my $text = <<'EOF';
  [Table caption]
|   th1 |   th2 |
+-------+-------+
| b1 | b2 |
| b3 | b4 |
EOF

    my $expect = [
        {
            type    => 'table',
            caption => 'Table caption',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'right',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'right',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th2',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'right',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'right',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'right',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b3',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'right',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'simple table with header and two body rows, all right-aligned'
    );
}

{
    my $text = <<'EOF';
  [Table caption]
| th1   | th2   |
+-------+-------+
| th1-1 | th2-1 |
+-------+-------+
| b1 | b2 |
| b3 | b4 |
EOF

    my $expect = [
        {
            type    => 'table',
            caption => 'Table caption',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th2',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1-1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th2-1',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b3',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'simple table with two header rows and two body rows'
    );
}

{
    my $text = <<'EOF';
 th1   | th2   | th3
-------+-------+-----
 b1    | b2    | b3
 b4    | b5    | b6
EOF

    my $expect = [
        {
            type => 'table',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th2',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th3',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b3',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b5',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b6',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'three cells across, no leading/trailing pipes or pluses'
    );
}

{
    my $text = <<'EOF';
 th1   | th2   | th3
-------+-------+-----
 b1    | b2    | b3

 b4    | b5    | b6
EOF

    my $expect = [
        {
            type => 'table',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th2',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th3',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b3',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b5',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b6',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'three cells across, two table bodies'
    );
}

{
    my $text = <<'EOF';
 th1          || th3
-------+-------+-----
 b1    | b2         ||
 b4                |||
EOF

    my $expect = [
        {
            type => 'table',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 2,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th3',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 2,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 3,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'three cells across, each row has some >1 colspan cells'
    );
}

{
    my $text = <<'EOF';
 th1          || th3
-------+-------+-----
 b1    | b2         ||
 b4                |||
EOF

    my $expect = [
        {
            type => 'table',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 2,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th3',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 2,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 3,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'three cells across, each row has some >1 colspan cells'
    );
}

{
    my $text = <<'EOF';
| th1 | th2 |
+-----+-----+
| b\| | b2  |
| b3  | b4  |
EOF

    my $expect = [
        {
            type => 'table',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th2',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b|',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b3',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'simple table with escaped pipe in cell'
    );
}

{
    my $text = <<'EOF';
| th1         | th2 |
+-------------+-----+
| b1          | b2  |
: continues\: :     :
: here        :     :
| b3          | b4  |
EOF

    my $expect = [
        {
            type => 'table',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th2',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        { type => 'paragraph' },
                        [
                            {
                                type => 'text',
                                text => "b1\ncontinues:\nhere\n",
                            },
                        ]
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b3',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'simple table with continuation lines'
    );
}

{
    my $text = <<'EOF';
| th1         | th2 |
+-------------+-----+
| * list           ||
: * l2             ::
: * l3             ::
EOF

    my $expect = [
        {
            type => 'table',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th2',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 2,
                        is_header_cell => 0,
                    },
                    [
                        { type => 'unordered_list' },
                        [
                            {
                                type   => 'list_item',
                                bullet => '*',
                            },
                            [
                                {
                                    type => 'text',
                                    text => "list\n",
                                }
                            ], {
                                type   => 'list_item',
                                bullet => '*',
                            },
                            [
                                {
                                    type => 'text',
                                    text => "l2\n",
                                }
                            ], {
                                type   => 'list_item',
                                bullet => '*',
                            },
                            [
                                {
                                    type => 'text',
                                    text => "l3\n",
                                }
                            ],
                        ],
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'table with a list inside a cell'
    );
}

{
    my $text = <<'EOF';
  [Table caption]
|     | th2 |
+-----+-----+
| b1  | b2  |
| b3  | b4  |
EOF

    my $expect = [
        {
            type    => 'table',
            caption => 'Table caption',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    }, {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'th2',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b2',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b3',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'b4',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'simple table with empty first header cell, so first col is header cells'
    );
}

{
    my $text = <<'EOF';
| Header 1 and 2     || Nothing  |
+--------------------++----------+
| Header 1 | Header 2 | Header 3 |
+----------+----------+----------+
| B1       | B2       | B3       |
EOF

    my $expect = [
        {
            type => 'table',
        },
        [
            {
                type => 'table_header',
            },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 2,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'Header 1 and 2',
                        }
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'Nothing',
                        },
                    ],
                ],
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'Header 1',
                        }
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'Header 2',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 1,
                    },
                    [
                        {
                            type => 'text',
                            text => 'Header 3',
                        },
                    ],
                ],
            ],
            { type => 'table_body' },
            [
                { type => 'table_row' },
                [
                    {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'B1',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'B2',
                        },
                    ], {
                        type           => 'table_cell',
                        alignment      => 'left',
                        colspan        => 1,
                        is_header_cell => 0,
                    },
                    [
                        {
                            type => 'text',
                            text => 'B3',
                        },
                    ],
                ],
            ],
        ],
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'first header row should have 3 columns'
    );
}

{
    my $text = <<'EOF';
[Not a caption]

[Also not]

Some text
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                text => "[Not a caption]\n",
                type => 'text'
            }
        ],
        { type => 'paragraph' },
        [
            {
                text => "[Also not]\n",
                type => 'text'
            }
        ],
        { type => 'paragraph' },
        [
            {
                text => "Some text\n",
                type => 'text'
            }
        ]
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'Parser should not parse [foo] as a table caption if there is no table'
    );
}

{

    # This markup is insane, but we don't want to die or warn on this sort of
    # thing. This will generate some sort of output, though it won't make much
    # sense when rendered as HTML.
    my $text = <<'EOF';
| a | real | table |
 | Foo * bar
* : foo: bar
EOF

    my $expect = [
        { 'type' => 'table' },
        [
            { 'type' => 'table_body' },
            [
                { 'type' => 'table_row' },
                [
                    {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'a',
                            'type' => 'text'
                        }
                    ], {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'real',
                            'type' => 'text'
                        }
                    ], {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'table',
                            'type' => 'text'
                        }
                    ]
                ],
                { 'type' => 'table_row' },
                [
                    {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        { 'type' => 'paragraph' },
                        [
                            {
                                'text' => "*\n",
                                'type' => 'text'
                            }
                        ]
                    ], {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        { 'type' => 'paragraph' },
                        [
                            {
                                'text' => "Foo * bar\nfoo\n",
                                'type' => 'text'
                            }
                        ]
                    ], {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        { 'type' => 'paragraph' },
                        [
                            {
                                'text' => "bar\n",
                                'type' => 'text'
                            }
                        ]
                    ]
                ]
            ]
        ]
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'Totally pathological table at least generates some output and does not die or warn'
    );
}

{
    my $text = <<"EOF";
|Foo|\tBar|
EOF

    my $expect = [
        { 'type' => 'table' },
        [
            { 'type' => 'table_body' },
            [
                { 'type' => 'table_row' },
                [
                    {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'Foo',
                            'type' => 'text'
                        }
                    ], {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'Bar',
                            'type' => 'text'
                        }
                    ]
                ]
            ]
        ]
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'Handle tabs in a table cell without going into an endless loop'
    );
}

{
    my $text = <<'EOF';
A Theory-style table

  [Table caption]
| Header 1 and 2     || Nothing  |
+--------------------++----------+
| Header 1 | Header 2 | Header 3 |
+----------+----------+----------+
| B1       | B2       | B3       |
|    right |  center  |          |

| l1       | x        | x        |
: l2       :          :          :
: l3       :          :          :
| end                          |||
EOF

    my $expect = [
        { 'type' => 'paragraph' },
        [
            {
                'type' => 'text',
                'text' => "A Theory-style table\n",
            },
        ], {
            'caption' => 'Table caption',
            'type'    => 'table'
        },
        [
            { 'type' => 'table_header' },
            [
                { 'type' => 'table_row' },
                [
                    {
                        'is_header_cell' => 1,
                        'colspan'        => 2,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'Header 1 and 2',
                            'type' => 'text'
                        }
                    ], {
                        'is_header_cell' => 1,
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'Nothing',
                            'type' => 'text'
                        }
                    ]
                ],
                { 'type' => 'table_row' },
                [
                    {
                        'is_header_cell' => 1,
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'Header 1',
                            'type' => 'text'
                        }
                    ], {
                        'is_header_cell' => 1,
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'Header 2',
                            'type' => 'text'
                        }
                    ], {
                        'is_header_cell' => 1,
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'Header 3',
                            'type' => 'text'
                        }
                    ]
                ]
            ],
            { 'type' => 'table_body' },
            [
                { 'type' => 'table_row' },
                [
                    {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'B1',
                            'type' => 'text'
                        }
                    ], {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'B2',
                            'type' => 'text'
                        }
                    ], {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'B3',
                            'type' => 'text'
                        }
                    ]
                ],
                { 'type' => 'table_row' },
                [
                    {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'right',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'right',
                            'type' => 'text'
                        }
                    ], {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'center',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'center',
                            'type' => 'text'
                        }
                    ], {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    }
                ]
            ],
            { 'type' => 'table_body' },
            [
                { 'type' => 'table_row' },
                [
                    {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        { 'type' => 'paragraph' },
                        [
                            {
                                'text' => "l1\nl2\nl3\n",
                                'type' => 'text'
                            }
                        ]
                    ], {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'x',
                            'type' => 'text'
                        }
                    ], {
                        'is_header_cell' => '0',
                        'colspan'        => 1,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'x',
                            'type' => 'text'
                        }
                    ]
                ],
                { 'type' => 'table_row' },
                [
                    {
                        'is_header_cell' => '0',
                        'colspan'        => 3,
                        'alignment'      => 'left',
                        'type'           => 'table_cell'
                    },
                    [
                        {
                            'text' => 'end',
                            'type' => 'text'
                        }
                    ]
                ]
            ]
        ]
    ];

    parse_ok(
        { dialects => 'Theory' },
        $text,
        $expect,
        'complex table preceded by paragraph that broke with new regex'
    );
}

done_testing();
