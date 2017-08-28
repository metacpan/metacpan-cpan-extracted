package HPC::Runner::Command::submit_jobs::Plugin::Role::Log;

use Moose::Role;
use namespace::autoclean;
use Log::Log4perl qw(:easy);

##Application log
##There is a bug in here somewhere - this be named anything ...
has 'log' => (
    is      => 'rw',
    default => sub {
        my $self = shift;

        my $log_conf = q(
log4perl.rootLogger = DEBUG, Screen
log4perl.appender.Screen = \
  Log::Log4perl::Appender::ScreenColoredLevels
log4perl.appender.Screen.layout = \
  Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = \
  [%d] %m %n
      );
        Log::Log4perl::init( \$log_conf );
        return Log::Log4perl->get_logger();
    }
);


1;
