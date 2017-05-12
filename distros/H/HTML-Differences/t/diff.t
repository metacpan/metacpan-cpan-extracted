use strict;
use warnings;

use Test::More;

use HTML::Differences qw( diffable_html );

my $data = do {
    local $/;
    <DATA>;
};

for my $test ( split /^\|{25}$/ms, $data ) {
    my ( $desc, $html, $expect, $ignore_comments )
        = map { split /^-{25}$/m, $_ } $test;
    s/^\n+|\n+$//g for $desc, $expect;

    is_deeply(
        diffable_html(
            $html,
            ignore_comments => $ignore_comments,
        ),
        [ map { s/\\n/\n/g; $_ } grep { length } split /\n/, $expect ],
        $desc
    );
}

done_testing();

__DATA__
simple HTML5 document
-------------------------
<!DOCTYPE html>
<html>
  <head>
    <title>Test1</title>
  </head>
  <body>
    <p>Paragraph</p>
  </body>
</html>
-------------------------
<!DOCTYPE html>
<html>
<head>
<title>
Test1
</title>
</head>
<body>
<p>
Paragraph
</p>
</body>
</html>
|||||||||||||||||||||||||
attribute with entity in value
-------------------------
<p class="foo&quot;bar">Paragraph</p>
-------------------------
<p class="foo&quot;bar">
Paragraph
</p>
|||||||||||||||||||||||||
including comments
-------------------------
<!--comment-->
<p>Foo</p>
-------------------------
<!--comment-->
<p>
Foo
</p>
|||||||||||||||||||||||||
ignoring comments
-------------------------
<!--comment-->
<p>Foo</p>
-------------------------
<p>
Foo
</p>
-------------------------
1
|||||||||||||||||||||||||
whitespace in <pre> tag
-------------------------
<p>
  Foo
</p>

<pre>
  Foo

</pre>

<p>

  Bar

</p>
-------------------------
<p>
Foo
</p>
<pre>
\n  Foo\n\n
</pre>
<p>
Bar
</p>
|||||||||||||||||||||||||
whitespace-only text
-------------------------
<p>

</p>
-------------------------
<p>
</p>
|||||||||||||||||||||||||
Missing end tag
-------------------------
<p>This is <strong>strong</p>
-------------------------
<p>
This is
<strong>
strong
</p>
