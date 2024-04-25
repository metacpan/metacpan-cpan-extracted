use Test2::V0;
use Log::Any::Test;    # should appear before 'use Log::Any'!
use Log::Any qw($log);

package MyTest1 {
  use Log::Any::Simple ':default';
  info('foo %s baz', 'bar');
  ::is($::log->msgs(), [{category => 'MyTest1', level => 'info', message => 'foo bar baz'}], 'log info default import');
  ::imported_ok(qw(trace debug info warning error fatal));
  ::not_imported_ok(qw(inform warn err crit critical alert emergency));
  $::log->clear();
}

package MyTest2 {
  use Log::Any::Simple ':all';
  info('foo %s baz', 'bar');
  ::is($::log->msgs(), [{category => 'MyTest2', level => 'info', message => 'foo bar baz'}], 'log info default import');
  ::imported_ok(qw(trace debug info warning error fatal));
  ::imported_ok(qw(inform warn err crit critical alert emergency));
  $::log->clear();
}

package MyTest3 {
  use Log::Any::Simple 'debug', 'crit';
  ::imported_ok(qw(debug crit));
  ::not_imported_ok(qw(trace info warning error fatal));
  ::not_imported_ok(qw(inform warn err critical alert emergency));
  $::log->clear();
}

package MyTest4 {
  use Log::Any::Simple ':default', ':die_at' => 'info';
  ::like(::dies { info('foo %s baz', 'bar') }, qr/foo bar baz/, 'dies at info');
  ::is($::log->msgs(), [{category => 'MyTest4', level => 'info', message => 'foo bar baz'}], 'log info with die_at');
  $::log->clear();
}

package MyTest5 {
  use Log::Any::Simple qw(die_with_stack_trace get_logger);
  ::imported_ok(qw(die_with_stack_trace get_logger));
}

done_testing;
