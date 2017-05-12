#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
	package GIDTest;
	use GID;

	sub test_last_index {
		return last_index { $_ eq 1 } ( 1,1,1,1 );
	}

	sub test_uniq {
		return uniq ( 1,1,1,1 );
	}

	1;
}

is(GIDTest->test_last_index,3,'gid last_index works fine');
is_deeply([GIDTest->test_uniq],[1],'gid uniq works fine');

{
	package GIDTest::NoDistinct;
	use GID qw(
		-distinct
	);

	sub test_distinct {
		return distinct ( 1,1,1,1 );
	}

	sub test_uniq {
		return uniq ( 1,1,1,1 );
	}

	1;
}

eval {
	GIDTest::NoDistinct->test_distinct;
};
like($@,qr/Undefined subroutine &GIDTest::NoDistinct::distinct/,'Excluded distinct on import');

is_deeply([GIDTest::NoDistinct->test_uniq],[1],'gid uniq works fine with exclude of distinct');

{
	package GIDTest::NoIo;
	use GID qw(
		-io
	);

	sub test_io {
		return io('xxxxxxxxxxxxxxxx');
	}

	sub test_env {
		return env('GID_TEST_ENV_TEST');
	}

	1;
}

eval {
	GIDTest::NoIo->test_io;
};
like($@,qr/Undefined subroutine &GIDTest::NoIo::io/,'Don\'t load IO::All at all');

$ENV{GID_TEST_ENV_TEST} = 23;

is(GIDTest::NoIo->test_env('GID_TEST_ENV_TEST'),"23",'Checking env() through GIDTest::NoIo');

{
	package GIDTest::NoEnv;
	use GID qw(
		-env
	);

	sub test_env {
		return env('GID_TEST_ENV_TEST');
	}

	1;
}

eval {
	GIDTest::NoEnv->test_env;
};
like($@,qr/Undefined subroutine &GIDTest::NoEnv::env/,'Excluded env gid function, env call must fail');

{
	package GIDTest::NoListMoreUtils;
	use GID qw(
		-List::MoreUtils
	);

	sub test_distinct {
		return distinct ( 1,1,1,1 );
	}

	sub test_uniq {
		return uniq ( 1,1,1,1 );
	}

	1;
}

eval {
	GIDTest::NoListMoreUtils->test_distinct;
};
like($@,qr/Undefined subroutine &GIDTest::NoListMoreUtils::distinct/,'Excluded List::MoreUtils, distinct must fail');

eval {
	GIDTest::NoListMoreUtils->test_uniq;
};
like($@,qr/Undefined subroutine &GIDTest::NoListMoreUtils::uniq/,'Excluded List::MoreUtils, uniq must fail');

{
	package GIDTest::EnvOnly;
	use GID qw(
		env
	);

	sub test_env {
		return env('GID_TEST_ENV_TEST');
	}

	sub test_io {
		return io('xxxxxxxxxxxxxxxx');
	}

	1;
}

eval {
	GIDTest::EnvOnly->test_io;
};
like($@,qr/Undefined subroutine &GIDTest::EnvOnly::io/,'Including env only, io call must fail');

$ENV{GID_TEST_ENV_TEST} = 24;

is(GIDTest::EnvOnly->test_env('GID_TEST_ENV_TEST'),"24",'Checking env() through GIDTest::EnvOnly');

my $modifier_var_after = 0;
my $modifier_var_before = 0;
my $modifier_var_around = 0;

{
	package GIDTest::Modifiers;
	use GID;

	sub test_env {
		return env('GID_TEST_ENV_TEST');
	}

	after test_env => sub {
		$modifier_var_after += 1;
	};

	before test_env => sub {
		$modifier_var_before += 2;
	};

	around test_env => sub {
		my $orig = shift;
		$modifier_var_around += 3;
		return $orig->(@_);
	};

	1;
}

$ENV{GID_TEST_ENV_TEST} = 27;

is(GIDTest::Modifiers->test_env('GID_TEST_ENV_TEST'),"27",'Checking env() through GIDTest::Modifiers');
is($modifier_var_after,1,'Modifier after is called');
is($modifier_var_before,2,'Modifier before is called');
is($modifier_var_around,3,'Modifier around is called');

eval "
	package GIDTest::CrashExcludeInclude;
	use GID qw(
		-distinct
		distinct
	);
	1;
";
like($@,qr/GID: you can't define -exclude's and include's on import of GID/,'Not using include and exclude at once on import');

done_testing;
