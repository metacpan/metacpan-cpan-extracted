#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

use Test::More;
use Test::Deep;

use Data::Dumper;

my $class = 'LCS';

use_ok($class);

my $object = new_ok($class);

if (1) {
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
  [ 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVY_',
    '_bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVYZ'],
];

if (0) {
  is($object->max(1,1),1,'1,1');
  is($object->max(1,0),1,'1,0');
  is($object->max(0,1),1,'0,1');
  is($object->max(0,0),0,'0,0');
}

if (0) {
  is(LCS::max(1,1),1,'1,1');
  is(LCS::max(1,0),1,'1,0');
  is(LCS::max(0,1),1,'0,1');
  is(LCS::max(0,0),0,'0,0');
}

if (0) {
  is_deeply([$object->fill_strings(qw(a b))],[qw(a b)],'fill a b');
  is_deeply([$object->fill_strings(qw(aa b))],[qw(aa b_)],'fill aa b_');
  is_deeply([$object->fill_strings(qw(a bb))],[qw(a_ bb)],'fill a_ bb');
  is_deeply([$object->fill_strings(qw(aa b),'*')],[qw(aa b*)],'fill aa b*');
  is_deeply([$object->fill_strings('aa', '')],[qw(aa __)],'fill aa __');
}

if (1) {
for my $example (@$examples) {
#for my $example ($examples->[1]) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = map { $_ =~ s/_//;$_ } split(//,$example->[0]);
  my @b = map { $_ =~ s/_//;$_ } split(//,$example->[1]);

  is_deeply([$object->align2strings(
  	  $object->sequences2hunks(\@a,\@b)
  	)],
  [$a,$b], "a2str $a, $b");
  is_deeply([$object->align2strings(
  	  $object->sequences2hunks(\@a,\@b),
  	  '_'
  	)],
  [$a,$b], "a2str $a, $b");
}
}

if (1) {
  my $tests = [
    [
      [[0,0,1]],
      [[0,0]]
    ],
    [
      [[0,0,2]],
      [[0,0],[1,1]]
    ],
    [
      [[0,10,2]],
      [[0,10],[1,11]]
    ],
    [
      [[10,0,2]],
      [[10,0],[11,1]]
    ],
    [
      [[0,10,2],     [4,14,2]],
      [[0,10],[1,11],[4,14],[5,15]]
    ],
    [
      [[10,0,2],     [14,4,2]],
      [[10,0],[11,1],[14,4],[15,5]]
    ],

  ];
  for my $test (@$tests) {
  #for my $test ($tests->[2]) {
    is_deeply(
      $object->clcs2lcs($test->[0]),
      $test->[1]
    );
    #print Dumper($test->[0]);
    #print Dumper($object->clcs2lcs($test->[0]));
    #print Dumper($test->[1]);
    is_deeply(
      $object->lcs2clcs($test->[1]),
      $test->[0]
    );
  }


}

if (1) {
for my $example (@$examples) {
#for my $example ($examples->[1]) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = map { $_ =~ s/_//;$_ } split(//,$example->[0]);
  my @b = map { $_ =~ s/_//;$_ } split(//,$example->[1]);

  is_deeply([$object->hunks2sequences(
  	  $object->sequences2hunks(\@a,\@b)
  	)],
  [\@a,\@b], "hunks2seq $a, $b");
}
}

use LCS::Tiny;

if (1) {
  my $class = 'LCS::Tiny';

  use_ok($class);

  my $object = new_ok($class);

  ok($object->new());
  ok($object->new(1,2));
  ok($object->new({}));
  ok($object->new({a => 1}));

  ok($class->new());
}


if (1) {
for my $example (@$examples) {
#for my $example ($examples->[1]) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = $a =~ /([^_])/g;
  my @b = $b =~ /([^_])/g;

  my $as = $a;
  my $bs = $b;
  $as =~ s/_//g;
  $bs =~ s/_//g;

  cmp_deeply(
    LCS::Tiny->LCS(\@a,\@b),
    any(@{$object->allLCS(\@a,\@b)} ),
    "Tiny::LCS $a, $b"
  );
  if (0) {
    $Data::Dumper::Deepcopy = 1;
    print STDERR 'allLCS: ',Data::Dumper->Dump($object->allLCS(\@a,\@b)),"\n";
    print STDERR 'LCS: ',Dumper(LCS::Tiny->LCS(\@a,\@b)),"\n";
  }
}
}

if (1) {
for my $example (@$examples) {
#for my $example ($examples->[1]) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = $a =~ /([^_])/g;
  my @b = $b =~ /([^_])/g;

  cmp_deeply(
    $object->lcs2align(\@a,\@b,$object->LCS(\@a,\@b)),
    any(
      map { $object->lcs2align(\@a,\@b,$_) } @{$object->allLCS(\@a,\@b)}
    ),
    "lcs2align $a, $b"
  );
  if (0) {
    $Data::Dumper::Deepcopy = 1;
    print STDERR 'allLCS: ',Data::Dumper->Dump([
      map { $object->lcs2align(\@a,\@b,$_) } @{$object->allLCS(\@a,\@b)}
    ]),"\n";
    print STDERR 'LCS: ',Dumper($object->lcs2align(\@a,\@b,$object->LCS(\@a,\@b))),"\n";
  }
}
}

if (1) {
for my $example (@$examples) {
#for my $example ($examples->[1]) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = $a =~ /([^_])/g;
  my @b = $b =~ /([^_])/g;

  cmp_deeply(
    $object->align(\@a,\@b),
    any(
      map { $object->lcs2align(\@a,\@b,$_) } @{$object->allLCS(\@a,\@b)}
    ),
    "lcs2align $a, $b"
  );
  if (0) {
    $Data::Dumper::Deepcopy = 1;
    print STDERR 'allLCS: ',Data::Dumper->Dump([
      map { $object->lcs2align(\@a,\@b,$_) } @{$object->allLCS(\@a,\@b)}
    ]),"\n";
    print STDERR 'LCS: ',Dumper($object->lcs2align(\@a,\@b,$object->LCS(\@a,\@b))),"\n";
  }
}
}

if (1) {
for my $example (@$examples) {
#for my $example ($examples->[1]) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = $a =~ /([^_])/g;
  my @b = $b =~ /([^_])/g;

  cmp_deeply(
    $object->LCS(\@a,\@b),
    any(@{$object->allLCS(\@a,\@b)} ),
    "LCS $a, $b"
  );
  if (0) {
    $Data::Dumper::Deepcopy = 1;
    print STDERR Data::Dumper->Dump($object->allLCS(\@a,\@b)),"\n";
    print STDERR 'ag: ',Dumper($object->LCS(\@a,\@b)),"\n";
  }
}
}

if (1) {
for my $example (@$examples) {
#for my $example ($examples->[15]) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = $a =~ /([^_])/g;
  my @b = $b =~ /([^_])/g;

  is(
    $object->LLCS(\@a,\@b),
    scalar(@{$object->LCS(\@a,\@b)}) ,
    "LLCS $a, $b"
  );
}
}

done_testing;
