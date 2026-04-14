use strict;
use warnings;
use Test::More;

use_ok('Enum::Declare');

# :Str with explicit string values
{
	package LogLevel;
	use Enum::Declare;

	enum LogLevel :Str { Debug = "debug", Info = "info", Warn = "warn", Error = "error" };
}

is(LogLevel::Debug(), 'debug', 'Debug is "debug"');
is(LogLevel::Info(),  'info',  'Info is "info"');
is(LogLevel::Warn(),  'warn',  'Warn is "warn"');
is(LogLevel::Error(), 'error', 'Error is "error"');

my $meta = LogLevel::LogLevel();
isa_ok($meta, 'Enum::Declare::Meta');
is($meta->count, 4, 'count is 4');
is($meta->name('debug'), 'Debug', 'name("debug") is Debug');
is($meta->value('Warn'), 'warn', 'value("Warn") is "warn"');
ok($meta->valid('info'),  'valid("info")');
ok(!$meta->valid('foo'),  'not valid("foo")');

# :Str with default values (lowercased variant names)
{
	package Fruit;
	use Enum::Declare;

	enum Fruit :Str { Apple, Banana, Cherry };
}

is(Fruit::Apple(),  'apple',  'Apple defaults to "apple"');
is(Fruit::Banana(), 'banana', 'Banana defaults to "banana"');
is(Fruit::Cherry(), 'cherry', 'Cherry defaults to "cherry"');

my $fruit_meta = Fruit::Fruit();
is_deeply($fruit_meta->values, ['apple', 'banana', 'cherry'], 'default :Str values');

# :Str with mixed explicit and default
{
	package Status;
	use Enum::Declare;

	enum Status :Str { Active = "on", Inactive, Pending = "wait" };
}

is(Status::Active(),   'on',       'Active is "on"');
is(Status::Inactive(), 'inactive', 'Inactive defaults to "inactive"');
is(Status::Pending(),  'wait',     'Pending is "wait"');

# :Str with single-quoted strings
{
	package Color;
	use Enum::Declare;

	enum Color :Str { Red = 'red', Green = 'green', Blue = 'blue' };
}

is(Color::Red(),   'red',   'single-quoted Red');
is(Color::Green(), 'green', 'single-quoted Green');
is(Color::Blue(),  'blue',  'single-quoted Blue');

# verify integer enums still work with new attr parameter
{
	package Numbers;
	use Enum::Declare;

	enum Num { A, B, C };
}

is(Numbers::A(), 0, 'plain enum still works');
is(Numbers::B(), 1, 'plain enum still works');

done_testing();
