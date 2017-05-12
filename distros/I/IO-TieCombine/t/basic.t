#!perl
use strict;
use warnings;

use IO::TieCombine;
use Test::More 0.96;

my $hub = IO::TieCombine->new;

my $scalar_A = $hub->scalar_ref('Alpha');
my $fh_A     = $hub->fh('Alpha');

my $scalar_B = $hub->scalar_ref('Beta');
my $fh_B     = $hub->fh('Beta');

sub append_bar {
  $_[0] .= 'bar';
}

tie my $scalar_C, $hub, 'Charlie';

$$scalar_A .= 'foo';
print $fh_B "beta1";
$$scalar_B .= 'embargo';
append_bar($$scalar_A);

eval { $$scalar_B = 'DIE!'; };
like($@, qr{append, not reassign}, "you can't assign to a slot fh");

print $fh_A "hot pants";
$$scalar_B .= 'ooga';
print $fh_B "beta2";

$scalar_C .= 'fin';

is($hub->slot_contents('Alpha'),   'foobarhot pants',       'Alpha slot');
is($hub->slot_contents('Beta'),    'beta1embargooogabeta2', 'Beta slot');
is($hub->slot_contents('Charlie'), 'fin',                   'Charlie slot');
is(
  $hub->combined_contents,
  'foobeta1embargobarhot pantsoogabeta2fin',
  'combined',
);

if ($] >= 5.010001) {
  subtest "the 'say' built-in" => sub {
    plan tests => 1;
    my $ok = eval q{
      use feature 'say';
      $hub->clear_slot('Alpha');
      print $fh_A "foo\n";
      say   $fh_A "foo";
      is($hub->slot_contents('Alpha'), "foo\nfoo\n", "say appends a newline");
      1;
    };
    die $@ unless $ok;
  };
}

done_testing;
