use strict;
use warnings;
use Test::More 0.88;
use File::Spec;
use POSIX 'strftime';
use Log::Handler;
use Log::Handler::Output::File::Stamper;

our $LOG = File::Spec->catfile('t', '.foo.log.'.strftime("%Y%m%d", localtime));
END { unlink($LOG); }

{
    my $stamp = Log::Handler::Output::File::Stamper->new(
        filename => [ 't', '.foo.log.%d{yyyyMMdd}' ],
    );

    is ref($stamp), 'Log::Handler::Output::File::Stamper', 'new';
}

{
    my $log = Log::Handler->new;
    $log->add(
        'Log::Handler::Output::File::Stamper' => +{
            filename => [ 't', '.foo.log.%d{yyyyMMdd}' ],
        }
    );
    is ref($log), 'Log::Handler', 'handler';
    is(
        ref($log->{outputs}[0]{output}),
        'Log::Handler::Output::File::Stamper',
        'added stamper'
    );

    {
        $log->fatal("hoge");
        open my $fh, '<', $LOG or die "could not open '$LOG': $!";
        my $log = <$fh>;
        close $fh;
        like $log, qr/\[FATAL\] hoge/, 'log content';
    }
}

done_testing;
