#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 20;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/calc.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;

# Let's get some lines of code

SKIP: {

my @codelines = $ebug->codelines();

skip "Don't try lining up codelines because of sitecustomize", 20
  if $codelines[0] =~ /sitecustomize/;

my @calc = (
  '#!perl',
  '',
  'my $q = 1;',
  'my $w = 2;',
  'my $e = add($q, $w);',
  '$e++;',
  '$e++;',
  '',
  'print "$e\\n";',
  '',
  'sub add {',
  '  my($z, $x) = @_;',
  '  my $c = $z + $x;',
  '  return $c;',
  '}',
  '',
  '# unbreakable line',
  'my $breakable_line = 1;',
  '# other unbreakable line',
);

is_deeply(\@codelines, \@calc);

@codelines = $ebug->codelines(1, 3, 4, 5);
is_deeply(\@codelines, [
  '#!perl',
  'my $q = 1;',
  'my $w = 2;',
  'my $e = add($q, $w);',
]);

# Let's step through the program, and check that codeline is correct

my @lines = (3, 4, 5, 12, 13, 14, 6, 7, 9);
foreach my $l (@lines) {
  is($ebug->codeline, $calc[$l-1]);
  $ebug->step;
}

$ebug = Devel::ebug->new;
$ebug->program("t/calc_oo.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;
@codelines = $ebug->codelines("t/calc_oo.pl", 7, 8);
is_deeply(\@codelines, [
  'my $calc = Calc->new;',
  'my $r = $calc->add(5, 10); # 15',
]);

@codelines = $ebug->codelines("t/Calc.pm", 5, 6);
is_deeply(\@codelines, [
  'use base qw(Class::Accessor::Chained::Fast);',
  'our $VERSION = "0.29";',
]);

@codelines = $ebug->codelines("t/Calc.pm");
is(scalar(@codelines), 34);

$ebug->program("t/pod.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;
@codelines = $ebug->codelines();
is($codelines[0], '#!perl');
is($codelines[8], 'print "Result is $zz!\n";');
is($codelines[9], '');
is($codelines[10], '');
is($codelines[11], '');
is($codelines[31], 'sub add {');

}
