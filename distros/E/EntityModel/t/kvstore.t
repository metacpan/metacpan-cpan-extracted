#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;
BEGIN { plan skip_all => 'skipping to avoid IO::Async requirement'; }

BEGIN {
	if(eval { require IO::Async::Loop; require Net::Async::Memcached }) {
		plan tests => 6;
	} else {
		plan skip_all => 'IO::Async + memcached not found';
	}
}
use Time::HiRes ();
use IO::Async::Loop;
use EntityModel::StorageClass::KVStore;
use EntityModel::StorageClass::KVStore::Layer::Fake;
use EntityModel::StorageClass::KVStore::Layer::PostgreSQL;
use EntityModel::StorageClass::KVStore::Layer::Memcached;
use EntityModel::StorageClass::KVStore::Layer::LRU;
use Test::Refcount;


subtest 'simple' => sub {
	my $repo = new_ok('EntityModel::StorageClass::KVStore');
	is_oneref($repo, 'refcount is correct');

	# Start with a single layer which procedurally generates a response,
	# so we're testing retrieve without needing to fall back to ->store at any point
	is($repo->add_layer(EntityModel::StorageClass::KVStore::Layer::Fake->new), $repo, 'can add initial layer');

	my $k = 'test';
	my $start = Time::HiRes::time;
	is($repo->lookup(
		query => $k,
		on_success => sub {
			my $v = shift;
			my $elapsed = Time::HiRes::time - $start;
			note sprintf "Took %5.3fms for %s => %s", $elapsed * 1000.0, $k, $v;
			is($v, 'rslt:tset', 'have expected result ' . $v);
		},
		on_failure => sub {
			fail('we did not expect to fail');
		},
	), $repo, 'perform lookup');
	done_testing;
};

subtest 'simple+LRU cache' => sub {
	my $repo = new_ok('EntityModel::StorageClass::KVStore');
	is_oneref($repo, 'refcount is correct');

	# Start with a single layer which procedurally generates a response,
	# so we're testing retrieve without needing to fall back to ->store at any point
	is($repo->add_layer(EntityModel::StorageClass::KVStore::Layer::Fake->new), $repo, 'can add initial layer');
	# Now put a LRU cache layer over this
	is($repo->add_layer(my $lru = EntityModel::StorageClass::KVStore::Layer::LRU->new), $repo, 'add the LRU cache');

	my $k = 'other';
	my $start = Time::HiRes::time;
	is($repo->lookup(
		query => $k,
		on_success => sub {
			my $v = shift;
			my $elapsed = Time::HiRes::time - $start;
			note sprintf "Took %5.3fms for %s => %s", $elapsed * 1000.0, $k, $v;
			is($v, 'rslt:rehto', 'have expected result ' . $v);
		},
		on_failure => sub {
			fail('we did not expect to fail');
		},
	), $repo, 'perform lookup');

	# Since LRU is nonblocking we should be able to pull the same data back directly via ->lookup
	is($lru->lookup('other'), 'rslt:rehto', 'was stored correctly in LRU cache');
	done_testing;
};

subtest 'simple+LRU cache+memcached' => sub {
	my $loop = IO::Async::Loop->new;
	my $repo = new_ok('EntityModel::StorageClass::KVStore');
	is_oneref($repo, 'refcount is correct');

	is($repo->add_layer(EntityModel::StorageClass::KVStore::Layer::Fake->new), $repo, 'can add initial layer');
	is($repo->add_layer(EntityModel::StorageClass::KVStore::Layer::Memcached->new(server => 'localhost', loop => $loop)), $repo, 'add the memcached layer');
	is($repo->add_layer(my $lru = EntityModel::StorageClass::KVStore::Layer::LRU->new), $repo, 'add the LRU cache');

	my $k = 'memcached';
	my $start = Time::HiRes::time;
	is($repo->lookup(
		query => $k,
		on_success => sub {
			my $v = shift;
			my $elapsed = Time::HiRes::time - $start;
			note sprintf "Took %5.3fms for %s => %s", $elapsed * 1000.0, $k, $v;
			is($v, 'rslt:dehcacmem', 'have expected result ' . $v);
			$loop->loop_stop;
		},
		on_failure => sub {
			fail('we did not expect to fail');
			$loop->loop_stop;
		},
	), $repo, 'perform lookup');
	$loop->loop_forever;

	is($lru->lookup('memcached'), 'rslt:dehcacmem', 'was stored correctly in LRU cache');
	$start = Time::HiRes::time;
	is($repo->lookup(
		query => $k,
		on_success => sub {
			my $v = shift;
			my $elapsed = Time::HiRes::time - $start;
			note sprintf "Took %5.3fms for %s => %s", $elapsed * 1000.0, $k, $v;
			is($v, 'rslt:dehcacmem', 'have expected result ' . $v);
		},
		on_failure => sub {
			fail('we did not expect to fail');
		},
	), $repo, 'another lookup, just because');
	is_oneref($repo, 'refcount is correct');
	my $finished;
	$repo->shutdown(
		on_success => sub {
			ok($repo, 'shutdown complete');
			++$finished;
			$loop->loop_stop
		}
	);
	$loop->loop_forever unless $finished;
	is_oneref($repo, 'refcount is correct');
	done_testing;
};
subtest 'postgres' => sub {
	plan skip_all => 'set PG_* env vars' unless exists $ENV{PG_USER};
	my $loop = IO::Async::Loop->new;
	my $repo = new_ok('EntityModel::StorageClass::KVStore');
	is_oneref($repo, 'refcount is correct');
	is($repo->add_layer(my $pg = EntityModel::StorageClass::KVStore::Layer::PostgreSQL->new(
		host => $ENV{PG_HOST},
		user => $ENV{PG_USER},
		pass => $ENV{PG_PASSWORD},
		database => $ENV{PG_DATABASE},
		loop => $loop,
	)), $repo, 'add a pg layer');

	# Put something in it
	my $k = 'postgres!';
	my $start = Time::HiRes::time;
	is($repo->lookup(
		query => $k,
		on_success => sub {
			my $v = shift;
			my $elapsed = Time::HiRes::time - $start;
			note sprintf "Took %5.3fms for %s => %s", $elapsed * 1000.0, $k, $v;
			ok($v, 'have expected result ' . $v);
			$loop->loop_stop;
		},
		on_failure => sub {
			fail('we did not expect to fail');
		},
	), $repo, 'perform lookup');
	$loop->loop_forever;
	is_oneref($repo, 'refcount is correct');
	my $finished;
	$repo->shutdown(
		on_success => sub {
			ok($repo, 'shutdown complete');
			++$finished;
			$loop->loop_stop
		}
	);
	$loop->loop_forever unless $finished;
	is_oneref($repo, 'refcount is correct');
	done_testing;
};

subtest 'postgres+lru' => sub {
	plan skip_all => 'set PG_* env vars' unless exists $ENV{PG_USER};
	my $loop = IO::Async::Loop->new;
	my $repo = new_ok('EntityModel::StorageClass::KVStore');
	is_oneref($repo, 'refcount is correct');
	is($repo->add_layer(my $pg = EntityModel::StorageClass::KVStore::Layer::PostgreSQL->new(
		host => $ENV{PG_HOST},
		user => $ENV{PG_USER},
		pass => $ENV{PG_PASSWORD},
		database => $ENV{PG_DATABASE},
		loop => $loop,
	)), $repo, 'add a pg layer');
	is($repo->add_layer(my $lru = EntityModel::StorageClass::KVStore::Layer::LRU->new), $repo, 'add the LRU cache');
	my $k = 'some_value';
	my $start = Time::HiRes::time;
	is($repo->lookup(
		query => $k,
		on_success => sub {
			my $v = shift;
			my $elapsed = Time::HiRes::time - $start;
			note sprintf "Took %5.3fms for %s => %s", $elapsed * 1000.0, $k, $v;
			ok($v, 'have expected result ' . $v);

			# do it again...
			$start = Time::HiRes::time;
			is($repo->lookup(
				query => $k,
				on_success => sub {
					my $new_v = shift;
					my $elapsed = Time::HiRes::time - $start;
					note sprintf "Took %5.3fms for %s => %s", $elapsed * 1000.0, $k, $v;
					is($v, $new_v, 'have expected result ' . $v);
					$loop->loop_stop;
				},
				on_failure => sub {
					fail('we did not expect to fail');
					$loop->loop_stop;
				},
			), $repo, 'perform lookup');
		},
		on_failure => sub {
			fail('we did not expect to fail');
		},
	), $repo, 'perform lookup');
	$loop->loop_forever;
	is_oneref($repo, 'refcount is correct');
	my $finished;
	$repo->shutdown(
		on_success => sub {
			ok($repo, 'shutdown complete');
			++$finished;
			$loop->loop_stop
		}
	);
	$loop->loop_forever unless $finished;
	is_oneref($repo, 'refcount is correct');
	done_testing;
};
subtest 'postgres+lru+memcached' => sub {
	plan skip_all => 'set PG_* env vars' unless exists $ENV{PG_USER};
	my $loop = IO::Async::Loop->new;
	my $repo = new_ok('EntityModel::StorageClass::KVStore');
	is_oneref($repo, 'refcount is correct');
	is($repo->add_layer(my $pg = EntityModel::StorageClass::KVStore::Layer::PostgreSQL->new(
		host => $ENV{PG_HOST},
		user => $ENV{PG_USER},
		pass => $ENV{PG_PASSWORD},
		database => $ENV{PG_DATABASE},
		loop => $loop,
	)), $repo, 'add a pg layer');
	is($repo->add_layer(EntityModel::StorageClass::KVStore::Layer::Memcached->new(server => 'localhost', loop => $loop)), $repo, 'add the memcached layer');
	is($repo->add_layer(my $lru = EntityModel::StorageClass::KVStore::Layer::LRU->new), $repo, 'add the LRU cache');
	my $start = Time::HiRes::time;
	my $k = join '-', 'another_value', $$, $start, +{};
	is($repo->lookup(
		query => $k,
		on_success => sub {
			my $v = shift;
			my $elapsed = Time::HiRes::time - $start;
			note sprintf "Took %5.3fms for %s => %s", $elapsed * 1000.0, $k, $v;
			ok($v, 'have expected result ' . $v);

			# do it again...
			$start = Time::HiRes::time;
			is($repo->lookup(
				query => $k,
				on_success => sub {
					my $new_v = shift;
					my $elapsed = Time::HiRes::time - $start;
					note sprintf "Took %5.3fms for %s => %s", $elapsed * 1000.0, $k, $v;
					is($v, $new_v, 'have expected result ' . $v);
					$loop->loop_stop;
				},
				on_failure => sub {
					fail('we did not expect to fail');
					$loop->loop_stop;
				},
			), $repo, 'perform lookup');
		},
		on_failure => sub {
			fail('we did not expect to fail');
		},
	), $repo, 'perform lookup');
	$loop->loop_forever;
	is_oneref($repo, 'refcount is correct');
	my $finished;
	$repo->shutdown(
		on_success => sub {
			ok($repo, 'shutdown complete');
			++$finished;
			$loop->loop_stop
		}
	);
	$loop->loop_forever unless $finished;
	is_oneref($repo, 'refcount is correct');
	done_testing;
};
done_testing;

__END__

=pod

Entities can be defined with a keyfield. This is used as the default alternative
lookup for structures such as key-value stores.

push @entities, {
	name => 'entity1',
	keyfield => 'name',
	primary => [qw(id)],
	field => [
		{ name => 'id', type => 'bigserial' },
		{ name => 'name', type => 'text' },
	],
};

resolve {
 entity1 => 'something',
 entity2 => 'another thing',
 entity1 => 'number 3',
} sub {
 my ($something, $another_thing, $number_3) = @_;
};

=cut

