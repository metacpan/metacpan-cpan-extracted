#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 22;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/calc.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;

# Let's step through the program, and check that we get the
# lexical variables for each line

my $want_vars = {
  3 => '',
  4 => '$q=1',
  5 => '$q=1,$w=2',
 12 => '$e=undef,$q=1,$w=2',
 13 => '$e=undef,$q=1,$w=2,$x=2,$z=1',
 14 => '$c=3,$e=undef,$q=1,$w=2,$x=2,$z=1',
  6 => '$e=3,$q=1,$w=2',
  7 => '$e=4,$q=1,$w=2',
  9 => '$e=5,$q=1,$w=2',
};

foreach (1..9) {
  my $line = $ebug->line;
  my $pad  = $ebug->pad;
  my @vars;
  foreach my $k (sort keys %$pad) {
    my $v = $pad->{$k} || 'undef';
    push @vars, "$k=$v";
  }
  my $vars = join ',', @vars;
  $vars ||= '';
  is($vars, $want_vars->{$line}, "$line has $vars");
  $ebug->step;
}

$ebug = Devel::ebug->new;
$ebug->program("t/stack.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;
$ebug->break_point(22);

$ebug->run;
my $pad = $ebug->pad_human;

is($pad->{'$first'}, 'undef');
is($pad->{'%hash'}, '(...)');

$ebug->run;
$pad = $ebug->pad;
is($pad->{'$first'}, '1');
is_deeply($pad->{'@rest'}, [undef, 2]);
$pad = $ebug->pad_human;
is($pad->{'$first'}, '1');
is($pad->{'@rest'}, "(undef, 2)");

$ebug->run;
$pad = $ebug->pad_human;
is($pad->{'$first'}, '123');

$ebug->run;
$pad = $ebug->pad_human;
is($pad->{'$first'}, '-0.3');

$ebug->run;
$pad = $ebug->pad_human;
is($pad->{'$first'}, "'a'");

$ebug->run;
$pad = $ebug->pad_human;
is($pad->{'$first'}, '"orange o rama"');

$ebug->run;
$pad = $ebug->pad_human;
is($pad->{'$first'}, '[...]');

$ebug->run;
$pad = $ebug->pad_human;
is($pad->{'$first'}, '{...}');

$ebug->run;
$pad = $ebug->pad_human;
is($pad->{'$first'}, '$koremutake');

