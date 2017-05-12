use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<'EOF';
Some text with \[a backslash escape\]
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "Some text with [a backslash escape]\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'backslash escape a potential link' );
}

{
    my $text = '\*start with escape\*';

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "*start with escape*\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'backslash escape at beginning of document' );
}

{
    my $text = '`Ignore \* in code`';

    my $expect = [
        { type => 'paragraph' },
        [
            { type => 'code' },
            [
                {
                    type => 'text',
                    text => 'Ignore \* in code',
                },
            ], {
                type => 'text',
                text => "\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'backslash escape is ignored in code span' );
}

{
    my $text = <<'EOF';
Backslash: \\

Backtick: \`

Greater-than: \>
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "Backslash: \\\n",
            },
        ],
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "Backtick: `\n",
            },
        ],
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "Greater-than: >\n",
            },
        ],
    ];

    parse_ok(
        $text, $expect,
        'backslashed backslash, backtick and greater-than'
    );
}

{
    my $text = <<'EOF';
Backslash: `\\`

Backtick: `` \` ``
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Backslash: ',
            },
            { type => 'code' },
            [
                {
                    type => 'text',
                    text => '\\\\',
                },
            ], {
                type => 'text',
                text => "\n",
            },
        ],
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Backtick: ',
            },
            { type => 'code' },
            [
                {
                    type => 'text',
                    text => q{\`},
                },
            ], {
                type => 'text',
                text => "\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'backslashes in code spans' );
}

done_testing();
