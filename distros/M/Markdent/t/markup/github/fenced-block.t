use strict;
use warnings;

use Test2::V0;

use FindBin qw( $Bin );
use lib "$Bin/../../../t/lib";

use Test::Markdent;

{
    my $code = <<'EOF';
now in a code block
    preserve the formatting
EOF
    chomp $code;

    my $text = <<"EOF";
Some plain text.

```
$code
```

More plain text.
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "Some plain text.\n",
            },
        ], {
            type     => 'code_block',
            code     => $code,
            language => undef,
        },
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "More plain text.\n",
            },
        ],
    ];

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'fenced code block with no language'
    );
}

{
    my $code = <<'EOF';
now in a code block
    preserve the formatting
EOF
    chomp $code;

    my @text;

    #  Code block as per GitHub standard
    #
    push @text, <<"EOF";
Some plain text.

```Perl
$code
```

More plain text.
EOF

    #  End code block

    #  Code block as per Pandoc v1.12.3.3
    #
    push @text, <<"EOF";
Some plain text.

``` {.Perl}
$code
```

More plain text.
EOF

    #  End code block

    #  Code block as per Pandoc v1.13.2
    #
    push @text, <<"EOF";
Some plain text.

``` Perl
$code
```

More plain text.
EOF

    #  End code block

    #  Code block with trailing space after Perl language declaration
    #
    push @text, <<"EOF";
Some plain text.

``` Perl 
$code
```

More plain text.
EOF

    #  End code block

    foreach my $text (@text) {

        my $expect = [
            { type => 'paragraph' },
            [
                {
                    type => 'text',
                    text => "Some plain text.\n",
                },
            ], {
                type     => 'code_block',
                code     => $code,
                language => 'Perl',
            },
            { type => 'paragraph' },
            [
                {
                    type => 'text',
                    text => "More plain text.\n",
                },
            ],
        ];

        parse_ok(
            { dialects => 'GitHub' },
            $text,
            $expect,
            'fenced code block with language indicator'
        );
    }
}

{
    my $code = <<'EOF';
---
test
---
EOF

    my $text = <<"EOF";
```
$code
```
EOF

    my $expect = [
        {
            type     => 'code_block',
            code     => $code,
            language => undef,
        },
    ];

    parse_ok(
        { dialects => 'GitHub' },
        $text,
        $expect,
        'fenced code block with dashes in it - dashes are not treated as two-line header'
    );
}

done_testing();
