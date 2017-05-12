package ETLp::Test::IterativePlugin;

use strict;
use Test::More;
use Data::Dumper;
use base (qw(ETLp::Test::PluginBase));
use Try::Tiny;
use ETLp;

sub basic_tests : Tests(6) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "customer",
        env_config_file  => "env.conf",
        section          => "customer_good",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    $etlp->run;

    my $archive_dir = $etlp->config->{config}->{archive_dir};

    is(
        -f $archive_dir . '/customer1.csv.gz'
          && -f $archive_dir . '/customer2.csv.gz'
          && -f $archive_dir . '/customer3.csv.gz',
        1,
        'Files archived'
    );

    my $record_count = @{
        $self->dbh->selectrow_arrayref(
            'select sum(record_count) from etlp_file_process')
      }[0];

    is($record_count, 300, 'Audit Total');

    $record_count = @{
        $self->dbh->selectrow_arrayref(
            'select count(
        *) from stg_customer'
        )
      }[0];

    is($record_count, 300, 'Staging table total');

    my $audit_sql = q{
        select c.config_name,
               s.section_name,
               st.status_name
        from   etlp_job           j,
               etlp_configuration c,
               etlp_section       s,
               etlp_status        st
        where  j.section_id = s.section_id
        and    s.config_id  = c.config_id
        and    j.status_id  = st.status_id
    };

    my $audit_result =
      $self->dbh->selectall_arrayref($audit_sql, {Slice => {}});

    my $audit_record = [
        {
            'status_name'  => 'succeeded',
            'section_name' => 'customer_good',
            'config_name'  => 'customer'
        }
    ];

    is_deeply($audit_result, $audit_record, 'Good run audit records');

    my $item_sql = q{
        select i.job_id,
               i.item_id,
               i.item_type,
               i.item_name,
               i.message,
               st.status_name,
               p.phase_name
        from   etlp_item   i,
               etlp_status st,
               etlp_phase  p
        where  i.status_id = st.status_id
        and    i.phase_id  = p.phase_id
        order  by i.item_id
    };

    my $item_record = [
        {
            'item_type'   => 'gunzip',
            'status_name' => 'succeeded',
            'job_id'      => 1,
            'item_name'   => 'decompress',
            'phase_name'  => 'pre_process',
            'message'     => undef,
            'item_id'     => 1
        },
        {
            'item_type'   => 'validate',
            'status_name' => 'succeeded',
            'job_id'      => 1,
            'item_name'   => 'validate customer file',
            'phase_name'  => 'pre_process',
            'message'     => undef,
            'item_id'     => 2
        },
        {
            'item_type'   => 'csv_loader',
            'status_name' => 'succeeded',
            'job_id'      => 1,
            'item_name'   => 'load customer file',
            'phase_name'  => 'process',
            'message'     => undef,
            'item_id'     => 3
        },
        {
            'item_type'   => 'gzip',
            'status_name' => 'succeeded',
            'job_id'      => 1,
            'item_name'   => 'compress file',
            'phase_name'  => 'post_process',
            'message'     => undef,
            'item_id'     => 4
        },
        {
            'item_type'   => 'gunzip',
            'status_name' => 'succeeded',
            'job_id'      => 1,
            'item_name'   => 'decompress',
            'phase_name'  => 'pre_process',
            'message'     => undef,
            'item_id'     => 5
        },
        {
            'item_type'   => 'validate',
            'status_name' => 'succeeded',
            'job_id'      => 1,
            'item_name'   => 'validate customer file',
            'phase_name'  => 'pre_process',
            'message'     => undef,
            'item_id'     => 6
        },
        {
            'item_type'   => 'csv_loader',
            'status_name' => 'succeeded',
            'job_id'      => 1,
            'item_name'   => 'load customer file',
            'phase_name'  => 'process',
            'message'     => undef,
            'item_id'     => 7
        },
        {
            'item_type'   => 'gzip',
            'status_name' => 'succeeded',
            'job_id'      => 1,
            'item_name'   => 'compress file',
            'phase_name'  => 'post_process',
            'message'     => undef,
            'item_id'     => 8
        },
        {
            'item_type'   => 'gunzip',
            'status_name' => 'succeeded',
            'job_id'      => 1,
            'item_name'   => 'decompress',
            'phase_name'  => 'pre_process',
            'message'     => undef,
            'item_id'     => 9
        },
        {
            'item_type'   => 'validate',
            'status_name' => 'succeeded',
            'job_id'      => 1,
            'item_name'   => 'validate customer file',
            'phase_name'  => 'pre_process',
            'message'     => undef,
            'item_id'     => 10
        },
        {
            'item_type'   => 'csv_loader',
            'status_name' => 'succeeded',
            'job_id'      => 1,
            'item_name'   => 'load customer file',
            'phase_name'  => 'process',
            'message'     => undef,
            'item_id'     => 11
        },
        {
            'item_type'   => 'gzip',
            'status_name' => 'succeeded',
            'job_id'      => 1,
            'item_name'   => 'compress file',
            'phase_name'  => 'post_process',
            'message'     => undef,
            'item_id'     => 12
        }
    ];

    my $item_result = $self->dbh->selectall_arrayref($item_sql, {Slice => {}});
    is_deeply($item_result, $item_record, 'Good run item records');

    my $file_proc_sql = q{
        select f.file_proc_id,
               f.item_id,
               f.filename,
               f.message,
               f.file_id,
               st.status_name
        from   etlp_file_process f,
               etlp_status       st
        where  f.status_id = st.status_id
        order  by file_proc_id
    };

    my $file_process_record = [
        {
            'status_name'  => 'succeeded',
            'filename'     => 'customer1.csv.gz',
            'file_id'      => 1,
            'file_proc_id' => 1,
            'message'      => 'file gunzipped',
            'item_id'      => 1
        },
        {
            'status_name'  => 'succeeded',
            'filename'     => 'customer1.csv',
            'file_id'      => 1,
            'file_proc_id' => 2,
            'message'      => 'validating file',
            'item_id'      => 2
        },
        {
            'status_name'  => 'succeeded',
            'filename'     => 'customer1.csv',
            'file_id'      => 1,
            'file_proc_id' => 3,
            'message'      => 'loading the file',
            'item_id'      => 3
        },
        {
            'status_name'  => 'succeeded',
            'filename'     => 'customer1.csv',
            'file_id'      => 1,
            'file_proc_id' => 4,
            'message'      => 'file gzipped',
            'item_id'      => 4
        },
        {
            'status_name'  => 'succeeded',
            'filename'     => 'customer2.csv.gz',
            'file_id'      => 2,
            'file_proc_id' => 5,
            'message'      => 'file gunzipped',
            'item_id'      => 5
        },
        {
            'status_name'  => 'succeeded',
            'filename'     => 'customer2.csv',
            'file_id'      => 2,
            'file_proc_id' => 6,
            'message'      => 'validating file',
            'item_id'      => 6
        },
        {
            'status_name'  => 'succeeded',
            'filename'     => 'customer2.csv',
            'file_id'      => 2,
            'file_proc_id' => 7,
            'message'      => 'loading the file',
            'item_id'      => 7
        },
        {
            'status_name'  => 'succeeded',
            'filename'     => 'customer2.csv',
            'file_id'      => 2,
            'file_proc_id' => 8,
            'message'      => 'file gzipped',
            'item_id'      => 8
        },
        {
            'status_name'  => 'succeeded',
            'filename'     => 'customer3.csv.gz',
            'file_id'      => 3,
            'file_proc_id' => 9,
            'message'      => 'file gunzipped',
            'item_id'      => 9
        },
        {
            'status_name'  => 'succeeded',
            'filename'     => 'customer3.csv',
            'file_id'      => 3,
            'file_proc_id' => 10,
            'message'      => 'validating file',
            'item_id'      => 10
        },
        {
            'status_name'  => 'succeeded',
            'filename'     => 'customer3.csv',
            'file_id'      => 3,
            'file_proc_id' => 11,
            'message'      => 'loading the file',
            'item_id'      => 11
        },
        {
            'status_name'  => 'succeeded',
            'filename'     => 'customer3.csv',
            'file_id'      => 3,
            'file_proc_id' => 12,
            'message'      => 'file gzipped',
            'item_id'      => 12
        }
    ];

    my $file_process_result =
      $self->dbh->selectall_arrayref($file_proc_sql, {Slice => {}});

    is_deeply($file_process_record, $file_process_result,
        'Good run item records');
}

sub die_error : Tests(3) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "customer",
        env_config_file  => "env.conf",
        section          => "customer_die",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    try {
        $etlp->run;
    }
    catch {
        my $error = $_;
        like(
            $error,
qr/line number: EIF - Binary character in unquoted field, binary off/,
            "Can't validate binary data"
        );
    };

    my ($num_items) =
      $self->dbh->selectrow_array('select count(*) from etlp_item',
        {Slice => {}});

    is($num_items, 1, 'Died after one item');

    my @files = <$app_root/data/fail/*>;
    my $files = ["$app_root/data/fail/customer1.csv.gz",];

    is_deeply(\@files, $files, 'Bad file moved to fail');
}

sub skip_error : Tests(3) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "customer",
        env_config_file  => "env.conf",
        section          => "customer_skip",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    $etlp->run;

    my ($num_items) =
      $self->dbh->selectrow_array('select count(*) from etlp_item');

    is($num_items, 3, 'Ran all three validate items');

    my $job_sql = q{
        select  s.status_name
        from    etlp_job j,
                etlp_status s
        where   j.status_id = s.status_id
    };

    my ($job_status) = $self->dbh->selectrow_array($job_sql, {Slice => {}});
    is($job_status, 'warning', 'skip job failed with a warning');

    my @files = <$app_root/data/fail/*>;

    my $files = [
        "$app_root/data/fail/customer1.csv.gz",
        "$app_root/data/fail/customer2.csv.gz",
        "$app_root/data/fail/customer3.csv.gz",
    ];

    is_deeply(\@files, $files, 'All skipped files moved to fail');
}

sub ignore_error : Tests(4) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "customer",
        env_config_file  => "env.conf",
        section          => "customer_ignore",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    try {
        $etlp->run;
    }
    catch {
        my $error = $_;
        like(
            $error,
qr/line number: EIF - Binary character in unquoted field, binary off/,
            "Can't validate binary data"
        );
    };

    my ($num_items) =
      $self->dbh->selectrow_array('select count(*) from etlp_item');

    is($num_items, 9, 'all nine items called');

    my $job_sql = q{
        select  s.status_name
        from    etlp_job j,
                etlp_status s
        where   j.status_id = s.status_id
    };

    my ($job_status) = $self->dbh->selectrow_array($job_sql, {Slice => {}});
    is($job_status, 'warning', 'ignore job failed with a warning');

    my $files = [
        "$app_root/data/fail/customer1.csv.gz",
        "$app_root/data/fail/customer2.csv.gz",
        "$app_root/data/fail/customer3.csv.gz",
    ];

    my @files = <$app_root/data/fail/*>;
    is_deeply(\@files, $files, 'All ignored error files moved to fail');
}

sub os_test : Tests(3) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "customer",
        env_config_file  => "env.conf",
        section          => "customer_os",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    $etlp->run;

    my @files = glob("$app_root/data/archive/*");

    my $files = [
        "$app_root/data/archive/customer1.csv.gz",
        "$app_root/data/archive/customer2.csv.gz",
        "$app_root/data/archive/customer3.csv.gz",
    ];

    is_deeply(\@files, $files, 'Iterative command executed correctly');

    $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "customer",
        env_config_file  => "env.conf",
        section          => "customer_os_bad",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    try {
        $etlp->run;
    }
    catch {
        like(
            $_,
            qr/customer1.csv.gz: No such file or directory/s,
            'Invalid OS command'
        );
    };

    is(-f "$app_root/data/fail/customer1.csv.gz", 1, 'File moved to fail dir');
}

sub perl : Tests(1) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "perl",
        env_config_file  => "env.conf",
        section          => "rename_files",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    $etlp->run;

    my @files = <$app_root/data/incoming/*>;

    my $files = [
        "$app_root/data/incoming/customer1.csv.gz_bak",
        "$app_root/data/incoming/customer2.csv.gz_bak",
        "$app_root/data/incoming/customer3.csv.gz_bak",
    ];

    is_deeply(\@files, $files, 'Files renamed via Perl');
}

sub perl2 : Tests(2) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;
    my $etlp     = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "perl",
        env_config_file  => "env.conf",
        section          => "error_test",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    try {
        $etlp->run;
    }
    catch {
        like(
            $_,
            qr/Unable to run \$filename = Test::NonExistent::add_suffix/,
            'Exception propagated'
        );
        my $row = $self->dbh->selectrow_hashref(
            'select * from etlp_item order by item_id desc');
        
        like($row->{message}, qr/No such file or directory/m, 'Perl failure');
    };
}


1;
