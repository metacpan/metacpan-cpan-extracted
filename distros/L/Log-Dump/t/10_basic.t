use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Log::Dump::Test::Class;

subtest 'class_has' => sub {
  for my $method (qw( log logger logfilter logfile logcolor )) {
    ok(Log::Dump::Test::Class->can($method), "has $method");
  }
};

subtest 'object_has' => sub {
  my $object = Log::Dump::Test::Class->new;

  for my $method (qw( log logger logfilter logfile logcolor )) {
    ok($object->can($method), "has $method");
  }
};

done_testing;
