use strict;
use warnings;

use Test::More 0.88;

use Markdent::Simple::Fragment;

my $mds = Markdent::Simple::Fragment->new();

my $markdown = <<'EOF';
A header
========

Some *text* with **markup**
in a paragraph.

* a list
* with items

That is all
EOF

my $expect = <<'EOF';
<h1>A header
</h1><p>Some <em>text</em> with <strong>markup</strong>
in a paragraph.
</p><ul><li>a list
</li><li>with items
</li></ul><p>That is all
</p>
EOF

chomp $expect;

is(
    $mds->markdown_to_html( markdown => $markdown ),
    $expect,
    'Markdent::Simple::Fragment returns expected HTML'
);

done_testing();
