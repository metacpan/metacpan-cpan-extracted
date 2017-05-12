use warnings;
use strict;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use MKDoc::Text::Structured;

my $text = <<EOF;
* An item
* Another item

* Headlines work too
  ==================

  I can write *paragraphs within lists*.

    And even _pre-formatted text_!

  - Also, I can have sub-lists
  - That's no problem
  - Notice that '*' and '-' have the same meaning.
    It's just syntaxic sugar, really
EOF

my $res = MKDoc::Text::Structured::process ($text);
like ($res, qr#<ul><li><p>An item</p></li>#);
like ($res, qr#<li><p>Another item</p></li>#);
like ($res, qr#<li><h2>Headlines work too</h2>#);
like ($res, qr#<p>I can write <strong>paragraphs within lists</strong>.</p>#);
like ($res, qr#<pre>And even _pre-formatted text_!</pre>#);
like ($res, qr#<ul><li><p>Also, I can have sub-lists</p></li>#);
like ($res, qr#<li><p>That's no problem</p></li>#);
like ($res, qr#<li><p>Notice that &lsquo;\*&rsquo; and &lsquo;-&rsquo; have the same meaning.#);
like ($res, qr#It's just syntaxic sugar, really</p></li></ul></li></ul>#);

1;

__END__
