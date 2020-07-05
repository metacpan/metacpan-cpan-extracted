use strict;
use warnings;

use Test2::V0;

use FindBin qw( $Bin );
use lib "$Bin/../../../t/lib";

use Test::Markdent;

{
    my $text = <<'EOF';
* one line
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "one line\n",
                }
            ],
        ],
    ];

    parse_ok( $text, $expect, 'one line unordered list' );
}

{
    my $tab = "\t";

    my $text = <<"EOF";
*${tab}one line
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "one line\n",
                }
            ],
        ],
    ];

    parse_ok(
        $text, $expect,
        'one line unordered list with tab after bullet'
    );
}

{
    my $text = <<'EOF';
* l1
* l2
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "l1\n",
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
            ],
        ],
    ];

    parse_ok( $text, $expect, 'two line unordered list' );
}

{
    my $text = <<'EOF';
* l1
   * l2
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "l1\n",
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
            ],
        ],
    ];

    parse_ok(
        $text, $expect,
        'two line unordered list, second list item has 3 space indent'
    );
}

{
    my $text = <<'EOF';
* l1
    * l2
* l3
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "l1\n",
                }, {
                    type => 'unordered_list',
                },
                [
                    {
                        type   => 'list_item',
                        bullet => '*',
                    },
                    [
                        {
                            type => 'text',
                            text => "l2\n",
                        }
                    ],
                ]
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
    ];

    parse_ok(
        $text, $expect,
        'unordered list with nested list as second item'
    );
}

{
    my $text = <<'EOF';
* l1
  continues
* l3
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "l1\n  continues\n",
                },
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
    ];

    parse_ok(
        $text, $expect,
        'unordered list with multi-line single list item'
    );
}

{
    my $text = <<'EOF';
* l1
continues
* l3
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "l1\ncontinues\n",
                },
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
    ];

    parse_ok(
        $text, $expect,
        'unordered list with multi-line single list item (no indent for continuation)'
    );
}

{
    my $text = <<'EOF';
* l1

  para

* l3
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
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
                        text => "l1\n",
                    },
                ],
                { type => 'paragraph' },
                [
                    {
                        type => 'text',
                        text => "  para\n",
                    },
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
                        text => "l3\n",
                    },
                ],
            ],
        ],
    ];

    parse_ok(
        $text, $expect,
        'unordered list with first item having two paragraphs'
    );
}

{
    my $text = <<'EOF';
* l1

  para

straight para
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
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
                        text => "l1\n",
                    },
                ],
                { type => 'paragraph' },
                [
                    {
                        type => 'text',
                        text => "  para\n",
                    },
                ],
            ],
        ],
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "straight para\n",
            }
        ],
    ];

    parse_ok(
        $text, $expect,
        'unordered list with first item having two paragraphs followed by regular paragraph'
    );
}

{
    my $text = <<'EOF';
*   Abacus
    * answer
*   Bubbles
    1.  bunk
    2.  bupkis
        * BELITTLER
    3. burper
*   Cunning
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "Abacus\n",
                },
                { type => 'unordered_list' },
                [
                    {
                        type   => 'list_item',
                        bullet => '*',
                    },
                    [
                        {
                            type => 'text',
                            text => "answer\n",
                        },
                    ],
                ],
            ], {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "Bubbles\n",
                },
                { type => 'ordered_list' },
                [
                    {
                        type   => 'list_item',
                        bullet => '1.',
                    },
                    [
                        {
                            type => 'text',
                            text => "bunk\n",
                        },
                    ], {
                        type   => 'list_item',
                        bullet => '2.',
                    },
                    [
                        {
                            type => 'text',
                            text => "bupkis\n",
                        },
                        { type => 'unordered_list' },
                        [
                            {
                                type   => 'list_item',
                                bullet => '*',
                            },
                            [
                                {
                                    type => 'text',
                                    text => "BELITTLER\n",
                                },
                            ],
                        ],
                    ], {
                        type   => 'list_item',
                        bullet => '3.',
                    },
                    [
                        {
                            type => 'text',
                            text => "burper\n",
                        },
                    ],
                ],
            ], {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "Cunning\n",
                },
            ],
        ],
    ];

    parse_ok( $text, $expect, 'complex three-level list from Dingus' );
}

{
    my $text = <<'EOF';
1. ordered
2. #2
    * unordered
    * #2
3. and ordered again
EOF

    my $expect = [
        {
            type => 'ordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '1.',
            },
            [
                {
                    type => 'text',
                    text => "ordered\n",
                }
            ], {
                type   => 'list_item',
                bullet => '2.',
            },
            [
                {
                    type => 'text',
                    text => "#2\n",
                },
                { type => 'unordered_list' },
                [
                    {
                        type   => 'list_item',
                        bullet => '*',
                    },
                    [
                        {
                            type => 'text',
                            text => "unordered\n",
                        },
                    ], {
                        type   => 'list_item',
                        bullet => '*',
                    },
                    [
                        {
                            type => 'text',
                            text => "#2\n",
                        },
                    ],
                ],
            ], {
                type   => 'list_item',
                bullet => '3.',
            },
            [
                {
                    type => 'text',
                    text => "and ordered again\n",
                },
            ],
        ],
    ];

    parse_ok( $text, $expect, 'ordered list containing an unordered list' );
}

{
    my $text = <<'EOF';
*   asterisk 1

*   asterisk 2

* * *
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
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
                        text => "asterisk 1\n",
                    },
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
                        text => "asterisk 2\n",
                    },
                ],
            ],
        ],
        { type => 'horizontal_rule' },
    ];

    parse_ok(
        $text, $expect,
        'unordered list terminated by a horizontal rule'
    );
}

{
    my $text = <<'EOF';
* + x
* + x
* + x
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "+ x\n",
                },
            ], {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "+ x\n",
                },
            ], {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "+ x\n",
                },
            ],
        ],
    ];

    parse_ok(
        $text, $expect,
        'list where each list item text looks like a bullet'
    );
}

{
    my $text = <<'EOF';
* ---
* foo
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "---\n",
                },
            ], {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "foo\n",
                },
            ],
        ],
    ];

    parse_ok( $text, $expect, 'list cannot contain a horizontal rule' );
}

{
    my $text = <<'EOF';

1. First

2. Second:
    * Fee
    * Fie

3. Third
EOF

    my $expect = [
        {
            type => 'ordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '1.',
            },
            [
                { type => 'paragraph' },
                [
                    {
                        type => 'text',
                        text => "First\n",
                    },
                ],
            ], {
                type   => 'list_item',
                bullet => '2.',
            },
            [
                { type => 'paragraph' },
                [
                    {
                        type => 'text',
                        text => "Second:\n",
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
                            text => "Fee\n",
                        },
                    ], {
                        type   => 'list_item',
                        bullet => '*',
                    },
                    [
                        {
                            type => 'text',
                            text => "Fie\n",
                        },
                    ],
                ],
            ], {
                type   => 'list_item',
                bullet => '3.',
            },
            [
                { type => 'paragraph' },
                [
                    {
                        type => 'text',
                        text => "Third\n",
                    },
                ],
            ],
        ],
    ];

    parse_ok(
        $text, $expect,
        'loose list with sublist should still have paras'
    );
}

{
    my $tab = "\t";

    my $text = <<"EOF";
*${tab}Tab
${tab}*${tab}Tab
${tab}${tab}*${tab}Tab
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '*',
            },
            [
                {
                    type => 'text',
                    text => "Tab\n",
                }, {
                    type => 'unordered_list',
                },
                [
                    {
                        type   => 'list_item',
                        bullet => '*',
                    },
                    [
                        {
                            type => 'text',
                            text => "Tab\n",
                        }, {
                            type => 'unordered_list',
                        },
                        [
                            {
                                type   => 'list_item',
                                bullet => '*',
                            },
                            [
                                {
                                    type => 'text',
                                    text => "Tab\n",
                                }
                            ],
                        ],
                    ],
                ],
            ],
        ],
    ];

    parse_ok( $text, $expect, 'nested lists with leading tabs' );
}

{
    my $tab = "\t";

    my $text = <<"EOF";
*${tab}this

${tab}*${tab}sub

${tab}that
EOF

    my $expect = [
        {
            type => 'unordered_list',
        },
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
                        text => "this\n",
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
                            text => "sub\n",
                        },
                    ],
                ],
                { type => 'paragraph' },
                [
                    {
                        type => 'text',
                        text => "that\n",
                    },
                ],
            ],
        ],
    ];

    parse_ok(
        $text, $expect,
        'weird use of tabs and nested lists from mdtest'
    );
}

{
    my $text = <<'EOF';
1. First
1. Second
1. Third
EOF

    my $expect = [
        {
            type => 'ordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '1.',
            },
            [
                {
                    type => 'text',
                    text => "First\n",
                }
            ], {
                type   => 'list_item',
                bullet => '2.',
            },
            [
                {
                    type => 'text',
                    text => "Second\n",
                },
            ], {
                type   => 'list_item',
                bullet => '3.',
            },
            [
                {
                    type => 'text',
                    text => "Third\n",
                },
            ],
        ],
    ];

    parse_ok( $text, $expect, 'lazily numbered ordered list' );
}

{
    my $text = <<'EOF';
042. First
6. Second
10. Third
EOF

    my $expect = [
        {
            type => 'ordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '1.',
            },
            [
                {
                    type => 'text',
                    text => "First\n",
                }
            ], {
                type   => 'list_item',
                bullet => '2.',
            },
            [
                {
                    type => 'text',
                    text => "Second\n",
                },
            ], {
                type   => 'list_item',
                bullet => '3.',
            },
            [
                {
                    type => 'text',
                    text => "Third\n",
                },
            ],
        ],
    ];

    parse_ok( $text, $expect, 'drunkenly numbered ordered list' );
}

{
    my $text = <<'EOF';
1. ordered
5. #2
    1. nested
    1. #2
1. and ordered again
EOF

    my $expect = [
        {
            type => 'ordered_list',
        },
        [
            {
                type   => 'list_item',
                bullet => '1.',
            },
            [
                {
                    type => 'text',
                    text => "ordered\n",
                }
            ], {
                type   => 'list_item',
                bullet => '2.',
            },
            [
                {
                    type => 'text',
                    text => "#2\n",
                },
                { type => 'ordered_list' },
                [
                    {
                        type   => 'list_item',
                        bullet => '1.',
                    },
                    [
                        {
                            type => 'text',
                            text => "nested\n",
                        },
                    ], {
                        type   => 'list_item',
                        bullet => '2.',
                    },
                    [
                        {
                            type => 'text',
                            text => "#2\n",
                        },
                    ],
                ],
            ], {
                type   => 'list_item',
                bullet => '3.',
            },
            [
                {
                    type => 'text',
                    text => "and ordered again\n",
                },
            ],
        ],
    ];

    parse_ok(
        $text, $expect,
        'drunk and lazily numbered ordered lists, nested'
    );
}

done_testing();
