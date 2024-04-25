use Test2::V0;
use Log::Any::Test;    # should appear before 'use Log::Any'!
use Log::Any qw($log);

package MyTest1 {
  use Log::Any::Simple ':prefix' => 'foo ';
  Log::Any::Simple::info('bar');
  ::is($::log->msgs(), [{category => 'MyTest1', level => 'info', message => 'foo bar'}], 'prefix');
  $::log->clear();
}

package MyTest2 {
  use Log::Any::Simple ':default', ':prefix' => 'foo ';
  info('bar');
  ::is($::log->msgs(), [{category => 'MyTest2', level => 'info', message => 'foo bar'}], 'prefix from imported function');
  $::log->clear();
}

done_testing;
