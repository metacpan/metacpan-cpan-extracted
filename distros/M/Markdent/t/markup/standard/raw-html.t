use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<'EOF';
Some random <span class="foo">html in</span> my text!
EOF

    my $expect = [
        {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => 'Some random ',
            }, {
                type       => 'start_html_tag',
                tag        => 'span',
                attributes => {
                    class => 'foo',
                },
            },
            [
                {
                    type => 'text',
                    text => 'html in',
                },
            ], {
                type => 'text',
                text => " my text!\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'html in a block' );
}

{
    my $text = <<'EOF';
Using entities: &amp; and &#38;
EOF

    my $expect = [
        {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => 'Using entities: ',
            }, {
                type   => 'html_entity',
                entity => 'amp',
            }, {
                type => 'text',
                text => ' and ',
            }, {
                type   => 'html_entity',
                entity => '#38',
            }, {
                type => 'text',
                text => "\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'html entities in a paragraph' );
}

{
    my $html = <<'EOF';
<div>
  <p>
    An arbitrary chunk of html.
  </p>
</div>
EOF

    my $text = <<"EOF";
Some text

$html
EOF

    my $expect = [
        {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => "Some text\n",
            },
        ], {
            type => 'html_block',
            html => $html,
        },
    ];

    parse_ok( $text, $expect, 'html in a block' );
}

{
    my $html = <<'EOF';
<div class="foo">
  <p>
    An arbitrary chunk of html.
  </p>
</div>
EOF

    my $text = <<"EOF";
Some text

$html
EOF

    my $expect = [
        {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => "Some text\n",
            },
        ], {
            type => 'html_block',
            html => $html,
        },
    ];

    parse_ok( $text, $expect, 'html in a block' );
}

{
    my $html = <<'EOF';
<div>
<div>
  <p>
    An arbitrary chunk of html.
  </p>
</div>
</div>
EOF

    my $text = <<"EOF";
Some text

$html
EOF

    my $expect = [
        {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => "Some text\n",
            },
        ], {
            type => 'html_block',
            html => $html,
        },
    ];

    parse_ok( $text, $expect, 'html in a block with nested <div> tags' );
}

{
    my $html = <<'EOF';
<div>
  <div>
  <p>
    An arbitrary chunk of html.
  </p>
  </div>
</div>
EOF

    my $text = $html;

    my $expect = [
        {
            type => 'html_block',
            html => $html,
        },
    ];

    parse_ok( $text, $expect, 'html as sole content' );
}

{
    my $html = <<'EOF';
<div>
An arbitrary chunk of html.
</div>
EOF

    my $text = <<"EOF";
Some text
$html
EOF

    my $expect = [
        {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => "Some text\n",
            }, {
                type       => 'start_html_tag',
                tag        => 'div',
                attributes => {},
            },
            [
                {
                    type => 'text',
                    text => "\nAn arbitrary chunk of html.\n",
                },
            ], {
                type => 'text',
                text => "\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'html without preceding newline' );
}

{
    my $html = <<'EOF';
<div>
An arbitrary chunk of html.
</div>
EOF

    chomp $html;

    my $text = <<"EOF";
$html
Some text
EOF

    my $expect = [
        {
            type => 'paragraph',
        },
        [
            {
                type       => 'start_html_tag',
                tag        => 'div',
                attributes => {},
            },
            [
                {
                    type => 'text',
                    text => "\nAn arbitrary chunk of html.\n",
                },
            ], {
                type => 'text',
                text => "\nSome text\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'html without following newline' );
}

{
    my $html = <<'EOF';
<div>
An arbitrary chunk of html.
</div>
EOF

    my $text = <<"EOF";
$html

$html
EOF

    my $expect = [
        {
            type => 'html_block',
            html => $html,
        }, {
            type => 'html_block',
            html => $html,
        },
    ];

    parse_ok( $text, $expect, 'same html block twice in a row' );
}

{
    my $html = "<div>An arbitrary chunk of html.</div>\n";

    my $text = <<"EOF";
$html
A paragraph in the middle

$html
EOF

    my $expect = [
        {
            type => 'html_block',
            html => $html,
        },
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "A paragraph in the middle\n",
            },
        ], {
            type => 'html_block',
            html => $html,
        },
    ];

    parse_ok(
        $text, $expect,
        'two html blocks and a paragraph in the middle'
    );
}

{
    my $text = <<'EOF';
`Inside code we do not match <em>html</em> &amp; entities`
EOF

    my $expect = [
        {
            type => 'paragraph',
        },
        [
            { type => 'code' },
            [
                {
                    type => 'text',
                    text =>
                        'Inside code we do not match <em>html</em> &amp; entities',
                },
            ], {
                type => 'text',
                text => "\n",
            },
        ],
    ];

    parse_ok(
        $text, $expect,
        'html inside code block is not treated as html'
    );
}

{
    my $text = <<'EOF';
Some self-closing <img src="foo" /> HTML.
EOF

    my $expect = [
        {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => 'Some self-closing ',
            }, {
                type       => 'html_tag',
                tag        => 'img',
                attributes => { src => 'foo' },
            }, {
                type => 'text',
                text => " HTML.\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'a self-closing html tag (img)' );
}

{
    my $text = <<'EOF';
A paragraph

<!-- html comment 1 -->
<!-- html comment 2 -->

Inline <!-- comment --> here
EOF

    my $expect = [
        {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => "A paragraph\n",
            },
        ], {
            type => 'html_comment_block',
            text => ' html comment 1 ',
        }, {
            type => 'html_comment_block',
            text => ' html comment 2 ',
        }, {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => 'Inline ',
            }, {
                type => 'html_comment',
                text => ' comment ',
            }, {
                type => 'text',
                text => " here\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'html comments, standalone and inline' );
}

{
    my $text = <<'EOF';
Using pair of &laquo;entities&raquo; and &THORN; and &sup2;&#37;
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                text => 'Using pair of ',
                type => 'text',
            }, {
                type   => 'html_entity',
                entity => 'laquo',
            }, {
                type => 'text',
                text => 'entities',
            }, {
                entity => 'raquo',
                type   => 'html_entity',
            }, {
                type => 'text',
                text => ' and ',
            }, {
                entity => 'THORN',
                type   => 'html_entity',
            }, {
                type => 'text',
                text => ' and ',
            }, {
                entity => 'sup2',
                type   => 'html_entity',
            }, {
                entity => '#37',
                type   => 'html_entity',
            }, {
                text => "\n",
                type => 'text',
            },
        ],
    ];

    parse_ok( $text, $expect, 'two wrapped html entities' );
}

done_testing();
