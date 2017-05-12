use strict;
use warnings;
use feature 'say';
use File::Temp qw(tempdir);
use Log::Log4perl;
use Time::Piece ();

my $tmp = tempdir(CLEANUP => 1);
my $conf = <<END;
log4perl.logger.hoge = INFO, CronologAppender

log4perl.appender.CronologAppender = Log::Dispatch::Pipe
log4perl.appender.CronologAppender.output_to    = cronolog ${tmp}/%Y-%m-%d/hoge.log
log4perl.appender.CronologAppender.binmode      = :utf8
log4perl.appender.CronologAppender.try_at_init  = 1
log4perl.appender.CronologAppender.layout       = Log::Log4perl::Layout::SimpleLayout
END

Log::Log4perl::init(\$conf);

say "Booting server [PID:$$] to log output to ${tmp}";

sub {
    my $env    = shift;
    my $time   = Time::Piece->localtime->strftime('%F %T');
    my $logger = Log::Log4perl::get_logger('hoge');

    $logger->info("[PID:$$] Got request at ${time}");

    [ 200, [ 'Content-Type' => 'text/plain' ], ['Hoge'], ];
};
