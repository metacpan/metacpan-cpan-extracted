package ETLp::Test::SerialPlugin;

use strict;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);
use base (qw(ETLp::Test::PluginBase));
use Try::Tiny;
use ETLp;
use ETLp::Config;
use autodie;
use UNIVERSAL::require;

sub os : Tests(7) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "serial",
        env_config_file  => "env.conf",
        section          => "serial_os_test",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    $etlp->run;

    my $serial_os_file = "$app_root/data/archive/test_file.lst";
    ok(-f $serial_os_file eq '1', 'Serial OS');

    my $args = {
        'section_id' => 1,
        'message'    => 1,
        'status_id'  => 1
    };

    my $proc_records = [
        {
            'section_id' => 1,
            ,
            'message'   => undef,
            'status_id' => '4'
        }
    ];

    my $procs =
      $self->dbh->selectall_arrayref('select * from etlp_job order by job_id',
        {Slice => $args});

    is_deeply($procs, $proc_records, 'Audit Serial OS Processes');

    $args = {
        'job_id'    => 1,
        'phase_id'  => 1,
        'item_name' => 1,
        'status_id' => 1
    };

    my $item_records = [
        {
            'job_id'    => '1',
            'phase_id'  => '2',
            'item_name' => 'create file',
            'status_id' => '3'
        },
        {
            'job_id'    => '1',
            'phase_id'  => '2',
            'item_name' => 'create file - hide command',
            'status_id' => '3'
        },
        {
            'job_id'    => '1',
            'phase_id'  => '2',
            'item_name' => 'dummy command',
            'status_id' => '2'
        },
        {
            'job_id'    => '1',
            'phase_id'  => '2',
            'item_name' => 'move file',
            'status_id' => '3'
        }
    ];

    my $items =
      $self->dbh->selectall_arrayref('select * from etlp_item order by item_id',
        {Slice => $args});

    is_deeply($items, $item_records, 'Audit Serial OS Items');

    my @messages = @{
        $self->dbh->selectcol_arrayref(
            'select message from etlp_item order by item_id')
      };

    like(
        $messages[0],
        qr!^touch\s.*data/incoming/test_file.lst!,
        'touch succeeded'
    );
    like(
        $messages[1],
        qr!^touch\s+%incoming_dir%/test_file.lst!,
        'touch succeeded (hide command)'
    );
    like(
        $messages[2],
        qr!khjbvjfcghj: No such file or directory!s,
        'Invalid OS command'
    );
    like($messages[3], qr!^mv\s+.*data/incoming/test_file.lst\s+.*data/archive!,
        'mv succeeded');
}

sub os_app_root : Tests(3) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "serial",
        env_config_file  => "env",
        section          => "app_root_test",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    $etlp->run;

    $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "serial",
        env_config_file  => "env",
        section          => "app_root_test_bad",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    eval { $etlp->run; };

    my $args = {
        'job_id'    => 1,
        'phase_id'  => 1,
        'item_name' => 1,
        'status_id' => 1
    };

    my $item_records = [
        {
            'job_id'    => '1',
            'phase_id'  => '2',
            'item_name' => 'app root test',
            'status_id' => '3'
        },
        {
            'job_id'    => '2',
            'phase_id'  => '2',
            'item_name' => 'app root failure test',
            'status_id' => '2'
        }
    ];

    my $items =
      $self->dbh->selectall_arrayref('select * from etlp_item order by item_id',
        {Slice => $args});

    is_deeply($items, $item_records, '%app_root% substitution');

    my @messages = @{
        $self->dbh->selectcol_arrayref(
            'select message from etlp_item order by item_id')
      };

    like(
        $messages[0],
        qr!^perl\s.*t/app_root/bin/app_root_test.pl!,
        'App Root Message'
    );

    like($messages[1], qr!No such file or directory!m, 'App Root Message Bad');
}

sub serial_perl : Tests(2) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "serial",
        env_config_file  => "env",
        section          => "serial_perl_test",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    my $outfile = "$app_root/log/serial_perl.txt";

    $etlp->run;

    is(-f $outfile, 1, "Serial perl");

    my $row = $self->dbh->selectrow_hashref('select * from etlp_item');
    is($row->{item_name}, 'Perl Serial', 'Serial audit correct');
}

sub file_watcher : Tests(7) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    if (!eval "require  Parallel::SubFork") {
        return;
    }

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "serial",
        env_config_file  => "env",
        section          => "fw_pattern",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    my $manager = Parallel::SubFork->new();
    $manager->start(
        \&gen_file,
        delay     => 3,
        directory => "$app_root/data/incoming",
        filename  => "fw_test.csv"
    );

    try {
        $etlp->run;
    } catch {
        ETLp::Config->logger->error($_);
    };

    my $audit_rec = $self->dbh->selectrow_hashref(
        'select * from etlp_item order by item_id desc', {Slice => {}}
    );
    
    is($audit_rec->{item_name}, 'Pattern Match', 'Pattern Watcher');
    is($audit_rec->{message}, 'File(s) detected', 'File pattern detected');
    $manager->wait_for_all();
    remove_file("$app_root/data/incoming/fw_test.csv");
    
    $self->dbh->commit;
    
    $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "serial",
        env_config_file  => "env",
        section          => "fw_file",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    $manager = Parallel::SubFork->new();
    $manager->start(
        \&gen_file,
        delay     => 3,
        directory => "$app_root/data/incoming",
        filename  => "fw_test.csv"
    );
    
    $etlp->run;
    
    $audit_rec = $self->dbh->selectrow_hashref(
        'select * from etlp_item order by item_id desc', {Slice => {}}
    );
    
    is($audit_rec->{item_name}, 'File Name Match', 'Exact file name specification');
    is($audit_rec->{message}, 'File(s) detected', 'File name detected');
    
    $manager->wait_for_all();    
    remove_file("$app_root/data/incoming/fw_test.csv");
    $self->dbh->commit;
    
    $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "serial",
        env_config_file  => "env",
        section          => "fw_file",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );
    
    $etlp->run;
    
    $audit_rec = $self->dbh->selectrow_hashref(
        'select * from etlp_item order by item_id desc', {Slice => {}}
    );
    
    is($audit_rec->{message}, 'No file(s) detected', 'No file detected');
    
    $manager->wait_for_all();    
    $self->dbh->commit;
    
    $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "serial",
        env_config_file  => "env",
        section          => "fw_no_file",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );
    
    try {
        $etlp->run;
    } catch {
        like($_, qr/No file found/, 'No file found error');
    };
    
    $audit_rec = $self->dbh->selectrow_hashref(
        'select * from etlp_item order by item_id desc', {Slice => {}}
    );
    
    is($audit_rec->{message}, 'No file found', 'No file error logged');
}

sub remove_file {
    my $file = shift;
    if (-f $file) {
        unlink $file || die "Unable to unlink $file\n";
    }
}

sub gen_file {
    my %args = @_;
    sleep $args{delay};
    open(my $fh, '>', "$args{directory}/$args{filename}");
    close $fh;
}

1;
