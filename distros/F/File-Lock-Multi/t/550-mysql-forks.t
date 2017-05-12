#!perl

use strict;
use warnings (FATAL => 'all');
use Test::More;
use Test::Exception;
use File::Temp qw(tmpnam);
use File::Lock::Multi;
use Time::HiRes qw(time sleep);
use Test::Fork;

sub inner;
sub outer;
my $dbh_factory;

eval 'use DBD::mysql; 1';

if($@) {
  plan skip_all => "DBD::mysql not installed";
} else {
  eval 'use File::Lock::Multi::MySQL; use DBI; 1' or die $@;
  $ENV{DBI_DSN} ||= "DBI:mysql:";
  $dbh_factory = sub { DBI->connect($ENV{DBI_DSN}, { RaiseError => 1 }) };
  if(eval { $dbh_factory->() }) {
    plan tests => 7;
  } else {
    plan skip_all => "Could not connect to database $ENV{DBI_DSN}: $@";
  }
}

my $file = tmpnam;

if(my $kid = fork_ok(2, \&inner)) {
  outer;
} else {
  die "fork() failed!";
}

sub outer {
  my $l = File::Lock::Multi::MySQL->new(file => $file, dbh => $dbh_factory);
  ok($l->lock, "outer proc got a lock");
  diag("parent hanging onto lock to help child's test");
  sleep(2);
  ok($l->release, "released");
  diag("parent waiting for lock to not be lockable");
  sleep(0.2) until !$l->lockable;
  diag("no longer lockable -- waiting for release");
  my $st = time;
  ok($l->lock, "outer proc (eventually) got a lock");
  my $et = time;
  my $dt = $et - $st;
  ok($dt > 1, "blocked until our child exited");
}

sub inner {
  my $l = File::Lock::Multi::MySQL->new(file => $file, dbh => $dbh_factory);
  sleep 1;
  diag("child waiting for lock to not be lockable");
  sleep(0.2) until !$l->lockable;
  diag("child attempting to lock");
  my $st = time;
  ok($l->lock, "inner proc (eventually) got a lock");
  my $et = time;
  my $dt = $et - $st;
  ok($dt > 1, "blocked until our parent released");
  diag("child hanging onto lock to help parent's test");
  sleep(2);
}

