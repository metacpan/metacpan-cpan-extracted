use strict;
use warnings;

use Test2::V0;

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<'EOF';
Header 1
========
EOF

    my $expect = [
        {
            type  => 'header',
            level => 1,
        },
        [
            {
                type => 'text',
                text => "Header 1\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'Single two-line header' );
}

{
    my $text = <<'EOF';
# Header 1
EOF

    my $expect = [
        {
            type  => 'header',
            level => 1,
        },
        [
            {
                type => 'text',
                text => "Header 1\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'Single atx header' );
}

{
    my $text = <<'EOF';
Header 1
========

Header 2
--------

# Header 1A

## Header 2A ##

### Header 3 ###

#### Header 4

##### Header 5

###### Header 6
EOF

    my $expect = [
        {
            type  => 'header',
            level => 1,
        },
        [
            {
                type => 'text',
                text => "Header 1\n",
            },
        ], {
            type  => 'header',
            level => 2,
        },
        [
            {
                type => 'text',
                text => "Header 2\n",
            },
        ], {
            type  => 'header',
            level => 1,
        },
        [
            {
                type => 'text',
                text => "Header 1A\n",
            },
        ], {
            type  => 'header',
            level => 2,
        },
        [
            {
                type => 'text',
                text => "Header 2A\n",
            },
        ], {
            type  => 'header',
            level => 3,
        },
        [
            {
                type => 'text',
                text => "Header 3\n",
            },
        ], {
            type  => 'header',
            level => 4,
        },
        [
            {
                type => 'text',
                text => "Header 4\n",
            },
        ], {
            type  => 'header',
            level => 5,
        },
        [
            {
                type => 'text',
                text => "Header 5\n",
            },
        ], {
            type  => 'header',
            level => 6,
        },
        [
            {
                type => 'text',
                text => "Header 6\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'all possible header types' );
}

{
    my $text = <<'EOF';
Header *with em*
================

### H3 **with strong**
EOF

    my $expect = [
        {
            type  => 'header',
            level => 1,
        },
        [
            {
                type => 'text',
                text => 'Header ',
            },
            { type => 'emphasis' },
            [
                {
                    type => 'text',
                    text => 'with em',
                },
            ], {
                type => 'text',
                text => "\n",
            },
        ], {
            type  => 'header',
            level => 3,
        },
        [
            {
                type => 'text',
                text => 'H3 ',
            },
            { type => 'strong' },
            [
                {
                    type => 'text',
                    text => 'with strong',
                },
            ], {
                type => 'text',
                text => "\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'two-line header with em markup' );
}

{
    my $text = <<'EOF';
Header with no empty space after
================
### H3 with no empty space after
a paragraph
EOF

    my $expect = [
        {
            type  => 'header',
            level => 1,
        },
        [
            {
                type => 'text',
                text => "Header with no empty space after\n",
            },
        ], {
            type  => 'header',
            level => 3,
        },
        [
            {
                type => 'text',
                text => "H3 with no empty space after\n",
            },
        ], {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => "a paragraph\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'headers with no whitespace after' );
}

{
    my $tab = "\t";

    my $text = <<"EOF";
#${tab}Header 1${tab}#
EOF

    my $expect = [
        {
            type  => 'header',
            level => 1,
        },
        [
            {
                type => 'text',
                text => "Header 1\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'ATX header with tabs' );
}

{
    my $tab = "\t";

    my $text = <<"EOF";
${tab}Header 1
==============
EOF

    my $expect = [
        {
            type  => 'header',
            level => 1,
        },
        [
            {
                type => 'text',
                text => "    Header 1\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'two-line header with tabs' );
}

done_testing();
