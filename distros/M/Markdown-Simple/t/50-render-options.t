use strict;
use warnings;
use Test::More tests => 8;
use Markdown::Simple ();

# Default mode: GFM. Bare URL becomes an autolink.
my $gfm = Markdown::Simple::markdown_to_html("see http://example.com\n");
like $gfm, qr{<a href="http://example\.com"[^>]*>http://example\.com</a>},
    'default (GFM) autolinks bare URLs';

# `gfm => 0` reverts to strict CommonMark — no autolink scan.
my $cm = Markdown::Simple::markdown_to_html("see http://example.com\n", { gfm => 0 });
unlike $cm, qr/<a href="http:/, 'gfm => 0: no autolink';

# Tables on by default, off via opt-out.
my $tbl = "| a | b |\n| - | - |\n| 1 | 2 |\n";
like   Markdown::Simple::markdown_to_html($tbl),                   qr/<table>/, 'tables on by default';
unlike Markdown::Simple::markdown_to_html($tbl, { tables => 0 }), qr/<table>/, 'tables => 0 disables tables';

# Strikethrough rendered by default; opt-out is currently a TODO
# (inline scanner does not gate ~~ on a flag yet).
like Markdown::Simple::markdown_to_html("~~gone~~\n"), qr{<del>gone</del>}, 'strikethrough by default';
unlike Markdown::Simple::markdown_to_html("~~gone~~\n", { strikethrough => 0 }),
    qr{<del>}, 'strikethrough => 0 disables';

# hard_breaks opt-in: soft breaks become <br />.
like Markdown::Simple::markdown_to_html("a\nb\n", { hard_breaks => 1 }),
    qr{<br ?/?>}, 'hard_breaks => 1 emits <br />';

# disallow_raw_html opt-out (GFM has it on; turn it off + unsafe to allow <script>).
like Markdown::Simple::markdown_to_html("<script>x</script>\n", { disallow_raw_html => 0, unsafe => 1 }),
    qr{<script>}, 'disallow_raw_html => 0 lets <script> through (with unsafe => 1)';
