use lib 'lib';
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Capture::Tiny qw(capture_stdout);
use Log::Mini::Logger::STDOUT;


subtest 'creates correct object' => sub {
    isa_ok(Log::Mini::Logger::STDOUT->new, 'Log::Mini::Logger::STDOUT');
};

subtest 'prints to stderr' => sub {
    my $log = _build_logger();

    for my $level (qw/error warn debug/) {
        my $stderr = capture_stdout {
            $log->$level('message');
        };

        ok $stderr;
    }
};

subtest 'prints to stderr with \n' => sub {
    my $log = _build_logger();

    for my $level (qw/error warn debug/) {
        my $stderr = capture_stdout {
            $log->$level('message');
        };

        like $stderr, qr/\n$/;
    }
};

subtest 'prints sprintf formatted line' => sub {
    my $output = [];
    my $log = _build_logger(output => $output);

    for my $level (qw/error warn debug/) {
        my $stderr = capture_stdout {
            $log->$level('message %s', 'formatted');

        };
        like $stderr,
            qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d.\d{3} \[$level\] message formatted$/;
    }
};

sub _build_logger {
    my $logger = Log::Mini::Logger::STDOUT->new;
    $logger->set_level('debug');
    return $logger;
}

done_testing;