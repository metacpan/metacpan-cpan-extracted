use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

{
  package CustomClassNames;
  our @ISA = qw(HTML::FromANSI::Tiny);

  our %ATTR_TO_CLASS = (
    red => 'text-danger',
    bold => 'brave',
  );

  sub attr_to_class {
    $ATTR_TO_CLASS{$_[1]} || $_[1];
  }
}

my $text = "foo\e[31m&\033[1;32mb<a>r";

my $h = new_ok($mod);
my $subclass = 'CustomClassNames';

eq_or_diff
  scalar $h->html($text),
  '<span class="">foo</span><span class="red">&amp;</span><span class="bold green">b&lt;a&gt;r</span>',
  'default attr_to_class';

$h = new_ok($subclass);

eq_or_diff
  scalar $h->html($text),
  '<span class="">foo</span><span class="text-danger">&amp;</span><span class="brave green">b&lt;a&gt;r</span>',
  'subclass';

done_testing;
