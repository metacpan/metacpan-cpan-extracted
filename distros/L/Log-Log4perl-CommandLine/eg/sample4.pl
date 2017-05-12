use Log::Log4perl qw(:easy);
use Log::Log4perl::CommandLine ':all',
                               ':loginit' => { layout => '%c %m%n' };

TRACE "trace message";
DEBUG "debug message";
INFO  "info  message";
WARN  "warn  message";
ERROR "error message";
FATAL "fatal message";
