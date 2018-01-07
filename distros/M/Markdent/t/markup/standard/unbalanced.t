use strict;
use warnings;

use Test2::V0;

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<'EOF';
**strong with *good* em*
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => '**strong with ',
            },
            { type => 'emphasis' },
            [
                {
                    type => 'text',
                    text => 'good',
                },
            ], {
                type => 'text',
                text => " em*\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'bad strong containing good emphasis' );
}

{
    my $text = <<'EOF';
**bad strong with *good em*
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => '**bad strong with ',
            },
            { type => 'emphasis' },
            [
                {
                    type => 'text',
                    text => 'good em',
                },
            ], {
                type => 'text',
                text => "\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'bad strong start containing good emphasis' );
}

{
    my $text = <<'EOF';
**bad strong with ``bad code and *indirectly bad em*
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text =>
                    "**bad strong with ``bad code and *indirectly bad em*\n",
            },
        ],
    ];

    parse_ok(
        $text, $expect,
        'bad strong and code start containing good emphasis'
    );
}

{
    my $text = <<'EOF';
**bad strong with *good em* and ``bad code
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => '**bad strong with ',
            },
            { type => 'emphasis' },
            [
                {
                    type => 'text',
                    text => 'good em',
                },
            ], {
                type => 'text',
                text => " and ``bad code\n",
            },
        ],
    ];

    parse_ok(
        $text, $expect,
        'bad strong start, good emphasis, then bad code start'
    );
}

{
    my $text = <<'EOF';
**bad strong with *good em and ``good code``*
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => '**bad strong with ',
            },
            { type => 'emphasis' },
            [
                {
                    type => 'text',
                    text => 'good em and ',
                },
                { type => 'code' },
                [
                    {
                        type => 'text',
                        text => 'good code',
                    },
                ],
            ], {
                type => 'text',
                text => "\n",
            },
        ],
    ];

    parse_ok(
        $text, $expect,
        'bad strong start, good emphasis containing good code'
    );
}

{
    my $text = <<'EOF';
**bad strong with *good ``em and good* code``**
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => '**bad strong with ',
            },
            { type => 'emphasis' },
            [
                {
                    type => 'text',
                    text => 'good ',
                },
                { type => 'code' },
                [
                    {
                        type => 'text',
                        text => 'em and good* code',
                    },
                ],
            ], {
                type => 'text',
                text => "*\n",
            },
        ],
    ];

    parse_ok(
        $text, $expect,
        'bad strong start, good emphasis and good code'
    );
}

{
    my $text = <<'EOF';
Some <em><span class="foo">unbalanced</em></span> html.
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some ',
            }, {
                type       => 'start_html_tag',
                tag        => 'em',
                attributes => {},
            },
            [
                {
                    type       => 'start_html_tag',
                    tag        => 'span',
                    attributes => { class => 'foo' },
                },
                [
                    {
                        type => 'text',
                        text => 'unbalanced',
                    },
                ],
            ], {
                type => 'text',
                text => " html.\n",
            },
        ],
    ];

    parse_ok(
        $text, $expect,
        'unbalanced inline html tags are not detected'
    );
}

done_testing();
