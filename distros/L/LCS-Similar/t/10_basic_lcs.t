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

my $class = 'LCS::Similar';

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
];

if (1) {
  is($object->max(1,1),1,'1,1');
  is($object->max(1,0),1,'1,0');
  is($object->max(0,1),1,'0,1');
  is($object->max(0,0),0,'0,0');
}

if (1) {
  is(LCS::Similar->max(1,1),1,'1,1');
  is(LCS::Similar->max(1,0),1,'1,0');
  is(LCS::Similar->max(0,1),1,'0,1');
  is(LCS::Similar->max(0,0),0,'0,0');
}

if (1) {
  is($object->max3(1,1,1),1,'1,1,1');
  is($object->max3(1,1,0),1,'1,1,0');
  is($object->max3(0,1,1),1,'0,1,1');
  is($object->max3(0,0,1),1,'0,0,1');
  is($object->max3(1,0,0),1,'1,0,0');
  is($object->max3(0,0,0),0,'0,0,0');
}

if (1) {
  is(LCS::Similar->max3(1,1,1),1,'1,1,1');
  is(LCS::Similar->max3(1,1,0),1,'1,1,0');
  is(LCS::Similar->max3(0,1,1),1,'0,1,1');
  is(LCS::Similar->max3(0,0,1),1,'0,0,1');
  is(LCS::Similar->max3(1,0,0),1,'1,0,0');
  is(LCS::Similar->max3(0,0,0),0,'0,0,0');
}

if (1) {
for my $example (@$examples) {
#for my $example ($examples->[1]) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = $a =~ /([^_])/g;
  my @b = $b =~ /([^_])/g;

  my $lcs = LCS::Similar->LCS(\@a,\@b);
  my $all_lcs = LCS->allLCS(\@a,\@b);

  if (1) {
  cmp_deeply(
    $lcs,
    any(
        $lcs,
        supersetof(@{$all_lcs})
    ),
    "$a, $b"
  );
  }

  if (0) {
    local $Data::Dumper::Deepcopy = 1;
    print STDERR Data::Dumper->Dump([$all_lcs],[qw(allLCS)]),"\n";
    print STDERR Data::Dumper->Dump([$lcs],[qw(LCS)]),"\n";
  }
}
}

if (1) {
for my $example (@$examples2) {
#for my $example ($examples->[3]) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = $a =~ /([^_])/g;
  my @b = $b =~ /([^_])/g;

  my $lcs = LCS::Similar->LCS(\@a,\@b);
  my $all_lcs = LCS->allLCS(\@a,\@b);

  cmp_deeply(
    $lcs,
    any(
        $lcs,
        supersetof(@{$all_lcs})
    ),
    "$a, $b"
  );

  if (0) {
    local $Data::Dumper::Deepcopy = 1;
    print STDERR Data::Dumper->Dump([$all_lcs],[qw(allLCS)]),"\n";
    print STDERR Data::Dumper->Dump([$lcs],[qw(LCS)]),"\n";
  }
}
}

my @data3 = ([qw/a b d/ x 50], [qw/b a d c/ x 50]);
# NOTE: needs 100 years
if (0) {
  cmp_deeply(
    LCS::Similar->LCS(@data3),
    any(@{LCS->allLCS(@data3)} ),
    '[qw/a b d/ x 50], [qw/b a d c/ x 50]'
  );
  if (0) {
    $Data::Dumper::Deepcopy = 1;
    print STDERR 'allLCS: ',Data::Dumper->Dump(LCS->allLCS(@data3)),"\n";
    print STDERR 'LCS: ',Dumper(LCS::Similar->LCS(@data3)),"\n";
  }
}


done_testing;
