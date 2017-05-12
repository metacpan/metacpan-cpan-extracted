package ETLp::Test::AppConfig;

use Test::More;
use Data::Dumper;
use Carp;
use ETLp;
use base (qw(ETLp::Test::Base));
use Try::Tiny;
use ETLp::Config;

sub test_config : Tests(7) {
    my $self       = shift;
    my $config_dir = $self->test_config_dir;

    my $etlp = ETLp->new(
        app_config_file  => 'file.conf.loc',
        env_config_file  => 'env_test.conf',
        config_directory => $self->test_config_dir,
        section          => 'prices',
        log_dir          => $self->log_dir,
        localize         => 1,
    );

    my $test_conf = {
        'type'   => 'iterative',
        'config' => {
            'filename_format' => '^(prices(\\d{14}).csv)(?:\\.gz(?:\\.pgp)?)?$',
            'posix_date_fomat' => '%Y%m%d%H%M%S',
            'incoming_dir'     => '/data/comit/incoming',
            'archive_dir'      => '/data/comit/archive',
            'fail_dir'         => '/data/comit/fail',
            'table_name'       => 'stg_prices',
            'controlfile_dir'  => '/data/load/conf/control',
            'controlfile'      => 'final_price.ctl',
            'on_error'         => 'die'
        },
        'pre_process' => {
            'item' => [
                {
                    'name'     => 'decrypt',
                    'type'     => 'perl',
                    'package'  => 'DW::Decrypt',
                    'method'   => 'decrypt',
                    'on_error' => 'next',
                    'params'   => {}
                },
                {
                    'name'     => 'decompress',
                    'type'     => 'gunzip',
                    'on_error' => 'die'
                },
                {
                    'name'      => 'validate_file',
                    'type'      => 'validate',
                    'file_type' => 'csv',
                    'on_error'  => 'ignore'
                }
            ],
        },
        'process' => {
            'item' => [
                {
                    'name' => 'load',
                    'type' => 'csv_loader'
                }
            ],
        },
        'post_process' => {
            'item' => [
                {
                    'name' => 'compress',
                    'type' => 'gzip'
                }
            ],
        }
    };

    is_deeply($etlp->config, $test_conf, 'Confguration parsed');

    try {
        $etlp = ETLp->new(
            app_config_file  => 'file.conf.loc',
            env_config_file  => 'env_test.conf',
            config_directory => $self->test_config_dir,
            section          => 'dummy',
            log_dir          => $self->log_dir,
            localize         => 1,
        );
    }
    catch {
        like($_, qr/No section dummy/, 'Section not defined');
    };

    try {
        $etlp = ETLp->new(
            app_config_file  => 'file2.conf.loc',
            env_config_file  => 'env_test.conf',
            config_directory => $self->test_config_dir,
            section          => 'dummy',
            log_dir          => $self->log_dir,
            localize         => 1,
        );
    }
    catch {
        like(
            $_,
            qr/No such application configuration file/,
            'No such configfuration file'
        );
    };

    try {
        $etlp = ETLp->new(
            app_config_file  => 'file_bad.conf.loc',
            env_config_file  => 'env_test.conf',
            config_directory => $self->test_config_dir,
            section          => 'dummy',
            log_dir          => $self->log_dir,
            localize         => 1,
        );
    }
    catch {
        like($_, qr/Config::General: Block "<test>" has no EndBlock statement/,
            'Syntax error');
    };

    try {
        $etlp = ETLp->new(
            app_config_file  => 'file.conf.loc',
            env_config_file  => 'env_test.conf',
            config_directory => $self->test_config_dir,
            section          => 'no_type',
            log_dir          => $self->log_dir,
            localize         => 1,
        );
    }
    catch {
        like($_, qr/no_type/, 'No type defined');
    };

    try {
        $etlp = ETLp->new(
            app_config_file  => 'file.conf.loc',
            env_config_file  => 'env_test.conf',
            config_directory => $self->test_config_dir,
            section          => 'no_item_name',
            log_dir          => $self->log_dir,
            localize         => 1,
        );
    }
    catch {
        like($_, qr/Item has no name/, 'No name defined');
    };

    my $relative_test_conf = {
        'type'   => 'iterative',
        'config' => {
            'filename_format' => '^(prices(\\d{14}).csv)(?:\\.gz(?:\\.pgp)?)?$',
            'posix_date_fomat' => '%Y%m%d%H%M%S',
            'table_name'       => 'stg_prices',
            'controlfile'      => 'final_price.ctl',
            'on_error'         => 'die',
            'incoming_dir'     => '/tmp/data/comit/incoming',
            'archive_dir'      => '/tmp/data/comit/archive',
            'fail_dir'         => '/tmp/data/comit/fail',
            'controlfile_dir'  => '/tmp/data/load/conf/control'
        },
        'pre_process' => {
            'item' => [
                {
                    'name'     => 'decrypt',
                    'type'     => 'perl',
                    'package'  => 'DW::Decrypt',
                    'method'   => 'decrypt',
                    'on_error' => 'next',
                    'params'   => {}
                },
                {
                    'name'     => 'decompress',
                    'type'     => 'gunzip',
                    'on_error' => 'die'
                },
                {
                    'name'      => 'validate_file',
                    'type'      => 'validate',
                    'file_type' => 'csv',
                    'on_error'  => 'ignore'
                }
            ],
        },
        'process' => {
            'item' => [
                {
                    'name' => 'load',
                    'type' => 'csv_loader'
                }
            ],
        },
        'post_process' => {
            'item' => [
                {
                    'name' => 'compress',
                    'type' => 'gzip'
                }
            ],
        }
    };

    $etlp = ETLp->new(
        app_config_file  => 'file.conf.loc',
        env_config_file  => 'env_test.conf',
        config_directory => $self->test_config_dir,
        section          => 'prices_relative',
        log_dir          => $self->log_dir,
        app_root         => '/tmp',
        localize         => 1,
    );

    is_deeply($etlp->config, $relative_test_conf,
        'Relative configuration parsed');

}

1;
