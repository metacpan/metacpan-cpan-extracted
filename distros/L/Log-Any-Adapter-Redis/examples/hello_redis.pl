
use Log::Any::Adapter;
use Log::Any qw($log);

Log::Any::Adapter->set('Redis',
    log_hostname => 1,
    log_pid      => 1
);

$log->info('Hello, Redis');
