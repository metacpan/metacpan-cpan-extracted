use strict;
use warnings;
use Test::More 0.98;
use Test::Fatal;
use Test::Mock::Guard;
use Capture::Tiny qw/capture/;

use Linux::GetPidstat::Collector;

my %opt = (
    interval => 1,
    count    => 60,
);

is exception {
    my $instance = Linux::GetPidstat::Collector->new(%opt);
}, undef, "create ok";

my $guard = Test::Mock::Guard->new(
    'Linux::GetPidstat::Collector' => {
        _command_get_pidstat => sub {
            my ($pid) = shift;
            return "cat t/assets/source/metric_$pid.txt";
        },
    },
);

my $instance = Linux::GetPidstat::Collector->new(%opt);

{
    my $ret = $instance->get_pidstats_results([
        { program_name => 'backup_mysql' , pids => ['14423'] },
        { program_name => 'summarize_log', pids => ['14530'] },
    ]);
    is_deeply $ret, {
        'backup_mysql' => {
            'cpu' => '21.2',
            'cswch_per_sec' => '19.87',
            'disk_read_per_sec' => '0',
            'disk_write_per_sec' => '0',
            'memory_percent' => '34.64',
            'memory_rss' => '10881534000',
            'nvcswch_per_sec' => '30.44',
            'stk_ref' => '25500',
            'stk_size' => '128500'
        },
        'summarize_log' => {
            'cpu' => '21.2',
            'cswch_per_sec' => '19.87',
            'disk_read_per_sec' => '0',
            'disk_write_per_sec' => '0',
            'memory_percent' => '34.64',
            'memory_rss' => '10881534000',
            'nvcswch_per_sec' => '30.44',
            'stk_ref' => '25500',
            'stk_size' => '128500'
        }
    } or diag explain $ret;
}

{
    my $ret = $instance->get_pidstats_results([
        { program_name => 'backup_mysql' , pids => ['14423'] },
        { program_name => 'summarize_log', pids => ['14530','14533','14534'] },
    ]);
    is_deeply $ret, {
        'backup_mysql' => {
            'cpu' => '21.2',
            'cswch_per_sec' => '19.87',
            'disk_read_per_sec' => '0',
            'disk_write_per_sec' => '0',
            'memory_percent' => '34.64',
            'memory_rss' => '10881534000',
            'nvcswch_per_sec' => '30.44',
            'stk_ref' => '25500',
            'stk_size' => '128500'
        },
        'summarize_log' => {
            'cpu' => '63.6',
            'cswch_per_sec' => '59.61',
            'disk_read_per_sec' => '0',
            'disk_write_per_sec' => '0',
            'memory_percent' => '103.92',
            'memory_rss' => '32644602000',
            'nvcswch_per_sec' => '91.32',
            'stk_ref' => '76500',
            'stk_size' => '385500'
        }
    } or diag explain $ret;
}

local $ENV{GETPIDSTAT_DEBUG} = 1;

{
    my $guard_local = Test::Mock::Guard->new(
        'Linux::GetPidstat::Collector' => {
            _command_get_pidstat => sub {
                return "cat t/assets/not_found_source/metric.txt";
            },
        },
    );
    my ($stdout, $stderr, $ret) = capture {
        $instance->get_pidstats_results([
            { program_name => 'backup_mysql' , pids => ['14423'] },
            { program_name => 'summarize_log', pids => ['14530','14533','14534'] },
        ]);
    };
    ok !%$ret or diag explain $ret;

    my @stderr_lines = split /\n/, $stderr;
    my ($failed_collect, $failed_get, $failed_command);
    for (@stderr_lines) {
        $failed_collect++
            if /Failed to collect metrics/;
        $failed_get++
            if /Failed getting pidstat:/;
        $failed_command++
            if /Failed a command: cat t\/assets\/not_found_source\/metric.txt/;
    }
    is $failed_collect, 2 or diag $stderr;
    is $failed_get    , 2 or diag $stderr;
    is $failed_command, 2 or diag $stderr;
    is scalar @stderr_lines, 6 or diag $stderr;
}

{
    my $guard_local = Test::Mock::Guard->new(
        'Linux::GetPidstat::Collector' => {
            _command_get_pidstat => sub {
                return "cat t/assets/source/invalid_metric.txt";
            },
        },
    );
    my ($stdout, $stderr, $ret) = capture {
        $instance->get_pidstats_results([
            { program_name => 'backup_mysql' , pids => ['14423'] },
            { program_name => 'summarize_log', pids => ['14530','14533','14534'] },
        ]);
    };
    ok !%$ret or diag explain $ret;

    my @stderr_lines = split /\n/, $stderr;
    my ($failed_collect, $failed_get, $failed_command, $empty_metric);
    for (@stderr_lines) {
        $failed_collect++
            if /Failed to collect metrics/;
        $failed_get++
            if /Failed getting pidstat:/;
        $failed_command++
            if /Failed a command: cat t\/assets\/not_found_source\/metric.txt/;
        $empty_metric++
            if /Empty metric: name=/;
    }
    is $failed_collect, 2 or diag $stderr;
    is $failed_get    , 2 or diag $stderr;
    ok !$failed_command or diag $stderr;
    is $empty_metric  , 2 or diag $stderr;
    is scalar @stderr_lines, 6 or diag $stderr;
}

done_testing;
