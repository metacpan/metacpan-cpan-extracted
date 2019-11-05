#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

use Test::More;
use Test::Deep;
#cmp_deeply([],any());

use LCS;

use Data::Dumper;

my $class = 'LCS::BV';

use_ok($class);

my $object = new_ok($class);

if (0) {
ok($object->new());
ok($object->new(1,2));
ok($object->new({}));
ok($object->new({a => 1}));

ok($class->new());
}

my $examples = [
  ['ttatc__cg',
   '__agcaact'],
  ['abcabba_',
   'cb_ab_ac'],
   ['yqabc_',
    'zq__cb'],
  [ 'rrp',
    'rep'],
  [ 'a',
    'b' ],
  [ 'aa',
    'a_' ],
  [ 'abb',
    '_b_' ],
  [ 'a_',
    'aa' ],
  [ '_b_',
    'abb' ],
  [ 'ab',
    'cd' ],
  [ 'ab',
    '_b' ],
  [ 'ab_',
    '_bc' ],
  [ 'abcdef',
    '_bc___' ],
  [ 'abcdef',
    '_bcg__' ],
  [ 'xabcdef',
    'y_bc___' ],
  [ 'öabcdef',
    'ü§bc___' ],
  [ 'o__horens',
    'ontho__no'],
  [ 'Jo__horensis',
    'Jontho__nota'],
  [ 'horen',
    'ho__n'],
  [ 'Chrerrplzon',
    'Choereph_on'],
  [ 'Chrerr',
    'Choere'],
  [ 'rr',
    're'],
  [ 'abcdefg_',
    '_bcdefgh'],
  [ 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVY_', # l=52
    '_bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVYZ'],
  [ 'aabbcc',
    'abc'],
  [ 'aaaabbbbcccc',
    'abc'],
  [ 'aaaabbcc',
    'abc'],
];


my $examples2 = [
  [ 'abcdefghijklmnopqrstuvwxyz0123456789!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVY_',
    '_bcdefghijklmnopqrstuvwxyz0123456789!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVYZ'],
  [ 'abcdefghijklmnopqrstuvwxyz0123456789"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVY_',
    '!'],
  [ '!',
    'abcdefghijklmnopqrstuvwxyz0123456789"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVY_'],
  [ 'abcdefghijklmnopqrstuvwxyz012345678!9!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVYZ',
    'abcdefghijklmnopqrstuvwxyz012345678_9!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVYZ'],
  [ 'abcdefghijklmnopqrstuvwxyz012345678_9!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVYZ',
    'abcdefghijklmnopqrstuvwxyz012345678!9!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVYZ'],
  [ 'aaabcdefghijklmnopqrstuvwxyz012345678_9!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVYZZZ',
    'a!Z'],
];

my $examples3 = [
  [ 'a_',
    'aa' ],
  [ '_b_',
    'abb' ],
];

if (1) {
for my $example (@$examples) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = $a =~ /([^_])/g;
  my @b = $b =~ /([^_])/g;

  is(
    LCS::BV->LLCS(\@a,\@b),
    LCS->LLCS(\@a,\@b),

    "$a, $b -> " . LCS::BV->LLCS(\@a,\@b)
  );
}
}

if (1) {
for my $example (@$examples2) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = $a =~ /([^_])/g;
  my @b = $b =~ /([^_])/g;

  is(
    LCS::BV->LLCS(\@a,\@b),
    LCS->LLCS(\@a,\@b),

    "$a, $b -> " . LCS::BV->LLCS(\@a,\@b)
  );

}
}


if (1) {
for my $example (@$examples3) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = $a =~ /([^_])/g;
  my @b = $b =~ /([^_])/g;

  is(
    LCS::BV->LLCS(\@a,\@b),
    LCS->LLCS(\@a,\@b),

    "$a, $b -> " . LCS::BV->LLCS(\@a,\@b)
  );

}
}

if (1) {
my $prefix = 'a';
my $infix  = 'b';
my $suffix = 'c';

my $max_length = 2;

for my $prefix_length1 (0..$max_length) {
  for my $infix_length1 (0..$max_length) {
    for my $suffix_length1 (0..$max_length) {
      my $a = $prefix x $prefix_length1 . $infix x $infix_length1 . $suffix x $suffix_length1;
      my @a = split(//,$a);
      my $m = scalar @a;
      for my $prefix_length2 (0..$max_length) {
        for my $infix_length2 (0..$max_length) {
          for my $suffix_length2 (0..$max_length) {

      my $b = $prefix x $prefix_length2 . $infix x $infix_length2 . $suffix x $suffix_length2;
      my @b = split(//,$b);
      my $n = scalar @b;

  is(
    LCS::BV->LLCS(\@a,\@b),
    LCS->LLCS(\@a,\@b),

    "[$a] m: $m, [$b] n: $n -> " . LCS->LLCS(\@a,\@b)
  );
        }
    }
  }
      }
    }
  }
}

if (1) {
my $string1 = 'abd';
my $string2 = 'badc';
my @base_lengths = (16, 32, 64, 128, 256);
# int(rand(10))

for my $base_length1 (@base_lengths) {
  my $mult1 = int($base_length1/length($string1)) + 1;
    my @a = split(//,$string1 x $mult1);
    my $m = scalar @a;
    for my $base_length2 (@base_lengths) {
      my $mult2 = int($base_length2/length($string2)) + 1;
      my @b = split(//,$string2 x $mult2);
      my $n = scalar @b;
  is(
    LCS::BV->LLCS(\@a,\@b),
    LCS->LLCS(\@a,\@b),

    "[$string1 x $mult1] m: $m, [$string2 x $mult2] n: $n -> " . LCS->LLCS(\@a,\@b)
  );

    }
}
}


my @data3 = ([qw/a b d/ x 50], [qw/b a d c/ x 50]);

if (1) {
  is(
    LCS::BV->LLCS(@data3),
    LCS->LLCS(@data3),

    '[qw/a b d/ x 50], [qw/b a d c/ x 50] -> ' . LCS->LLCS(@data3)
  );

}




done_testing;
