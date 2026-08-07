use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Markdown::Simple;

sub hl {
    my ($src, %extra) = @_;
    Markdown::Simple::markdown_to_html($src, { highlight => 1, %extra });
}

sub hl_s {
    my ($src, %extra) = @_;
    Markdown::Simple->new({ highlight => 1, %extra })->render($src);
}

# ── flag disabled: fenced blocks pass through as plain HTML ───────────────

{
    my $out = Markdown::Simple::markdown_to_html("```perl\nmy \$x = 1;\n```\n");
    like   $out, qr{<pre><code class="language-perl">},  'flag off: opens code element';
    unlike $out, qr{<span},                              'flag off: no spans emitted';
    like   $out, qr{my \$x = 1;},                        'flag off: content preserved verbatim';
}

# ── flag enabled, no language tag: plain passthrough ─────────────────────

{
    my $out = hl("```\nplain code\n```\n");
    like   $out, qr{<pre><code>plain code},  'no lang: plain <pre><code>';
    unlike $out, qr{<span},                 'no lang: no spans';
}

# ── Perl ─────────────────────────────────────────────────────────────────

{
    my $out = hl("```perl\nmy \$x = 42;\n```\n");
    like $out, qr{<pre><code class="language-perl">},  'perl: opens with language class';
    like $out, qr{<span class="esh-k">my</span>},      'perl: keyword my';
    like $out, qr{<span class="esh-v">\$x</span>},    'perl: variable $x';
    like $out, qr{<span class="esh-n">42</span>},      'perl: number 42';
    like $out, qr{</code></pre>},                       'perl: closes correctly';
}

{
    my $out = hl("```perl\nif (\$ok) { die \"oops\"; }\n```\n");
    like $out, qr{<span class="esh-k">if</span>},     'perl: keyword if';
    like $out, qr{<span class="esh-k">die</span>},    'perl: keyword die';
    like $out, qr{&quot;oops&quot;},                   'perl: double-quotes HTML-escaped inside string span';
}

{
    my $out = hl("```perl\n# a comment\n```\n");
    like $out, qr{<span class="esh-c"># a comment</span>}, 'perl: line comment';
}

{
    my $out = hl("```pl\nmy \$y = 1;\n```\n");
    like $out, qr{<span class="esh-k">my</span>}, 'pl alias: highlighting applies';
}

# ── C ────────────────────────────────────────────────────────────────────

{
    my $out = hl("```c\nint x = 0;\n```\n");
    like $out, qr{<pre><code class="language-c">},     'c: opens with language class';
    like $out, qr{<span class="esh-k">int</span>},      'c: keyword int';
    like $out, qr{<span class="esh-n">0</span>},        'c: number 0';
}

{
    my $out = hl("```c\n/* comment */\n```\n");
    like $out, qr{<span class="esh-c">}, 'c: block comment';
}

{
    my $out = hl("```c\n#include <stdio.h>\n```\n");
    like $out, qr{<span class="esh-p">}, 'c: preprocessor directive';
}

# ── JavaScript ───────────────────────────────────────────────────────────

{
    my $out = hl("```js\nconst x = 1;\n```\n");
    like $out, qr{<span class="esh-k">const</span>}, 'js: keyword const';
    like $out, qr{<span class="esh-n">1</span>},     'js: number 1';
}

{
    my $out = hl("```javascript\nreturn null;\n```\n");
    like $out, qr{<span class="esh-k">return</span>}, 'javascript alias: keyword return';
    like $out, qr{<span class="esh-k">null</span>},   'javascript alias: keyword null';
}

{
    my $out = hl("```js\n// note\n```\n");
    like $out, qr{<span class="esh-c">// note</span>}, 'js: line comment';
}

# ── CSS ──────────────────────────────────────────────────────────────────

{
    my $out = hl("```css\n\@media screen { }\n```\n");
    like $out, qr{<span class="esh-p">}, 'css: at-rule';
}

{
    my $out = hl("```css\n/* reset */\n```\n");
    like $out, qr{<span class="esh-c">}, 'css: block comment';
}

# ── XML / HTML ───────────────────────────────────────────────────────────

{
    my $out = hl("```xml\n<root attr=\"val\"/>\n```\n");
    like $out, qr{<span class="esh-g">root</span>},   'xml: tag name';
    like $out, qr{<span class="esh-a">attr</span>},   'xml: attribute name';
    like $out, qr{<span class="esh-s">&quot;val&quot;</span>}, 'xml: attribute value HTML-escaped';
}

{
    my $out = hl("```html\n<div id=\"app\">\n```\n");
    like $out, qr{<span class="esh-g">div</span>},    'html: tag name';
    like $out, qr{<span class="esh-a">id</span>},     'html: attribute';
}

# ── HTML safety: content must always be escaped ───────────────────────────

{
    my $out = hl("```c\nchar *s = \"<b>&amp;</b>\";\n```\n");
    unlike $out, qr{<b>},     'c: raw < not passed through';
    like   $out, qr{&lt;b&gt;}, 'c: < escaped to &lt; inside string span';
    like   $out, qr{&amp;},    'c: & escaped inside string span';
}

# ── Language tag is lowercased ────────────────────────────────────────────

{
    my $out = hl("```Perl\nmy \$z = 0;\n```\n");
    like $out, qr{<pre><code class="language-perl">}, 'uppercased lang tag lowercased in class';
    like $out, qr{<span class="esh-k">my</span>},     'uppercased lang still highlighted';
}

# ── Surrounding document structure is intact ─────────────────────────────

{
    my $src = "# Title\n\nParagraph.\n\n```perl\nmy \$x = 1;\n```\n\nAfter.\n";
    my $out = hl($src);
    like $out, qr{<h1>Title</h1>},                 'surrounding h1 intact';
    like $out, qr{<p>Paragraph\.</p>},             'surrounding paragraph intact';
    like $out, qr{<span class="esh-k">my</span>}, 'fenced block highlighted';
    like $out, qr{<p>After\.</p>},                 'trailing paragraph intact';
}

# ── Multiple fenced blocks in one document ────────────────────────────────

{
    my $src = "```perl\nmy \$a = 1;\n```\n\n```c\nint b = 2;\n```\n";
    my $out = hl($src);
    like $out, qr{<span class="esh-k">my</span>},  'first block: perl keyword';
    like $out, qr{<span class="esh-k">int</span>}, 'second block: c keyword';
}

# ── Session (OO) API ─────────────────────────────────────────────────────

{
    my $md = Markdown::Simple->new({ highlight => 1 });
    my $out = $md->render("```perl\nuse strict;\n```\n");
    like $out, qr{<span class="esh-k">use</span>}, 'session API: perl keyword highlighted';
}

{
    my $md  = Markdown::Simple->new({ highlight => 1 });
    my $out = $md->render("```perl\nmy \$i = \$_;\n```\n");
    like $out, qr{<span class="esh-v">\$i</span>}, 'session: variable $i';
    like $out, qr{<span class="esh-v">\$_</span>}, 'session: variable $_';

    # second render on same session should work correctly
    my $out2 = $md->render("```c\nvoid f(void) {}\n```\n");
    like $out2, qr{<span class="esh-k">void</span>}, 'session reuse: second render correct';
}

done_testing;
