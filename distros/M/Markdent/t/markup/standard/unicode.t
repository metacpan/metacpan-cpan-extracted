use strict;
use warnings;
use utf8;

use Test2::V0;

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<"EOF";
# \x{1f600} smiley face
EOF

    my $expect = [
        {
            type  => 'header',
            level => 1,
        },
        [
            {
                type => 'text',
                text => "\x{1f600} smiley face\n",
            },
        ],
    ];

    parse_ok( $text, $expect, 'Header containing unicode' );
}

{
    my $text = <<"EOF";
Unicode in span - <span class="foo">\x{1f600} smiley face</span> - works
EOF

    my $expect = [
        {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => 'Unicode in span - ',
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
                    text => "\x{1f600} smiley face",
                },
            ], {
                type => 'text',
                text => " - works\n",
            },
        ],
    ];

    parse_ok(
        $text, $expect,
        'span-level html containing unicode in a block'
    );
}

{
    my $text = <<"EOF";
\x{1f600} smiley face

<h2>\x{1f600} smiley face</h2>
EOF

    my $expect = [
        {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => "\x{1f600} smiley face\n",
            },
        ], {
            type => 'html_block',
            html => "<h2>\x{1f600} smiley face</h2>\n",
        },
    ];

    parse_ok(
        $text, $expect,
        'unicode in paragraph followed by html block containing unicode'
    );
}

done_testing;
