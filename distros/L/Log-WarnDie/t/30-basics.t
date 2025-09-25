use strict;
use warnings;
use Test::More tests => 8;

use Log::Dispatch;

BEGIN { use_ok('Log::WarnDie') }

use lib 't/lib';	# Seems to have been removed from CPAN
use Log::Dispatch::Buffer;

# Create a Log::Dispatch::Buffer object to capture log messages
my $buffer = Log::Dispatch::Buffer->new(min_level => 'warning');
my $dispatcher = Log::Dispatch->new();
$dispatcher->add($buffer);

# Assign dispatcher to Log::WarnDie
Log::WarnDie->dispatcher($dispatcher);

# Test warning interception
warn 'This is a test warning';
my $logs = $buffer->fetch();
is(scalar(@$logs), 1, 'Warning captured in the log');
like($logs->[0]->{message}, qr/This is a test warning/, 'Correct warning message logged');

# Clear buffer
$buffer->flush();

# Test die interception
eval { die 'This is a test error' };
$logs = $buffer->flush();
is(scalar(@$logs), 1, 'Die message captured in the log');
like($logs->[0]->{message}, qr/This is a test error/, 'Correct die message logged');

# Test filter functionality
Log::WarnDie->filter(sub { return ($_[0] !~ /ignore this/) });
warn 'ignore this warning';
warn 'process this warning';
$logs = $buffer->fetch();
is(scalar(@$logs), 1, 'Filter excluded the ignored message');
like($logs->[0]->{message}, qr/process this warning/, 'Correct warning message logged after filter');

# Disable Log::WarnDie
Log::WarnDie->dispatcher(undef);

# Test warning bypass after disabling
warn 'This warning should not be logged';
$logs = $buffer->fetch();
is(scalar(@$logs), 1, 'Logging disabled after no Log::WarnDie');
