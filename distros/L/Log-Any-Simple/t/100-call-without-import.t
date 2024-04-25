use Test2::V0;
use Log::Any::Test;    # should appear before 'use Log::Any'!
use Log::Any qw($log);

package MyTest1 {
  use Log::Any::Simple;
  Log::Any::Simple::info('foo %s baz', 'bar');
  ::is($::log->msgs(), [{category => 'MyTest1', level => 'info', message => 'foo bar baz'}], 'log info default import');
  $::log->clear();
}

package MyTest2 {
  use Log::Any::Simple ();
  Log::Any::Simple::info('foo %s baz', 'bar');
  ::is($::log->msgs(), [{category => 'MyTest2', level => 'info', message => 'foo bar baz'}], 'log info no import');
  $::log->clear();
}

package MyTest3 {
  use Log::Any::Simple ':category' => 'bin';
  Log::Any::Simple::info('foo %s baz', 'bar');
  ::is($::log->msgs(), [{category => 'bin', level => 'info', message => 'foo bar baz'}], 'log info explicit category');
  $::log->clear();
}

package MyTest4 {
  use Log::Any::Simple ':die_at' => 'info';
  ::like(::dies { Log::Any::Simple::info('foo %s baz', 'bar') }, qr/foo bar baz/, 'dies at info');
  ::is($::log->msgs(), [{category => 'MyTest4', level => 'info', message => 'foo bar baz'}], 'log info with die_at');
  $::log->clear();
}

done_testing;
