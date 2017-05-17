use strict;
use warnings;
use Test::More 0.98;
use Test::Fatal;
use Test::Mock::Guard;
use Capture::Tiny qw/capture/;

use Time::Piece;
use WebService::Mackerel;
use Linux::GetPidstat::Writer::Mackerel;

my $t = localtime 12345;
my %opt = (
    mackerel_metric_type       => 'service',
    mackerel_api_key           => 'dummy_key',
    mackerel_service_name      => 'dummy_name',
    mackerel_metric_key_prefix => 'batch_',
    now                        => $t,
    dry_run                    => '1',
);

subtest 'new' => sub {
    is exception {
        my $instance = Linux::GetPidstat::Writer::Mackerel->new(%opt);
    }, undef, "create ok";
};

subtest 'dry_run' => sub {
    my $guard = Test::Mock::Guard->new(
        'WebService::Mackerel' => {
            new => sub {
                my ($self, %args) = @_;
                is $args{api_key}     , 'dummy_key';
                is $args{service_name}, 'dummy_name';
            },
        },
    );

    my $instance = Linux::GetPidstat::Writer::Mackerel->new(%opt);
    my ($stdout, $stderr) = capture {
        $instance->output('backup_mysql', 'cpu', '21.20');
    };

    my @stdout_lines = split /\n/, $stdout;
    is scalar @stdout_lines, 1 or diag $stdout;
    is $stdout_lines[0],
        '(dry_run) mackerel post: type=service, name=custom.batch_cpu.backup_mysql, time=12345, metric=21.20';
    is $stderr, '';

    is $guard->call_count('WebService::Mackerel', 'new'), 1;
};

$opt{dry_run} = 0;

subtest 'post_service_metrics' => sub {
    my $guard = Test::Mock::Guard->new(
        'WebService::Mackerel' => {
            post_service_metrics => sub {
                my ($self, $args) = @_;
                is $args->[0]->{name} , 'custom.batch_cpu.backup_mysql';
                is $args->[0]->{time} , '12345';
                is $args->[0]->{value}, '21.20';
                return '{"success":true}';
            },
        },
    );

    my $instance = Linux::GetPidstat::Writer::Mackerel->new(%opt);
    $instance->output('backup_mysql', 'cpu', '21.20');
    is $guard->call_count('WebService::Mackerel', 'post_service_metrics'), 1;
};

subtest 'post_host_metrics' => sub {
    my $guard = Test::Mock::Guard->new(
        'WebService::Mackerel' => {
            post_host_metrics => sub {
                my ($self, $args) = @_;
                is $args->[0]->{hostId}, 'test';
                is $args->[0]->{name}  , 'custom.batch_cpu.backup_mysql';
                is $args->[0]->{time}  , '12345';
                is $args->[0]->{value} , '21.20';
                return '{"success":true}';
            },
        },
    );

    my $instance = Linux::GetPidstat::Writer::Mackerel->new(%opt, mackerel_metric_type => 'host', mackerel_host_id => 'test');
    $instance->output('backup_mysql', 'cpu', '21.20');
    is $guard->call_count('WebService::Mackerel', 'post_host_metrics'), 1;
};

subtest 'mackerel_metric_key_prefix' => sub {
    my $guard = Test::Mock::Guard->new(
        'WebService::Mackerel' => {
            post_service_metrics => sub {
                my ($self, $args) = @_;
                is $args->[0]->{name} , 'custom.prefix_cpu.backup_mysql';
                is $args->[0]->{time} , '12345';
                is $args->[0]->{value}, '21.20';
                return '{"success":true}';
            },
        },
    );

    my $instance = Linux::GetPidstat::Writer::Mackerel->new(%opt, mackerel_metric_key_prefix => "prefix_");
    $instance->output('backup_mysql', 'cpu', '21.20');
    is $guard->call_count('WebService::Mackerel', 'post_service_metrics'), 1;
};

subtest 'error handling' => sub {
    subtest 'invalid metric type of mackerel' => sub {
        my $instance = Linux::GetPidstat::Writer::Mackerel->new(%opt, mackerel_metric_type => 'dummy');
        like exception {
            $instance->output('backup_mysql', 'cpu', '21.20')
        }, qr/Invalid metric type of mackerel: type=dummy/;
    };
    subtest 'authentication failed' => sub {
        my $guard = Test::Mock::Guard->new(
            'WebService::Mackerel' => {
                post_service_metrics => sub {
                    my ($self, $args) = @_;
                    return '{"error":"Authentication failed. Please try with valid Api Key."}';
                },
            },
        );

        my $instance = Linux::GetPidstat::Writer::Mackerel->new(%opt);
        my ($stdout, $stderr) = capture {
            $instance->output('backup_mysql', 'cpu', '21.20');
        };

        my @stderr_lines = split /\n/, $stderr;
        is scalar @stderr_lines, 1 or diag $stderr;
        like $stderr_lines[0],
            qr/Failed mackerel post service metrics: res=\{'error' => 'Authentication failed\. Please try with valid Api Key\.'}/
            or diag $stderr;
        is $guard->call_count('WebService::Mackerel', 'post_service_metrics'), 1;
    };

    subtest 'not json' => sub {
        my $guard = Test::Mock::Guard->new(
            'WebService::Mackerel' => {
                post_service_metrics => sub {
                    my ($self, $args) = @_;
                    return 'not json';
                },
            },
        );

        my $instance = Linux::GetPidstat::Writer::Mackerel->new(%opt);
        my ($stdout, $stderr) = capture {
            $instance->output('backup_mysql', 'cpu', '21.20');
        };

        my @stderr_lines = split /\n/, $stderr;
        is scalar @stderr_lines, 1 or diag $stderr;
        like $stderr_lines[0],
            qr/Failed mackerel post service metrics: err='null' expected, at character offset 0 \(before "not json"\)/
            or diag $stderr;
        is $guard->call_count('WebService::Mackerel', 'post_service_metrics'), 1;
    };
};

done_testing;
