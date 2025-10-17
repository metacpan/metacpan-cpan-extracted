use strict;
use warnings;

use Test::Most;

# Test passing a code ref

BEGIN { use_ok('Log::Abstraction') }

my $count = 0;

my $logger = Log::Abstraction->new({
	level => 'debug',
	logger => sub {
		$count++;
		cmp_ok(ref($_[0]), 'eq', 'HASH', 'Code refs are passed a reference to a hash');
		cmp_ok(ref($_[0]->{'message'}), 'eq', 'ARRAY', 'Messages are passed as a reference to an array');
		cmp_ok(scalar(@{$_[0]->{'message'}}), '==', 1, 'One message was given');
		cmp_ok($_[0]->{'message'}->[0], 'eq', 'Test Message', 'Code refs are passed the correct message');
		diag($_[0]->{'message'}->[0]) if($ENV{'TEST_VERBOSE'});
	}
});

$logger->debug('Test Message');
cmp_ok($count, '==', 1, 'Code was called');

done_testing();
