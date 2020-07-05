use strict;
use warnings;

use Test2::V0;

use FindBin qw( $Bin );
use lib "$Bin/../../../t/lib";

use Test::Markdent;

{
    my $text = <<'EOF';
> blockquote
>
> * with list
> * more list
>
> back to blockquote
EOF

    my $expect = [
        { type => 'blockquote' },
        [
            { type => 'paragraph' },
            [
                {
                    type => 'text',
                    text => "blockquote\n",
                },
            ],
            { type => 'unordered_list' },
            [
                {
                    type   => 'list_item',
                    bullet => '*',
                },
                [
                    {
                        type => 'text',
                        text => "with list\n",
                    },
                ], {
                    type   => 'list_item',
                    bullet => '*',
                },
                [
                    {
                        type => 'text',
                        text => "more list\n",
                    },
                ],
            ],
            { type => 'paragraph' },
            [
                {
                    type => 'text',
                    text => "back to blockquote\n",
                },
            ],
        ],
    ];

    parse_ok( $text, $expect, 'blockquote contains a list' );
}

{
    my $text = <<'EOF';
> Email-style angle brackets
> are used for blockquotes.

> > And, they can be nested.

> #### Headers in blockquotes
> 
> * You can quote a list.
> * Etc.
EOF

    my $expect = [
        { type => 'blockquote' },
        [
            { type => 'paragraph' },
            [
                {
                    type => 'text',
                    text =>
                        "Email-style angle brackets\nare used for blockquotes.\n",
                },
            ],
            { type => 'blockquote' },
            [
                { type => 'paragraph' },
                [
                    {
                        type => 'text',
                        text => "And, they can be nested.\n",
                    },
                ],
            ], {
                type  => 'header',
                level => 4,
            },
            [
                {
                    type => 'text',
                    text => "Headers in blockquotes\n",
                },
            ],
            { type => 'unordered_list' },
            [
                {
                    type   => 'list_item',
                    bullet => '*',
                },
                [
                    {
                        type => 'text',
                        text => "You can quote a list.\n",
                    },
                ], {
                    type   => 'list_item',
                    bullet => '*',
                },
                [
                    {
                        type => 'text',
                        text => "Etc.\n",
                    },
                ],
            ],
        ],
    ];

    parse_ok(
        $text, $expect,
        'blockquote contains headers, blockquote and list (from Dingus examples)'
    );
}

{
    my $text = <<'EOF';
*   A list item with a blockquote:

    > This is a blockquote
    > inside a list item.

* And another list item
EOF

    my $expect = [
        { type => 'unordered_list' },
        [
            {
                type   => 'list_item',
                bullet => '*',
            },
            [
                { type => 'paragraph' },
                [
                    {
                        type => 'text',
                        text => "A list item with a blockquote:\n",
                    },
                ],
                { type => 'blockquote' },
                [
                    { type => 'paragraph' },
                    [
                        {
                            type => 'text',
                            text =>
                                "This is a blockquote\ninside a list item.\n",
                        },
                    ],
                ],
            ], {
                type   => 'list_item',
                bullet => '*',
            },
            [
                { type => 'paragraph' },
                [
                    {
                        type => 'text',
                        text => "And another list item\n",
                    },
                ],
            ],
        ]
    ];

    parse_ok( $text, $expect, 'list containing a blockquote' );
}

{
    my $text = <<'EOF';
*   A list item with a pre block:

        This is a pre block
        inside a list item.

* And another list item
EOF

    my $expect = [
        { type => 'unordered_list' },
        [
            {
                type   => 'list_item',
                bullet => '*',
            },
            [
                { type => 'paragraph' },
                [
                    {
                        type => 'text',
                        text => "A list item with a pre block:\n",
                    },
                ], {
                    type => 'preformatted',
                    text => "This is a pre block\ninside a list item.\n",
                },
            ], {
                type   => 'list_item',
                bullet => '*',
            },
            [
                { type => 'paragraph' },
                [
                    {
                        type => 'text',
                        text => "And another list item\n",
                    },
                ],
            ],
        ],
    ];

    parse_ok( $text, $expect, 'list containing a pre block' );
}

done_testing();
