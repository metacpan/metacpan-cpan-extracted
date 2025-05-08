use strict;
use warnings;

use Test::Most;
use Test::Needs 'Test::Carp';

BEGIN { use_ok('Log::Abstraction') }

Test::Carp->import();

# Test invalid arguments to new()
throws_ok { Log::Abstraction->new(1, 2, 3) } qr/Invalid arguments passed to new()/, 'Odd number of arguments should throw error';

my $logger = Log::Abstraction->new(logger => []);
throws_ok { $logger->_log('info', 'Test message') } qr/Illegal Operation/, '_log() should only be called internally';

# Test warn method with incorrect input
throws_ok { $logger->warn('This is not a hash reference') } qr//, 'warn() should require a hash reference';
throws_ok { $logger->warn({}) } qr//, 'warn() should require a warning key';

# Test logging with no logger and no syslog
my $logger_no_output = Log::Abstraction->new(carp_on_warn => 1);
# throws_ok { $logger_no_output->warn({ warning => 'No logger set' }) } qr/No logger set/, 'warn() should fallback to Carp';
does_carp_that_matches(sub { $logger_no_output->warn({ warning => 'No logger set' }) }, qr/No logger set/);

# Done testing
done_testing();
