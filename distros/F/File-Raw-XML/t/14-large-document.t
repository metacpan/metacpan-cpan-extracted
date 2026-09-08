#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use File::Raw::XML qw(file_xml_decode);

# A five-mebibyte document: a hundred thousand elements, nesting to two
# hundred, one attribute value of a mebibyte, one text node of a mebibyte.
# Parsed, counted, canonicalised, and the canonical form compared with the
# input, which is written in canonical form so the two must be identical.
#
# The bound on wall-clock is loose on purpose: a loaded smoker cannot trip
# it, and the assertion that matters is completion. The elapsed time is
# reported, not asserted tightly.

my $MiB = 1024 * 1024;

my $elements = join '', map { sprintf '<e i="%06d">%06d</e>', $_, $_ } 1 .. 100_000;
my $chain    = ('<d>' x 200) . 'deep' . ('</d>' x 200);
my $big_attr = '<big a="' . ('x' x $MiB) . '"></big>';
my $big_text = '<t>' . ('y' x $MiB) . '</t>';

my $head = "<r>$elements$chain$big_attr$big_text";
my $pad  = 5 * $MiB - length($head) - length('<p></p></r>');
my $bytes = $head . '<p>' . ('z' x $pad) . '</p></r>';
is(length $bytes, 5 * $MiB, 'the document is five mebibytes');

my $t0 = time;

my $doc = eval { file_xml_decode($bytes) };
ok($doc, 'it parses') or do { diag $@; done_testing; exit };
my $root = $doc->root;

my $n_e = () = $root->descendants(undef, 'e');
is($n_e, 100_000, 'a hundred thousand e elements');
my $n_d = () = $root->descendants(undef, 'd');
is($n_d, 200, 'nested to two hundred');
my ($deepest) = $root->descendants(undef, 'd');
my $depth = 0;
for (my $n = $root->descendants(undef, 'd') ? ($root->descendants(undef, 'd'))[-1] : undef; $n; $n = $n->parent) { $depth++ }
is($depth, 202, 'the innermost d is 202 nodes from the document node');
is(($root->descendants(undef, 'd'))[-1]->text, 'deep', 'and carries the text');

my ($big) = $root->find(undef, 'big');
is(length $big->attr('a'), $MiB, 'the mebibyte attribute value comes back whole');
my ($t) = $root->find(undef, 't');
is(length $t->text, $MiB, 'the mebibyte text node comes back whole');

my $out = $doc->c14n(mode => 'exclusive');
is(length $out, length $bytes, 'the exclusive canonical form has the input length');
ok($out eq $bytes, 'and is the input, byte for byte');
$out = $doc->c14n(mode => 'inclusive');
ok($out eq $bytes, 'so is the inclusive one');

my $elapsed = time - $t0;
cmp_ok($elapsed, '<', 600, sprintf 'parse, count and canonicalise completed (%.2fs)', $elapsed);

done_testing;
