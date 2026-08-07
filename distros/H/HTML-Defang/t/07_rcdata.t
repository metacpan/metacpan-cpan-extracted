#!/usr/bin/perl -w

BEGIN { # CPAN users don't have ME::*, so use eval
  eval 'use ME::FindLibs'
}

use Test::More tests => 16;
use HTML::Defang;

use strict;
use warnings;

my ($R, $H);

my $D = HTML::Defang->new();

# The contents of a <title> element are RCDATA (see the HTML5 spec:
#  https://dev.w3.org/html5/spec-LC/tree-construction.html#parsing-main-inhead
#  -> generic RCDATA element parsing algorithm). That means a browser does
#  *not* parse comments or nested tags inside a title; the only markup it
#  recognises is a matching </title end tag, everything else is text.
#
# The interesting bug: an attacker hides a literal </title> plus active
# markup inside what looks like an HTML comment. If the defanger parses the
# title as normal HTML it interprets the <!-- --> comment and thinks the
# <img> is inert comment data, emitting it unchanged. But a browser closes
# the title at the literal </title> and then runs the <img> as live markup.

# Simple title passes through untouched
$H = q{<title>some title</title>};
$R = $D->defang($H);
is($R, q{<title>some title</title>}, "Plain title unchanged");

# Character references in a title are left alone (they're just text)
$H = q{<title>Me &amp; You &lt;3</title>};
$R = $D->defang($H);
is($R, q{<title>Me &amp; You &lt;3</title>}, "Title entities preserved");

# THE BUG: <img onerror> smuggled inside a comment, after a literal </title>.
# Before the fix, the whole "<!-- ... -->" was treated as an inert comment and
# the <img onerror> was emitted verbatim - a browser would close the title at
# the literal </title> and then execute the onerror. After the fix, title
# content is treated as RCDATA (stops at the first </title), so the <img> is
# parsed as a real post-title tag and its onerror is defanged.
$H = q{<title><!-- </title> <img src=x onerror=alert(1)> --></title>};
$R = $D->defang($H);
unlike($R, qr{<img\b[^>]*\bonerror=}i, "onerror after smuggled </title> is defanged");
like($R, qr{defang_onerror}i, "onerror was defanged, not dropped");

# Same idea, but hiding the breakout inside an attribute value. In RCDATA the
# browser ignores the quoting entirely, closes at </title>, and runs the <img>.
$H = q{<title>x<img alt="</title><img src=x onerror=alert(1)>"></title>};
$R = $D->defang($H);
unlike($R, qr{<img\b[^>]*\bonerror=}i, "onerror inside attr-smuggled breakout is defanged");

# The comment-mangling end-tag confusion from the bug report: a browser keeps
# all of this as title text (the </ti< is not a valid end tag and comments
# don't exist in RCDATA), so the defanger must not mangle it either.
$H = q{<title>abc</ti<!-- foo -->tle></title>};
$R = $D->defang($H);
is($R, q{<title>abc</ti<!-- foo -->tle></title>}, "RCDATA text with fake end tag/comment left intact");

# A </titlex is not a real end tag (must be followed by whitespace / > / /),
# so it stays as title text and title only closes at the real </title>.
$H = q{<title>a</titlex>b</title>};
$R = $D->defang($H);
is($R, q{<title>a</titlex>b</title>}, "Non-boundary </titlex is text, not an end tag");

# No closing </title> at all: like a browser, the rest is title text and any
# would-be tags inside stay inert text rather than being parsed.
$H = q{<title>unterminated <img src=x onerror=alert(1)>};
$R = $D->defang($H);
is($R, q{<title>unterminated <img src=x onerror=alert(1)>}, "Unterminated title keeps content as RCDATA text");

# The same class of bug applies to every element the HTML tokenizer treats as
# RCDATA/RAWTEXT and that we keep as a real tag: <textarea> (RCDATA) and
# <noembed>/<noframes> (RAWTEXT). Each must consume its content as opaque text
# up to its own end tag, so a comment-smuggled breakout gets defanged.
for my $Tag (qw(textarea noembed noframes)) {
  $H = qq{<$Tag><!-- </$Tag> <img src=x onerror=alert(1)> --></$Tag>};
  $R = $D->defang($H);
  unlike($R, qr{<img\b[^>]*\bonerror=}i, "$Tag: onerror after smuggled </$Tag> is defanged");
  like($R, qr{defang_onerror}i, "$Tag: onerror was defanged, not dropped");
}

# <textarea>'s own attribute rules must survive the raw-text handling: known
# attributes (cols/rows) are kept, event handlers are defanged.
$H = q{<textarea cols=40 rows=5 onclick=alert(1)>hi</textarea>};
$R = $D->defang($H);
like($R, qr{cols=40 rows=5}, "textarea keeps known attributes");
like($R, qr{defang_onclick}, "textarea defangs event handler attribute");
