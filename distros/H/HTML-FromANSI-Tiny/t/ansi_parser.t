use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'HTML::FromANSI::Tiny';
my $pmod = 'Parse::ANSIColor::Tiny';
eval "require $mod" or die $@;

my $h = new_ok($mod, [{}]);

isa_ok $h->ansi_parser, $pmod, "required and instantiated $pmod automatically";

my $p = new_ok($pmod);
   $h = new_ok($mod, [ansi_parser => $p]);

ok $h->ansi_parser == $p, 'provided our own ansi parser';

my $text = "\e[31mfoo\033[1;32mbar\033[0m";
my $exp = '<span class="red">foo</span><span class="bold green">bar</span>';

eq_or_diff
  scalar $h->html($text),
  $exp,
  'parse text with provided parser';

eq_or_diff
  scalar $h->html($p->parse($text)),
  $exp,
  'parse text manually';

{ package # no_index
    FakeParser;
  sub new { bless {}, shift }
  sub parse { shift; [ [[$_[0]], $_[0]] ] }
}

my $fake = FakeParser->new;

$h = new_ok($mod, [ansi_parser => $fake]);

ok $h->ansi_parser == $fake, 'provided our own ansi parser';

eq_or_diff
  scalar $h->html('foo'),
  '<span class="foo">foo</span>',
  'faked parser';

# we're violating encapsulation... shhh

$h = new_ok($mod);
is $h->ansi_parser->{auto_reverse}, undef, 'option not set on parser';

$h = new_ok($mod, [background => 'blue']);
is $h->ansi_parser->{background}, 'on_blue', 'passed bg to parser';

$h = new_ok($mod, [background => 'red', foreground => 'yellow', auto_reverse => 1, nonparseropt => 'foo']);
is $h->ansi_parser->{background},   'on_red', 'option passed to parser';
is $h->ansi_parser->{foreground},   'yellow', 'option passed to parser';
is $h->ansi_parser->{auto_reverse},        1, 'option passed to parser';
ok !exists($h->ansi_parser->{nonparseropt}), 'only certain options passed';

done_testing;
