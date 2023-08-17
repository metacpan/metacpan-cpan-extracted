
use strict;
use warnings;
use Test::More;
use List::Util qw( any );
use Log::Any;

plan tests => 61;

use FindBin;
use lib $FindBin::RealBin;
use TestAdapters;

BEGIN {
    eval {
        require Devel::StackTrace;
        Devel::StackTrace->VERSION( 2.00 );
    };
    if ( $@ ) {
        plan skip_all => 'Devel::StackTrace >= 2.00 is required for this test';
    }
    eval {
        require Storable;
        Storable->VERSION( 3.08 );
    };
    if ( $@ ) {
        plan skip_all => 'Storable >= 3.08 is required for this test';
    }
    eval {
        require Devel::StackTrace::Extract;
    };
    if ( $@ ) {
        plan skip_all => 'Devel::StackTrace::Extract is required for this test';
    }
}

use Log::Any::Proxy::WithStackTrace;    # necessary?

my $default_log   = Log::Any->get_logger;
my $log           = Log::Any->get_logger( proxy_class => 'WithStackTrace' );
my $log_show_args = Log::Any->get_logger( proxy_class => 'WithStackTrace', proxy_show_stack_trace_args => 1);

is ref $default_log,   'Log::Any::Proxy::Null',
    'no adapter default proxy is Null';
is ref $log,           'Log::Any::Proxy::WithStackTrace',
    'no adapter explicit proxy is WithStackTrace';
is ref $log_show_args, 'Log::Any::Proxy::WithStackTrace',
    'no adapter explicit proxy with proxy_show_stack_trace_args flag is WithStackTrace';

$default_log  ->info("test");
$log          ->info("test");
$log_show_args->info("test");

is ref $default_log,   'Log::Any::Proxy::Null',
    'no adapter default proxy is still Null after logging';
is ref $log,           'Log::Any::Proxy::WithStackTrace',
    'no adapter explicit proxy is still WithStackTrace after logging';
is ref $log_show_args, 'Log::Any::Proxy::WithStackTrace',
    'no adapter explicit proxy with proxy_show_stack_trace_args flag is still WithStackTrace after logging';

Log::Any->set_adapter('+TestAdapters::Structured');

is ref $default_log,   'Log::Any::Proxy',
    'existing default proxy is reblessed after adapter';
is ref $log,           'Log::Any::Proxy::WithStackTrace',
    'existing explicit proxy is still WithStackTrace after adapter';
is ref $log_show_args, 'Log::Any::Proxy::WithStackTrace',
    'existing explicit proxy with proxy_show_stack_trace_args flag is still WithStackTrace after adapter';

is ref $default_log->adapter,   'TestAdapters::Structured',
    'existing default proxy has correct adapter';
is ref $log->adapter,           'TestAdapters::Structured',
    'existing explicit proxy has correct adapter';
is ref $log_show_args->adapter, 'TestAdapters::Structured',
    'existing explicit proxy with proxy_show_stack_trace_args flag has correct adapter';

my @test_cases = (
    [
        'simple',
        [ 'test' ],
        'test',
    ],
    [
        'with structured data',
        [ 'test', { foo => 1 } ],
        'test',
    ],
    [
        'formatted',
        [ 'test %s', 'extra' ],
        'test extra',
    ],
);

sub check_test_cases {
    foreach my $test_case (@test_cases) {
        my ($desc, $args, $expected) = @$test_case;

        my $is_formatted = $args->[0] =~ /%/;

        my $method = $is_formatted ? 'infof' : 'info';

        my ($msgs, $msg);

        my $type = 'default';

        @TestAdapters::STRUCTURED_LOG = ();
        $default_log->$method(@$args);
        $msgs = \@TestAdapters::STRUCTURED_LOG;
        is @$msgs, 1, "$desc expected number of structured messages from $type logger";
        is $msgs->[0]->{category}, 'main',
            "$desc expected category from $type logger";
        is $msgs->[0]->{level}, 'info',
            "$desc expected level from $type logger";
        $msg = $msgs->[0]->{messages}->[0];  # "messages" for text
        is $msg, $expected,
            "$desc expected message from $type logger";

        $type = 'stack trace';

        @TestAdapters::STRUCTURED_LOG = ();
        $log->$method(@$args);
        $msgs = \@TestAdapters::STRUCTURED_LOG;
        is @$msgs, 1, "$desc expected number of structured messages from $type logger";
        is $msgs->[0]->{category}, 'main',
            "$desc expected category from $type logger";
        is $msgs->[0]->{level}, 'info',
            "$desc expected level from $type logger";
        $msg = $msgs->[0]->{data}->[0];  # "data" for non-text
        is ref $msg, 'Log::Any::MessageWithStackTrace',
            "$desc expected message object from $type logger";
        is "$msg", $expected,
            "$desc expected stringified message from $type logger";
        my $trace = $msg->stack_trace;
        is ref $trace, 'Devel::StackTrace',
            "$desc expected stack_trace object from $type logger";
        is $trace->frame_count, 2,
            "$desc stack_trace object has expected number of frames from $type logger";
        #  first frame should be the call to "info" inside this sub (19 lines up),
        # second frame should be the call to this sub from main
        is $trace->frame(0)->line, __LINE__ - 19,
            "$desc stack_trace object has expected first frame from $type logger";
        is $trace->frame(1)->subroutine, 'main::check_test_cases',
            "$desc stack_trace object has expected second frame from $type logger";
        if (!$is_formatted && @$args > 1) {
            my $more_data = $msgs->[0]->{data}->[1];
            is_deeply $more_data, $args->[1],
                "expected structured data from $type logger";
        }
        foreach my $frame ($trace->frames) {
            is scalar @{ $frame->{args} }, 0,
                "stack_trace frame does not have args by default";
        }

        @TestAdapters::STRUCTURED_LOG = ();
        $log_show_args->$method(@$args);
        $msgs = \@TestAdapters::STRUCTURED_LOG;
        $msg = $msgs->[0]->{data}->[0];  # "data" for non-text

        $trace = $msg->stack_trace;

        ok(
            any (
                sub {
                    ($_->args >= 1);
                },
                $trace->frames
            ),
            "stack_trace frame has args if proxy_show_stack_trace_args => 1 is passed to logger",
        );
    }
}

check_test_cases();

