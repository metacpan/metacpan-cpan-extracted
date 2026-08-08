#!perl

# render_with_toc returns ($html, \@headings), where each heading is
# { level, text, id } and the ids are the ones actually on the <hN> tags.
# The point is that a caller can build a table of contents that links into
# the document without re-deriving, re-parsing or guessing anything.

use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Markdown::Simple;

# ---- shape ------------------------------------------------------------------

{
    my $md = Markdown::Simple->new;
    my ($html, $toc) = $md->render_with_toc(
        "# Title\n\nText.\n\n## First bit\n\n### Deep\n\n## Second\n"
    );

    is ref $toc, 'ARRAY', 'the heading list is an arrayref';
    is scalar @$toc, 4,   'one entry per heading';

    is_deeply $toc, [
        { level => 1, text => 'Title',     id => 'title'     },
        { level => 2, text => 'First bit', id => 'first-bit' },
        { level => 3, text => 'Deep',      id => 'deep'      },
        { level => 2, text => 'Second',    id => 'second'    },
    ], 'levels, text and ids in document order';

    like $html, qr{<h1 id="title">},  'the html carries the same ids';
    like $html, qr{<h3 id="deep">},   'at every level';
}

# ---- asking for the list turns the anchors on -------------------------------

{
    # The session was built without heading_ids, but a table of contents whose
    # entries point at anchors that were never emitted would be useless.
    my $md = Markdown::Simple->new;
    my ($html, $toc) = $md->render_with_toc("# Anchored Anyway\n");
    is scalar @$toc, 1, 'one heading collected';
    like $html, qr{<h1 id="anchored-anyway">},
        'ids are emitted even though the session did not ask for them';
}

# ---- text is plain, id is the slug ------------------------------------------

{
    my $md = Markdown::Simple->new;
    my ($html, $toc) = $md->render_with_toc("## The **bold** `code` bit\n");
    is $toc->[0]{text}, 'The bold code bit',
        'text is the plain heading text with inline markup stripped';
    is $toc->[0]{id}, 'the-bold-code-bit', 'id is its slug';
    like $html, qr{<strong>bold</strong>},
        'while the html keeps the markup';
}

# ---- duplicates get the ids they were actually given ------------------------

{
    my $md = Markdown::Simple->new;
    my ($html, $toc) = $md->render_with_toc("# Notes\n\n# Notes\n");
    is_deeply [ map { $_->{id} } @$toc ], [ 'notes', 'notes-1' ],
        'the list reports the de-duplicated ids';
    is_deeply [ map { $_->{text} } @$toc ], [ 'Notes', 'Notes' ],
        'while the text stays as written';
    like $html, qr{id="notes-1"}, 'and matches what the document contains';
}

# ---- empty and heading-free documents ---------------------------------------

{
    my $md = Markdown::Simple->new;
    my ($html, $toc) = $md->render_with_toc('');
    is_deeply $toc, [], 'an empty document has no headings';
    is $html, '', 'and renders to nothing';
}

{
    my $md = Markdown::Simple->new;
    my (undef, $toc) = $md->render_with_toc("Just a paragraph.\n\nAnd another.\n");
    is_deeply $toc, [], 'a document with no headings has an empty list';
}

# ---- a heading inside a container is still a heading ------------------------

{
    my $md = Markdown::Simple->new;
    my (undef, $toc) = $md->render_with_toc("> # Quoted\n\n# Plain\n");
    is_deeply [ map { $_->{text} } @$toc ], [ 'Quoted', 'Plain' ],
        'a heading inside a blockquote is collected too';
}

# ---- the session stays usable ------------------------------------------------

{
    my $md = Markdown::Simple->new;
    my (undef, $first)  = $md->render_with_toc("# One\n");
    my (undef, $second) = $md->render_with_toc("# Two\n");
    is_deeply [ map { $_->{id} } @$first  ], ['one'], 'first render';
    is_deeply [ map { $_->{id} } @$second ], ['two'],
        'the uniqueness table is per document, so the second render starts clean';

    my $plain = $md->render("# Three\n");
    like $plain, qr{<h1>Three</h1>},
        'and a plain render on the same session is unaffected';
}

# ---- utf8 flag propagation ---------------------------------------------------

{
    # The renderer emits raw bytes and leaves the character question to the
    # caller, so a character-string input has to come back as character
    # strings throughout, rather than the html and the heading text
    # disagreeing about their encoding.
    my $md  = Markdown::Simple->new;
    my $src = "# Caf\x{e9} Notes\n";
    utf8::upgrade($src);
    my ($html, $toc) = $md->render_with_toc($src);
    ok utf8::is_utf8($html), 'html comes back as characters';
    ok utf8::is_utf8($toc->[0]{text}), 'so does the heading text';
    ok utf8::is_utf8($toc->[0]{id}),   'and the id';
    like $toc->[0]{text}, qr/Caf\x{e9}/, 'with the character intact';
}

{
    my $md = Markdown::Simple->new;
    my ($html, $toc) = $md->render_with_toc("# Plain ASCII\n");
    ok !utf8::is_utf8($html), 'a byte-string input stays bytes';
    ok !utf8::is_utf8($toc->[0]{text}), 'including the heading text';
}

done_testing();
