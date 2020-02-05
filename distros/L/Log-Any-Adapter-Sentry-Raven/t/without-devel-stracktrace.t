use strict;
use warnings;

use Test::More;

use Sentry::Raven; # which requires Devel::StackTrace
use Log::Any qw($log);
use Log::Any::Adapter;
use Test::MockObject;
use Test::Without::Module qw(Devel::StackTrace);

my $CAPTURE = "capture_message";
my $mock_sentry = Test::MockObject->new();
   $mock_sentry->set_isa('Sentry::Raven');
   $mock_sentry->mock($CAPTURE => sub {});

Log::Any::Adapter->set('Sentry::Raven',
    sentry    => $mock_sentry,
    log_level => 'warn'
);

$log->error("Ignored");
my ($name, $args) = $mock_sentry->next_call();
my ($_invocant, $_message, %context) = @$args;
ok !$context{'sentry.interfaces.Stacktrace'},
   "no stack trace without Devel::StackTrace";

done_testing;
