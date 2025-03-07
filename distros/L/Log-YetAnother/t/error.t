use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Log::YetAnother') }

# Test invalid arguments to new()
throws_ok { Log::YetAnother->new(1, 2, 3) } qr/Invalid arguments passed to new()/, 'Odd number of arguments should throw error';

throws_ok { Log::YetAnother->new(syslog => { facility => 'local0' }) } qr/syslog needs to know the script name/, 'Missing script_name when syslog is provided should throw error';

# Test illegal call to _log()
my $logger = Log::YetAnother->new(logger => []);
throws_ok { $logger->_log('info', 'Test message') } qr/Illegal Operation/, '_log() should only be called internally';

# Test warn method with incorrect input
throws_ok { $logger->warn('This is not a hash reference') } qr//, 'warn() should require a hash reference';
throws_ok { $logger->warn({}) } qr//, 'warn() should require a warning key';

# Test logging with no logger and no syslog
my $logger_no_output = Log::YetAnother->new();
lives_ok { $logger_no_output->warn({ warning => 'No logger set' }) } 'warn() should fallback to Carp';

# Done testing
done_testing();
