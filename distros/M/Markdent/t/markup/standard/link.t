use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<'EOF';
Some text with [A link](http://www.example.com) and more text.
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some text with ',
            }, {
                type           => 'link',
                uri            => 'http://www.example.com',
                is_implicit_id => 0,
            },
            [
                {
                    type => 'text',
                    text => 'A link',
                },
            ], {
                type => 'text',
                text => " and more text.\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'text with an inline link' );
}

{
    my $text = <<'EOF';
Some text with [A link](<http://www.example.com>) and more text.
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some text with ',
            }, {
                type           => 'link',
                uri            => 'http://www.example.com',
                is_implicit_id => 0,
            },
            [
                {
                    type => 'text',
                    text => 'A link',
                },
            ], {
                type => 'text',
                text => " and more text.\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'text with an inline link' );
}

{
    my $text = <<'EOF';
Some text with [A link](http://www.example.com "A title") and more text.
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some text with ',
            }, {
                type           => 'link',
                uri            => 'http://www.example.com',
                title          => 'A title',
                is_implicit_id => 0,
            },
            [
                {
                    type => 'text',
                    text => 'A link',
                },
            ], {
                type => 'text',
                text => " and more text.\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'text with an inline link (has title)' );
}

{
    my $tab = "\t";

    my $text = <<"EOF";
Some text with [A link](http://www.example.com${tab}"A title") and more text.
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some text with ',
            }, {
                type           => 'link',
                uri            => 'http://www.example.com',
                title          => 'A title',
                is_implicit_id => 0,
            },
            [
                {
                    type => 'text',
                    text => 'A link',
                },
            ], {
                type => 'text',
                text => " and more text.\n",
            },
        ]
    ];

    parse_ok(
        $text, $expect,
        'text with an inline link (has title and tab before title)'
    );
}

{
    my $text = <<'EOF';
Some text with [A link][link id] and more text.

[link id]: /foo
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some text with ',
            }, {
                type           => 'link',
                id             => 'link id',
                uri            => '/foo',
                is_implicit_id => 0,
            },
            [
                {
                    type => 'text',
                    text => 'A link',
                },
            ], {
                type => 'text',
                text => " and more text.\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'text with a link by id' );
}

{
    my $text = <<'EOF';
Some text with [A link] [link id] and more text.

[link id]: </bar>
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some text with ',
            }, {
                type           => 'link',
                id             => 'link id',
                uri            => '/bar',
                is_implicit_id => 0,
            },
            [
                {
                    type => 'text',
                    text => 'A link',
                },
            ], {
                type => 'text',
                text => " and more text.\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'text with a link by id, space before id' );
}

{
    my $text = <<'EOF';
Some text with [A link][] and more text.

[A link]:
/foo/bar "title"
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some text with ',
            }, {
                type           => 'link',
                id             => 'A link',
                uri            => '/foo/bar',
                title          => 'title',
                is_implicit_id => 1,
            },
            [
                {
                    type => 'text',
                    text => 'A link',
                },
            ], {
                type => 'text',
                text => " and more text.\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'text with a link by id, implicit id' );
}

{
    my $text = <<'EOF';
Some text with [A link] and more text.

[A link]: /foo
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some text with ',
            }, {
                type           => 'link',
                id             => 'A link',
                uri            => '/foo',
                is_implicit_id => 1,
            },
            [
                {
                    type => 'text',
                    text => 'A link',
                },
            ], {
                type => 'text',
                text => " and more text.\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'text with a link by id, implicit id (no [])' );
}

{
    my $text = <<'EOF';
Some text with [A link *with* markup](http://www.example.com) and more text.
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some text with ',
            }, {
                type           => 'link',
                uri            => 'http://www.example.com',
                is_implicit_id => 0,
            },
            [
                {
                    type => 'text',
                    text => 'A link ',
                }, {
                    type => 'emphasis',
                },
                [
                    {
                        type => 'text',
                        text => 'with',
                    },
                ], {
                    type => 'text',
                    text => ' markup',
                },
            ], {
                type => 'text',
                text => " and more text.\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'text with a link, link text has markup' );
}

{
    my $text = <<'EOF';
Some text with [A link [*with* markup] and brackets](http://www.example.com)
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some text with ',
            }, {
                type           => 'link',
                uri            => 'http://www.example.com',
                is_implicit_id => 0,
            },
            [
                {
                    type => 'text',
                    text => 'A link [',
                }, {
                    type => 'emphasis',
                },
                [
                    {
                        type => 'text',
                        text => 'with',
                    },
                ], {
                    type => 'text',
                    text => ' markup] and brackets',
                },
            ], {
                type => 'text',
                text => "\n",
            },
        ]
    ];

    parse_ok(
        $text, $expect,
        'text with a link, link text has markup and nested brackets'
    );
}

{
    my $text = <<'EOF';
Some text with [*A link*] and more text.

[*A link*]: /baz
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some text with ',
            }, {
                type           => 'link',
                id             => '*A link*',
                uri            => '/baz',
                is_implicit_id => 1,
            },
            [
                { type => 'emphasis' },
                [
                    {
                        type => 'text',
                        text => 'A link',
                    },
                ],
            ], {
                type => 'text',
                text => " and more text.\n",
            },
        ]
    ];

    parse_ok(
        $text, $expect,
        'text with a link by id, implicit id contains markup'
    );
}

{
    my $text = <<'EOF';
An auto link <http://www.example.com/> and more text
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'An auto link ',
            }, {
                type => 'auto_link',
                uri  => 'http://www.example.com/',
            }, {
                type => 'text',
                text => " and more text\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'text with an auto link' );
}

{
    my $text = <<'EOF';
(With outer parens and [parens in url](/foo(bar)))
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => '(With outer parens and ',
            }, {
                type           => 'link',
                uri            => '/foo(bar)',
                is_implicit_id => 0,
            },
            [
                {
                    type => 'text',
                    text => 'parens in url',
                },
            ], {
                type => 'text',
                text => ")\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'tricky use parens with an inline link' );
}

{
    my $text = <<'EOF';
(With outer parens and [parens in url](/foo(bar) "title"))
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => '(With outer parens and ',
            }, {
                type           => 'link',
                uri            => '/foo(bar)',
                title          => 'title',
                is_implicit_id => 0,
            },
            [
                {
                    type => 'text',
                    text => 'parens in url',
                },
            ], {
                type => 'text',
                text => ")\n",
            },
        ]
    ];

    parse_ok(
        $text, $expect,
        'tricky use parens with an inline link that has a title'
    );
}

{
    my $text = <<'EOF';
[Empty]()
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type           => 'link',
                uri            => q{},
                is_implicit_id => 0,
            },
            [
                {
                    type => 'text',
                    text => 'Empty',
                },
            ], {
                type => 'text',
                text => "\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'An empty inline link' );
}

{
    my $text = <<'EOF';
[Empty](  )
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type           => 'link',
                uri            => q{},
                is_implicit_id => 0,
            },
            [
                {
                    type => 'text',
                    text => 'Empty',
                },
            ], {
                type => 'text',
                text => "\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'An inline link with only whitespace' );
}

{
    my $text = <<'EOF';
[Link?][no such id]
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "[Link?][no such id]\n",
            },
        ]
    ];

    parse_ok(
        $text, $expect,
        'Link by reference with a bad id is treated as text'
    );
}

{
    my $text = <<'EOF';
Here's one where the [link
breaks] across lines.

Here's another where the [link 
breaks] across lines, but with a line-ending space.

[link breaks]: /url/
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => q{Here's one where the },
            }, {
                type           => 'link',
                uri            => '/url/',
                id             => 'link breaks',
                is_implicit_id => 1,
            },
            [
                {
                    type => 'text',
                    text => "link\nbreaks",
                }
            ], {
                type => 'text',
                text => " across lines.\n",
            },
        ],
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => q{Here's another where the },
            }, {
                type           => 'link',
                uri            => '/url/',
                id             => 'link breaks',
                is_implicit_id => 1,
            },
            [
                {
                    type => 'text',
                    text => "link \nbreaks",
                }
            ], {
                type => 'text',
                text => " across lines, but with a line-ending space.\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'Link text with a newline' );
}

done_testing();
