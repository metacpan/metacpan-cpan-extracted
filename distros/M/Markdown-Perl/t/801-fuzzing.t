use strict;
use warnings;
use utf8;

use Markdown::Perl;
use Markdown::Perl::Options;
use Test2::V0;

my $maxi_test = !!$ENV{MAXI_TEST};

my @token = (
  'foo', 'bar', 'baz', ' ', '  ', '   ', '    ', "\n", "\t", '"', '>', "\n>",
  '- ', "\n- ", '1. ', "\n1. ", '[', ']', '[]', '[foo]', '\n[foo]:', ':',
  '/url','http://url', '<', '>', '<http://url>', '(', ')', '(http://url)', '*',
  '*foo*', '**', '_', '`', '```', "\n```", '---', '--', '-', '#', '##', '<div>',
  '</div>', "\n\n", '![', '](', '](http://url)', "  \n", "\\\n", '.', '=',
  'www.foo.fr', '&lt;', '&Amp;', '&', '+', '|', '| foo ', '| :--', ':', '::',
  ':::', 'bar |', '--: |', '#id', '.class', '{#id}', '{.class}', '{key=value}',
  '{', '}'
);

my $num_tests = $maxi_test ? 100000 : $ENV{EXTENDED_TESTING} ? 4000 : 500;
my $max_tokens = 100;

my @testers = map { Markdown::Perl->new(mode => $_, warn_for_unused_input => 0) } @Markdown::Perl::Options::valid_modes;

for (1 .. $num_tests) {
  my $num_token = int(rand($max_tokens)) + 1;
  my $md = join('', map { $token[rand(@token)] } 1..$num_token);
  my $failed = 0;
  for my $t (@testers) {
    my @diag = ('Mode: '.($t->{mode} // 'default'), 'Markdown:', $md);
    my $convert;
    my $warnings = warnings { $convert = lives { $t->convert($md) } };
    if (!$convert) {
      $failed = 1;
      fail('Convert', @diag, 'Error: ', $@)
    }
    if (@{$warnings}) {
      $failed = 1;
      fail('No generated warnings', @diag, 'Warnings: ', @{$warnings});
    }
  }
  if (!$failed && !$maxi_test) {
    pass('fuzz test');
  }
  if ($_ % 1000 == 0 && $maxi_test) {
    note('Ran '.($_ / 1000).'% of the test');
  }
}

if ($maxi_test) {
  pass('Fuzz test');  # At least one reported test (in case everything is succesful).
}

done_testing;
