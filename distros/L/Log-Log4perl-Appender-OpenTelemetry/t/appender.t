use v5.42;
use Test2::V0;
use Log::Log4perl;
# same as OpenTelemetry::SDK::Exporter::Console
use JSON::MaybeXS;

local $ENV{OTEL_BSP_MAX_EXPORT_BATCH_SIZE} = 1;
local $ENV{OTEL_LOGS_EXPORTER} = 'console';
local $ENV{OTEL_TRACES_EXPORTER} = 'none';
local $ENV{OTEL_LOG_LEVEL} = 'TRACE';
local $ENV{OTEL_PERL_EXPORTER_CONSOLE_FORMAT} = 'json';
local $ENV{OTEL_BSP_EXPORT_TIMEOUT} = 1;

require OpenTelemetry::SDK;
OpenTelemetry::SDK->import;

my $conf = <<CONF;
    log4perl.category = DEBUG, OpenTelemetry
    log4perl.appender.OpenTelemetry = Log::Log4perl::Appender::OpenTelemetry
    log4perl.appender.OpenTelemetry.layout = PatternLayout
    log4perl.appender.OpenTelemetry.layout.ConversionPattern = %x %m{chomp}
CONF

Log::Log4perl->init(\$conf);

my $appender = Log::Log4perl->appenders->{OpenTelemetry};
isa_ok($appender, 'Log::Log4perl::Appender');

my $err;
local *STDERR;
open(STDERR, '>', \$err)
    or die "Failed to open a temporary STDERR: $!";

package Test::Package::Name 1.234 {
    use v5.42;
    use feature 'defer';
    no warnings 'experimental::defer';
    use OpenTelemetry 'otel_tracer_provider';

    state $logger = Log::Log4perl->get_logger;


    sub some_function {
        Log::Log4perl::NDC->push("prefix");
        Log::Log4perl::MDC->put("MDC_key", "MDC value");
        defer {
            Log::Log4perl::NDC->pop;
            Log::Log4perl::MDC->remove;
        }

        otel_tracer_provider->tracer->in_span(test_span => (
                attributes => {
                    testattr => 'testvalue'
                })
            => sub {
            $logger->debug("debugging message 1");
        });
    }
}

Test::Package::Name->some_function;

my $output;
ok(lives {
    $output = decode_json($err);
},
    "output JSON decode ok")
    or note($@);

is $output
    => {
        attributes              => hash {
            field 'MDC_key'     => 'MDC value';
            end();
        },
        dropped_attributes      => 0,
        flags                   => 1,
        body                    => "prefix debugging message 1",
        instrumentation_scope   => hash {
            # the Log4perl category
            field 'name'        => 'Test.Package.Name';
            field 'version'     => '';
            end();
        },
        resource                => hash { etc() },
        severity_number         => 5,
        severity_text           => 'DEBUG',
        timestamp               => number_gt(1790934942),
        observed_timestamp      => number_gt(1790934942),
        span_id                 => L(),
        trace_id                => L(),
    },
    => 'OTLP log record ok';

done_testing;
