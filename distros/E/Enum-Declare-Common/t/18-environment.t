use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::Environment;

subtest 'environment constants' => sub {
	is(Development, 'development', 'Development');
	is(Staging,     'staging',     'Staging');
	is(Production,  'production',  'Production');
	is(Testing,     'testing',     'Testing');
};

subtest 'meta accessor' => sub {
	my $meta = Env();
	is($meta->count, 4, '4 environments');
	ok($meta->valid('production'),  'production is valid');
	ok($meta->valid('development'), 'development is valid');
	ok(!$meta->valid('local'),      'local is not valid');
	is($meta->name('staging'), 'Staging', 'name of staging is Staging');
};

done_testing;
