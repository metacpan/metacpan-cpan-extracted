use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<'EOF';
Just an http://example.com link in some plain text.
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Just an ',
            }, {
                type => 'auto_link',
                uri  => 'http://example.com',
            }, {
                type => 'text',
                text => " link in some plain text.\n",
            },
        ],
    ];

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'bare http link is linked'
    );
}

{
    my $text = <<'EOF';
Just an http://example.com link and https://example.com link in some plain text.
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Just an ',
            }, {
                type => 'auto_link',
                uri  => 'http://example.com',
            }, {
                type => 'text',
                text => ' link and ',
            }, {
                type => 'auto_link',
                uri  => 'https://example.com',
            }, {
                type => 'text',
                text => " link in some plain text.\n",
            },
        ],
    ];

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'bare http and https links together'
    );
}

{
    my $text = <<'EOF';
Nohttp://example.com link.
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "Nohttp://example.com link.\n",
            },
        ],
    ];

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'No false positive on bare link'
    );
}

{
    my $text = <<'EOF';
Link:http://example.com
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Link:',
            }, {
                type => 'auto_link',
                uri  => 'http://example.com',
            }, {
                type => 'text',
                text => "\n",
            },
        ],
    ];

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'Bare link preceded by non-word character is linked'
    );
}
{
    my $text = 'http://example.com';

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'auto_link',
                uri  => 'http://example.com',
            }, {
                type => 'text',
                text => "\n",
            },
        ],
    ];

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'Bare link at start of document is linked'
    );
}

done_testing();
