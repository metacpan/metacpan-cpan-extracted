use Test::More tests => 4;
use Log::Log4perl::AutoInit qw(get_logger);
use Log::Log4perl;

my $config1 = "
   log4perl.rootlogger = WARN, Screen
   log4perl.appender.Screen = Log::Log4perl::Appender::Screen
   log4perl.appender.Screen.layout = SimpleLayout
";

my $config2 = "$config1
   log4perl.appender.Basic = log4perl.appender.Screen
   log4perl.appender.Basic.layout = PatternLayout
   log4perl.appender.Basic.layout.ConversionPattern = %d - %p - %M -- %m%n
";

Log::Log4perl::AutoInit::set_config(\$config1);
ok(get_logger, 'Got a logger first time.');
my $appenders;
ok($appenders = Log::Log4perl::appenders(), 'Got an appenders list');
Log::Log4perl::AutoInit::set_config(\$config2);
ok(get_logger, 'Got a logger the second time.');
is_deeply(Log::Log4perl::appenders(), $appenders, "Appenders unchanged by second config");

