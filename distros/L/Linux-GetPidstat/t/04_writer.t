use strict;
use warnings;
use Test::More 0.98;
use Test::Fatal;
use Test::Mock::Guard;
use Capture::Tiny qw/capture/;
use Time::Piece;
use Path::Tiny;
use Data::Section::Simple qw/get_data_section/;

use POSIX qw/tzset/;
$ENV{TZ} = 'Asia/Tokyo';
tzset;

use Linux::GetPidstat::Writer;

my $t = localtime 1465484400;
my $tempfile = Path::Tiny->tempfile;
my %opt = (
    res_file => $tempfile,
    now      => $t,
    dry_run  => '0',
);

is exception {
    my $instance = Linux::GetPidstat::Writer->new(%opt);
}, undef, "create ok";

my @mkr_buffer;
my $guard = Test::Mock::Guard->new(
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

my $output_file  = get_data_section('output.file');
my @output_file_lines = split '\n', $output_file;

subtest 'output to a file' => sub {
    my $instance = Linux::GetPidstat::Writer->new(%opt);
    $instance->output({
        'backup_mysql' => {
            'cpu'                => '21.20',
            'cswch_per_sec'      => '19.87',
            'disk_read_per_sec'  => '0.00',
            'disk_write_per_sec' => '0.00',
            'memory_percent'     => '34.63',
            'memory_rss'         => '10881534000.00',
            'nvcswch_per_sec'    => '30.45',
            'stk_ref'            => '25500.00',
            'stk_size'           => '128500.00'
        },
        'summarize_log' => {
            'cpu'                => '21.20',
            'cswch_per_sec'      => '19.87',
            'disk_read_per_sec'  => '0.00',
            'disk_write_per_sec' => '0.00',
            'memory_percent'     => '34.63',
            'memory_rss'         => '10881534000.00',
            'nvcswch_per_sec'    => '30.45',
            'stk_ref'            => '25500.00',
            'stk_size'           => '128500.00'
        },
    });

    my $got = $tempfile->slurp;
    my @lines = split /\n/, $got;
    is_deeply [sort @lines], [sort @output_file_lines] or diag $got;

    # did not post to mackerel
    ok !@mkr_buffer or diag @mkr_buffer;

    # cleanup
    $tempfile->spew('');
};

subtest 'output to a file (dry_run=1)' => sub {
    $opt{dry_run} = 1;

    my $instance = Linux::GetPidstat::Writer->new(%opt);
    my ($stdout, $stderr) = capture {
        $instance->output({
            'backup_mysql' => {
                'cpu'                => '21.20',
                'cswch_per_sec'      => '19.87',
                'disk_read_per_sec'  => '0.00',
                'disk_write_per_sec' => '0.00',
                'memory_percent'     => '34.63',
                'memory_rss'         => '10881534000.00',
                'nvcswch_per_sec'    => '30.45',
                'stk_ref'            => '25500.00',
                'stk_size'           => '128500.00'
            },
            'summarize_log' => {
                'cpu'                => '21.20',
                'cswch_per_sec'      => '19.87',
                'disk_read_per_sec'  => '0.00',
                'disk_write_per_sec' => '0.00',
                'memory_percent'     => '34.63',
                'memory_rss'         => '10881534000.00',
                'nvcswch_per_sec'    => '30.45',
                'stk_ref'            => '25500.00',
                'stk_size'           => '128500.00'
            },
        });
    };
    my @stdout_lines = split /\n/, $stdout;
    is scalar @stdout_lines, 18 or diag $stdout;
    is $stderr, '';

    # did not write to a file
    ok -z $tempfile or diag $tempfile->slurp;

    # did not post to mackerel
    ok !@mkr_buffer or diag @mkr_buffer;

    # cleanup
    $opt{dry_run} = 0;
};

$opt{mackerel_metric_type}       = 'service';
$opt{mackerel_api_key}           = 'dummy_key';
$opt{mackerel_service_name}      = 'dummy_name';
$opt{mackerel_metric_key_prefix} = 'batch_';

my $output_mkr  = get_data_section('output.mkr');
my @output_mkr_lines = split '\n', $output_mkr;

subtest 'output to a file and mackerel' => sub {
    my $instance = Linux::GetPidstat::Writer->new(%opt);
    $instance->output({
        'backup_mysql' => {
            'cpu'                => '21.20',
            'cswch_per_sec'      => '19.87',
            'disk_read_per_sec'  => '0.00',
            'disk_write_per_sec' => '0.00',
            'memory_percent'     => '34.63',
            'memory_rss'         => '10881534000.00',
            'nvcswch_per_sec'    => '30.45',
            'stk_ref'            => '25500.00',
            'stk_size'           => '128500.00'
        },
        'summarize_log' => {
            'cpu'                => '21.20',
            'cswch_per_sec'      => '19.87',
            'disk_read_per_sec'  => '0.00',
            'disk_write_per_sec' => '0.00',
            'memory_percent'     => '34.63',
            'memory_rss'         => '10881534000.00',
            'nvcswch_per_sec'    => '30.45',
            'stk_ref'            => '25500.00',
            'stk_size'           => '128500.00'
        },
    });

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
    $opt{dry_run} = 1;

    my $instance = Linux::GetPidstat::Writer->new(%opt);
    my ($stdout, $stderr) = capture {
        $instance->output({
            'backup_mysql' => {
                'cpu'                => '21.20',
                'cswch_per_sec'      => '19.87',
                'disk_read_per_sec'  => '0.00',
                'disk_write_per_sec' => '0.00',
                'memory_percent'     => '34.63',
                'memory_rss'         => '10881534000.00',
                'nvcswch_per_sec'    => '30.45',
                'stk_ref'            => '25500.00',
                'stk_size'           => '128500.00'
            },
            'summarize_log' => {
                'cpu'                => '21.20',
                'cswch_per_sec'      => '19.87',
                'disk_read_per_sec'  => '0.00',
                'disk_write_per_sec' => '0.00',
                'memory_percent'     => '34.63',
                'memory_rss'         => '10881534000.00',
                'nvcswch_per_sec'    => '30.45',
                'stk_ref'            => '25500.00',
                'stk_size'           => '128500.00'
            },
        });
    };
    my @stdout_lines = split /\n/, $stdout;
    # 18(file) + 1(mackerel)
    is scalar @stdout_lines, 19 or diag $stdout;
    is $stderr, '';

    # did not write to a file
    ok -z $tempfile or diag $tempfile->slurp;

    # did not post to mackerel
    ok !@mkr_buffer or diag @mkr_buffer;

    # cleanup
    $opt{dry_run} = 0;
};

done_testing;

__DATA__
@@ output.file
2016-06-10T00:00:00,1465484400,summarize_log,memory_percent,34.63
2016-06-10T00:00:00,1465484400,summarize_log,stk_size,128500.00
2016-06-10T00:00:00,1465484400,summarize_log,stk_ref,25500.00
2016-06-10T00:00:00,1465484400,summarize_log,memory_rss,10881534000.00
2016-06-10T00:00:00,1465484400,summarize_log,disk_write_per_sec,0.00
2016-06-10T00:00:00,1465484400,summarize_log,cpu,21.20
2016-06-10T00:00:00,1465484400,summarize_log,nvcswch_per_sec,30.45
2016-06-10T00:00:00,1465484400,summarize_log,cswch_per_sec,19.87
2016-06-10T00:00:00,1465484400,summarize_log,disk_read_per_sec,0.00
2016-06-10T00:00:00,1465484400,backup_mysql,memory_percent,34.63
2016-06-10T00:00:00,1465484400,backup_mysql,stk_ref,25500.00
2016-06-10T00:00:00,1465484400,backup_mysql,stk_size,128500.00
2016-06-10T00:00:00,1465484400,backup_mysql,disk_write_per_sec,0.00
2016-06-10T00:00:00,1465484400,backup_mysql,memory_rss,10881534000.00
2016-06-10T00:00:00,1465484400,backup_mysql,nvcswch_per_sec,30.45
2016-06-10T00:00:00,1465484400,backup_mysql,cswch_per_sec,19.87
2016-06-10T00:00:00,1465484400,backup_mysql,cpu,21.20
2016-06-10T00:00:00,1465484400,backup_mysql,disk_read_per_sec,0.00
@@ output.mkr
mackerel post: name=custom.batch_memory_rss.backup_mysql, time=1465484400, metric=10881534000.00
mackerel post: name=custom.batch_disk_write_per_sec.backup_mysql, time=1465484400, metric=0.00
mackerel post: name=custom.batch_disk_read_per_sec.backup_mysql, time=1465484400, metric=0.00
mackerel post: name=custom.batch_cpu.backup_mysql, time=1465484400, metric=21.20
mackerel post: name=custom.batch_nvcswch_per_sec.backup_mysql, time=1465484400, metric=30.45
mackerel post: name=custom.batch_cswch_per_sec.backup_mysql, time=1465484400, metric=19.87
mackerel post: name=custom.batch_stk_size.backup_mysql, time=1465484400, metric=128500.00
mackerel post: name=custom.batch_stk_ref.backup_mysql, time=1465484400, metric=25500.00
mackerel post: name=custom.batch_memory_percent.backup_mysql, time=1465484400, metric=34.63
mackerel post: name=custom.batch_cpu.summarize_log, time=1465484400, metric=21.20
mackerel post: name=custom.batch_nvcswch_per_sec.summarize_log, time=1465484400, metric=30.45
mackerel post: name=custom.batch_cswch_per_sec.summarize_log, time=1465484400, metric=19.87
mackerel post: name=custom.batch_disk_read_per_sec.summarize_log, time=1465484400, metric=0.00
mackerel post: name=custom.batch_disk_write_per_sec.summarize_log, time=1465484400, metric=0.00
mackerel post: name=custom.batch_memory_rss.summarize_log, time=1465484400, metric=10881534000.00
mackerel post: name=custom.batch_memory_percent.summarize_log, time=1465484400, metric=34.63
mackerel post: name=custom.batch_stk_ref.summarize_log, time=1465484400, metric=25500.00
mackerel post: name=custom.batch_stk_size.summarize_log, time=1465484400, metric=128500.00
