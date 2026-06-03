use strict;
use warnings;
use Test::More;

use_ok('EV::Gearman');
use_ok('EV::Gearman::Job');

ok(EV::Gearman->can($_), "method $_") for qw(
    new connect connect_unix disconnect is_connected
    echo
    submit_job submit_job_high submit_job_low
    submit_job_bg submit_job_high_bg submit_job_low_bg
    submit_job_epoch
    get_status get_status_unique
    option set_client_id
    can_do cant_do reset_abilities
    register_function unregister_function
    work work_one work_stop grab_job all_yours
    admin server_status server_workers server_version maxqueue shutdown_server
    on_error on_connect on_disconnect
    pending_count waiting_count active_count
    connect_timeout command_timeout reconnect priority keepalive
);

ok(EV::Gearman::Job->can($_), "Job method $_") for qw(
    handle function unique workload data
    complete fail exception send_data warning status
);

done_testing;
