use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

my $text = "foo\e[31m&\033[1;32mb<a>r";

my $h = new_ok($mod);

eq_or_diff
  scalar $h->html($text),
  '<span class="">foo</span><span class="red">&amp;</span><span class="bold green">b&lt;a&gt;r</span>',
  'default tag';

$h = new_ok($mod, [tag => 'rum']);

eq_or_diff
  scalar $h->html($text),
  '<rum class="">foo</rum><rum class="red">&amp;</rum><rum class="bold green">b&lt;a&gt;r</rum>',
  'custom tag';

$h = new_ok($mod, [tag => 'yo:ho']);

eq_or_diff
  [$h->html($text)],
  ['<yo:ho class="">foo</yo:ho>', '<yo:ho class="red">&amp;</yo:ho>', '<yo:ho class="bold green">b&lt;a&gt;r</yo:ho>'],
  'custom tag with namespace';

$h = new_ok($mod, [tag => 0]);

eq_or_diff
  [$h->html($text)],
  ['<0 class="">foo</0>', '<0 class="red">&amp;</0>', '<0 class="bold green">b&lt;a&gt;r</0>'],
  'custom tag with namespace';

done_testing;
