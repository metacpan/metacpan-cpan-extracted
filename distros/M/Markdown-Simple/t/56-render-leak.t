#!perl

# The renderer grows six buffers off the general heap during a parse: the
# alt-text accumulator, the autolink coalescing buffer, the highlight
# accumulator, the three parallel footnote tables, and (in the block scanner)
# the linkref and footnote entry arrays. None of them live in the arena, and
# the render state itself is a stack blob in mds_render_html_to_sv_ex, so
# nothing reclaimed them until mds_render_html_cleanup / mds_linkref_free /
# mds_footnote_free existed. Every render leaked, between roughly 60 bytes for
# a plain paragraph and 600 bytes for a document using footnotes.
#
# This measures resident set across a long render loop. It is deliberately
# coarse: the thresholds are far above allocator noise and far below what the
# old code lost, so it catches a reintroduced leak without being flaky.

use 5.010;
use strict;
use warnings;
use Test::More;
use Markdown::Simple;

plan skip_all => 'needs a POSIX ps for RSS sampling'
    if $^O eq 'MSWin32' || $^O eq 'VMS';

my $probe = _rss();
plan skip_all => 'cannot read RSS on this platform'
    unless defined $probe && $probe > 0;

plan tests => 6;

my %DOC = (
    'plain text'      => "Just a paragraph of text here.\n",
    'images'          => "![some alt text](http://example.com/image.png)\n\n",
    'highlighted code'=> "```perl\nmy \$x = 1; # comment\n```\n\n",
    'footnotes'       => "Text with a ref[^a].\n\n[^a]: the note\n\n",
    'link references' => "See [the docs][d] here.\n\n[d]: http://example.com\n\n",
);

# 20000 renders of a 20-block document. Over this loop the fixed code holds
# flat at 0 KB, while the leaky version lost between 1.2 MB (plain text, the
# autolink buffer alone) and 26 MB (the procedural path, every buffer at
# once). 512 KB sits an order of magnitude below the smallest real leak and
# well above allocator noise.
my $ITERATIONS = 20_000;
my $ALLOWED_KB = 512;

for my $name (sort keys %DOC) {
    my $doc = $DOC{$name} x 20;
    my $md  = Markdown::Simple->new({ highlight => 1 });

    # Warm up first: the arena keeps its head page between renders and the
    # output SV settles on a capacity, so the first renders legitimately grow.
    $md->render($doc) for 1 .. 200;

    my $before = _rss();
    $md->render($doc) for 1 .. $ITERATIONS;
    my $growth = _rss() - $before;

    cmp_ok $growth, '<', $ALLOWED_KB,
        "$name: RSS grew ${growth}KB over $ITERATIONS renders (< ${ALLOWED_KB}KB)";
}

# The procedural entry point takes the same cleanup path with a per-call
# arena rather than a borrowed one.
{
    my $doc = join '', values %DOC;
    $doc x= 20;
    markdown_to_html($doc, { highlight => 1 }) for 1 .. 200;

    my $before = _rss();
    markdown_to_html($doc, { highlight => 1 }) for 1 .. $ITERATIONS;
    my $growth = _rss() - $before;

    cmp_ok $growth, '<', $ALLOWED_KB,
        "markdown_to_html: RSS grew ${growth}KB over $ITERATIONS renders";
}

sub _rss {
    my $out = `ps -o rss= -p $$ 2>/dev/null`;
    return undef unless defined $out;
    $out =~ s/\s//g;
    return $out =~ /\A[0-9]+\z/ ? 0 + $out : undef;
}
