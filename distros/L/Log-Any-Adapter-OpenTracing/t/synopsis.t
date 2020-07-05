use strict;
use warnings;

use Test::More;

use OpenTracing::DSL qw(:v1);
use Log::Any qw($log);
use Log::Any::Adapter qw(OpenTracing);

trace {
    my ($span) = @_;
    {
        my @logs = @{$span->logs || []};
        is(@logs, 0, 'no log message yet');
    }
    $log->info(my $msg = 'Messages in a span should be logged');
    {
        my @logs = @{$span->logs};
        is(@logs, 1, 'have a single log message');
        is($logs[0]->tags->{message}, $msg, 'message was recorded correctly');
    }
};
$log->info('Messages outside a span would not be logged');
done_testing;

