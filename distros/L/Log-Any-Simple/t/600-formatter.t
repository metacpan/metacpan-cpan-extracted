use Test2::V0;
use Log::Any::Test;    # should appear before 'use Log::Any'!
use Log::Any qw($log);

package MyTest1 {
  use Log::Any::Simple;
  Log::Any::Simple::info('foo %s', sub { ['bar'] });
  ::is($::log->msgs(), [{category => 'MyTest1', level => 'info', message => "foo ['bar']"}], 'lazy and short dump');
  $::log->clear();
}

package MyTest2 {
  use Log::Any::Simple ':default';
  info('foo %s', sub { ['bar'] });
  ::is($::log->msgs(), [{category => 'MyTest2', level => 'info', message => "foo ['bar']"}], 'lazy and short dump imported');
  $::log->clear();
}

package MyTest3 {
  use Log::Any::Simple ':dump_long';
  Log::Any::Simple::info('foo %s', ['bar']);
  ::is($::log->msgs(), [{category => 'MyTest3', level => 'info', message => "foo     [\n      'bar'\n    ]"}], 'long dump');
  $::log->clear();
}

package MyTest4 {
  use Log::Any::Simple ':default', ':dump_long';
  info('foo %s', ['bar']);
  ::is($::log->msgs(), [{category => 'MyTest4', level => 'info', message => "foo     [\n      'bar'\n    ]"}], 'long dump imported');
  $::log->clear();
}

done_testing;
