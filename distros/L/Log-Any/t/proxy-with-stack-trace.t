
use strict;
use warnings;
use Test::More;
use List::Util qw( any );
use Log::Any;
use Scalar::Util qw( blessed );
use Storable qw( dclone );

use FindBin;
use lib $FindBin::RealBin;
use TestAdapters;

my (
    $num_tests,
    $have_Mojo_Exception,
    $have_Moose_Exception,
    $have_Throwable_Error,
);
BEGIN {

    $num_tests = 152;
    eval {
        require Mojo::Exception;
        $have_Mojo_Exception = 1;
        $num_tests += 27;
    };
    eval {
        require Throwable::Error;
        $have_Throwable_Error = 1;
        $num_tests += 31;
    };
    eval {
        require Moose::Exception;
        $have_Moose_Exception = 1;
        $num_tests += 31;
    };

    eval {
        require Devel::StackTrace;
        Devel::StackTrace->VERSION( 2.00 );
    };
    if ( $@ ) {
        plan skip_all => 'Devel::StackTrace >= 2.00 is required for this test';
        $num_tests = 0;
    }
}

plan tests => $num_tests if $num_tests;

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
is !!$default_log->{proxy_show_stack_trace_args}, '',
    'Defauly log does not proxy_show_stack_trace_args';
is ref $log,           'Log::Any::Proxy::WithStackTrace',
    'existing explicit proxy is still WithStackTrace after adapter';
is !!$log->{proxy_show_stack_trace_args}, '',
    'WithStackTrace does not proxy_show_stack_trace_args';
is ref $log_show_args, 'Log::Any::Proxy::WithStackTrace',
    'existing explicit proxy with proxy_show_stack_trace_args flag is still WithStackTrace after adapter';
is !!$log_show_args->{proxy_show_stack_trace_args}, 1,
    'WithStackTrace does proxy_show_stack_trace_args';

is ref $default_log->adapter,   'TestAdapters::Structured',
    'existing default proxy has correct adapter';
is ref $log->adapter,           'TestAdapters::Structured',
    'existing explicit proxy has correct adapter';
is ref $log_show_args->adapter, 'TestAdapters::Structured',
    'existing explicit proxy with proxy_show_stack_trace_args flag has correct adapter';

###################################################################

# Dummy default for initial call:
my $logger     = $default_log;
my $message    = "dummy";
my $extra_args = [];

my ($Mojo_Exception, $Moose_Exception, $Throwable_Error);

sub foo
{
    sub bar {

        # Log with a stack trace that is 3 frames deep (main->foo->bar):
        $logger->info($message, @$extra_args);

        # Create a Mojo::Exception with a similar stack trace:
        if ($have_Mojo_Exception && !$Mojo_Exception) {
            local $@;
            eval { Mojo::Exception->throw("Help!") };
            $Mojo_Exception = $@;
        }

        # Create a Moose::Exception with a similar stack trace:
        if ($have_Moose_Exception && !$Moose_Exception) {
            $Moose_Exception = Moose::Exception->new(message => "Help!");
        }

        # Create a Throwable::Error with a similar stack trace:
        if ($have_Throwable_Error && !$Throwable_Error) {
            local $@;
            eval { Throwable::Error->throw("Help!") };
            $Throwable_Error = $@;
            # Default log adapter doesn't like coderefs:
            $Throwable_Error->stack_trace->{frame_filter} = undef;
            $Throwable_Error->{stack_trace_args}          = undef;
        }
    }

    bar("quux");
}

# Make sure exception objects get initialized:
foo("bar", "baz") if $have_Mojo_Exception  ||
                     $have_Moose_Exception ||
                     $have_Throwable_Error;

my ($desc, $expected_by_type);

foreach my $t (
    [
        "with string",
        "Help!",
        [],
        {
            "default log" => "Help!",
            "proxy log" => [
                "Help!",
                "Log::Any::MessageWithStackTrace",
            ],
            "proxy log show args" => [
                "Help!",
                "Log::Any::MessageWithStackTrace",
            ],
        },
    ],
    [
        "with string and extra args",
        "Help!",
        [ {extra => "data"} ],
        {
            "default log" => "Help!",
            "proxy log" => [
                "Help!",
                "Log::Any::MessageWithStackTrace",
            ],
            "proxy log show args" => [
                "Help!",
                "Log::Any::MessageWithStackTrace",
            ],
        },
    ],
    [
        "with string and bad extra args",
        "Help!",
        [ {extra => "data"}, "huh?" ],
        {
            "default log"         => "Help!",
            # no automatic object inflation if unexpected args:
            "proxy log"           => "Help!",
            "proxy log show args" => "Help!",
        },
    ],
    [
        "with string and bad non-hashref extra args",
        "Help!",
        [ "huh?" ],
        {
            "default log"         => "Help!",
            # no automatic object inflation if unexpected args:
            "proxy log"           => "Help!",
            "proxy log show args" => "Help!",
        },
    ],
    [
        "with non-string unblessed message",
        {foo => "bar"},
        [],
        {
            "default log" => [
                {foo => "bar"},
                "HASH",
            ],
            # no automatic object inflation if non-string message:
            "proxy log" => [
                {foo => "bar"},
                "HASH",
            ],
            "proxy log show args" => [
                {foo => "bar"},
                "HASH",
            ],
        },
    ],
    [
        "with dummy blessed object",
        bless({foo => "bar"}, "DummyError"),
        [],
        {
            "default log" => [
                qr{^DummyError=HASH\(0x[0-9a-f]+\)},
                "DummyError",
            ],
            # no automatic object inflation if random blessed message:
            "proxy log" => [
                qr{^DummyError=HASH\(0x[0-9a-f]+\)},
                "DummyError",
            ],
            "proxy log show args" => [
                qr{^DummyError=HASH\(0x[0-9a-f]+\)},
                "DummyError",
            ],
        },
    ],
    [
        "with Mojo::Exception message",
        $Mojo_Exception,
        [],
        {
            "default log" => [
                qr{^Help! at t/proxy-with-stack-trace\.t line \d+\.},
                "Mojo::Exception",
            ],
            "proxy log" => [
                qr{^Help! at t/proxy-with-stack-trace\.t line \d+\.},
                "Mojo::Exception",
            ],
            "proxy log show args" => [
                qr{^Help! at t/proxy-with-stack-trace\.t line \d+\.},
                "Mojo::Exception",
            ],
        },
    ],
    [
        "with Moose::Exception message",
        $Moose_Exception,
        [],
        {
            "default log" => [
                qr{^Help! at t/proxy-with-stack-trace\.t line \d+\n},
                "Moose::Exception",
            ],
            "proxy log" => [
                qr{^Help! at t/proxy-with-stack-trace\.t line \d+\n},
                "Moose::Exception",
            ],
            "proxy log show args" => [
                qr{^Help! at t/proxy-with-stack-trace\.t line \d+\n},
                "Moose::Exception",
            ],
        },
    ],
    [
        "with Throwable::Error message",
        $Throwable_Error,
        [],
        {
            "default log" => [
                qr{^Help!\n\nTrace begun at t/proxy-with-stack-trace\.t line \d+\n},
                "Throwable::Error",
            ],
            "proxy log" => [
                qr{^Help!\n\nTrace begun at t/proxy-with-stack-trace\.t line \d+\n},
                "Throwable::Error",
            ],
            "proxy log show args" => [
                qr{^Help!\n\nTrace begun at t/proxy-with-stack-trace\.t line \d+\n},
                "Throwable::Error",
            ],
        },
    ],
) {
    my $orig_message;
    ($desc, $orig_message, $extra_args, $expected_by_type) = @$t;

    # This can happen if one of the optional exception modules is not
    # loaded:
    next unless $orig_message;

    foreach my $type (sort keys %$expected_by_type) {

        $message = ref $orig_message ? dclone $orig_message : $orig_message;

        $logger = {
            "default log"         => $default_log,
            "proxy log"           => $log,
            "proxy log show args" => $log_show_args,
        }->{$type};

        @TestAdapters::STRUCTURED_LOG = ();
        foo("bar", "baz");

        my $logged = \@TestAdapters::STRUCTURED_LOG;

        my $long_desc = "$type $desc";

        is @$logged, 1,
            "$long_desc - got expected number of log messages";
        my $msg = $logged->[0];
        is $msg->{category}, 'main',
            "$long_desc - got expected category";
        is $msg->{level}, 'info',
            "$long_desc - got expected level";

        my $expected = $expected_by_type->{$type};

        if (ref $expected) {
            my $messages = $msg->{messages};
            is $messages, undef,
                "$long_desc - got expected number of structured messages";
            my $data = $msg->{data};
            if (@$extra_args == 0) {
                is @$data, 1,
                    "$long_desc - got expected number of structured data";
            }
            elsif (@$extra_args == 1 && ref $extra_args->[0] eq 'HASH') {
                is @$data, 2,
                    "$long_desc - got expected number of structured data";
                is_deeply $data->[1], $extra_args->[0],
                    "$long_desc - got expected extra structured data";
            }
            else {
                is $data, undef,
                    "$long_desc - got expected number of structured data";
            }
            my $thing = $data->[0];
            my $blessed = blessed $thing;

            my $expected_value = $expected->[0];
            my $expected_type  = $expected->[1];

            if ($blessed || ! ref $expected_value) {

                if (ref $expected_value eq 'Regexp') {
                    like "$thing", $expected_value,
                        "$long_desc - message stringifies correctly";
                }
                else {
                    is "$thing", $expected_value,
                        "$long_desc - message stringifies correctly";
                }
            }
            is ref $thing, $expected_type,
                "$long_desc - expected type of structured data got logged";

            my (@frames, $stack_trace);
            if ($blessed) {
                @frames = $thing->can("frames") ? $thing->frames : ();
                unless (@frames) {
                    $stack_trace = $thing->can("stack_trace")
                                       ? $thing->stack_trace
                                       : $thing->can("trace")
                                           ? $thing->trace : undef;
                    @frames = $stack_trace->frames if $stack_trace;
                }
            }
            if (@frames) {

                # Mojo::Exception returns a listref istead of a list:
                @frames = @{$frames[0]} if @frames == 1 &&
                                           ref $frames[0] eq 'ARRAY';

                my $frame = $frames[-1];
                my $sub = $expected_type eq "Mojo::Exception"
                              ? $frame->[3] : $frame->subroutine;
                is $sub, "main::foo",
                    "$long_desc - first frame has correct sub";
                unless ($expected_type eq "Mojo::Exception") {
                    if ($type eq "proxy log") {
                        is_deeply [$frame->args], [],
                            "$long_desc - first frame has expected args";
                    }
                    elsif ($type eq "proxy log show args") {
                        is_deeply [$frame->args], ["bar","baz"],
                            "$long_desc - first frame has expected args";
                    }
                }
                $frame = $frames[-2];
                $sub = $expected_type eq "Mojo::Exception"
                           ? $frame->[3] : $frame->subroutine;
                is $sub, "main::bar",
                    "$long_desc - second frame has correct sub";
                unless ($expected_type eq "Mojo::Exception") {
                    if ($type eq "proxy log") {
                        is_deeply [$frame->args], [],
                            "$long_desc - second frame has expected args";
                    }
                    elsif ($type eq "proxy log show args") {
                        is_deeply [$frame->args], ["quux"],
                            "$long_desc - second frame has expected args";
                    }
                }
            }
        }
        else {
            my $messages = $msg->{messages};
            my @expected = ($expected);
            push @expected, $extra_args->[0] if $extra_args->[0] &&
                                            ref $extra_args->[0] ne 'HASH';
            push @expected, $extra_args->[1] if $extra_args->[1];
            is @$messages, @expected,
                "$long_desc - got expected number of structured messages";
            is_deeply $messages, \@expected,
                "$long_desc - expected structured message got logged";
            my $data = $msg->{data};
            if (ref $extra_args->[0] eq 'HASH') {
                is @$data, 1,
                    "$long_desc - got expected number of structured data";
                is_deeply $data->[0], $extra_args->[0],
                    "$long_desc - got expected structured data";
            }
            else {
                is $data, undef,
                    "$long_desc - got expected number of structured data";
            }
        }
    }
}

