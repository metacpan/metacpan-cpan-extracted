use strict;
use warnings;

use Test2::V0;

use FindBin qw( $Bin );
use lib "$Bin/../../../t/lib";

use Test::Markdent;

{
    my $text = <<'EOF';
Some random stuff.

Another paragraph.

EOF

    $text .= "| a  | table | row  | goes  | here  |\n" for 1 .. 100;

    $text .= <<'EOF';

Some more random stuff.

Yet another paragraph.
EOF

    my @expect = (
        { 'type' => 'paragraph' },
        [
            {
                'text' => "Some random stuff.\n",
                'type' => 'text'
            }
        ],
        { 'type' => 'paragraph' },
        [
            {
                'text' => "Another paragraph.\n",
                'type' => 'text'
            }
        ],
    );

    my @rows = (
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
                    'text' => 'table',
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
                    'text' => 'row',
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
                    'text' => 'goes',
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
                    'text' => 'here',
                    'type' => 'text'
                }
            ]
        ],
    ) x 100;

    push @expect,
        (
        { 'type' => 'table' },
        [
            { 'type' => 'table_body' },
            \@rows,
        ],
        );

    push @expect,
        (
        { 'type' => 'paragraph' },
        [
            {
                'text' => "Some more random stuff.\n",
                'type' => 'text'
            }
        ],
        { 'type' => 'paragraph' },
        [
            {
                'text' => "Yet another paragraph.\n",
                'type' => 'text'
            }
        ]
        );

    parse_ok(
        { dialects => 'Theory' },
        $text,
        \@expect,
        'very large table to test performance'
    );
}

done_testing();
