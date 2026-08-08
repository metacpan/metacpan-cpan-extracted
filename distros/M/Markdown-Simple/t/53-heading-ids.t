#!perl

# heading_ids => 1 puts a GitHub-style anchor on every heading.
#
# The renderer is a streaming emitter, so a heading's open tag falls due
# before the inline content the id is slugged from exists. It writes no tag at
# heading-enter, notes the offset, lets the inlines render normally, and
# splices the finished <hN id="..."> back in at leave. These tests pin both
# halves of that: the slug rule itself, and the fact that splicing does not
# disturb the inline content it was threaded around.

use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Markdown::Simple;

sub ids {
    my ($src, %opt) = @_;
    my $html = markdown_to_html($src, { heading_ids => 1, %opt });
    return [ $html =~ /<h[1-6] id="([^"]*)"/g ];
}

# ---- off unless asked for ---------------------------------------------------

{
    my $html = markdown_to_html("# Hello World\n");
    like $html, qr{<h1>Hello World</h1>}, 'no id by default';
    unlike $html, qr{id=}, 'nothing resembling an id leaks in';
}

# ---- the slug rule ----------------------------------------------------------

is_deeply ids("# Hello World\n"), ['hello-world'],
    'spaces become hyphens, case folds down';

is_deeply ids("### Whats New, Really?!\n"), ['whats-new-really'],
    'ASCII punctuation is dropped, not transliterated';

is_deeply ids("#    lots     of   space   \n"), ['lots-of-space'],
    'runs of whitespace collapse to one hyphen and the edges are trimmed';

is_deeply ids("# 42 things\n"), ['42-things'],
    'digits are kept, including in the leading position';

is_deeply ids("# snake_case_name\n"), ['snake_case_name'],
    'underscores and hyphens survive as themselves';

is_deeply ids("# -- leading and trailing --\n"), ['leading-and-trailing'],
    'hyphens at either edge are trimmed';

# ---- the slug comes from the text, not the markup ---------------------------

{
    my $html = markdown_to_html("## The **bold** bit\n", { heading_ids => 1 });
    like $html, qr{<h2 id="the-bold-bit">},
        'slug ignores emphasis markup';
    like $html, qr{<h2 id="the-bold-bit">The <strong>bold</strong> bit</h2>},
        'and the rendered inline content is left intact around the splice';
}

is_deeply ids("## First `code` bit\n"), ['first-code-bit'],
    'code span contributes its text to the slug';

is_deeply ids("# [a link](http://example.com)\n"), ['a-link'],
    'link text contributes, the destination does not';

is_deeply ids("# ![the alt text](x.png)\n"), ['the-alt-text'],
    'an image heading slugs from its alt text';

# ---- uniqueness -------------------------------------------------------------

is_deeply ids("# Notes\n\n# Notes\n\n# Notes\n"),
    ['notes', 'notes-1', 'notes-2'],
    'repeated headings are numbered from the original stem, not compounded';

is_deeply ids("# Notes!\n\n# Notes?\n"), ['notes', 'notes-1'],
    'headings that collide only after punctuation is stripped still de-duplicate';

# ---- degenerate headings ----------------------------------------------------

is_deeply ids("# ???\n"), ['section'],
    'a heading with nothing sluggable falls back to a positional stem';

is_deeply ids("# ???\n\n# !!!\n"), ['section', 'section-1'],
    'and those fall backs de-duplicate against each other';

# ---- non-ASCII --------------------------------------------------------------

{
    # Lowercasing UTF-8 correctly would need a full case-folding table, and
    # half-doing it would corrupt multi-byte sequences, so bytes >= 0x80 pass
    # through untouched. The anchor stays stable and round-trippable.
    my $html = markdown_to_html("# Ünicode Ähead\n", { heading_ids => 1 });
    like $html, qr{<h1 id="[^"]+">}, 'a non-ASCII heading still gets an id';
    my ($id) = $html =~ /<h1 id="([^"]*)"/;
    like $id, qr/nicode/, 'the ASCII run is lowercased as usual';
    like $id, qr/-/,      'the space still became a hyphen';
}

# ---- every level ------------------------------------------------------------

is_deeply ids("# a\n\n## b\n\n### c\n\n#### d\n\n##### e\n\n###### f\n"),
    [ 'a', 'b', 'c', 'd', 'e', 'f' ],
    'all six levels are anchored';

{
    my $html = markdown_to_html("# a\n\n###### f\n", { heading_ids => 1 });
    like $html, qr{<h1 id="a">a</h1>},      'h1 closes as an h1';
    like $html, qr{<h6 id="f">f</h6>},      'h6 closes as an h6';
}

# ---- setext -----------------------------------------------------------------

is_deeply ids("Setext Heading\n===\n"), ['setext-heading'],
    'setext headings are anchored too';

is_deeply ids("Sub Heading\n---\n"), ['sub-heading'],
    'and the level-2 setext form';

# ---- the splice does not disturb the document -------------------------------

{
    my $src  = "# Top\n\nA paragraph.\n\n## Middle\n\n- one\n- two\n\n## End\n\nLast.\n";
    my $with = markdown_to_html($src, { heading_ids => 1 });
    my $without = markdown_to_html($src);

    (my $stripped = $with) =~ s/ id="[^"]*"//g;
    is $stripped, $without,
        'removing the ids reproduces the un-anchored render byte for byte';
}

{
    # A heading long enough to force the output buffer to grow while the
    # splice point is outstanding: the mark is an offset precisely so a
    # realloc between enter and leave cannot invalidate it.
    my $long = 'word ' x 4000;
    my $html = markdown_to_html("# $long\n", { heading_ids => 1 });
    like $html, qr{<h1 id="word-word-},
        'a heading that outgrows the buffer still gets its tag spliced in';
    like $html, qr{</h1>}, 'and is closed properly';
}

done_testing();
