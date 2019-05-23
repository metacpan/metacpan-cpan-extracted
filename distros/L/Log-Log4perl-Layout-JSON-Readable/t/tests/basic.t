use Test::Most '-Test::Warn';
use Test::Warnings 'warning';
use Log::Log4perl;

# strongly inspired by Log::Log4perl::Layout::JSON basic.t

sub setup_and_return_string {
    my ($extra_settings) = @_;
    $extra_settings ||= '';

    my $conf = q(
        log4perl.rootLogger = INFO, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON::Readable
        log4perl.appender.Test.layout.field.message = %m
        log4perl.appender.Test.layout.field.category = %c
        log4perl.appender.Test.layout.field.time = %d
        log4perl.appender.Test.layout.field.level = %p
        log4perl.appender.Test.layout.field.pid = %P
        log4perl.appender.Test.layout.canonical = 1
    );
    Log::Log4perl::init( \"$conf$extra_settings" );
    Log::Log4perl::MDC->remove;

    my $appender = Log::Log4perl->appender_by_name("Test");
    my $logger = Log::Log4perl->get_logger('foo');

    $logger->info('info message');
    my $string = $appender->string();
    $appender->string('');

    return $string;
}

subtest 'default keys' => sub {
    my $string = setup_and_return_string();

    like(
        $string,
        qr[\{"time":"\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}","pid":"\d+","level":"INFO","category":"foo","message":"info message"\}],
        'time, pid, level are first',
    );
};

subtest 'custom keys' => sub {
    my $string = setup_and_return_string(<<'CONF');
log4perl.appender.Test.layout.first_fields= pid , category
CONF

    like(
        $string,
        qr[\{"pid":"\d+","category":"foo","level":"INFO","message":"info message","time":"\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}"\}],
        'pid, category are first',
    );
};

subtest 'warnings' => sub {
    my $warnings = warning {
        my $string = setup_and_return_string(<<'CONF');
log4perl.appender.Test.layout.bad_param= foo
CONF
    };

    like(
        $warnings,
        qr{\bUnknown configuration items: bad_param\b},
        'unknown params should warn',
    );
};

done_testing;
