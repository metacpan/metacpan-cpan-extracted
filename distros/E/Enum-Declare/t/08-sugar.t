use strict;
use warnings;
use Test::More;

# Declare enums BEFORE loading Sugar so types appear in Sugar's %valid_types
BEGIN {
	require Enum::Declare;
	Enum::Declare->import;
	eval q{
		package SugarIntApp;
		use Enum::Declare;
		enum Priority :Type { Low, Medium, High };

		package SugarStrApp;
		use Enum::Declare;
		enum Env :Str :Type { Dev, Staging, Prod = "production" };

		package SugarFlagsApp;
		use Enum::Declare;
		enum Access :Flags :Type { View, Edit, Delete };
	};
	die $@ if $@;
}

BEGIN {
	eval { require Object::Proto::Sugar };
	plan skip_all => 'Object::Proto::Sugar not installed' if $@;
}

# ====== Integer enum with has/isa ======

{
	package SugarTask;
	use Object::Proto::Sugar;
	has priority => (is => 'rw', isa => 'Priority');
}

subtest 'integer enum has/isa' => sub {
	my $t = new SugarTask priority => SugarIntApp::Low;
	is($t->priority, 0, 'accepts valid int enum value (Low=0)');

	$t->priority(SugarIntApp::High);
	is($t->priority, 2, 'setter accepts valid int enum value (High=2)');

	eval { new SugarTask priority => 5 };
	like($@, qr/Type constraint failed/, 'rejects invalid int enum');
};

# ====== String enum with has/isa ======

{
	package SugarConfig;
	use Object::Proto::Sugar;
	has env => (is => 'rw', isa => 'Env');
}

subtest 'string enum has/isa' => sub {
	my $c = new SugarConfig env => 'dev';
	is($c->env, 'dev', 'accepts valid string enum value');

	$c->env('production');
	is($c->env, 'production', 'setter accepts explicit string value');

	eval { new SugarConfig env => 'test' };
	like($@, qr/Type constraint failed/, 'rejects invalid string enum');
};

# ====== Flags enum with has/isa ======

{
	package SugarRole;
	use Object::Proto::Sugar;
	has access => (is => 'rw', isa => 'Access');
}

subtest 'flags enum has/isa' => sub {
	my $r = new SugarRole access => 3;
	is($r->access, 3, 'accepts combined flags (View|Edit=3)');

	eval { new SugarRole access => 8 };
	like($@, qr/Type constraint failed/, 'rejects out-of-range flags');
};

# ====== Coercion (always active for enum types) ======

{
	package SugarWidget;
	use Object::Proto::Sugar;
	has priority => (is => 'rw', isa => 'Priority');
}

subtest 'enum coercion' => sub {
	my $w = new SugarWidget priority => 'low';
	is($w->priority, 0, 'coerce converts "low" to 0');

	$w = new SugarWidget priority => 'HIGH';
	is($w->priority, 2, 'coerce converts "HIGH" to 2');

	$w = new SugarWidget priority => 1;
	is($w->priority, 1, 'valid value passes through coercion');
};

# ====== Required enum attribute ======

{
	package SugarRequired;
	use Object::Proto::Sugar;
	has status => (is => 'ro', isa => 'Priority', required => 1);
}

subtest 'required enum attribute' => sub {
	eval { new SugarRequired };
	like($@, qr/required/i, 'required enum attribute enforced');

	my $r = new SugarRequired status => 1;
	is($r->status, 1, 'required enum attribute accepts valid value');
};

# ====== Default enum value ======

{
	package SugarDefault;
	use Object::Proto::Sugar;
	has level => (is => 'rw', isa => 'Priority', default => 1);
}

subtest 'default enum value' => sub {
	my $d = new SugarDefault;
	is($d->level, 1, 'default enum value is used');

	$d = new SugarDefault level => 2;
	is($d->level, 2, 'explicit value overrides default');
};

done_testing;
