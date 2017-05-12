use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;
use Test::Requires 'Encode';
BEGIN { Encode->import(qw( encode decode is_utf8 )); }

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

sub is_utf8_ok {
  my ($string, $exp, $desc) = @_;
  my $is = is_utf8($string);
  $is = !$is if !$exp;
  ok($is, $desc);
}

sub html_ok {
  my ($h, $input, $exp, $exp_utf8) = @_;
  my $type = ($exp_utf8 ? 'character' : 'byte') . ' string';

  is_utf8_ok($input, $exp_utf8, "input is $type");

  my $html = $h->html($input);
  eq_or_diff
    $html,
    $exp,
    "parse and return $type";

  # We could remove this one if we consistently returned utf8-flagged strings
  # (e.g. call utf8::upgrade before encode_entities)
  # but currently there's no reason for that.
  is_utf8_ok($html, $exp_utf8, "output is $type");
}

my $text = " \xc3\x97 ";
my $ansi = "\033[32m${text}\033[0m";

sub wrap {
  qq!<span class="green">$_[0]</span>!;
}

subtest 'no html entity encoding (pass-through)' => sub {
  my $h    = new_ok($mod, [html_encode => sub { shift }]);
  my $html = wrap($text);

  html_ok $h, $ansi, $html, 0,
  html_ok $h, decode(utf8 => $ansi), decode(utf8 => $html), 1;
};

subtest 'default html entity encoding' => sub {
  test_requires 'HTML::Entities';

  my $h = new_ok($mod, []);

  subtest 'utf-8 bytes get mojibaked (expectedly) and encoded' => sub {
    html_ok $h, $ansi,
      wrap(q[ &Atilde;&#151; ]), 0;
  };

  subtest 'character string gets html-encoded properly' => sub {
    html_ok $h, decode(utf8 => $ansi),
      decode(utf8 => wrap(q[ &times; ])), 1;
  };

  subtest 'latin1 bytes get html-encoded properly' => sub {
    html_ok $h, "\033[32m \xa9 \033[m",
      wrap(q[ &copy; ]), 0;
  };

};

done_testing;
