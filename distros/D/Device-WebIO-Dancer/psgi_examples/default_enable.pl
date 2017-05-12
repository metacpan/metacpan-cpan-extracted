use Log::Dispatch;

use constant LOG_DIR   => 'logs';
use constant LOG_FILE  => LOG_DIR . '/plack.log';
use constant LOG_LEVEL => 'debug';

my $logger = Log::Dispatch->new(
    outputs => [
        [
            'File',
            min_level => LOG_LEVEL,
            filename  => LOG_FILE,
            mode      => '>>',
            newline   => 1,
        ],
    ],
);

set log => 'core';
set show_errors => 1;


enable 'Deflater';
enable 'Session', store => 'File';
enable 'Debug', panels => [ qw<DBITrace Memory Timer> ];
enable 'LogDispatch', logger => $logger;

1;
