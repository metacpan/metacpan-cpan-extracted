use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

my $h = new_ok($mod, []);

my $text = "foo\e[31m&\033[1;32mb<a>r";

eq_or_diff
  scalar $h->html($text),
  '<span class="">foo</span><span class="red">&amp;</span><span class="bold green">b&lt;a&gt;r</span>',
  'convert html entities';

my $custom = '<span class="">foo</span><span class="red">.baz(&)</span><span class="bold green">b.baz(<)a.baz(>)r</span>';

$h = new_ok($mod, [ html_encode => sub { my $s = shift; $s =~ s/([<>&])/.baz($1)/g; $s } ]);
eq_or_diff
  scalar $h->html($text),
  $custom,
  'custom html_encode';

done_testing;
