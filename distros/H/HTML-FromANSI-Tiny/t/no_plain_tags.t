use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

my $h = new_ok($mod, []);

my $text = "foo\e[31m&\e[0m&\033[1;32mb<\033[00ma>r";

eq_or_diff
  scalar $h->html($text),
  '<span class="">foo</span><span class="red">&amp;</span><span class="">&amp;</span><span class="bold green">b&lt;</span><span class="">a&gt;r</span>',
  'got span class=""';

$h = new_ok($mod, [{no_plain_tags => 1}]);

eq_or_diff
  scalar $h->html($text),
  'foo<span class="red">&amp;</span>&amp;<span class="bold green">b&lt;</span>a&gt;r',
  'got some untagged text (still html encoded)';

done_testing;
