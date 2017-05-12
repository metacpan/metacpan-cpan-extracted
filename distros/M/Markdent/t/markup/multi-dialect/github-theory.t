use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<'EOF';
  [Table caption]
| th1          | th2          |
+--------------+--------------+
| under_score  | foo_bar_baz  |
| b3           | b4           |
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
                            text => 'under_score',
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
                            text => 'foo_bar_baz',
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
        { dialects => [ 'GitHub', 'Theory' ] },
        $text,
        $expect,
        'simple table with header and two body rows'
    );
}

done_testing();
