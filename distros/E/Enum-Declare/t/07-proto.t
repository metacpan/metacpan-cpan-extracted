use strict;
use warnings;
use Test::More;
use Object::Proto;
use Enum::Declare;

# ====== Integer enum type registration ======

{
	package IntApp;
	use Enum::Declare;
	enum Color :Type { Red, Green, Blue };
}

subtest 'integer enum type' => sub {
	ok(Object::Proto::has_type('Color'), 'Color type is registered');

	object 'Painting', 'shade:Color';

	my $p = new Painting shade => IntApp::Red;
	is($p->shade, 0, 'accepts valid int enum value 0 (Red)');

	$p->shade(1);
	is($p->shade, 1, 'accepts valid int enum value 1 (Green)');

	$p->shade(2);
	is($p->shade, 2, 'accepts valid int enum value 2 (Blue)');

	eval { new Painting shade => 99 };
	like($@, qr/Type constraint failed/, 'rejects invalid int enum value');

	eval { $p->shade(99) };
	like($@, qr/Type constraint failed/, 'rejects invalid int on setter');
};

# ====== String enum type registration ======

{
	package StrApp;
	use Enum::Declare;
	enum LogLevel :Str:Type { Debug, Info, Warn = "warning" };
}

subtest 'string enum type' => sub {
	ok(Object::Proto::has_type('LogLevel'), 'LogLevel string type is registered');

	object 'Logger', 'level:LogLevel';

	my $l = new Logger level => 'debug';
	is($l->level, 'debug', 'accepts valid string enum value "debug"');

	$l->level('info');
	is($l->level, 'info', 'accepts valid string enum value "info"');

	$l->level('warning');
	is($l->level, 'warning', 'accepts explicit string value "warning"');

	eval { new Logger level => 'error' };
	like($@, qr/Type constraint failed/, 'rejects invalid string enum value');
};

# ====== Flags enum type registration ======

{
	package FlagsApp;
	use Enum::Declare;
	enum Perms :Flags:Type { Read, Write, Execute };
}

subtest 'flags enum type' => sub {
	ok(Object::Proto::has_type('Perms'), 'Perms flags type is registered');

	object 'File', 'mode:Perms';

	my $f = new File mode => 1;
	is($f->mode, 1, 'accepts single flag (Read=1)');

	$f->mode(3);
	is($f->mode, 3, 'accepts combined flags (Read|Write=3)');

	$f->mode(7);
	is($f->mode, 7, 'accepts all flags combined (7)');

	$f->mode(0);
	is($f->mode, 0, 'accepts 0 (no flags)');

	eval { new File mode => 8 };
	like($@, qr/Type constraint failed/, 'rejects value outside flags mask');

	eval { $f->mode(15) };
	like($@, qr/Type constraint failed/, 'rejects flags overflow');
};

# ====== Explicit value enum type registration ======

{
	package ExplApp;
	use Enum::Declare;
	enum HttpStatus :Type { OK = 200, NotFound = 404, ServerError = 500 };
}

subtest 'explicit value enum type' => sub {
	ok(Object::Proto::has_type('HttpStatus'), 'HttpStatus type is registered');

	object 'Response', 'status:HttpStatus';

	my $r = new Response status => 200;
	is($r->status, 200, 'accepts explicit value 200');

	$r->status(404);
	is($r->status, 404, 'accepts explicit value 404');

	eval { new Response status => 201 };
	like($@, qr/Type constraint failed/, 'rejects non-enum explicit value');
};

# ====== Coercion: case-insensitive name -> value ======

subtest 'integer enum coercion' => sub {
	object 'Widget', 'color:Color:coerce';

	my $w = new Widget color => 'red';
	is($w->color, 0, 'coerces "red" (lowercase) to 0');

	$w = new Widget color => 'Red';
	is($w->color, 0, 'coerces "Red" (original case) to 0');

	$w = new Widget color => 'GREEN';
	is($w->color, 1, 'coerces "GREEN" (uppercase) to 1');

	$w = new Widget color => 0;
	is($w->color, 0, 'valid value 0 passes through coercion');
};

# ====== Coercion: string enum ======

subtest 'string enum coercion' => sub {
	object 'LogConfig', 'level:LogLevel:coerce';

	my $c = new LogConfig level => 'Debug';
	is($c->level, 'debug', 'coerces "Debug" to "debug" for string enum');

	$c = new LogConfig level => 'WARN';
	is($c->level, 'warning', 'coerces "WARN" to "warning" for string enum');
};

# ====== list_types includes enum types ======

subtest 'list_types integration' => sub {
	my $types = Object::Proto::list_types();
	my %type_set = map { $_ => 1 } @$types;
	ok($type_set{Color},      'Color in list_types');
	ok($type_set{LogLevel},   'LogLevel in list_types');
	ok($type_set{Perms},      'Perms in list_types');
	ok($type_set{HttpStatus}, 'HttpStatus in list_types');
};

# ====== Enum without :Type is NOT registered ======

subtest 'no :Type means no type registration' => sub {
	{
		package NoTypeApp;
		use Enum::Declare;
		enum PlainEnum { Foo, Bar, Baz };
	}
	ok(!Object::Proto::has_type('PlainEnum'), 'enum without :Type is not registered');
};

done_testing;
