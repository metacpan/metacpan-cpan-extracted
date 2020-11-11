use strict;
use warnings;

use Test2::V0;

use FindBin qw( $Bin );
use lib "$Bin/../../../t/lib";

use Test::Markdent;

# See https://github.com/houseabsolute/Markdent/issues/25
#
# It turns out any line starting with a tab had issues if it wasn't surrounded
# by empty lines.
{
    my $text = <<"EOF";
foo
\t<- tab
bar
EOF

    my $expect_text = $text;
    $expect_text =~ s/^\t/    /m;

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => $expect_text,
            },
        ],
    ];

    parse_ok(
        $text,
        $expect,
        q{line starts with a tab but there are no newlines around it so it's not preformatted},
    );
}

{
    my $text = <<"EOF";
foo
\t\t<- tab
bar
EOF

    my $expect_text = $text;
    $expect_text =~ s/^\t/    /m;

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => $expect_text,
            },
        ],
    ];

    parse_ok(
        $text,
        $expect,
        q{line starts with a tab but there are no newlines around it so it's not preformatted},
    );
}

done_testing();
