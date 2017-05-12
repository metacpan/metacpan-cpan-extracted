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

my $class = 'LCS::XS';

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
for my $example (@$examples) {
#for my $example ($examples->[3]) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = $a =~ /([^_])/g;
  my @b = $b =~ /([^_])/g;

  cmp_deeply(
    [$object->LCS(\@a,\@b)],
    any(@{LCS->allLCS(\@a,\@b)} ),

    "$a, $b"
  );
  if (0) {
    $Data::Dumper::Deepcopy = 1;
    print STDERR 'allLCS: ',Data::Dumper->Dump(LCS->allLCS(\@a,\@b)),"\n";

    print STDERR 'LCS: ',Dumper($object->LCS(\@a,\@b)),"\n";
  }
}
}

if (0) {
for my $example (@$examples) {
#for my $example ($examples->[3]) {
  my $a = $example->[0];
  my $b = $example->[1];
  my @a = $a =~ /([^_])/g;
  my @b = $b =~ /([^_])/g;
  my $as = join '',@a;
  my $bs = join '',@b;

  cmp_deeply(
    [$object->LCSs($as,$bs)],
    any(@{LCS->allLCS(\@a,\@b)} ),

    "$a, $b"
  );
  if (0) {
    $Data::Dumper::Deepcopy = 1;
    print STDERR 'allLCS: ',Data::Dumper->Dump(LCS->allLCS(\@a,\@b)),"\n";

    print STDERR 'LCS: ',Dumper($object->LCSs(\@a,\@b)),"\n";
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

  cmp_deeply(
    [$object->LCS(\@a,\@b)],
    any(@{LCS->allLCS(\@a,\@b)} ),

    "$a, $b"
  );
  if (0) {
    $Data::Dumper::Deepcopy = 1;
    print STDERR 'allLCS: ',Data::Dumper->Dump(LCS->allLCS(\@a,\@b)),"\n";
    print STDERR 'LCS: ',Dumper($object->LCS(\@a,\@b)),"\n";
  }
}
}


done_testing;
