use strict;
use warnings;
use Test::More;
use Markdown::Simple qw(markdown_to_html);

# Each test passes `{ <feature> => 0 }` and asserts that the corresponding
# syntax is NOT recognised (the source bytes fall through as literal text).

sub like_html { my ($got, $re, $name) = @_; like $got, $re, $name; }

# ---- headers ------------------------------------------------------------
{
    my $h = markdown_to_html("# hi\n",       { headers => 0 });
    unlike $h, qr{<h1>}, 'ATX heading disabled';
    like   $h, qr{# hi},  '... and emitted as text';

    my $s = markdown_to_html("Hi\n==\n",     { headers => 0 });
    unlike $s, qr{<h1>}, 'setext heading disabled';
}

# ---- thematic break -----------------------------------------------------
{
    my $h = markdown_to_html("---\n",        { thematic_break => 0 });
    unlike $h, qr{<hr},   'thematic break disabled';
}

# ---- fenced code --------------------------------------------------------
{
    my $h = markdown_to_html("```\nx\n```\n", { fenced_code => 0 });
    unlike $h, qr{<pre><code},                 'fenced code disabled (no <pre><code>)';
    like   $h, qr{<p>},                        '... text rendered as paragraph';
}

# ---- indented code ------------------------------------------------------
{
    my $h = markdown_to_html("    code\n",   { indented_code => 0 });
    unlike $h, qr{<pre><code},               'indented code disabled';
    like   $h, qr{code},                      '... still has the text';
}

# ---- blockquote ---------------------------------------------------------
{
    my $h = markdown_to_html("> hi\n",       { blockquote => 0 });
    unlike $h, qr{<blockquote>},             'blockquote disabled';
    like   $h, qr{&gt; hi|&gt;\s*hi},         '... &gt; escaped marker present';
}

# ---- ordered / unordered lists -----------------------------------------
{
    my $h = markdown_to_html("1. one\n2. two\n", { ordered_lists => 0 });
    unlike $h, qr{<ol>}, 'ordered lists disabled';

    my $u = markdown_to_html("- one\n- two\n",   { unordered_lists => 0 });
    unlike $u, qr{<ul>}, 'unordered lists disabled';

    my $b = markdown_to_html("- one\n- two\n",   { unordered_lists => 0, ordered_lists => 0 });
    unlike $b, qr{<[uo]l>}, 'both list kinds disabled';
}

# ---- html ---------------------------------------------------------------
{
    my $h = markdown_to_html("<div>x</div>\n", { html => 0, unsafe => 1 });
    unlike $h, qr{<div>}, 'raw HTML block disabled';
}

# ---- references ---------------------------------------------------------
{
    # Use a hostname with a space so it can never be auto-linked; we want
    # to assert only that the *reference* mechanism is off, not test the
    # autolink scanner.
    my $h = markdown_to_html("[a]: target\n\n[a][a]\n", { references => 0 });
    unlike $h, qr{href="target"}, 'link references disabled';
}

# ---- inline: bold / italic ---------------------------------------------
{
    my $h = markdown_to_html("**bold**\n",  { bold => 0 });
    unlike $h, qr{<strong>},                 'strong disabled';

    my $i = markdown_to_html("*em*\n",       { italic => 0 });
    unlike $i, qr{<em>},                     'emph disabled';
}

# ---- inline: code -------------------------------------------------------
{
    my $h = markdown_to_html("a `c` b\n",    { code => 0 });
    unlike $h, qr{<code>},                   'inline code disabled';
    like   $h, qr{`c`},                       '... backticks emitted literally';
}

# ---- inline: links / images --------------------------------------------
{
    my $h = markdown_to_html("[x](y)\n",     { links => 0 });
    unlike $h, qr{<a\s+href},                'inline links disabled';

    my $i = markdown_to_html("![alt](src)\n", { images => 0 });
    unlike $i, qr{<img\b},                   'inline images disabled';
}

# ---- defaults preserved -------------------------------------------------
{
    my $h = markdown_to_html("# t\n");
    like $h, qr{<h1>t</h1>}, 'default options unchanged (heading still works)';
}

done_testing;
