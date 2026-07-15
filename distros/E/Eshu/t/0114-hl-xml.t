use strict;
use warnings;
use Test::More;
use Eshu;

sub hl_xml  { Eshu->highlight_string($_[0], lang => 'xml') }
sub hl_html { Eshu->highlight_string($_[0], lang => 'html') }

# ── tag names ─────────────────────────────────────────────────────

{
    my $got = hl_xml("<root>");
    like($got, qr{<span class="esh-g">root</span>}, 'XML opening tag name');
}

{
    my $got = hl_xml("</body>");
    like($got, qr{<span class="esh-g">body</span>}, 'XML closing tag name');
}

{
    my $got = hl_xml("<br/>");
    like($got, qr{<span class="esh-g">br</span>}, 'self-closing tag name');
}

{
    my $got = hl_html("<div>");
    like($got, qr{<span class="esh-g">div</span>}, 'HTML tag name: div');
}

{
    my $got = hl_html("<p class=\"intro\">");
    like($got, qr{<span class="esh-g">p</span>}, 'HTML tag name: p');
}

# namespaced tags
{
    my $got = hl_xml("<ns:element>");
    like($got, qr{<span class="esh-g">ns:element</span>}, 'namespaced tag name');
}

# ── attribute names ───────────────────────────────────────────────

{
    my $got = hl_xml('<tag attr="val">');
    like($got, qr{<span class="esh-a">attr</span>}, 'attribute name');
}

{
    my $got = hl_html('<input type="text" name="q" id="search">');
    like($got, qr{<span class="esh-a">type</span>}, 'attribute: type');
    like($got, qr{<span class="esh-a">name</span>}, 'attribute: name');
    like($got, qr{<span class="esh-a">id</span>},   'attribute: id');
}

{
    my $got = hl_xml('<elem xml:lang="en">');
    like($got, qr{<span class="esh-a">xml:lang</span>}, 'namespaced attribute');
}

# ── attribute values ──────────────────────────────────────────────

{
    my $got = hl_xml('<tag attr="value">');
    like($got, qr{<span class="esh-s">&quot;value&quot;</span>}, 'double-quoted attribute value');
}

{
    my $got = hl_xml("<tag attr='value'>");
    like($got, qr{<span class="esh-s">'value'</span>}, 'single-quoted attribute value');
}

{
    my $got = hl_html('<a href="http://example.com">');
    like($got, qr{<span class="esh-s">&quot;http://example\.com&quot;</span>}, 'URL attribute value');
}

# ── comments ──────────────────────────────────────────────────────

{
    my $got = hl_xml("<!-- a comment -->");
    like($got, qr{<span class="esh-c">&lt;!-- a comment --&gt;</span>}, 'XML comment');
}

{
    my $got = hl_xml("<!-- multi\nline\ncomment -->");
    like($got, qr{<span class="esh-c">}, 'multi-line comment opens span');
}

{
    my $got = hl_html("<!-- TODO: remove this -->");
    like($got, qr{<span class="esh-c">&lt;!-- TODO: remove this --&gt;</span>},
        'HTML comment');
}

# ── CDATA ─────────────────────────────────────────────────────────

{
    my $got = hl_xml("<![CDATA[raw < data & here]]>");
    like($got, qr{<span class="esh-s">&lt;!\[CDATA\[raw &lt; data &amp; here\]\]&gt;</span>},
        'CDATA section');
}

# ── DOCTYPE / PI ──────────────────────────────────────────────────

{
    my $got = hl_xml("<!DOCTYPE html>");
    like($got, qr{<span class="esh-p">&lt;!DOCTYPE html&gt;</span>}, 'DOCTYPE');
}

{
    my $got = hl_xml("<?xml version=\"1.0\"?>");
    # PI falls through as plain text (no span) — just check it doesn't crash
    ok(defined $got, 'processing instruction does not crash');
}

# ── text content ──────────────────────────────────────────────────

{
    my $got = hl_html("<p>Hello world</p>");
    like($got, qr{Hello world}, 'text content is preserved');
}

{
    my $got = hl_xml("<note>AT&amp;T</note>");
    # &amp; in source is already an entity; after our HTML-escape it becomes &amp;amp;
    like($got, qr{AT&amp;amp;T}, 'entity in text content is double-escaped (safe)');
}

# ── the '<' '>' in tags themselves ────────────────────────────────

{
    my $got = hl_xml("<root>");
    like($got, qr{&lt;}, 'opening < of tag is HTML-escaped');
    like($got, qr{&gt;}, 'closing > of tag is HTML-escaped');
}

# ── mixed content ─────────────────────────────────────────────────

{
    my $src = <<'END';
<?xml version="1.0"?>
<!-- greeting -->
<greet lang="en">
  <msg>Hello &amp; welcome</msg>
</greet>
END
    my $got = hl_xml($src);
    like($got, qr{<span class="esh-c">&lt;!-- greeting --&gt;</span>},
        'comment in full XML example');
    like($got, qr{<span class="esh-g">greet</span>}, 'root tag in full XML example');
    like($got, qr{<span class="esh-a">lang</span>},  'attribute in full XML example');
    like($got, qr{<span class="esh-s">&quot;en&quot;</span>},  'attr value in full XML example');
    like($got, qr{<span class="esh-g">msg</span>},   'child tag in full XML example');
}

{
    my $src = <<'END';
<!DOCTYPE html>
<!-- page -->
<html lang="en">
<head><title>Test</title></head>
<body class="main">
  <p id="intro">Hi &amp; welcome</p>
</body>
</html>
END
    my $got = hl_html($src);
    like($got, qr{<span class="esh-p">&lt;!DOCTYPE html&gt;</span>},
        'DOCTYPE in full HTML example');
    like($got, qr{<span class="esh-c">&lt;!-- page --&gt;</span>},
        'comment in full HTML example');
    like($got, qr{<span class="esh-g">html</span>},  'html tag in full HTML example');
    like($got, qr{<span class="esh-g">head</span>},  'head tag in full HTML example');
    like($got, qr{<span class="esh-g">title</span>}, 'title tag in full HTML example');
    like($got, qr{<span class="esh-g">body</span>},  'body tag in full HTML example');
    like($got, qr{<span class="esh-a">class</span>}, 'class attr in full HTML example');
    like($got, qr{<span class="esh-s">&quot;main&quot;</span>}, 'class value in full HTML example');
    like($got, qr{<span class="esh-g">p</span>},      'p tag in full HTML example');
}


# ── boolean attribute (no value) ──────────────────────────────────

{
    my $got = hl_html("<input disabled>");
    like($got, qr{<span class="esh-a">disabled</span>}, 'boolean attribute with no value');
}

# ── multiple attributes on one tag ────────────────────────────────

{
    my $got = hl_html('<div id="app" class="main" data-v="1">');
    like($got, qr{<span class="esh-a">id</span>},     'attr: id');
    like($got, qr{<span class="esh-a">class</span>},  'attr: class');
    like($got, qr{<span class="esh-a">data-v</span>}, 'attr: data-v (hyphenated)');
}

# ── namespaced element ────────────────────────────────────────────

{
    my $got = hl_xml("<svg:rect x='0' y='0'/>");
    like($got, qr{<span class="esh-g">svg:rect</span>}, 'namespaced element svg:rect');
    like($got, qr{<span class="esh-a">x</span>}, 'attribute x on namespaced element');
}

# ── xmlns attribute ───────────────────────────────────────────────

{
    my $got = hl_xml('<root xmlns="http://example.com">');
    like($got, qr{<span class="esh-a">xmlns</span>}, 'xmlns attribute name');
}

# ── xmlns:prefix attribute ────────────────────────────────────────

{
    my $got = hl_xml('<root xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');
    like($got, qr{<span class="esh-a">xmlns:xsi</span>}, 'xmlns:prefix attribute');
}

# ── attribute value with entities ─────────────────────────────────

{
    my $got = hl_xml('<tag attr="a &amp; b">');
    like($got, qr{<span class="esh-s">&quot;a &amp;amp; b&quot;</span>},
         'entity inside attribute value is double-escaped');
}

# ── self-closing with multiple attrs ──────────────────────────────

{
    my $got = hl_xml('<br class="x" id="y"/>');
    like($got, qr{<span class="esh-g">br</span>},     'self-close tag name');
    like($got, qr{<span class="esh-a">class</span>},  'self-close attr 1');
    like($got, qr{<span class="esh-a">id</span>},     'self-close attr 2');
}

# ── empty element ─────────────────────────────────────────────────

{
    my $got = hl_xml("<empty></empty>");
    my @matches = ($got =~ m{<span class="esh-g">empty</span>}g);
    is(scalar @matches, 2, 'empty element: tag name appears twice (open + close)');
}

# ── CDATA with XML special chars ──────────────────────────────────

{
    my $got = hl_xml("<![CDATA[if (a < b && c > d) { }]]>");
    like($got, qr{<span class="esh-s">}, 'CDATA section gets esh-s span');
    like($got, qr{&lt; b}, 'CDATA content is HTML-escaped');
}

# ── comment content is HTML-escaped ──────────────────────────────

{
    my $got = hl_xml("<!-- a < b & c > d -->");
    like($got, qr{<span class="esh-c">.*&lt;.*&amp;.*&gt;.*</span>}s,
         'comment content HTML-escaped');
}

# ── text content HTML safety ──────────────────────────────────────

{
    my $got = hl_xml("<p>a &lt; b &gt; c</p>");
    like($got, qr{&amp;lt;}, 'entity in text content double-escaped');
}

# ── DOCTYPE lang alias ────────────────────────────────────────────

{
    my $got = Eshu->highlight_string("<html>", lang => 'htm');
    like($got, qr{<span class="esh-g">html</span>}, 'lang=htm dispatches to XML highlighter');
}

{
    my $got = Eshu->highlight_string("<svg/>", lang => 'svg');
    like($got, qr{<span class="esh-g">svg</span>}, 'lang=svg dispatches to XML highlighter');
}

{
    my $got = Eshu->highlight_string("<root/>", lang => 'xhtml');
    like($got, qr{<span class="esh-g">root</span>}, 'lang=xhtml dispatches to XML highlighter');
}

# ── tag-less text (plain content) ─────────────────────────────────

{
    my $got = hl_xml("just some text");
    like($got, qr{just some text}, 'plain text without tags passes through');
    unlike($got, qr{esh-g}, 'plain text has no tag spans');
}

# ── adjacent tags ─────────────────────────────────────────────────

{
    my $got = hl_html("<ul><li>item</li></ul>");
    like($got, qr{<span class="esh-g">ul</span>}, 'ul tag highlighted');
    like($got, qr{<span class="esh-g">li</span>}, 'li tag highlighted');
}

# ── multiline attribute ───────────────────────────────────────────

{
    my $got = hl_html("<div\n    class=\"multi\">");
    like($got, qr{<span class="esh-a">class</span>}, 'attribute on continuation line');
}

done_testing;
