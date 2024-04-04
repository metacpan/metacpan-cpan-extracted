use strict;
use warnings;
use utf8;

use Markdown::Perl::InlineTree ':all';
use Test2::V0;

sub text_tree {
  my $t = Markdown::Perl::InlineTree->new();
  for (@_) {
    $t->push(new_text($_)) if $_;
    $t->push(new_code('ignored)')) unless $_;
  }
  return $t;
}

my $t = text_tree('a(bc', '123d(e)f', '', 'gh)i3');

is([$t->find_in_text(qr/\(/, 0, 0)], [0, 1, 2], 'find_in_text_from_start');
is([$t->find_in_text(qr/\(/, 1, 0)], [1, 4, 5], 'find_in_text_from_second_child');
is([$t->find_in_text(qr/\(/, 0, 1)], [0, 1, 2], 'find_in_text_from_early_in_first_child');
is([$t->find_in_text(qr/\(/, 0, 2)], [1, 4, 5], 'find_in_text_from_far_in_first_child');
is([$t->find_in_text(qr/\(/, 0, 2, 2, 0)], [1, 4, 5], 'find_in_text_with_bound');
is($t->find_in_text(qr/\(/, 0, 2, 1, 1), U(), 'find_in_text_with_too_small_bound');

is([$t->find_balanced_in_text(qr/\(/, qr/\)/, 0, 2)], [3, 2, 3], 'find_balanced_in_text');

is([$t->find_in_text_with_balanced_content(qr/\(/, qr/\)/, qr/./, 0, 0)], [0, 0, 1], 'find_with_balance_anything');
is([$t->find_in_text_with_balanced_content(qr/\(/, qr/\)/, qr/\d/, 0, 0)], [3, 4, 5], 'find_with_balance_digit');
is([$t->find_in_text_with_balanced_content(qr/\(/, qr/\)/, qr/\d/, 0, 2)], [1, 0, 1], 'find_with_balance_digit_easy');

is($t->span_to_source_text(1,2,3,4), '3d(e)f<code>ignored)</code>gh)i', 'span_to_source_text');

my $nt = $t->extract(1, 3, 3, 2);
is($nt->fold(sub { $_[1].$_[0]->{content} }, ''), 'd(e)fignored)gh', 'extract_extracted');
is($t->fold(sub { $_[1].$_[0]->{content} }, ''), 'a(bc123)i3', 'extract_rest');

$nt = $t->extract(0, 0, 2, 3);
is($nt->fold(sub { $_[1].$_[0]->{content} }, ''), 'a(bc123)i3', 'extract_all');
is($t->fold(sub { $_[1].$_[0]->{content} }, ''), '', 'extract_rest_nothing');

{
  my $t = text_tree('*foo');
  my $nt = $t->extract(0, 0, 0, 1);
  is(scalar(@{$nt->{children}}), 1, 'extract_first_char1');
  is($nt->{children}[0]{content}, '*', 'extract_first_char2');
  is(scalar(@{$t->{children}}), 1, 'extract_first_char3');
  is($t->{children}[0]{content}, 'foo', 'extract_first_char4');
}

{
  my $t = text_tree('*foo');
  $t->insert(0, new_text('bar'));
  my $nt = $t->extract(1, 0, 1, 1);
  is(scalar(@{$nt->{children}}), 1, 'extract_from_second_child1');
  is($nt->{children}[0]{content}, '*', 'extract_from_second_child2');
  is(scalar(@{$t->{children}}), 2, 'extract_from_second_child3');
  is($t->{children}[1]{content}, 'foo', 'extract_from_second_child4');
}

done_testing;
