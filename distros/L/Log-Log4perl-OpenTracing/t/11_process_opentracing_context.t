use Test::Most;

use lib 't/lib/';

use Log::Log4perl;
use Log::Log4perl::OpenTracing;
use OpenTracing::GlobalTracer;
use OpenTracing::Implementation::Mock::Tracer;

subtest 'Set Global Tracer' => sub {
    my $tracer = OpenTracing::Implementation::Mock::Tracer->new(
        context => { #yeah, we have hardcoded context :-)
            foo => 'bike',
            bar => { baz => 'best', qux => 'blue' }
        },
    );
    OpenTracing::GlobalTracer->set_global_tracer($tracer);
    is (OpenTracing::GlobalTracer->get_global_tracer, $tracer,
        "Installed 'MyMock::Tracer'"
    );
};

subtest 'Test ConversionPattern with Curlies' => sub {
    
    my $conf = q(
        log4perl.rootLogger = TRACE, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout=PatternLayout
        log4perl.appender.Test.layout.ConversionPattern=value:%O{bar.baz} - %m%n
    );
    
    Log::Log4perl::init( \$conf );
    $Log::Log4perl::JOIN_MSG_ARRAY_CHAR="";
    
    ok my $appender = Log::Log4perl->appender_by_name("Test");
    
    my $logger = Log::Log4perl->get_logger;
    
    $logger->trace('Hello World');
    my $result = $appender->string();
    is $result, "value:best - Hello World\n",
        "Got the expected values";
    
    $appender->string('');
};

done_testing;
