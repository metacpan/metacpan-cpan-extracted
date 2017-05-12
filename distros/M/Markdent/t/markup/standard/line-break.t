use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<'EOF';
Has two spaces  
That's a line break
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Has two spaces',
            }, {
                type => 'line_break',
            }, {
                type => 'text',
                text => qq{That's a line break\n},
            },
        ],
    ];

    parse_ok(
        $text, $expect,
        'two spaces at end of paragraph line forces a line break'
    );
}

{
    my $text = <<'EOF';
Has two spaces  
And two more  
Now just one 
That's not a line break
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'Has two spaces',
            }, {
                type => 'line_break',
            }, {
                type => 'text',
                text => 'And two more',
            }, {
                type => 'line_break',
            }, {
                type => 'text',
                text => qq{Now just one \nThat's not a line break\n},
            },
        ],
    ];

    parse_ok(
        $text, $expect,
        'two spaces at end of paragraph line forces a line break but one space does not',
    );
}

done_testing();
