use strict;
use warnings;

use Test::More;

use Capture::Tiny qw(capture_stderr);
use Data::Dumper;
use Log::Any qw($log);
use Log::Any::Adapter;
use Test::Fatal qw(exception);
use Test::MockObject;

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

    {
        local $log->context->{foo} = 'bar';
        $log->error($Message);
        my ($name, $args) = $mock_sentry->next_call();
        is $name, $CAPTURE, "$CAPTURE called again";

        my ($_invocant, $message, %context) = @$args;
        is $message, $Message, "sentry message did not include foo/bar";
        my $stack_trace = delete $context{'sentry.interfaces.Stacktrace'};
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
        ok $stack_trace->{frames}, "stack trace included with Devel::StackTrace";
    }

    {
        $log->error(My::Test::Exception->new($Message));
        my ($name, $args) = $mock_sentry->next_call();
        is $name, $CAPTURE, "$CAPTURE called with exception";

        my ($_invocant, $message, %context) = @$args;
        is $message, "$Message", "exception stringified";
        my $stack_trace = delete $context{'sentry.interfaces.Stacktrace'};
        is @{$stack_trace->{frames}}, 1, "trace extracted from exception";
    }

    {
        local $My::Test::Exception::WEIRD_TRACE = 1;
        $log->error(My::Test::Exception->new($Message));
        my ($name, $args) = $mock_sentry->next_call();

        my ($_invocant, $message, %context) = @$args;
        my $stack_trace = delete $context{'sentry.interfaces.Stacktrace'};
        ok $stack_trace->{frames}, "got a trace despite bad extraction";
        isnt @{$stack_trace->{frames}}, 1, "fell back to new trace";
    }

    {
        $log->error("We found an exception:", My::Test::Exception->new($Message));
        my ($name, $args) = $mock_sentry->next_call();

        my ($_invocant, $message, %context) = @$args;
        is $message, "We found an exception:\n$Message", "exception joined";
        my $stack_trace = delete $context{'sentry.interfaces.Stacktrace'};
        isnt @{$stack_trace->{frames}}, 1, "didn't extract handled exception trace";
    }
};

{
    package My::Test::Exception;
    use overload '""' => sub { ${ shift() } };

    our $WEIRD_TRACE = 1;

    sub new {
        my ($class, $message) = @_;
        bless \$message, $class;
    }

    sub trace {
        return "without a trace" if $WEIRD_TRACE;

        my $self = shift;
        my $trace = Devel::StackTrace->new(
            message => "$self",
            skip_frames => -1,
        );
        $trace->frames(
            Devel::StackTrace::Frame->new(
                [
                    'Imaginary',    # package
                    'Imaginary.pm', # filename
                    -1,             # line
                    'dream',        # subroutine
                    # more caller vals would follow in the wild
                ],
                [], # params

                # these are all the default from Devel::StackTrace
                undef,       # respect_overload,
                undef,       # max_arg_length
                "$self",     # message
                undef,       # indent
            )
        );
        return $trace;
    }
}

done_testing;
