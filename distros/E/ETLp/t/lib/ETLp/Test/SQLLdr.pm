package ETLp::Test::SQLLdr;

use strict;
use Test::More;
use Data::Dumper;
use base (qw(ETLp::Test::PluginBase));
use Try::Tiny;
use ETLp;
use FindBin qw($Bin);
use File::Copy;
use File::Basename;

sub ldr_error : Tests(9) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "sqlldr",
        env_config_file  => "env",
        section          => "ldr_error",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    try {
        $etlp->run;
    }
    catch {
        like($_, qr/SQL\*Loader returned a warning/, 'is_warning_error');
    };

    ok(-f $app_root . "/log/scores.csv.ctl",   "Control file exists");
    ok(-f $app_root . "/log/scores.csv.bad",   "Bad file exists");
    ok(-f $app_root . "/log/scores.csv.log",   "Log file exists");
    ok(-f $app_root . '/data/fail/scores.csv', "File moved to fail dir");

    my $row_count =
      $self->dbh->selectcol_arrayref('select count(*) from scores')->[0];
    is($row_count, 1, 'Only one row loaded');

    my $job_rec       = $self->get_job_rec(1);
    my $item_rec      = $self->get_item_rec(1);
    my $file_proc_rec = $self->get_file_proc_rec(1);
    is($file_proc_rec->{status_id}, 2, 'File process failure - record failure');
    is($job_rec->{status_id}, 2, 'File warning generated load process failure');
    is($item_rec->{status_id}, 2,
        'File warning generated load process failure');
}

sub ldr_warn : Tests(5) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "sqlldr",
        env_config_file  => "env",
        section          => "ldr_warn",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    $etlp->run;

    ok(!-f $app_root . "/log/scores.csv.bad", "Bad file removed");
    ok(!-f $app_root . "/log/scores.csv.log", "Log file removed");
    my $job_rec       = $self->get_job_rec(1);
    my $item_rec      = $self->get_item_rec(1);
    my $file_proc_rec = $self->get_file_proc_rec(1);
    is($file_proc_rec->{status_id}, 4, 'File process failure - record warning');
    is($job_rec->{status_id}, 3, 'File warning generated load process warning');
    is($item_rec->{status_id}, 3, 'File warning generated item warning');
}

sub ldr_ok : Tests(4) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "sqlldr",
        env_config_file  => "env",
        section          => "ldr_ok",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    $etlp->run;

    ok(!-f $app_root . "/log/scores.csv.bad", "Bad file removed");
    ok(!-f $app_root . "/log/scores.csv.log", "Log file removed");
    my $file_proc_rec = $self->get_file_proc_rec(1);
    is($file_proc_rec->{status_id}, 3, 'File process success status');

    my $row_count =
      $self->dbh->selectcol_arrayref('select count(*) from scores')->[0];
    is($row_count, 4, 'All rows loaded');
}

sub ldr_params : Tests(2) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "sqlldr",
        env_config_file  => "env",
        section          => "ldr_params",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    $etlp->run;

    my $logfile = $app_root . '/log/scores_header.csv.log';
    my $logcontent;

    open(my $fh, '<', $logfile);
    {
        local $/;
        $logcontent = <$fh>;
    }

    close $fh;

    like($logcontent, qr/Path used:\s+Direct/m, 'Parameter: Direct Path');
    like(
        $logcontent,
        qr/Total logical records skipped:\s+1\b/m,
        'Parameter: Skipped 1 row'
    );
}

sub ldr_invalid_params  : Tests(1) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "sqlldr",
        env_config_file  => "env",
        section          => "ldr_invalid_param",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    try {
        $etlp->run;
    }
    catch {
        like($_, qr/Invalid keyword: this_is_an_invalid_param/s,
            'Invalid Parameter');
    };
}

sub _oracle_ddl {
    my $self = shift;
    return (
        q{
            create table scores (
                id       integer,
                name     varchar2(20),
                score    number,
                file_id  integer
            )
        },
    );
}

sub _drop_oracle_ddl {
    my $self = shift;
    return (
        q{
            drop table scores
        },
    );
}

sub z_prep_files : Test(setup) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;
    my $data_dir = "$Bin/tests/csv";
    my $dest_dir = "$app_root/data/incoming";

    foreach my $file (glob("$data_dir/*.csv")) {
        copy $file, $dest_dir || die "Cannot copy $file to $data_dir: $!";
    }
}

sub get_job_rec {
    my $self    = shift;
    my $proc_id = shift;
    return $self->dbh->selectrow_hashref(
        'select * from etlp_job where job_id = ?',
        undef, $proc_id);
}

sub get_item_rec {
    my $self    = shift;
    my $item_id = shift;
    return $self->dbh->selectrow_hashref(
        'select * from etlp_item where item_id = ?',
        undef, $item_id);
}

sub get_file_proc_rec {
    my $self         = shift;
    my $file_proc_id = shift;
    return $self->dbh->selectrow_hashref(
        'select * from etlp_file_process where file_proc_id = ?',
        undef, $file_proc_id);
}
1;
