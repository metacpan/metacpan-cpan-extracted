use strict;
use warnings;
use Test::More 0.98;
use Test::Fatal;
use Test::Mock::Guard;
use Data::Section::Simple qw/get_data_section/;
use Path::Tiny;
use Capture::Tiny qw/capture/;

use POSIX qw/tzset/;
$ENV{TZ} = 'Asia/Tokyo';
tzset;

use Linux::GetPidstat;

my @mkr_buffer;
my $guard = Test::Mock::Guard->new(
    'Linux::GetPidstat::Reader' => {
        _command_search_child_pids => sub {
            my ($pid) = shift;
            return "cat t/assets/source/pstree_$pid.txt";
        },
    },
    'Linux::GetPidstat::Collector' => {
        _command_get_pidstat => sub {
            return "cat t/assets/source/metric.txt";
        },
    },
    'WebService::Mackerel' => {
        post_service_metrics => sub {
            my ($self, $args) = @_;
            for my $arg (@$args) {
                push @mkr_buffer, sprintf
                    "mackerel post: name=%s, time=%s, metric=%s",
                    $arg->{name}, $arg->{time}, $arg->{value};
            }
            return '{"success":true}';
        },
    },
);

my $instance = Linux::GetPidstat->new;

like exception {
    $instance->run;
}, qr/pid_dir required/, "no pid_dir is not allowed";

like exception {
    $instance->run(pid_dir => 'pid_dir');
}, qr/res_file or mackerel_\[api_key|service_name\] required/;

my $tempfile = Path::Tiny->tempfile;
my %cli_default_opt = (
    pid_dir       => 't/assets/invalid_pid',
    res_file      => $tempfile,
    include_child => 1,
    datetime      => '2016-06-10 00:00:00',
    interval      => 1,
    count         => 60,
    dry_run       => 0
);

like exception {
    $instance->run(%cli_default_opt);
}, qr/Not found pids in pid_dir:/;

$cli_default_opt{pid_dir} = 't/assets/pid';
{
    my $guard_local = Test::Mock::Guard->new(
        'Linux::GetPidstat::Reader' => {
            _command_search_child_pids => sub {
                my ($pid) = shift;
                return "cat t/assets/source/pstree_$pid.txt";
            },
        },
        'Linux::GetPidstat::Collector' => {
            _command_get_pidstat => sub {
                return "cat t/assets/source/invalid_metric.txt";
            },
        },
    );
    like exception {
        $instance->run(%cli_default_opt);
    }, qr/Failed to collect metrics/;
}

my $output_file  = get_data_section('output.file');
my @output_file_lines = split '\n', $output_file;

subtest 'output to a file' => sub {
    $instance->run(%cli_default_opt);

    my $got = $tempfile->slurp;
    my @lines = split /\n/, $got;
    is_deeply [sort @lines], [sort @output_file_lines] or diag $got;

    # did not post to mackerel
    ok !@mkr_buffer or diag @mkr_buffer;

    # cleanup
    $tempfile->spew('');
};

subtest 'output to a file (dry_run=1)' => sub {
    $cli_default_opt{dry_run} = 1;

    my ($stdout, $stderr) = capture {
        $instance->run(%cli_default_opt);
    };

    my @lines = split /\n/, $stdout;
    is scalar @lines, 18 or diag $stdout;
    is $stderr, '' or diag $stderr;

    # did not write to a file
    ok -z $tempfile or diag $tempfile->slurp;

    # did not post to mackerel
    ok !@mkr_buffer or diag @mkr_buffer;

    # cleanup
    $cli_default_opt{dry_run} = 0;
};

my $output_mkr  = get_data_section('output.mkr');
my @output_mkr_lines = split '\n', $output_mkr;

$cli_default_opt{mackerel_api_key}      = 'dummy_key';
$cli_default_opt{mackerel_service_name} = 'dummy_name';
subtest 'output to a file and mackerel' => sub {
    $instance->run(%cli_default_opt);

    # file
    my $got = $tempfile->slurp;
    my @lines = split /\n/, $got;
    is_deeply [sort @lines], [sort @output_file_lines] or diag $got;

    # mackerel
    is_deeply [sort @mkr_buffer], [sort @output_mkr_lines]
        or sub { diag $_ for @mkr_buffer }->();

    # cleanup
    $tempfile->spew('');
    @mkr_buffer = ();
};

subtest 'output to a file and mackerel (dry_run=1)' => sub {
    $cli_default_opt{dry_run} = 1;

    my ($stdout, $stderr) = capture {
        $instance->run(%cli_default_opt);
    };

    my @lines = split /\n/, $stdout;
    is scalar @lines, 36 or diag $stdout;
    is $stderr, '' or diag $stderr;

    # did not write to a file
    ok -z $tempfile or diag $tempfile->slurp;

    # did not post to mackerel
    ok !@mkr_buffer or diag @mkr_buffer;

    # cleanup
    $cli_default_opt{dry_run} = 0;
};

done_testing;

__DATA__
@@ output.file
2016-06-10T00:00:00,1465484400,target_script2,cpu,127.2
2016-06-10T00:00:00,1465484400,target_script2,stk_ref,153000
2016-06-10T00:00:00,1465484400,target_script2,disk_read_per_sec,0
2016-06-10T00:00:00,1465484400,target_script2,cswch_per_sec,119.22
2016-06-10T00:00:00,1465484400,target_script2,nvcswch_per_sec,182.7
2016-06-10T00:00:00,1465484400,target_script2,memory_percent,207.78
2016-06-10T00:00:00,1465484400,target_script2,disk_write_per_sec,0
2016-06-10T00:00:00,1465484400,target_script2,memory_rss,65289204000
2016-06-10T00:00:00,1465484400,target_script2,stk_size,771000
2016-06-10T00:00:00,1465484400,target_script,cswch_per_sec,19.87
2016-06-10T00:00:00,1465484400,target_script,nvcswch_per_sec,30.45
2016-06-10T00:00:00,1465484400,target_script,cpu,21.2
2016-06-10T00:00:00,1465484400,target_script,stk_ref,25500
2016-06-10T00:00:00,1465484400,target_script,disk_read_per_sec,0
2016-06-10T00:00:00,1465484400,target_script,disk_write_per_sec,0
2016-06-10T00:00:00,1465484400,target_script,memory_rss,10881534000
2016-06-10T00:00:00,1465484400,target_script,stk_size,128500
2016-06-10T00:00:00,1465484400,target_script,memory_percent,34.63
@@ output.mkr
mackerel post: name=custom.batch_nvcswch_per_sec.target_script, time=1465484400, metric=30.45
mackerel post: name=custom.batch_stk_size.target_script, time=1465484400, metric=128500
mackerel post: name=custom.batch_memory_rss.target_script, time=1465484400, metric=10881534000
mackerel post: name=custom.batch_disk_write_per_sec.target_script, time=1465484400, metric=0
mackerel post: name=custom.batch_cswch_per_sec.target_script, time=1465484400, metric=19.87
mackerel post: name=custom.batch_stk_ref.target_script, time=1465484400, metric=25500
mackerel post: name=custom.batch_cpu.target_script, time=1465484400, metric=21.2
mackerel post: name=custom.batch_memory_percent.target_script, time=1465484400, metric=34.63
mackerel post: name=custom.batch_disk_read_per_sec.target_script, time=1465484400, metric=0
mackerel post: name=custom.batch_disk_write_per_sec.target_script2, time=1465484400, metric=0
mackerel post: name=custom.batch_cswch_per_sec.target_script2, time=1465484400, metric=119.22
mackerel post: name=custom.batch_cpu.target_script2, time=1465484400, metric=127.2
mackerel post: name=custom.batch_memory_percent.target_script2, time=1465484400, metric=207.78
mackerel post: name=custom.batch_disk_read_per_sec.target_script2, time=1465484400, metric=0
mackerel post: name=custom.batch_stk_ref.target_script2, time=1465484400, metric=153000
mackerel post: name=custom.batch_memory_rss.target_script2, time=1465484400, metric=65289204000
mackerel post: name=custom.batch_stk_size.target_script2, time=1465484400, metric=771000
mackerel post: name=custom.batch_nvcswch_per_sec.target_script2, time=1465484400, metric=182.7
