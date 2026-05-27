use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# Phase 02: arena, buf, and the new render entry point are exercised via
# XS hooks (_arena_test, _buf_test) and the public markdown_to_html.

plan tests => 8;

my $arena = Markdown::Simple::_arena_test();
ok $arena->{aligned},  'arena: every allocation MDS_ARENA_ALIGN-aligned';
ok $arena->{chained},  'arena: pages chain when capacity exhausted';
ok $arena->{big},      'arena: big allocations go to dedicated pages';
ok $arena->{reset},    'arena: reset() clears big list and rewinds head';

my $buf = Markdown::Simple::_buf_test();
ok $buf->{len},  'mds_buf: SvCUR correct after many growth events';
ok $buf->{data}, 'mds_buf: contents preserved across grow';

# Phase 03: the entry point now actually parses+renders. Verify a
# canonical paragraph and a large-input sanity bound.
my $rendered = Markdown::Simple::markdown_to_html("hello\n", { gfm => 0 });
is $rendered, "<p>hello</p>\n", 'mds_render_html_to_sv renders paragraph';

my $big = "x" x 100_000;
my $big_out = Markdown::Simple::markdown_to_html($big, { gfm => 0 });
ok length($big_out) >= 100_000 && length($big_out) <= 100_032,
    'mds_render_html_to_sv handles 100KB input (wraps in <p>)';
