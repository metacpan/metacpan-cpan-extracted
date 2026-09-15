use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

# The dist requires a Parse::ANSIColor::Tiny new enough to identify these,
# but don't fail loudly if you're testing against an older one.
my ($pmod, $pver) = qw( Parse::ANSIColor::Tiny 0.701 );
eval "require $pmod; $pmod\->VERSION($pver); 1" ## no critic (StringyEval)
  or plan skip_all => "$pmod version $pver required for 24-bit color";

sub html_is {
  my ($text, $expected, %opt) = @_;
  my $desc = delete $opt{desc};
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  eq_or_diff scalar $mod->new(%opt)->html($text), $expected, $desc;
}

sub style_is {
  my ($attr, $expected, %opt) = @_;
  my $desc = delete $opt{desc};
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  eq_or_diff $mod->new(%opt)->attr_to_style($attr), $expected, $desc || $attr;
}

style_is 'r255g0b0',   { color            => '#ff0000' };
style_is 'r0g0b0',     { color            => '#000000' };
style_is 'on_r0g0b128',{ 'background-color' => '#000080' };

# The 256-color palette names look similar but mean something else entirely.
style_is 'rgb515',     { color            => '#ff33ff' },
  desc => 'rgb515 is a 256-color palette name, not a 24-bit color';
style_is 'on_rgb000',  { 'background-color' => '#000000' },
  desc => 'on_rgb000 is a 256-color palette name, not a 24-bit color';

style_is 'reverse',    { }, desc => 'no style for reverse';

html_is "\e[38;2;255;0;0mdanger",
  '<span class="r255g0b0" style="color: #ff0000;">danger</span>',
  desc => 'a 24-bit foreground gets both a class and an inline style';

html_is "\e[48;2;0;0;128mdeep",
  '<span class="on_r0g0b128" style="background-color: #000080;">deep</span>',
  desc => 'a 24-bit background';

html_is "\e[1;38;2;255;0;0;48;2;0;0;128mboth",
  '<span class="bold r255g0b0 on_r0g0b128"'
    . ' style="color: #ff0000; background-color: #000080;">both</span>',
  desc => 'bold and both 24-bit colors';

html_is "\e[1;31mnope",
  '<span class="bold red">nope</span>',
  desc => 'attributes with a class of their own get no inline style';

html_is "\e[1;38;2;255;0;0mhot",
  '<span style="font-weight: bold; color: #ff0000;">hot</span>',
  inline_style => 1,
  desc => 'inline_style needs no class';

html_is "\e[38;2;255;0;0mdanger",
  '<pre class="term-r255g0b0" style="color: #ff0000;">danger</pre>',
  tag => 'pre', class_prefix => 'term-',
  desc => 'class_prefix and tag still apply';

html_is "plain\e[38;2;255;0;0mdanger",
  'plain<span class="r255g0b0" style="color: #ff0000;">danger</span>',
  no_plain_tags => 1,
  desc => 'no_plain_tags leaves the colored run tagged';

html_is [ [ ['r1g2b3'], 'pre-parsed' ] ],
  '<span class="r1g2b3" style="color: #010203;">pre-parsed</span>',
  desc => 'attributes from an already-parsed structure';

html_is "\e[38;2;300;0;0moops",
  '<span class="">oops</span>',
  desc => 'an out-of-range color is dropped, not styled';

subtest 'a color you provide a style for gets a class like any other' => sub {
  my $h = new_ok($mod, [ styles => { r255g0b0 => { color => 'crimson' } } ]);

  eq_or_diff
    scalar $h->html("\e[38;2;255;0;0mdanger"),
    '<span class="r255g0b0">danger</span>',
    'no inline style needed';

  eq_or_diff
    [ grep { /r255g0b0/ } $h->css ],
    [ '.r255g0b0 { color: crimson; }' ],
    'and css() emits a rule for it';
};

subtest 'css() does not try to enumerate the 24-bit colors' => sub {
  my $h = new_ok($mod);
  my @before = $h->css;

  $h->html("\e[38;2;255;0;0mdanger\e[48;2;0;0;128mdeep");

  eq_or_diff [ $h->css ], \@before, 'same rules before and after';
  ok !grep({ /r255g0b0/ } @before), 'no rule for a 24-bit color';
};

done_testing;
