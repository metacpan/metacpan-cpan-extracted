use strict;
use warnings;
use Test::More;

use_ok('Enum::Declare');

# fully explicit values
{
	package HttpStatus;
	use Enum::Declare;

	enum HttpStatus { OK = 200, NotFound = 404, ServerError = 500 };
}

is(HttpStatus::OK(),          200, 'OK is 200');
is(HttpStatus::NotFound(),    404, 'NotFound is 404');
is(HttpStatus::ServerError(), 500, 'ServerError is 500');

my $meta = HttpStatus::HttpStatus();
is($meta->count, 3, 'count is 3');
is($meta->name(200), 'OK', 'name(200) is OK');
is($meta->name(404), 'NotFound', 'name(404)');
is($meta->value('ServerError'), 500, 'value(ServerError)');

# mixed: explicit + auto-increment
{
	package MixedEnum;
	use Enum::Declare;

	enum Foo { A = 10, B, C, D = 20, E };
}

is(MixedEnum::A(), 10, 'A is 10');
is(MixedEnum::B(), 11, 'B is 11 (auto-increment)');
is(MixedEnum::C(), 12, 'C is 12 (auto-increment)');
is(MixedEnum::D(), 20, 'D is 20 (explicit)');
is(MixedEnum::E(), 21, 'E is 21 (auto-increment from 20)');

my $foo_meta = MixedEnum::Foo();
is($foo_meta->count, 5, 'Foo count is 5');
is_deeply($foo_meta->values, [10, 11, 12, 20, 21], 'Foo values');

# negative values
{
	package NegEnum;
	use Enum::Declare;

	enum Temp { Cold = -10, Cool, Warm = 5, Hot };
}

is(NegEnum::Cold(), -10, 'Cold is -10');
is(NegEnum::Cool(), -9,  'Cool is -9 (auto-increment from -10)');
is(NegEnum::Warm(), 5,   'Warm is 5');
is(NegEnum::Hot(),  6,   'Hot is 6');

# plain enum still works (phase 1 compat)
{
	package PlainEnum;
	use Enum::Declare;

	enum Color { Red, Green, Blue };
}

is(PlainEnum::Red(),   0, 'Red is 0 (plain)');
is(PlainEnum::Green(), 1, 'Green is 1 (plain)');
is(PlainEnum::Blue(),  2, 'Blue is 2 (plain)');

done_testing();
