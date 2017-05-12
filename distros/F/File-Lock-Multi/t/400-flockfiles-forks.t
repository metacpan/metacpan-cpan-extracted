#!perl

use strict;
use warnings (FATAL => 'all');
use Test::More;
use Test::Exception;
use File::Temp qw(tmpnam);
use File::Lock::Multi;
use File::Lock::Multi::FlockFiles;
use Time::HiRes qw(time sleep);
use Test::Fork;

plan tests => 9;

sub inner;
sub outer;

my $file = tmpnam;

if(my $kid = fork_ok(4, \&inner)) {
  outer;
} else {
  die "fork() failed!";
}

sub outer {
  my $l1 = File::Lock::Multi::FlockFiles->new(file => "${file}1");
  my $l2 = File::Lock::Multi::FlockFiles->new(file => "${file}2");

  ok($l1->lock, "outer got primary lock");  

  diag("outer waiting for secondary lock to be held");
  sleep(0.2) until !$l2->lockable;

  ok($l1->release, "outer released primary lock");

  diag("outer waiting for primary lock to be held");
  sleep(0.2) until !$l1->lockable;

  ok($l2->lock, "outer obtained secondary lock");

  ok($l1->lock, "outer obtained primary lock");
}

sub inner {
  my $l1 = File::Lock::Multi::FlockFiles->new(file => "${file}1");
  my $l2 = File::Lock::Multi::FlockFiles->new(file => "${file}2");

  diag("inner waiting for primary lock to be held");
  sleep(0.2) until !$l1->lockable;

  ok($l2->lock, "inner obtained secondary lock");

  ok($l1->lock, "inner obtained primary lock");

  ok($l2->release, "inner released secondary lock");

  ok($l1->release, "inner released primary lock");
}

