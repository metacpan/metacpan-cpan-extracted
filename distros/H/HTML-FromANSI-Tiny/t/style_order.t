use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

# Deliberately not in alphabetical order, and enough properties that hash
# order coming out sorted by chance is unlikely (one in a hundred and twenty).
my %many = (
  'text-decoration'  => 'underline',
  'color'            => 'yellow',
  'opacity'          => '0.5',
  'background-color' => 'black',
  'font-weight'      => 'bold',
);

my $sorted = 'background-color: black; color: yellow; font-weight: bold;'
  . ' opacity: 0.5; text-decoration: underline;';

sub css_rule_is {
  my ($attr, $expected, %opt) = @_;
  my $desc = delete $opt{desc};
  my $h = $mod->new(styles => { $attr => { %many } }, %opt);
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  eq_or_diff
    [ grep { /^\.\Q$attr\E /  } $h->css ],
    [ $expected ],
    $desc;
}

sub inline_style_is {
  my ($text, $expected, %opt) = @_;
  my $desc = delete $opt{desc};
  my $h = $mod->new(styles => { underline => { %many } }, inline_style => 1, %opt);
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  eq_or_diff scalar $h->html($text), $expected, $desc;
}

css_rule_is 'underline', ".underline { $sorted }",
  desc => 'css() sorts the properties of a rule';

inline_style_is "\e[4mhi", qq[<span style="$sorted">hi</span>],
  desc => 'inline_style sorts the properties of a style attribute';

inline_style_is "\e[1;4mhi",
  qq[<span style="font-weight: bold; $sorted">hi</span>],
  desc => 'each attribute keeps its own properties, in attribute order';

done_testing;
