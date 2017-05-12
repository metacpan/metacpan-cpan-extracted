use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

my $text = "foo\e[31m&\033[1;32mb<a>\e[104mr\033[00m";

my $inline = new_ok($mod, [inline_style => 1]);

eq_or_diff
  scalar $inline->html($text),
  '<span style="">foo</span><span style="color: #f33;">&amp;</span>' .
    '<span style="font-weight: bold; color: #2c2;">b&lt;a&gt;</span>' .
    '<span style="font-weight: bold; color: #2c2; background-color: #99f;">r</span>',
  'defaults with inline style';

$inline = new_ok($mod, [inline_style => 1, styles => {
  bold => { 'text-shadow' => '5px 5px 5px black' },
  red  => { color => 'rgb(255, 0, 0)' },
  on_bright_blue => { 'background-color' => '#ccf' },
}]);

eq_or_diff
  scalar $inline->html($text),
  '<span style="">foo</span><span style="color: rgb(255, 0, 0);">&amp;</span>' .
    '<span style="text-shadow: 5px 5px 5px black; color: #2c2;">b&lt;a&gt;</span>' .
    '<span style="text-shadow: 5px 5px 5px black; color: #2c2; background-color: #ccf;">r</span>',
  'inline style with custom css';

done_testing;
