use strict;
use warnings;

use Test2::V0;

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<'EOF';
Some %*em text*%
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some %',
            }, {
                type => 'emphasis',
            },
            [
                {
                    type => 'text',
                    text => 'em text',
                },
            ], {
                type => 'text',
                text => "%\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'emphasis markup surrounded by percent signs' );
}

{
    my $text = <<'EOF';
This is ``code ` with backtick``
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'This is ',
            }, {
                type => 'code',
            },
            [
                {
                    type => 'text',
                    text => 'code ` with backtick',
                },
            ], {
                type => 'text',
                text => "\n",
            },
        ],
    ];

    parse_ok(
        $text, $expect,
        'code marked with `` containing a single backtick'
    );
}

{
    my $text = <<'EOF';
Do not look for `<html> in` code
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Do not look for ',
            }, {
                type => 'code',
            },
            [
                {
                    type => 'text',
                    text => '<html> in',
                },
            ], {
                type => 'text',
                text => " code\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'code containing html' );
}

{
    my $text = <<'EOF';
Do not look for `*any **markup** in*` code
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Do not look for ',
            }, {
                type => 'code',
            },
            [
                {
                    type => 'text',
                    text => '*any **markup** in*',
                },
            ], {
                type => 'text',
                text => " code\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'code containing strong & em' );
}

{
    my $text = <<'EOF';
(`` ` ``)
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => '(',
            }, {
                type => 'code',
            },
            [
                {
                    type => 'text',
                    text => q{`},
                },
            ], {
                type => 'text',
                text => ")\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'code in parens' );
}

{
    my $text = <<'EOF';
**strong** *em* ***both***
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            { type => 'strong' },
            [
                {
                    type => 'text',
                    text => 'strong',
                },
            ], {
                type => 'text',
                text => q{ },
            },
            { type => 'emphasis' },
            [
                {
                    type => 'text',
                    text => 'em',
                },
            ], {
                type => 'text',
                text => q{ },
            },
            { type => 'strong' },
            [
                { type => 'emphasis' },
                [
                    {
                        type => 'text',
                        text => 'both',
                    },
                ]
            ], {
                type => 'text',
                text => "\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'strong, em, and then both' );
}

done_testing();
