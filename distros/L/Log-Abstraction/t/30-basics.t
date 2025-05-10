use strict;
use warnings;

use Test::Most;
use File::Temp qw/tempfile/;
use Sys::Syslog qw(:standard :macros);

BEGIN { use_ok('Log::Abstraction') }

# Test logging to an in-memory array
my @log_array;
my $logger = Log::Abstraction->new({ logger => \@log_array });

$logger->debug('This is a debug message');
$logger->info('This is an info message');
$logger->notice('This is a notice message');
$logger->trace('This is a trace message');

is_deeply(
	\@log_array,
	[
		{ level => 'debug', message => 'This is a debug message' },
		{ level => 'info', message => 'This is an info message' },
		{ level => 'notice', message => 'This is a notice message' },
		{ level => 'trace', message => 'This is a trace message' }
	],
	'Logged messages to array'
);

# Test logging to a file
my ($fh, $filename) = tempfile();
$logger = Log::Abstraction->new($filename);

$logger->debug('File debug message');
$logger->info('File info message');

open my $log_fh, '<', $filename or die "Could not open log file: $!";
my @log_lines = <$log_fh>;
close $log_fh;

like($log_lines[0], qr/DEBUG: Log::Abstraction/, 'Logged debug message to file');
like($log_lines[0], qr/File debug message/, 'Logged correct debug message to file');
like($log_lines[1], qr/INFO: Log::Abstraction/, 'Logged info message to file');
like($log_lines[1], qr/File info message/, 'Logged correct info message to file');

# As above but with the file argument
($fh, $filename) = tempfile();
$logger = Log::Abstraction->new(logger => { file => $filename });

$logger->debug('File debug message2');
$logger->info('File info message2');

open $log_fh, '<', $filename or die "Could not open log file: $!";
@log_lines = <$log_fh>;
close $log_fh;

like($log_lines[0], qr/DEBUG: Log::Abstraction/, 'Logged debug message to file');
like($log_lines[0], qr/File debug message2/, 'Logged correct debug message to file');
like($log_lines[1], qr/INFO: Log::Abstraction/, 'Logged info message to file');
like($log_lines[1], qr/File info message2/, 'Logged correct info message to file');

# Test logging to a file descriptor
($fh, $filename) = tempfile();
$logger = Log::Abstraction->new({ fd => $fh });

$logger->debug('File debug message');
$logger->info('File info message');
close $fh;

open($log_fh, '<', $filename) or die "Could not open log file: $!";
@log_lines = <$log_fh>;
close $log_fh;

like($log_lines[0], qr/DEBUG: Log::Abstraction/, 'Logged debug message to file descriptor');
like($log_lines[0], qr/File debug message/, 'Logged correct debug message to file descriptor');
like($log_lines[1], qr/INFO: Log::Abstraction/, 'Logged info message to file descriptor');
like($log_lines[1], qr/File info message/, 'Logged correct info message to file descriptor');

# Test logging to a code reference
my @code_log;
$logger = Log::Abstraction->new(logger => sub { push @code_log, @_ });

$logger->debug('Code debug message');
$logger->info('Code info message');

diag(Data::Dumper->new([\@code_log])->Dump()) if($ENV{'TEST_VERBOSE'});
is_deeply(
	\@code_log,
	[
		{
			class => 'Log::Abstraction',
			file => 't/30-basics.t',
			line => 83,	# Adjust line number if needed
			level => 'debug',
			message => ['Code debug message']
		}, {
			class => 'Log::Abstraction',
			file => 't/30-basics.t',
			line => 84,	# Adjust line number if needed
			level => 'info',
			message => ['Code info message']
		}
	],
	'Logged messages to code reference'
);

# Not sure what to do to test this on Haiku.
# It says that the type 'unix' is not supported
if($^O ne 'haiku') {
	# Test logging to syslog
	$logger = Log::Abstraction->new(syslog => { type => 'unix' }, script_name => 'test');

	$logger->warn({ warning => 'Syslog warning message' });

	# Note: Verifying syslog output requires checking the syslog file, not done here
} else {
	diag('TODO: unix type not supported on Haiku - what is it instead?');
}

# Test logging an array
@log_array = ();
$logger = Log::Abstraction->new({ logger => \@log_array });
$logger->debug('This ', 'is ', 'a ', 'list');
$logger->warn('This ', 'is ', 'another ', 'list');
$logger->warn(warning => ['This ', 'is ', 'a ', 'ref ', 'to ', 'a ', 'list']);

diag(Data::Dumper->new([\@log_array])->Dump()) if($ENV{'TEST_VERBOSE'});
is_deeply(
	\@log_array,
	[
		{ level => 'debug', message => 'This is a list' },
		{ level => 'warn', message => 'This is another list' },
		{ level => 'warn', message => 'This is a ref to a list' },
	],
	'Logged list messages to array'
);

# Determine script name if not given
$logger = Log::Abstraction->new(syslog => { facility => 'local0' });
cmp_ok($logger->{'script_name'}, 'eq', '30-basics.t', 'Set a sensible value for script_name');

# Test illegal call to _log()

done_testing();
