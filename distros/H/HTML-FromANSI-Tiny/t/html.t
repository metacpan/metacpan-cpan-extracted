use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

my $h = new_ok($mod);

eq_or_diff
  scalar $h->html("\e[31mfoo\033[1;32mbar\033[0m"),
  '<span class="red">foo</span><span class="bold green">bar</span>',
  'convert synopsis example';

eq_or_diff
  [$h->html("\e[31mfoo\033[1;32mbar\033[0m")],
  ['<span class="red">foo</span>', '<span class="bold green">bar</span>'],
  'convert synopsis example in list context';

eq_or_diff
  scalar $h->html("foo\e[31mba\e[0mr\033[1;32mbaz"),
  q[<span class="">foo</span><span class="red">ba</span><span class="">r</span><span class="bold green">baz</span>],
  'slightly more complex';

$h = new_ok($mod, [ {tag => 'pre', class_prefix => 'term-'} ]);

eq_or_diff
  scalar $h->html("foo\e[31mba\e[0mr\033[1;32mbaz"),
  q[<pre class="">foo</pre><pre class="term-red">ba</pre><pre class="">r</pre><pre class="term-bold term-green">baz</pre>],
  'slightly more complex';

eq_or_diff
  [$h->html("foo\e[31mba\e[0mr\033[1;32mbaz")],
  ['<pre class="">foo</pre>', '<pre class="term-red">ba</pre>', '<pre class="">r</pre>', '<pre class="term-bold term-green">baz</pre>'],
  'slightly more complex in list context';

$h = new_ok($mod, [ {class_prefix => 't_', no_plain_tags => 1} ]);

eq_or_diff
  scalar $h->html("hey \e[7mLOOK AT THIS"),
  q[hey <span class="t_reverse">LOOK AT THIS</span>],
  'no auto_reverse; get "reverse" class';

$h = new_ok($mod, [ {class_prefix => 't_', no_plain_tags => 1, auto_reverse => 1} ]);

eq_or_diff
  scalar $h->html("hey \e[7mLOOK AT THIS"),
  q[hey <span class="t_on_white t_black">LOOK AT THIS</span>],
  'with auto_reverse get default colors';

subtest remove_escape_sequences => sub {
  my ($class, $version) = qw( Parse::ANSIColor::Tiny 0.500 );
  eval "require $class; $class\->VERSION($version); 1" ## no critic (StringyEval)
    or plan skip_all => "$class version $version required for remove_escapes";

  # Tests taken from Taiki Kawakami's pull request.
  # https://github.com/rwstauner/HTML-FromANSI-Tiny/pull/2/files
  eq_or_diff
    scalar $h->html("\e[2j\e[2Jfoo"),
    q[foo],
    'with escape sequence to clear screen';

  eq_or_diff
    scalar $h->html("\e[0k\e[0K\e[1k\e[1K\e[2k\e[2Kfoo"),
    q[foo],
    'with escape sequence to clear row';

  eq_or_diff
    scalar $h->html("\e[1;2h\e[10;20Hfoo"),
    q[foo],
    'with escape sequence to move cursor by lengthwise and crosswise';

  eq_or_diff
    scalar $h->html("\e[10a\e[10A\e[10b\e[10B\e[10c\e[10C\e[10d\e[10Dfoo"),
    q[foo],
    'with escape sequence to move cursor';

};

done_testing;
