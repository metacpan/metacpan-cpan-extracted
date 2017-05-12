#!perl

use strict;
use warnings;
use Log::Minimal::Object;
use Capture::Tiny qw/capture_stderr/;
use Test::More;

subtest 'Methods of Log::Minimal should work well' => sub {
    my $logger = Log::Minimal::Object->new;
    eval {
        $logger->critf("foobar");
        $logger->warnf("foobar");
        $logger->infof("foobar");
        $logger->debugf("foobar");
        $logger->critff("foobar");
        $logger->warnff("foobar");
        $logger->infoff("foobar");
        $logger->debugff("foobar");
        $logger->ddf("foobar");
    };
    ok !$@;

    eval { $logger->croakf("foobar") };
    like $@, qr!\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} \[ERROR] foobar at t/01_basic\.t line \d+\n\Z!;

    eval { $logger->croakff("foobar") };
    like $@, qr!\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} \[ERROR] foobar at .+[ ,][ ,]t/01_basic\.t line \d+\n\Z!;
};

subtest 'Undefined method of Log::Minimal should die' => sub {
    my $logger = Log::Minimal::Object->new;
    eval { $logger->undefined_method };
    ok $@;
};

subtest 'Configurations should work right' => sub {
    subtest 'decorated logger' => sub {
        my $logger = Log::Minimal::Object->new(
            color             => 1,
            trace_level       => 3,
            escape_whitespace => 1,
            log_level         => 'WARN',
        );
        my $got = capture_stderr {
            $logger->infof("foo\tbar");
            $logger->warnf("foo\tbar");
        };
        like $got, qr!\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} \[WARN] \e\[43m\e\[30mfoo\\tbar\e\[0m\e\[0m at .+Tiny\.pm line \d+\n\Z!;
    };

    subtest 'specify warn message' => sub {
        my $logger = Log::Minimal::Object->new(
            print => sub { warn "buz\tqux" },
        );
        my $got = capture_stderr {
            $logger->infof("foo\tbar");
            $logger->warnf("foo\tbar");
        };
        like $got, qr!buz\tqux at t/01_basic\.t line \d+.\nbuz\tqux at t/01_basic\.t line \d+\.\n\Z!;
    };

    subtest 'specify dieing message' => sub {
        my $logger = Log::Minimal::Object->new(
            die => sub { die "buz\tqux" },
        );
        eval { $logger->croakf("foo\tbar") };
        like $@, qr!buz\tqux at t/01_basic\.t line \d+\.\Z!
    };

    subtest 'enable autodump' => sub {
        my $logger = Log::Minimal::Object->new(
            autodump => 1,
        );
        my $got = capture_stderr {
            $logger->infof("%s", {foo => 'bar'});
        };
        like $got, qr!\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} \[INFO] {'foo' => 'bar'} at t/01_basic\.t line \d+\n\Z!;
    };

    subtest 'back to plain' => sub {
        my $logger = Log::Minimal::Object->new;
        my $got = capture_stderr {
            $logger->infof("foo\tbar");
            $logger->warnf("%s", {foo => 'bar'});
        };
        like $got, qr!\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} \[INFO] foo\tbar at t/01_basic\.t line \d+\n\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} \[WARN] HASH\(0x[0-9a-f]+\) at t/01_basic\.t line \d+\n\Z!;
    };
};

done_testing;

