use strict;
use warnings;

use Test::More;

use Capture::Tiny qw(capture_stderr);
use Data::Dumper;
use Log::Any qw($log);
use Log::Any::Adapter;
use Test::Fatal qw(exception);
use Test::MockObject;
use Test::Needs;

BEGIN { use_ok('Log::Any::Adapter::Sentry::Raven') };

subtest test_init => sub {
    ok exception { Log::Any::Adapter->set('Sentry::Raven') },
       "sentry object required";

    my $mock_sentry = Test::MockObject->new();
    ok  exception {
            Log::Any::Adapter->set('Sentry::Raven', sentry => $mock_sentry)
        },
        "Sentry::Raven object required";

    $mock_sentry->set_isa('Sentry::Raven');
    ok  !exception {
            Log::Any::Adapter->set('Sentry::Raven', sentry => $mock_sentry)
        },
        "sentry only required argument";

    ok $log->is_trace, "log defaults to tracing";
    ok $log->is_fatal, "and anything more urgent";

    {
        my ($err) = capture_stderr {
            ok  !exception {
                    Log::Any::Adapter->set('Sentry::Raven',
                        sentry    => $mock_sentry,
                        log_level => 'timber'
                    );
                },
                "handled bad log_level";
            ok $log->is_trace, "bad log_level = trace";
        };
        like $err, qr/trace/, "mentioned bad log_level in STDERR";
    }

    {
        ok  !exception {
                Log::Any::Adapter->set('Sentry::Raven',
                    sentry    => $mock_sentry,
                    log_level => 7, # trace is 8
                );
            },
            "allows numeric log levels, like other adapters";
        ok !$log->is_trace, "numeric log level can exclude trace";
        ok  $log->is_debug, "and include other levels";
    }

    Log::Any::Adapter->set('Sentry::Raven',
        sentry    => $mock_sentry,
        log_level => 'fatal'
    );
    ok !$log->is_trace, "log_level respected";
    ok  $log->is_fatal, "expected levels will be logged";
};

subtest test_logging => sub {
    my $CAPTURE = "capture_message";
    my $mock_sentry = Test::MockObject->new();
       $mock_sentry->set_isa('Sentry::Raven');
       $mock_sentry->mock($CAPTURE => sub {});

    Log::Any::Adapter->set('Sentry::Raven',
        sentry    => $mock_sentry,
        log_level => 'warn'
    );

    my $Message = "foo";
    $log->debug($Message);
    is $mock_sentry->next_call(), undef, "log_level prevents logging";

    $log->error($Message);
    my ($name, $args) = $mock_sentry->next_call();
    is $name, $CAPTURE, "$CAPTURE called";

    my ($_invocant, $message, %context) = @$args;
    is $message, $Message, "sentry logged right message";
    delete $context{'sentry.interfaces.Stacktrace'};
    {
        local $Data::Dumper::Maxdepth = 3;
        is_deeply(
            \%context,
            {
                level => 'error',
                tags  => {},
            },
            "logged expected context",
        )
            or diag(Dumper \%context);
    }

    my $stack_trace;
    {
        local $log->context->{foo} = 'bar';
        $log->error($Message);
        my ($name, $args) = $mock_sentry->next_call();
        is $name, $CAPTURE, "$CAPTURE called again";

        my ($_invocant, $message, %context) = @$args;
        is $message, $Message, "sentry message did not include foo/bar";
        $stack_trace = delete $context{'sentry.interfaces.Stacktrace'};
        {
            local $Data::Dumper::Maxdepth = 3;
            is_deeply(
                \%context,
                {
                    level => 'error',
                    tags  => { foo => 'bar' },
                },
                "Log::Any context included as Sentry tags"
            )
                or diag(Dumper \%context);
        }
    }

    test_needs 'Devel::StackTrace';
    ok $stack_trace->{frames}, "stack trace included with Devel::StackTrace";
};

done_testing;
