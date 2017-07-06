package HPC::Runner::Command::Logger::Loggers;

use Moose::Role;
use Log::Log4perl qw(:easy);

has 'screen_log' => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self     = shift;
        my $log_conf = q(
log4perl.category = DEBUG, Screen
log4perl.appender.Screen = \
    Log::Log4perl::Appender::ScreenColoredLevels
log4perl.appender.Screen.layout = \
    Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = \
    [%d] %m %n
        );

        Log::Log4perl->init( \$log_conf );
        return get_logger();
    }
);

1;
