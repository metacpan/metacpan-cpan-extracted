use warnings;
use strict;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use MKDoc::Text::Structured;

my $text = <<EOF;
* Hello
  =====

  Hello, World, this is test


This is a paragraph,
until it meets an empty line.

  But this is pre-formatted text.
  Hey  Hey Ho  Ho!

This is another paragraph.
EOF

my $res = MKDoc::Text::Structured::process ($text);

like ($res, qr#<ul><li><h2>Hello</h2>#);
like ($res, qr#<p>Hello, World, this is test</p></li></ul>#);
like ($res, qr#<p>This is a paragraph,#);
like ($res, qr#until it meets an empty line.</p>#);
like ($res, qr#<pre>But this is pre-formatted text.#);
like ($res, qr#Hey  Hey Ho  Ho!</pre>#);
like ($res, qr#<p>This is another paragraph.</p>#);


1;


__END__
