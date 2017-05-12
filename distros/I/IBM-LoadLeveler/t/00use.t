# Test if the module is loadable.

use Test::More tests => 37 ;


my @function_defs = qw ( ll_version
                         ll_query
                         ll_set_request
                         ll_reset_request
                         ll_get_objs
                         ll_get_data
                         ll_next_obj
                         ll_free_objs
                         ll_deallocate
                         ll_error
                         ll_get_jobs
                         ll_get_nodes
                         ll_make_reservation
                         ll_change_reservation
                         ll_bind
                         ll_remove_reservation
                         llsubmit
                         ll_control
                         ll_modify
                         ll_preempt
                         ll_preempt_jobs
                         ll_run_scheduler
                         ll_start_job
                         ll_start_job_ext
                         ll_terminate_job
                         llctl
                         llfavorjob
                         llfavoruser
                         llhold
                         llprio
			 ll_cluster
			 ll_cluster_auth
			 ll_fair_share
                         ll_config_changed
                         ll_read_config
			 ll_move_job
			 ll_move_spool
                       );

use_ok( 'IBM::LoadLeveler', @function_defs);

can_ok( __PACKAGE__, 'll_version');
can_ok( __PACKAGE__, 'll_query');
can_ok( __PACKAGE__, 'll_set_request');
can_ok( __PACKAGE__, 'll_reset_request');
can_ok( __PACKAGE__, 'll_get_objs');
can_ok( __PACKAGE__, 'll_get_data');
can_ok( __PACKAGE__, 'll_next_obj');
can_ok( __PACKAGE__, 'll_free_objs');
can_ok( __PACKAGE__, 'll_deallocate');
can_ok( __PACKAGE__, 'll_error');
can_ok( __PACKAGE__, 'll_get_jobs');
can_ok( __PACKAGE__, 'll_get_nodes');
can_ok( __PACKAGE__, 'll_make_reservation');
can_ok( __PACKAGE__, 'll_change_reservation');
can_ok( __PACKAGE__, 'll_bind');
can_ok( __PACKAGE__, 'll_remove_reservation');
can_ok( __PACKAGE__, 'llsubmit');
can_ok( __PACKAGE__, 'll_control');
can_ok( __PACKAGE__, 'll_modify');
can_ok( __PACKAGE__, 'll_preempt');
can_ok( __PACKAGE__, 'll_preempt_jobs');
can_ok( __PACKAGE__, 'll_run_scheduler');
can_ok( __PACKAGE__, 'll_start_job');
can_ok( __PACKAGE__, 'll_start_job_ext');
can_ok( __PACKAGE__, 'll_terminate_job');
can_ok( __PACKAGE__, 'llctl');
can_ok( __PACKAGE__, 'llfavorjob');
can_ok( __PACKAGE__, 'llhold');
can_ok( __PACKAGE__, 'llprio');
can_ok( __PACKAGE__, 'll_cluster');
can_ok( __PACKAGE__, 'll_cluster_auth');
can_ok( __PACKAGE__, 'll_fair_share');
can_ok( __PACKAGE__, 'll_config_changed');
can_ok( __PACKAGE__, 'll_read_config');
can_ok( __PACKAGE__, 'll_move_job');
can_ok( __PACKAGE__, 'll_move_spool');
