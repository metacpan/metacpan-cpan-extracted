use strict;
use warnings;

use Test::Differences;
use Test::More tests => 2;

use HTML::WikiConverter;

my $wc = HTML::WikiConverter->new( dialect => 'MultiMarkdown' );


{
    my $wiki = $wc->html2wiki( <<'EOF' );
<html>
<head>
<title>My Title</title>
</head>
<body>

<p>
Some random text.
</p>

<table>
  <tr>
    <th>Foo</th>
    <th>Bar</th>
  </tr>
  <tr>
    <td>1</td>
    <td>2</td>
  </tr>
  <tr>
    <td>3</td>
    <td>42</td>
  </tr>
</table>
</body>
</html>
EOF

    eq_or_diff( $wiki . "\n", <<'EOF', 'got expected wikitext back' );
Title: My Title

Some random text.

| Foo | Bar  |
|---|---|
| 1 | 2  |
| 3 | 42  |
EOF
}

{
    my $wiki = $wc->html2wiki( <<'EOF' );
<html>
<head>
<title>My Title</title>
</head>
<body>

<p>
<a href="http://example.com/">Some random text</a>.
</p>
</body>
</html>
EOF

    eq_or_diff( $wiki . "\n", <<'EOF', 'got expected wikitext back' );
Title: My Title

[Some random text][1].

  [1]: http://example.com/
EOF
}
