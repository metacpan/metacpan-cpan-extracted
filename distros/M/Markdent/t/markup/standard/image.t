use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::Markdent;

{
    my $text = <<'EOF';
An image: ![My Alt](http://www.example.com/example.jpg)
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => 'An image: ',
            }, {
                type           => 'image',
                uri            => 'http://www.example.com/example.jpg',
                alt_text       => 'My Alt',
                is_implicit_id => 0,
            }, {
                type => 'text',
                text => "\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'text and an inline link image' );
}

{
    my $text = <<'EOF';
![My Alt](http://www.example.com/example.jpg "A title")
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type           => 'image',
                uri            => 'http://www.example.com/example.jpg',
                alt_text       => 'My Alt',
                title          => 'A title',
                is_implicit_id => 0,
            }, {
                type => 'text',
                text => "\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'inline image (has title)' );
}

{
    my $text = <<'EOF';
![My Alt][image]

[image]: /foo.jpg
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type           => 'image',
                id             => 'image',
                uri            => '/foo.jpg',
                alt_text       => 'My Alt',
                is_implicit_id => 0,
            }, {
                type => 'text',
                text => "\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'image linked by id' );
}

{
    my $text = <<'EOF';
![My Alt] [image]

[image]: /foo.jpg
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type           => 'image',
                id             => 'image',
                uri            => '/foo.jpg',
                alt_text       => 'My Alt',
                is_implicit_id => 0,
            }, {
                type => 'text',
                text => "\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'image by id, space before id' );
}

{
    my $text = <<'EOF';
![My Alt][]

[My Alt]: /bar.jpg
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type           => 'image',
                id             => 'My Alt',
                uri            => '/bar.jpg',
                alt_text       => 'My Alt',
                is_implicit_id => 1,
            }, {
                type => 'text',
                text => "\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'image by id, implicit id' );
}

{
    my $text = <<'EOF';
![My Alt]

[My Alt]: /baz.jpg "foo"
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type           => 'image',
                id             => 'My Alt',
                alt_text       => 'My Alt',
                uri            => '/baz.jpg',
                title          => 'foo',
                is_implicit_id => 1,
            }, {
                type => 'text',
                text => "\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'image by id, implicit id (no [])' );
}

{
    my $text = <<'EOF';
![Empty]()
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type           => 'image',
                alt_text       => 'Empty',
                uri            => q{},
                is_implicit_id => 0,
            }, {
                type => 'text',
                text => "\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'An empty inline image' );
}

{
    my $text = <<'EOF';
![Empty](  )
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type           => 'image',
                alt_text       => 'Empty',
                uri            => q{},
                is_implicit_id => 0,
            }, {
                type => 'text',
                text => "\n",
            },
        ]
    ];

    parse_ok( $text, $expect, 'An inline image with only whitespace' );
}

{
    my $text = <<'EOF';
![Image?][no such id]
EOF

    my $expect = [
        { type => 'paragraph' },
        [
            {
                type => 'text',
                text => "![Image?][no such id]\n",
            },
        ]
    ];

    parse_ok(
        $text, $expect,
        'Image by reference with a bad id is treated as text'
    );
}

done_testing();
