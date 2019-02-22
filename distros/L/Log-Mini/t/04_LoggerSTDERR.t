use lib 'lib';
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Capture::Tiny qw(capture_stderr);
use Log::Mini::LoggerSTDERR;

subtest 'creates correct object' => sub {
    isa_ok(Log::Mini::LoggerSTDERR->new, 'Log::Mini::LoggerSTDERR');
};

subtest 'prints to stderr' => sub {
    my $log = _build_logger();

    for my $level (qw/error warn debug/) {
        my $stderr = capture_stderr {
            $log->$level('message');
        };

        ok $stderr;
    }
};

subtest 'prints to stderr with \n' => sub {
    my $log = _build_logger();

    for my $level (qw/error warn debug/) {
        my $stderr = capture_stderr {
            $log->$level('message');
        };

        like $stderr, qr/\n$/;
    }
};

sub _build_logger {
    my $logger = Log::Mini::LoggerSTDERR->new;
    $logger->set_level('debug');
    return $logger;
}

done_testing;