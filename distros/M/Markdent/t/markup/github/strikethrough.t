use strict;
use warnings;

use Test2::V0;

use FindBin qw( $Bin );
use lib "$Bin/../../../t/lib";

use Test::Markdent;

{
    my $text = <<'EOF';
Some %~~del text~~%
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Some %',
            }, {
                type => 'strikethrough',
            },
            [
                {
                    type => 'text',
                    text => 'del text',
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
        'strikethrough markup (~~)'
    );
}

{
    my $text = <<'EOF';
Some %\~\~del text\~\~%
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "Some %~~del text~~%\n",
            }
        ],
    ];

    parse_ok(
        {},
        $text,
        $expect,
        'escaping of ~'
    );
}

{
    my $text = <<'EOF';
Some %~~del text~~%
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "Some %~~del text~~%\n",
            },
        ],
    ];

    parse_ok(
        {},
        $text,
        $expect,
        'default dialect does not support strikethrough'
    );
}

done_testing();
