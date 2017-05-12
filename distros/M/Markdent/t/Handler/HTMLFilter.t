use strict;
use warnings;

use Data::Dumper;
use Test::More 0.88;
use Test::Deep;

use Markdent::Handler::HTMLFilter;
use Markdent::Handler::MinimalTree;
use Markdent::Parser;

use lib 't/lib';

use Test::Markdent;

{
    my $html = <<'EOF';
EOF

    my $text = <<"EOF";
Some text

<div>
  <p>
    An arbitrary chunk of html.
  </p>
</div>

<!-- a comment -->

Some <span>inline</span> HTML.
EOF

    my $expect = [
        {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => "Some text\n",
            },
        ], {
            type => 'paragraph',
        },
        [
            {
                type => 'text',
                text => 'Some ',
            }, {
                type => 'text',
                text => 'inline',
            }, {
                type => 'text',
                text => " HTML.\n",
            },
        ],
    ];

    my $mt = Markdent::Handler::MinimalTree->new();
    my $filter = Markdent::Handler::HTMLFilter->new( handler => $mt );

    my $parser = Markdent::Parser->new( handler => $filter );

    $parser->parse( markdown => $text );

    my $results = tree_from_handler($mt);

    diag( Dumper($results) )
        if $ENV{MARKDENT_TEST_VERBOSE};

    cmp_deeply( $results, $expect, 'all HTML events have been dropped' );
}

done_testing();
