use Test2::V0;

package MyTest {
  use Log::Any::Simple 'fatal';
  sub f { fatal('foo'); }
  sub g { f(); }
}

like(dies { MyTest::g() }, qr{foo at t/400}, 'dies with short message');

Log::Any::Simple::die_with_stack_trace('long');
like(dies { MyTest::g() }, qr{foo at [^ ]*lib/Log/Any/Simple}, 'dies with long message');

Log::Any::Simple::die_with_stack_trace('none');
like(dies { MyTest::g() }, qr/^foo\n$/s, 'dies with no trace');

Log::Any::Simple::die_with_stack_trace('short');
like(dies { MyTest::g() }, qr{foo at t/400}, 'dies with short again');

Log::Any::Simple::die_with_stack_trace(main => 'long');
like(dies { MyTest::g() }, qr{foo at t/400}, 'still dies with short message');

Log::Any::Simple::die_with_stack_trace(MyTest => 'long');
like(dies { MyTest::g() }, qr{foo at [^ ]*lib/Log/Any/Simple}, 'dies with long message again');

Log::Any::Simple::die_with_stack_trace(MyTest => undef);
like(dies { MyTest::g() }, qr{foo at t/400}, 'dies with short message again');

done_testing;
