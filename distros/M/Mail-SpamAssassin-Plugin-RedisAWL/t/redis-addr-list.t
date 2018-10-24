#!perl

use strict;
use warnings;

use Test::More;
use Test::RedisDB;
use Test::Exception;

diag('trying to start mock redis...');
my $redis = Test::RedisDB->new
  or plan skip_all => 'could not start redis (not installed?), skipping test...';

plan 'tests' => 8;

use_ok('Mail::SpamAssassin::RedisAddrList');
use_ok('Mail::SpamAssassin::Plugin::RedisAWL');

my $list = Mail::SpamAssassin::RedisAddrList->new;
isa_ok($list, 'Mail::SpamAssassin::RedisAddrList');

my $main = {
  'conf' => {
    'auto_whitelist_redis_server' => $redis->host.':'.$redis->port,
  },
};

my $checker;
lives_ok {
  $checker = $list->new_checker($main);
} 'create checker object (connects to redis)';

sub test_record_ok {
  my ($record, $count, $score) = @_;
  my $entry;
  lives_ok {
    $entry = $checker->get_addr_entry($record);
  } 'retrieve record '.$record;
  is_deeply($entry, {
      count => $count,
      totscore => $score,
      addr => $record,
    }, 'test content retrieved entry '.$record,
  );
  return $entry
}
sub score_record_ok {
  my $entry = shift;
  $entry = $checker->get_addr_entry($entry) unless ref $entry;
  foreach (1..5) {
    lives_ok {
      $checker->add_score($entry, 1.5);
    } 'add score to new record';
  }
  is_deeply($entry, {
      count => 5,
      totscore => 7.5,
      addr => $entry->{'addr'},
    }, 'test content of local entry');
}

subtest 'basic create,update,delete' => sub {
  # retrieve an empty entry
  my $entry = test_record_ok('user@domain.de|ip=127.0.0.1', 0, 0);

  # add an score for this record
  score_record_ok($entry);

  # check if redis entry is also updated
  $entry = test_record_ok('user@domain.de|ip=127.0.0.1', 5, 7.5);

  # remove this entry
  lives_ok {
    $entry = $checker->remove_entry($entry);
  } 'delete test record';

  # check if entry is empty again
  test_record_ok('user@domain.de|ip=127.0.0.1', 0, 0);
};

subtest 'test deletion when ip=none' => sub {
  my @testips = qw/127.0.0.1 192.168.0.1 10.10.10.10 none/;
  diag('creating user with different ips...');
  foreach my $testip (@testips)  {
    score_record_ok("user\@domain.de|ip=${testip}");
  }
  lives_ok {
    $checker->remove_entry({ 'addr' => 'user@domain.de|ip=none' });
  } 'delete record with ip=none';
  diag('checking if all records for all ips are empty again');
  foreach my $testip (@testips)  {
    test_record_ok("user\@domain.de|ip=${testip}", 0, 0);
  }
};

subtest 'test deletion with ip=none must not delete unrelated records' => sub {
  my @unrelated = qw/
    user@domain.de.bla|ip=127.0.0.1
    user.zumsel@domain.de|ip=127.0.0.1
    otheruser@domain.de.bla|ip=127.0.0.1
  /;
  diag('creating some unrelated record...');
  foreach my $addr (@unrelated) {
    score_record_ok($addr);
  };
  lives_ok {
    $checker->remove_entry({ 'addr' => 'user@domain.de|ip=none' });
  } 'delete record with ip=none';
  diag('check if unrelated records are still there...');
  foreach my $addr (@unrelated) {
    test_record_ok($addr, 5, 7.5);
  };
};

# clean up and shutdown testing
lives_ok {
  $checker->finish;
} 'shutdown checker';

$redis->stop;

