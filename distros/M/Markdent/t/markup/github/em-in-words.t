use strict;
use warnings;

use Test2::V0;

use FindBin qw( $Bin );
use lib "$Bin/../../../t/lib";

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

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'emphasis markup (*) surrounded by parentheses'
    );
}

{
    my $text = <<'EOF';
Some %_em text_%
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

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'emphasis markup (_) surrounded by parentheses'
    );
}

{
    my $text = <<'EOF';
under_score in words is not em_phasis
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "under_score in words is not em_phasis\n",
            },
        ],
    ];

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'An underscore in a word is not treated as emphasis'
    );
}

{
    my $text = <<'EOF';
as*terisk in words is em*phasis
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'as',
            },
            { type => 'emphasis' },
            [
                {
                    type => 'text',
                    text => 'terisk in words is em',
                },
            ], {
                type => 'text',
                text => "phasis\n",
            },
        ],
    ];

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'Asterisks in words are treated as emphasis'
    );
}

{
    my $text = <<'EOF';
in_fucking_credible
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "in_fucking_credible\n",
            },
        ],
    ];

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'Multiple underscores in one word are not treated as emphasis'
    );
}

{
    my $text = <<'EOF';
in*fucking*credible
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'in',
            },
            { type => 'emphasis' },
            [
                {
                    type => 'text',
                    text => 'fucking',
                },
            ], {
                type => 'text',
                text => "credible\n",
            },
        ],
    ];

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'Multiple asterisks in one word are treated as emphasis'
    );
}

{
    my $text = '_right at the beginning_';

    my $expect = [
        { type => 'paragraph' },
        [
            { type => 'emphasis' },
            [
                {
                    type => 'text',
                    text => 'right at the beginning',
                },
            ], {
                type => 'text',
                text => "\n",
            },
        ],
    ];

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'Underscore at beginning of document is treated as emphasis'
    );
}

done_testing();
