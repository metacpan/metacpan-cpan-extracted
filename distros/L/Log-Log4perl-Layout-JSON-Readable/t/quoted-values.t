use Test::Most '-Test::Warn';
use Test::Warnings 'warning';
use Log::Log4perl;

# RT #139214, reported by bokutin@cpan

Log::Log4perl::init(\<<'EOF');
log4perl.rootLogger = INFO, Test
log4perl.appender.Test = Log::Log4perl::Appender::String
log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON::Readable
log4perl.appender.Test.layout.field.message = %m
log4perl.appender.Test.layout.field.category = %c
log4perl.appender.Test.layout.canonical = 1
log4perl.appender.Test.layout.first_fields= message
EOF

my $appender = Log::Log4perl->appender_by_name("Test");
my $logger = Log::Log4perl->get_logger('foo');

$logger->info('info "message"');
my $string = $appender->string();
$appender->string('');

is(
    $string,
    q[{"message":"info \"message\"","category":"foo"}]."\n",
    'message is first, quotes are preserved',
);

$logger->info('');
$string = $appender->string();
$appender->string('');

is(
    $string,
    q[{"message":"","category":"foo"}]."\n",
    'message is first, empty values are ok',
);

done_testing;


