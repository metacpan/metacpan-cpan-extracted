use strict;
use warnings;
use Test::More;

use_ok('Enum::Declare');

# :Export — auto-exports all constants
{
	package ExportAll;
	use Enum::Declare;
	enum Method :Export { GET, POST, PUT, DELETE };
}

# selective import via @EXPORT_OK
{
	package Consumer1;
	ExportAll->import('GET', 'POST');
}

is(Consumer1::GET(),  0, 'GET imported into Consumer1');
is(Consumer1::POST(), 1, 'POST imported into Consumer1');
ok(!Consumer1->can('PUT'),    'PUT not imported');
ok(!Consumer1->can('DELETE'), 'DELETE not imported');

# auto-import via @EXPORT (all constants)
{
	package Consumer2;
	ExportAll->import();
}

is(Consumer2::GET(),    0, 'GET auto-exported');
is(Consumer2::POST(),   1, 'POST auto-exported');
is(Consumer2::PUT(),    2, 'PUT auto-exported');
is(Consumer2::DELETE(), 3, 'DELETE auto-exported');

# without :Export — no constants exported
{
	package NoAutoExport;
	use Enum::Declare;
	enum Color { Red, Green, Blue };
}

{
	package Consumer3;
	NoAutoExport->import();
}

ok(!Consumer3->can('Red'),   'Red not auto-exported without :Export');
ok(!Consumer3->can('Green'), 'Green not auto-exported');

# :Export combined with :Flags
{
	package Perms;
	use Enum::Declare;
	enum Perms :Flags :Export { Read, Write, Execute };
}

{
	package Consumer5;
	Perms->import();
}

is(Consumer5::Read(),    1, 'Read auto-exported from :Flags :Export');
is(Consumer5::Write(),   2, 'Write auto-exported');
is(Consumer5::Execute(), 4, 'Execute auto-exported');

# :Export combined with :Str
{
	package LogLevels;
	use Enum::Declare;
	enum Level :Str :Export { Debug, Info, Warn };
}

{
	package Consumer6;
	LogLevels->import();
}

is(Consumer6::Debug(), 'debug', 'Debug string auto-exported');
is(Consumer6::Info(),  'info',  'Info string auto-exported');

# :Export also exports the meta accessor
{
	package Consumer7;
	ExportAll->import('Method');
}

ok(Consumer7->can('Method'), 'meta accessor Method imported via selective import');
my $meta = Consumer7::Method();
isa_ok($meta, 'Enum::Declare::Meta', 'imported Method() returns Meta object');

{
	package Consumer8;
	ExportAll->import();
}

ok(Consumer8->can('Method'), 'meta accessor Method auto-exported');

# without :Export — meta accessor is NOT exported
{
	package Consumer9;
	NoAutoExport->import();
}

ok(!Consumer9->can('Color'), 'meta accessor Color not exported without :Export');

# :EnumName tag — selective import of one enum's constants
{
	package MultiEnum;
	use Enum::Declare;
	enum Fruit :Str :Export { Apple, Banana, Cherry };
	enum Veggie :Str :Export { Carrot, Pea, Corn };
}

{
	package TagConsumer1;
	MultiEnum->import(':Fruit');
}

ok(TagConsumer1->can('Apple'),  'Apple imported via :Fruit tag');
ok(TagConsumer1->can('Banana'), 'Banana imported via :Fruit tag');
ok(TagConsumer1->can('Cherry'), 'Cherry imported via :Fruit tag');
ok(TagConsumer1->can('Fruit'),  'Fruit meta accessor imported via :Fruit tag');
ok(!TagConsumer1->can('Carrot'), 'Carrot NOT imported via :Fruit tag');
ok(!TagConsumer1->can('Pea'),    'Pea NOT imported via :Fruit tag');

{
	package TagConsumer2;
	MultiEnum->import(':Veggie');
}

ok(!TagConsumer2->can('Apple'),  'Apple NOT imported via :Veggie tag');
ok(TagConsumer2->can('Carrot'),  'Carrot imported via :Veggie tag');
ok(TagConsumer2->can('Pea'),     'Pea imported via :Veggie tag');
ok(TagConsumer2->can('Corn'),    'Corn imported via :Veggie tag');
ok(TagConsumer2->can('Veggie'),  'Veggie meta accessor imported via :Veggie tag');

done_testing();
