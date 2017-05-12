use strict;
use utf8;
use warnings;
use File::Temp qw(tempdir);
use Log::Log4perl;
use Test::More;
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

{
    Log::Log4perl::init(\$conf);
}

subtest 'Test Log::Log4perl::get_logger' => sub {
    my $logger = Log::Log4perl::get_logger('hoge');

    isa_ok $logger, 'Log::Log4perl::Logger';
};

subtest 'Test logging with logger' => sub {

    my $date = Time::Piece->localtime->strftime('%Y-%m-%d');

    subtest "Write log in ${tmp}" => sub {
        my $logger = Log::Log4perl::get_logger('hoge');

        ok $logger->info('あいうえお1');
        ok $logger->info('あいうえお2');
    };

    subtest "Check log in ${tmp}" => sub {

        Log::Log4perl::Logger::cleanup();

        my $file    = "${tmp}/${date}/hoge.log";
        my $content = do {
            open my $fh, '<', $file or die $!;
            local $/ = undef;
            binmode $fh, ':utf8';
            <$fh>;
        };

        is $content, <<END;
INFO - あいうえお1
INFO - あいうえお2
END
    };
};

done_testing;
