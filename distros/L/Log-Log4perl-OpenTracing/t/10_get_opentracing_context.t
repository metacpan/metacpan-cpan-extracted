use Test::Most;

use lib 't/lib/';

use Log::Log4perl::OpenTracing;

use OpenTracing::GlobalTracer;
use OpenTracing::Implementation::Mock::Tracer;

subtest 'Set Global Tracer' => sub {
    my $tracer = OpenTracing::Implementation::Mock::Tracer->new(
        context => { #yeah, we have hardcoded context :-)
            foo => 1,
            bar => { baz => 2, qux => 3 }
        },
    );
    OpenTracing::GlobalTracer->set_global_tracer($tracer);
    is (OpenTracing::GlobalTracer->get_global_tracer, $tracer,
        "Installed 'MyMock::Tracer'"
    );
};

subtest 'Get %O Context' => sub {
    my $tracer = OpenTracing::GlobalTracer->get_global_tracer;
    my $context = Log::Log4perl::OpenTracing::get_opentracing_context;
    cmp_deeply(
        $context => {
            foo => 1,
            bar => {
                baz => 2,
                qux => 3,
            },
        },
        "Got the full injected context"
    )
};

done_testing();
