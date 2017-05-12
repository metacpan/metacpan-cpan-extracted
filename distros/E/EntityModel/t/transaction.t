use strict;
use warnings;
use Test::More tests => 3;
use Test::Refcount;
use Try::Tiny;
use Scalar::Util;
use EntityModel::Util;

subtest 'success' => sub {
 plan tests => 3;
 # Check for success
 as_transaction {
  my $tran = shift;
  pass("creating in transaction");
  $tran->();
 }  success => sub {
  pass("it worked");
  # congregate { say } Entity::Author->find(...), failure { die };
 }, failure => sub {
  fail("did not work");
 }, goodbye => sub {
  pass("next step");
 };
 done_testing;
};

# Check for failure
subtest 'failure' => sub {
 plan tests => 3;
 as_transaction {
  my $tran = shift;
  pass("doing transaction");
  die "failure";
  $tran->();
 }  success => sub {
  fail("should not have worked");
  # congregate { say } Entity::Author->find(...), failure { die };
 }, failure => sub {
  pass("failed as expected");
 }, goodbye => sub {
  pass("next step");
 };
};

subtest 'refcounts' => sub {
 plan tests => 26;
 {
  my $weak_tran;
  my $tran = as_transaction {
   Scalar::Util::weaken($weak_tran = shift);
  };
  is_oneref($tran, 'have single ref for transaction');
  ok($weak_tran, 'weak transaction still alive');
  ok($weak_tran, 'weak transaction still alive');
  $weak_tran->();
  is_oneref($tran, 'still single ref for transaction');
  $tran->commit;
  is_oneref($tran, 'still single ref for transaction');
  undef $tran;
  is($weak_tran, undef, 'weak copy disappeared');
 }

 {
  my $weak_tran;
  my $tran = as_transaction {
   is_refcount($_[0], 2, 'have expected refcount for transaction in transaction handling code');
   Scalar::Util::weaken($weak_tran = shift);
  }  success => sub { is_refcount($_[0], 3, 'refcount correct in success callback') }
  ,  failure => sub { fail("why the failure?") }
  ,  goodbye => sub { is_refcount($_[0], 3, 'refcount correct in goodbye callback') };
  is_oneref($tran, 'have single ref for transaction');
  ok($weak_tran, 'weak transaction still alive');
  ok($weak_tran->(), 'can apply transaction');
  ok($weak_tran, 'weak transaction still alive');
  is_oneref($tran, 'still single ref for transaction');
  ok($tran->commit, 'can commit');
  is_oneref($tran, 'still single ref for transaction');
 }
 {
  my $weak_tran;
  my $tran = as_transaction {
   is_refcount($_[0], 2, 'have expected refcount for transaction in transaction handling code');
   Scalar::Util::weaken($weak_tran = shift);
   die;
  }  success => sub { fail("should not succeed?") },
  ,  failure => sub { is_refcount($_[0], 3, 'refcount correct in failure callback') }
  ,  goodbye => sub { is_refcount($_[0], 3, 'refcount correct in goodbye callback') };
  is_oneref($tran, 'have single ref for transaction');
  ok($weak_tran, 'weak transaction still alive');
  ok($weak_tran->(), 'can apply transaction');
  ok($weak_tran, 'weak transaction still alive');
  is_oneref($tran, 'still single ref for transaction');
  ok($tran->commit, 'can commit');
  is_oneref($tran, 'still single ref for transaction');
 }
 done_testing;
};

done_testing;
