#!perl -wT

# Check FCGI::Buffer traps if you try to set the cache too late

use strict;
use warnings;
use Test::Most;
# use Test::NoWarnings;	# HTML::Clean has them

eval 'use Test::Carp';

if($@) {
	plan skip_all => 'Test::Carp required for test';
} else {
	use_ok('FCGI::Buffer');

	TOOLATE: {

		delete $ENV{'REMOTE_ADDR'};
		delete $ENV{'HTTP_USER_AGENT'};

		my $b = new_ok('FCGI::Buffer');
		ok($b->can_cache() == 1);
		ok($b->is_cached() == 0);

		my $test_count = 6;

		SKIP: {
			eval {
				require CHI;

				CHI->import;
			};

			if($@) {
				$test_count = 5;
				skip 'CHI not installed', 1 if $@;
			}

			diag("Using CHI $CHI::VERSION");

			# Print anything
			print "hello, world";

			my $cache = CHI->new(driver => 'Memory', datastore => {});

			sub f {
				$b->init(cache => $cache, cache_key => 'xyzzy');
			}

			# diag("Ignore the error that it can't retrieve the given body");
			does_carp(\&f);

			ok($b->is_cached() == 0);
		}
		done_testing($test_count);
	}
}
