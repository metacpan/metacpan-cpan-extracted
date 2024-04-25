use Test2::V0;

package MyTest1 {
  use Log::Any::Simple ':all';
  info('foo');
  ::like(::dies { fatal('bar') }, qr/bar/, 'dies at fatal by default');
}

package MyTest2 {
  use Log::Any::Simple ':all', ':die_at' => 'emergency';
  info('foo');
  fatal('bar');
  alert('baz');
  ::like(::dies { emergency('bin') }, qr/bin/, 'only dies at emergency');
}

package MyTest3 {
  use Log::Any::Simple ':all', ':die_at' => 'trace';
  ::like(::dies { trace('foo') }, qr/foo/, 'dies as soon as trace');
}

package MyTest4 {
  use Log::Any::Simple ':all', ':die_at' => 'none';
  info('foo');
  emergency('bar');
  ::pass('never dies');
}

done_testing;
