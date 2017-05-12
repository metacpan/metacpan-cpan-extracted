package HPC::Runner::Command::submit_jobs::Utils::Log;

use MooseX::App::Role;
with 'HPC::Runner::Command::Utils::Log';

has 'summary_log' => (
    is      => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $file_name = $self->logdir.'/summary.md';

        $self->_make_the_dirs($self->logdir);
        my $log_conf = q(
log4perl.category = DEBUG, FILELOG
log4perl.appender.FILELOG           = Log::Log4perl::Appender::File
log4perl.appender.FILELOG.mode      = append
log4perl.appender.FILELOG.layout    = Log::Log4perl::Layout::PatternLayout
log4perl.appender.FILELOG.layout.ConversionPattern = %d %p %m %n
        );
    $log_conf .= "log4perl.appender.FILELOG.filename  = $file_name";

        Log::Log4perl->init( \$log_conf);
        return get_logger();
      }
);

1;
