use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Log::Dump::Test::ClassUserA;
use Log::Dump::Test::ClassUserB;

subtest 'log_class_has' => sub {
  for my $method (qw( log logger logfilter logfile logcolor )) {
    ok(Log::Dump::Test::ClassLog->can($method), "has $method");
  }
};

subtest 'log_object_has' => sub {
  my $object = Log::Dump::Test::ClassLog->new;

  for my $method (qw( log logger logfilter logfile logcolor )) {
    ok($object->can($method), "has $method");
  }
};

subtest 'user_class_has' => sub {
  for my $method (qw( log logger logfilter logfile logcolor )) {
    ok(Log::Dump::Test::ClassUserA->can($method), "has $method");
  }
};

subtest 'user_object_has' => sub {
  my $object = Log::Dump::Test::ClassUserA->new;

  for my $method (qw( log logger logfilter logfile logcolor )) {
    ok($object->can($method), "has $method");
  }
};

subtest 'class_logger' => sub {
  Log::Dump::Test::ClassUserA->logger(undef);
  Log::Dump::Test::ClassUserB->logger(undef);

  ok(!defined Log::Dump::Test::ClassUserA->logger, 'logger for user A is not defined');

  ok(!defined Log::Dump::Test::ClassUserB->logger, 'logger for user A is not defined');

  ok(!defined Log::Dump::Class->logger, 'base logger is not defined');

  Log::Dump::Test::ClassUserA->logger(0);

  ok(defined Log::Dump::Test::ClassUserB->logger, 'logger for user B is also defined');

  ok(defined Log::Dump::Test::ClassLog->logger, 'class logger is also defined');

  ok(!defined Log::Dump::Class->logger, 'still, base logger is not defined');
};

subtest 'object_logger' => sub {
  Log::Dump::Test::ClassUserA->logger(undef);
  Log::Dump::Test::ClassUserB->logger(undef);

  my $user_a = Log::Dump::Test::ClassUserA->new;
  my $user_b = Log::Dump::Test::ClassUserB->new;

  ok(!defined $user_a->logger, 'logger for user A is not defined');

  ok(!defined $user_b->logger, 'logger for user A is not defined');

  ok(!defined Log::Dump::Test::ClassLog->logger, 'class logger is not defined');

  ok(!defined Log::Dump::Class->logger, 'base logger is not defined');

  $user_a->logger(0);

  ok(defined $user_b->logger, 'logger for user B is also defined');

  ok(defined Log::Dump::Test::ClassLog->logger, 'class logger is also defined');

  ok(!defined Log::Dump::Class->logger, 'still, base logger is not defined');
};

done_testing;
