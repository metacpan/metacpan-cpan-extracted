use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Log::Dump::Test::Loaded;

subtest 'class_has' => sub {
  for my $method (qw( log logger logfilter logfile logcolor )) {
    ok(Log::Dump::Test::Loaded->can($method), "has $method");
  }
};

subtest 'object_has' => sub {
  my $object = Log::Dump::Test::Loaded->new;

  for my $method (qw( log logger logfilter logfile logcolor )) {
    ok($object->can($method), "has $method");
  }
};

subtest 'other_class_has' => sub {
  for my $method (qw( log logger logfilter logfile logcolor )) {
    ok(Log::Dump::Test::Loaded->test_class->can($method), "has $method");
  }
};

subtest 'other_object_has' => sub {
  for my $method (qw( log logger logfilter logfile logcolor )) {
    ok(Log::Dump::Test::Loaded->test_object->can($method), "has $method");
  }
};

done_testing;
