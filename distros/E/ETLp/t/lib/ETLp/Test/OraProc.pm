package ETLp::Test::OraProc;

use strict;
use Test::More;
use Data::Dumper;
use base (qw(ETLp::Test::PluginBase));
use Try::Tiny;
use ETLp;
use ETLp::Config;

sub iterative_procs : Tests(5) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "plsql_test",
        env_config_file  => "env",
        section          => "plsql_iterative_test",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    $etlp->run;

    my $args = {
        'section_id' => 1,
        'message'    => 1,
        'status_id'  => 1
    };

    my $proc_records = [
        {
            'section_id' => 1,
            'message'    => undef,
            'status_id'  => '3'
        }
    ];

    my $procs =
      $self->dbh->selectall_arrayref('select * from etlp_job order by job_id',
        {Slice => $args});

    is_deeply($procs, $proc_records, 'Audit Iterative Processes');

    my $item_records = [
        {
            'item_type' => 'plsql',
            'job_id'    => 1,
            'phase_id'  => 2,
            'item_name' => 'record_file',
            'status_id' => 3
        },
        {
            'item_type' => 'plsql',
            'job_id'    => 1,
            'phase_id'  => 2,
            'item_name' => 'iterative test_noparams',
            'status_id' => 3
        },
        {
            'item_type' => 'plsql',
            'job_id'    => 1,
            'phase_id'  => 2,
            'item_name' => 'record_file',
            'status_id' => 3
        },
        {
            'item_type' => 'plsql',
            'job_id'    => 1,
            'phase_id'  => 2,
            'item_name' => 'iterative test_noparams',
            'status_id' => 3
        },
        {
            'item_type' => 'plsql',
            'job_id'    => 1,
            'phase_id'  => 2,
            'item_name' => 'record_file',
            'status_id' => 3
        },
        {
            'item_type' => 'plsql',
            'job_id'    => 1,
            'phase_id'  => 2,
            'item_name' => 'iterative test_noparams',
            'status_id' => 3
        }
    ];

    $args = {
        'job_id'    => 1,
        'item_type' => 1,
        'phase_id'  => 1,
        'item_name' => 1,
        'status_id' => 1
    };

    my $items =
      $self->dbh->selectall_arrayref('select * from etlp_item order by item_id',
        {Slice => $args});

    is_deeply($items, $item_records, 'Iterative Item Records');

    my @messages = @{
        $self->dbh->selectcol_arrayref(
            'select message from etlp_item order by item_id')
      };

    like(
        $messages[0],
qr!File: customer1.csv.gz; Archive Dir: .*/app_root/data/archive received.!,
        'message 1 returned'
    );
    like(
        $messages[2],
qr!File: customer2.csv.gz; Archive Dir: .*/app_root/data/archive received.!,
        'message 3 returned'
    );
    like(
        $messages[4],
qr!File: customer3.csv.gz; Archive Dir: .*/app_root/data/archive received.!,
        'message 5 returned'
    );
    
    # Stops DBI warning when $etlp goes out of scope and the next tests are run
    ETLp::Config->dbh->disconnect;

}

sub serial_procs : Tests(3) {
    my $self     = shift;
    my $app_root = $self->_get_app_root;

    my $etlp = ETLp->new(
        config_directory => "$app_root/conf",
        app_config_file  => "plsql_test",
        env_config_file  => "env",
        section          => "plsql_serial_test",
        log_dir          => "$app_root/log",
        app_root         => $app_root,
        localize         => 1,
    );

    try {
        $etlp->run;
    } catch {};

    my $args = {
        'section_id' => 1,
        'status_id'  => 1
    };

    my $proc_records = [
        {
            'section_id' => '1',
            'status_id'  => '4'
        }
    ];

    my $procs =
      $self->dbh->selectall_arrayref('select * from etlp_job order by job_id',
        {Slice => $args});

    is_deeply($procs, $proc_records, 'Audit Serial Processes');

    $procs =
      $self->dbh->selectall_arrayref('select * from etlp_item order by item_id',
        {Slice => {}});

    like($procs->[1]->{message}, qr/ORA-20001: Uh-oh/, 'PL/SQL Error trapped');

    $args = {
        'job_id'    => 1,
        'item_type' => 1,
        'phase_id'  => 1,
        'item_name' => 1,
        'status_id' => 1
    };

    my $item_records = [
        {
            'item_type' => 'plsql',
            'job_id'    => 1,
            'phase_id'  => 2,
            'item_name' => 'serial_test',
            'status_id' => 3
        },
        {
            'item_type' => 'plsql',
            'job_id'    => 1,
            'phase_id'  => 2,
            'item_name' => 'serial_error',
            'status_id' => 2
        },
        {
            'item_type' => 'plsql',
            'job_id'    => 1,
            'phase_id'  => 2,
            'item_name' => 'serial test_noparams',
            'status_id' => 3
        }
    ];

    my $items =
      $self->dbh->selectall_arrayref('select * from etlp_item order by item_id',
        {Slice => $args});

    is_deeply($items, $item_records, 'Serial Item Records');
}

sub _oracle_ddl {
    my $self = shift;
    return (
        q{
            CREATE PROCEDURE RECORD_FILE
            ( filename IN VARCHAR2,
              archive_dir IN VARCHAR2,
              message IN OUT VARCHAR2
            ) AS
            BEGIN
                message := 'File: '||filename ||'; Archive Dir: '||archive_dir||' received.';
            END RECORD_FILE;
        },
        q{
            CREATE PROCEDURE test_noparams AS
            BEGIN
                NULL;
            END test_noparams;
        },
        q{
            CREATE PROCEDURE serial_test
            ( param1 IN VARCHAR2,
              param2 IN VARCHAR2,
              message IN OUT VARCHAR2
            ) AS
            BEGIN
                message := 'param1: '||param1 ||'; param2: '||param2||' received.';
            END SERIAL_TEST;
        },
        q{
            CREATE PROCEDURE serial_error
            ( message IN OUT VARCHAR2 )  AS
            BEGIN
                message := 'An error is coming';
                RAISE_APPLICATION_ERROR(-20001, 'Uh-oh - error');
            END SERIAL_error;
        }
    );
}

sub _drop_oracle_ddl {
    my $self = shift;
    return (
        q{
            drop procedure record_file
        },
        q{
            drop procedure test_noparams
        },
        q{
            drop procedure serial_test
        },
        q{
            drop procedure serial_error
        }
    );
}
1;
