use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::Status;

subtest 'lifecycle constants' => sub {
	is(Pending,   'pending',   'Pending');
	is(Active,    'active',    'Active');
	is(Inactive,  'inactive',  'Inactive');
	is(Suspended, 'suspended', 'Suspended');
	is(Deleted,   'deleted',   'Deleted');
	is(Archived,  'archived',  'Archived');
};

subtest 'meta accessor' => sub {
	my $meta = Lifecycle();
	is($meta->count, 6, '6 lifecycle states');
	ok($meta->valid('active'),    'active is valid');
	ok($meta->valid('deleted'),   'deleted is valid');
	ok(!$meta->valid('disabled'), 'disabled is not valid');
	is($meta->name('pending'), 'Pending', 'name of pending is Pending');
	is($meta->name('archived'), 'Archived', 'name of archived is Archived');
};

done_testing;
