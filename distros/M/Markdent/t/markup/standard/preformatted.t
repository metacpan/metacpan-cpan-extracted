use strict;
use warnings;

use Test2::V0;

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<'EOF';
    preformatted line
EOF

    my $expect = [
        {
            type => 'preformatted',
            text => "preformatted line\n",
        }
    ];

    parse_ok( $text, $expect, 'one-line preformatted' );
}
{
    my $tab = "\t";

    my $text = <<"EOF";
${tab}preformatted line
EOF

    my $expect = [
        {
            type => 'preformatted',
            text => "preformatted line\n",
        }
    ];

    parse_ok( $text, $expect, 'one-line preformatted with leading tab' );
}

{
    my $text = <<'EOF';
    pre 1
      pre 2
EOF

    ( my $expect_text = $text ) =~ s/^[ ]{4}//gm;

    my $expect = [
        {
            type => 'preformatted',
            text => $expect_text,
        },
    ];

    parse_ok(
        $text, $expect,
        'two pre lines, second has 2-space indentation'
    );
}

{
    my $text = <<'EOF';
    pre 1


    pre 2
EOF

    ( my $expect_text = $text ) =~ s/^[ ]{4}//gm;

    my $expect = [
        {
            type => 'preformatted',
            text => $expect_text,
        },
    ];

    parse_ok( $text, $expect, 'preformatted text includes empty lines' );
}

{
    my $pre = <<'EOF';
    pre 1


    pre 2
EOF

    my $text = <<"EOF";
$pre
regular text
EOF

    ( my $expect_text = $pre ) =~ s/^[ ]{4}//gm;

    my $expect = [
        {
            type => 'preformatted',
            text => $expect_text,
        }, {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => "regular text\n",
            },
        ],
    ];

    parse_ok(
        $text, $expect,
        'preformatted text with empty lines followed by regular paragraph'
    );
}

done_testing();
