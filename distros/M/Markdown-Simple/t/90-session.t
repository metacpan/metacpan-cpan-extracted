#!/usr/bin/env perl
# t/90-session.t -- phase 11.2 persistent-arena session API.

use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# --- construction and basic render ---------------------------------------
my $md = Markdown::Simple->new();
isa_ok($md, 'Markdown::Simple', 'new() returns a session object');

my $html = $md->render("# hello\n");
like($html, qr{<h1>hello</h1>}, 'session render produces expected output');

# --- output matches the procedural form for many docs --------------------
my @docs = (
    "",
    "# heading\n",
    "para one\n\npara two\n",
    "- one\n- two\n- three\n",
    "**bold** and *em*\n",
    "| a | b |\n|---|---|\n| 1 | 2 |\n",
    "```\ncode block\n```\n",
    "[link](https://example.com)\n",
);
for my $i (0 .. $#docs) {
    my $a = Markdown::Simple::markdown_to_html($docs[$i]);
    my $b = $md->render($docs[$i]);
    is($b, $a, "session render matches procedural form (doc $i)");
}

# --- options are honoured at construction --------------------------------
my $cm = Markdown::Simple->new({ gfm => 0 });
my $gfm_table = "| a | b |\n|---|---|\n| 1 | 2 |\n";
unlike($cm->render($gfm_table), qr{<table>}, 'gfm=>0 disables tables');

my $no_headers = Markdown::Simple->new({ headers => 0 });
unlike($no_headers->render("# h\n"), qr{<h1>}, 'headers=>0 disables headings');

# --- arena reuse: many renders in a row do not leak / corrupt -----------
for (1 .. 200) {
    my $out = $md->render("para $_\n\nanother $_\n");
    like($out, qr{<p>para $_</p>}, "iter $_ paragraph 1 ok")
        if $_ <= 3 || $_ == 200;
}

# --- arena profile shows the warm page is reused ------------------------
# After several small renders the page_count should remain at 1 (the warm
# head page), not climb with each call.
$md->render("hello\n") for 1 .. 10;
my $prof = Markdown::Simple::_last_arena_profile();
is($prof->{page_count}, 1,
    'persistent arena keeps page_count at 1 for repeated small renders');

# --- DESTROY runs without segfault ---------------------------------------
undef $md;
pass('session DESTROY clean');

done_testing();
