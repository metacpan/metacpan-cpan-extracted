package Helios::Panoptes;

use 5.008000;
use strict;
use warnings;
use base qw(CGI::Application);
use Data::Dumper;

use CGI::Application::Plugin::DBH qw(dbh_config dbh);
use Error qw(:try);

use Helios::Service;

our $VERSION = '1.44';
our $CONF_PARAMS;

=head1 NAME

Helios::Panoptes - CGI::Application providing web admin interface to Helios distributed job 
processing system

=head1 DESCRIPTION

Helios::Panoptes is the web interface to the Helios distributed job processing system.  It 
provides a central point of control for all of the services and jobs in a Helios collective.  This 
web interface can be used to track jobs through the system and manage workloads on a per service 
and per host basis.  Available workers may be increased or decreased as necessary, tuned to 
match available resources.  Job processing can be held, or Helios daemons can be HALTed, from this 
interface.

(Why I<Panoptes>?  Check your Wikipedia.  Or better yet, Greek dictionary.)

=head1 CGI::Application SETUP METHODS

=head2 setup()

The setup() method defines the available run modes, which include:

=over 4

=item ctrl_panel

The Ctrl Panel is the web interface to the central Helios configuration parameter repository (the 
helios_params_tb table in the Helios database).  

=item ctrl_panel_mod

Used by the Ctrl Panel and Worker Admin run modes to change configuration parameters in 
helios_params_tb.

=item job_queue_view

The Job Queue view provides views of waiting, running, and completed jobs in the Helios collective.

=item collective

The Collective Admin provides a simple, dashboard-style view of the current services running in 
the Helios collective, broken down by host.  The service class version is displayed, as well 
as the daemons' uptime.  Job processing can be held and unheld here, and the daemons' run modes 
can be shifted between Normal and Overdrive mode.  The maximum workers for each service can be 
managed, and services can be shut down here via the HALT button.

=item job_submit

The Submit Job view provides a simple interface to submit a test job to the Helios collective for 
debugging purposes.

=back

=cut

sub setup {
	my $self = shift;
	$self->start_mode('job_queue_view');
	$self->mode_param('rm');
	$self->run_modes(
			ctrl_panel => 'ctrl_panel',
			ctrl_panel_mod => 'ctrl_panel_mod',
			job_queue_view => 'job_queue_view',
			job_detail => 'job_detail',
			job_submit => 'job_submit',
			collective => 'collective',
	);

	my $inifile;
	if (defined($ENV{HELIOS_INI}) ) {
		$inifile = $ENV{HELIOS_INI};
	} else {
		$inifile = './helios.ini';
	}
	$self->{service} = Helios::Service->new();
	$self->{service}->prep();
	my $config = $self->{service}->getConfig();
	$CONF_PARAMS = $config;
		
	# connect to db 
	$self->dbh_config($config->{dsn},$config->{user},$config->{password});
}

=head2 teardown()

The only thing that currently happens in teardown() is the database is disconnected.

=cut

sub teardown {
	my $self = shift;

	$self->dbh->disconnect();
}

=head1 RUN MODE METHODS

These methods define code that back the particular application pages.

=head2 ctrl_panel()

This method controls the rendering of the Ctrl Panel view, used to display Helios configuration 
parameters.  The view also allows the user to change config parameters, although the actual config 
modifications are handled by the ctrl_panel_mod() run mode.

=cut

sub ctrl_panel {
	my $self = shift;
	my $dbh = $self->dbh();
	my $q = $self->query();

	my $output;

	my $sql = <<PNLSQL;
SELECT worker_class,
	host,
	param,
	value
FROM helios_params_tb
ORDER BY worker_class, host, param
PNLSQL

	my $sth = $dbh->prepare($sql);
	unless($sth) { throw Error::Simple($dbh->errstr); }

	$sth->execute() or throw Error::Simple($dbh->errstr());

	my $classes;
	my $hosts;
	my $params = [];
	my $last_host;
	my $last_class;
	my $current_host;
	my $current_class;
	my $first_result = 1;
	while (my $result = $sth->fetchrow_hashref() ) {
		if ($first_result) {
			$last_class = $result->{worker_class};
			$last_host = $result->{host};
			$first_result = 0;
		}
		if ($result->{worker_class} ne $last_class) {
			$current_host->{PARAMS} = $params;
			$current_host->{HOST} = $last_host;
			$current_host->{WORKER_CLASS} = $last_class;
			push(@$hosts, $current_host);
			undef $params;
			undef $current_host;
			$last_host = $result->{host};

			$current_class->{HOSTS} = $hosts;
			$current_class->{WORKER_CLASS} = $last_class;
			push(@$classes, $current_class);
			undef $hosts;
			undef $current_class;
			$last_class = $result->{worker_class};
		}
		if ($result->{host} ne $last_host) {
			$current_host->{PARAMS} = $params;
			$current_host->{HOST} = $last_host;
			$current_host->{WORKER_CLASS} = $last_class;
			push(@$hosts, $current_host);
			undef $params;
			undef $current_host;
			$last_host = $result->{host};
		}
		
		push(@$params, $result);
	}

	$current_host->{PARAMS} = $params;
	$current_host->{HOST} = $last_host;
	$current_host->{WORKER_CLASS} = $last_class;
	push(@$hosts, $current_host);

	$current_class->{HOSTS} = $hosts;
	$current_class->{WORKER_CLASS} = $last_class;
	push(@$classes, $current_class);
	
	my $tmpl = $self->load_tmpl(undef, die_on_bad_params => 0);
	$tmpl->param(TITLE => "Helios - Control Panel");

	# only fill in parameters if we actually have some
	if ( $classes->[0]->{HOSTS}->[0]->{HOST} ) {
		$tmpl->param(CLASSES => $classes);
	}
	return $tmpl->output();	
}


=head2 ctrl_panel_mod()

Run mode used to modify Helios config parameters.  Used by ctrl_panel() and collective().

The ctrl_panel_mod run mode uses the following parameters:

=over 4

=item worker_class

The worker (service) class of the changed parameter

=item host

The host of the changed parameter (* for all hosts)

=item param

THe name of the parameter

=item value

The value the parameter should be changed to

=item action

The action (add, modify, delete) to perform.  A delete action will delete the param for the worker 
class and host in question (obviously), add will add it, and modify will replace any existing 
values of the parameter with the new value.

=back

=cut

sub ctrl_panel_mod {
	my $self = shift;
	my $dbh = $self->dbh();
	my $q = $self->query();
	my $return_to = $q->param('return_to');

	my $sql;

	my $worker_class = $q->param('worker_class');
	my $host = $q->param('host');
	my $param = $q->param('param');
	my $value = $q->param('value');
	my $action = $q->param('action');

	unless ($worker_class && $host && $param && $action) {
		throw Error::Simple("Worker class ($worker_class), host ($host), param ($param), and action ($action) required");
	}

	$self->modParam($action, $worker_class, $host, $param, $value);

	if (defined($return_to)) {
		if ( defined($q->param('groupby')) ) { 
			print $q->redirect("./panoptes.pl?rm=$return_to&groupby=".$q->param('groupby')); 
		}
		print $q->redirect("./panoptes.pl?rm=$return_to");
	} else {
		print $q->redirect('./panoptes.pl?rm=ctrl_panel');
	}
	return 1;
}


=head2 job_queue_view()

The job_queue_view() run mode handles the display of the lists of running, waiting, and completed 
jobs.  Note that although all Job Queue lists are dispatched to here, lists of completed jobs are 
actually redirected to _job_queue_view_completed().

=cut

sub job_queue_view {
	my $self = shift;
	my $q = $self->query();
	my $job_status = $q->param('status');
	my $job_detail = $q->param('job_detail');
	# "job_queue_view" is actually a basket of views, all sharing the same template
	if ( defined($job_status) && $job_status eq 'done' && $job_detail) { return $self->_job_queue_view_done($q); }
	if ( defined($job_status) && $job_status eq 'done' && !$job_detail) { return $self->_job_queue_count_done($q); }
	if ( !$job_detail ) { return $self->_job_queue_count($q); }

	my $dbh = $self->dbh();
	my $now = time();
	my $funcmap = $self->loadFuncMap();
	my $output;
	my $sql;
	my @where_clauses;

	# defaults
	my $time_horizon = 3600;
	$job_status = 'run';

	$sql = <<ACTIVEJOBSQL;
SELECT funcid,
	jobid,
	arg,
	uniqkey,
	insert_time,
	run_after,
	grabbed_until,
	priority,
	coalesce
FROM 
	job j
ACTIVEJOBSQL

	# form values
	if ( defined($q->param('time')) ) { $time_horizon = $q->param('time'); }
	if ( defined($q->param('status')) ) { $job_status = $q->param('status'); }

	SWITCH: {
		if ($job_status eq 'run') { 
			push(@where_clauses,"grabbed_until != 0");
			$time_horizon = 'all';
			last SWITCH;
		}
		if ($job_status eq 'wait') {
			push(@where_clauses,"run_after < $now");
			push(@where_clauses,"grabbed_until < $now");
			last SWITCH;
		}
		#[] default 
		$time_horizon = 'all';
	}

	# time horizon filter
	if ( defined($time_horizon) && ($time_horizon ne '') && ($time_horizon ne 'all') ) {
		push(@where_clauses, "run_after > ".($now - $time_horizon) );
	}

	# complete WHERE
	if (scalar(@where_clauses)) {
		$sql .= " WHERE ". join(' AND ',@where_clauses);
	}

	# ORDER BY
	$sql .= " ORDER BY funcid asc, run_after desc";

#t	print $q->header();
#t	print $sql;

	my $sth = $dbh->prepare($sql);
	unless($sth) { throw Error::Simple($dbh->errstr); }

	$sth->execute() or throw Error::Simple($dbh->errstr());

	my @job_types;
	my $job_count = 0;
	my @dbresult;
	my $current_job_class;
	my $first_result = 1;
	my $last_class = undef;
	while ( my $result = $sth->fetchrow_arrayref() ) {
		if ($first_result) {
			$last_class = $result->[0];
			$first_result = 0;
		}
		if ($result->[0] ne $last_class) {
			push(@job_types, $current_job_class);
			undef $current_job_class;
			$last_class = $result->[0];
			$job_count = 0;
		}
		
		my $date_parts = $self->splitEpochDate($result->[5]);
		my $grabbed_until = $self->splitEpochDate($result->[6]);
		$current_job_class->{JOB_CLASS} = $funcmap->{$result->[0]};
		$current_job_class->{JOB_COUNT} = ++$job_count;
		push(@{ $current_job_class->{JOBS} }, 
				{	JOBID => $result->[1],
#					ARG => $result->[2],
					UNIQKEY => $result->[3],
					INSERT_TIME => $result->[4],
					RUN_AFTER => $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS},
					GRABBED_UNTIL => $grabbed_until->{YYYY}.'-'.$grabbed_until->{MM}.'-'.$grabbed_until->{DD}.' '.$grabbed_until->{HH24}.':'.$grabbed_until->{MI}.':'.$grabbed_until->{SS},
					PRIORITY => $result->[7],
					COALESCE => $result->[8]
				});
	}
	push(@job_types, $current_job_class);

	my $tmpl = $self->load_tmpl(undef, die_on_bad_params => 0);
	$tmpl->param(TITLE => "Helios - Job Queue");
	$tmpl->param("STATUS_".$job_status, 1);
	$tmpl->param("TIME_".$time_horizon, 1);
	$tmpl->param("JOB_DETAIL_CHECKED" => 1);
	$tmpl->param(JOB_CLASSES => \@job_types);
	return $tmpl->output();	
}


=head2 _job_queue_view_done()

This method is called from job_queue_view() to deal with displaying completed jobs, which pulls 
completed job data from helios_job_history_tb instead of the job table.

=cut

sub _job_queue_view_done {
	my $self = shift;
	my $q = shift;
	my $dbh = $self->dbh();
	my $now = time();
	my $funcmap = $self->loadFuncMap();
	my $job_status;
	my $output;
	my $sql;
	my @where_clauses;

	# defaults
	my $time_horizon = 3600;

	$sql = '
select *
from (select 
      if (@jid = jobid, 
          if (@time = complete_time,
              @rnk := @rnk + least(0,  @inc := @inc + 1),
              @rnk := @rnk + greatest(@inc, @inc := 1)
                           + least(0,  @time := complete_time)
             ),
          @rnk := 1 + least(0, @jid  := jobid) 
                    + least(0, @time :=  complete_time)
                    + least(0, @inc :=  1)
         ) rank,
      jobid,
	  funcid,
	  run_after,
	  grabbed_until,
	  exitstatus,
	  complete_time
      from helios_job_history_tb,
           (select (@jid := 0)) as x
      where complete_time >= ?
      order by jobid, complete_time desc
	 ) as y
where rank < 2
order by funcid asc, complete_time desc
	';

	# form values
	if ( defined($q->param('time')) ) { $time_horizon = $q->param('time'); }
	if ( defined($q->param('time')) && ($q->param('time') eq '') ) { $time_horizon = 3600; }
	if ( defined($q->param('status')) ) { $job_status = $q->param('status'); }

#t	print $q->header();		
#t	print $sql,"<br>\n";
#t	print $now - $time_horizon,"<br>\n";

	my $sth = $dbh->prepare($sql);
	unless($sth) { throw Error::Simple($dbh->errstr); }

	$sth->execute($now - $time_horizon) or throw Error::Simple($dbh->errstr());

	my @job_types;
	my $job_count = 0;
	my $job_count_failed = 0;
	my @dbresult;
	my $current_job_class;
	my $first_result = 1;
	my $last_class = undef;
	my $last_jobid = 0;
	while ( my $result = $sth->fetchrow_hashref() ) {
#		print join("|",($result->{rank},$result->{funcid},$result->{jobid},$result->{complete_time},$result->{run_after},$result->{exitstatus},$result->{run_after},$result->{grabbed_until})),"<br>\n";		#p
		if ($first_result) {
			$last_class = $result->{funcid};
			$first_result = 0;
		}
		if ($result->{funcid} ne $last_class) {
			push(@job_types, $current_job_class);
			undef $current_job_class;
			$last_class = $result->{funcid};
			$job_count = 0;
			$job_count_failed = 0;
		}
		
		my $date_parts = $self->splitEpochDate($result->{run_after});
		my $complete_time = $self->splitEpochDate($result->{complete_time});
		$current_job_class->{JOB_CLASS} = $funcmap->{$result->{funcid}};
		$current_job_class->{JOB_COUNT} = ++$job_count;
		if ( $result->{exitstatus} != 0 ) { $current_job_class->{JOB_COUNT_FAILED} = ++$job_count_failed; }
		# if this jobid is the same as the last, that means it was a failure that was retried
		# dump it, because we've already added the final completion of the job (whether success or fail)
		# because we sorted "jobid, complete_time desc"
		push(@{ $current_job_class->{JOBS} }, 
				{	JOBID => $result->{jobid},
#					ARG => $result->[2],
					RUN_AFTER => $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS},
					GRABBED_UNTIL => $result->{grabbed_until},
					COMPLETE_TIME => $complete_time->{YYYY}.'-'.$complete_time->{MM}.'-'.$complete_time->{DD}.' '.$complete_time->{HH24}.':'.$complete_time->{MI}.':'.$complete_time->{SS},
					EXITSTATUS => $result->{exitstatus}
				});
		$last_jobid = $result->{jobid};
	}
	push(@job_types, $current_job_class);
	@job_types = sort { $a->{JOB_CLASS} cmp $b->{JOB_CLASS} } @job_types;
	my $tmpl = $self->load_tmpl('job_queue_view.html', die_on_bad_params => 0);
	$tmpl->param(TITLE => 'Helios - Job Queue');
	$tmpl->param("STATUS_".$job_status, 1);
	$tmpl->param("TIME_".$time_horizon, 1);
	$tmpl->param("JOB_DETAIL_CHECKED" => 1);
	$tmpl->param(JOB_CLASSES => \@job_types);
	return $tmpl->output();	
}


=head2 job_queue_count()

This method will handle a job queue view that displays only counts.

=cut

sub _job_queue_count {
	my $self = shift;
	my $q = $self->query();
	my $job_status = $q->param('status');

	my $dbh = $self->dbh();
	my $now = time();
	my $funcmap = $self->loadFuncMap();
	my $output;
	my $sql;
	my @where_clauses;

	# defaults
	my $time_horizon = 3600;
	$job_status = 'run';

	# form values
	if ( defined($q->param('time')) ) { $time_horizon = $q->param('time'); }
	if ( defined($q->param('status')) ) { $job_status = $q->param('status'); }

	$sql = "SELECT funcid, count(*) FROM job ";

	SWITCH: {
		if ($job_status eq 'run') { 
			push(@where_clauses,"grabbed_until != 0");
			$time_horizon = 'all';
			last SWITCH;
		}
		if ($job_status eq 'wait') {
			push(@where_clauses,"run_after < $now");
			push(@where_clauses,"grabbed_until < $now");
			last SWITCH;
		}
		# default 
		$time_horizon = 'all';
	}

	# time horizon filter
	if ( defined($time_horizon) && ($time_horizon ne '') && ($time_horizon ne 'all') ) {
		push(@where_clauses, "run_after > ".($now - $time_horizon) );
	}

	# complete WHERE
	if (scalar(@where_clauses)) {
		$sql .= " WHERE ". join(' AND ',@where_clauses);
	}

	# GROUP BY
	$sql .= " GROUP BY funcid";
	
	# ORDER BY
	$sql .= " ORDER BY funcid asc";

	my $sth = $dbh->prepare($sql);
	unless($sth) { throw Error::Simple($dbh->errstr); }

	$sth->execute() or throw Error::Simple($dbh->errstr());

	my @job_types;
	my $job_count = 0;
	my @dbresult;
	my $current_job_class;
	my $first_result = 1;
	my $last_class = undef;
	while ( my $result = $sth->fetchrow_arrayref() ) {
		if ($first_result) {
			$last_class = $result->[0];
			$first_result = 0;
		}
		if ($result->[0] ne $last_class) {
			push(@job_types, $current_job_class);
			undef $current_job_class;
			$last_class = $result->[0];
			$job_count = 0;
		}
		
		$current_job_class->{JOB_CLASS} = $funcmap->{$result->[0]};
		$current_job_class->{JOB_COUNT} = $result->[1];
	}
	push(@job_types, $current_job_class);

	my $tmpl = $self->load_tmpl('job_queue_view.html', die_on_bad_params => 0);
	$tmpl->param(TITLE => "Helios - Job Queue");
	$tmpl->param("STATUS_".$job_status, 1);
	$tmpl->param("TIME_".$time_horizon, 1);
	$tmpl->param("JOB_DETAIL_CHECKED" => 0);
	$tmpl->param(JOB_CLASSES => \@job_types);
	return $tmpl->output();	
}


sub _job_queue_count_done {
	my $self = shift;
	my $q = shift;
	my $dbh = $self->dbh();
	my $now = time();
	my $funcmap = $self->loadFuncMap();
	my $job_status;
	my $output;
	my $sql;
	my @where_clauses;

	# defaults
	my $time_horizon = 3600;

	$sql = '
select funcid, if(exitstatus,1,0) as exitstatus, count(*) as count
from (select 
      if (@jid = jobid, 
          if (@time = complete_time,
              @rnk := @rnk + least(0,  @inc := @inc + 1),
              @rnk := @rnk + greatest(@inc, @inc := 1)
                           + least(0,  @time := complete_time)
             ),
          @rnk := 1 + least(0, @jid  := jobid) 
                    + least(0, @time :=  complete_time)
                    + least(0, @inc :=  1)
         ) rank,
	  jobid,
	  funcid,
	  run_after,
	  exitstatus,
	  complete_time
      from helios_job_history_tb,
           (select (@jid := 0)) as x
      where complete_time >= ?
      order by jobid, complete_time desc
	 ) as y
where rank < 2
GROUP BY funcid, if(exitstatus,1,0)
	';

	# form values
	if ( defined($q->param('time')) ) { $time_horizon = $q->param('time'); }
	if ( defined($q->param('time')) && ($q->param('time') eq '') ) { $time_horizon = 3600; }
	if ( defined($q->param('status')) ) { $job_status = $q->param('status'); }

#t	print $q->header();		
#t	print $sql,"<br>\n";
#t	print $now - $time_horizon,"<br>\n";

	my $sth = $dbh->prepare($sql);
	unless($sth) { throw Error::Simple($dbh->errstr); }

	$sth->execute($now - $time_horizon) or throw Error::Simple($dbh->errstr());

	my @job_types;
	my $current_funcid;
	my $current_success_jobs = 0;
	my $current_failed_jobs = 0;
	my $last_funcid;
	my $first_result = 1;

	while ( my $result = $sth->fetchrow_arrayref() ) {
#		print join("|",@$result),"<br>\n";		#p
		if ($first_result) {
			$last_funcid = $result->[0];
			$current_funcid = $result->[0];
			$first_result = 0;
		}

		if ($current_funcid ne $result->[0] ) {
			# flush
			push(@job_types, { JOB_CLASS => $funcmap->{$current_funcid}, 
								JOB_COUNT => $current_success_jobs + $current_failed_jobs, 
								JOB_COUNT_FAILED =>  $current_failed_jobs
								}
			);
			$last_funcid = $result->[0];
			$current_success_jobs = 0;
			$current_failed_jobs = 0;
		}
		$current_funcid = $result->[0];
		if ($result->[1] == 0) {
			$current_success_jobs = $result->[2];
		} else {
			$current_failed_jobs = $result->[2];
		}
	}
	push(@job_types, { JOB_CLASS => $funcmap->{$current_funcid}, 
						JOB_COUNT => $current_success_jobs + $current_failed_jobs, 
						JOB_COUNT_FAILED =>  $current_failed_jobs
						}
	);
	@job_types = sort { $a->{JOB_CLASS} cmp $b->{JOB_CLASS} } @job_types;

	my $tmpl = $self->load_tmpl('job_queue_view.html', die_on_bad_params => 0);
	$tmpl->param(TITLE => 'Helios - Job Queue');
	$tmpl->param("STATUS_".$job_status, 1);
	$tmpl->param("TIME_".$time_horizon, 1);
	$tmpl->param("JOB_DETAIL_CHECKED" => 0);
	$tmpl->param(JOB_CLASSES => \@job_types);
	return $tmpl->output();	
}



=head2 job_submit()

The job_submit() run mode allows for manual submission of a job to the Helios collective via 
Panoptes.  This run mode is useful mainly for debugging purposes.

This run mode uses the Helios web job submission interface (submitJob.pl) and requires the 
job_submit_url option being set in the [global] section of helios.ini so it can submit the job to 
the appropriate URL.  eg:

 [global]
 job_submit_url=http://localhost/cgi-bin/submitJob.pl

This run mode is really just displaying a form with some of the details filled in.  Once you 
submit the form, the response you receive is actually the response returned from submitJob.pl.  If 
job submission was successful, this is normally a file of type text/xml with a <status> section 
(normally containing 0) and a <jobid> section (containing the id of the job just submitted).  If 
there was an error during submission, the response will be an HTTP error, and submitJob.pl will 
log a message in the Helios log.

=cut

sub job_submit {
	my $self = shift;
	my $q = $self->query();

	my $classmap = $self->loadClassMap();

	my @classes;
	foreach (sort keys %$classmap) {
		push(@classes, { job_type => $_, job_class => $classmap->{$_} });
	}


	my $tmpl = $self->load_tmpl('job_submit.html', die_on_bad_params => 0);
	$tmpl->param(TITLE => 'Helios - Job Submit');
	$tmpl->param(CLASSES => \@classes);
	$tmpl->param(JOB_SUBMIT_URL => $CONF_PARAMS->{job_submit_url});
	return $tmpl->output();	
}


=head2 collective()

The collective() run mode provides the Collective display, a list of what Helios service daemons 
are running in the collective, with some limited convenience controls for admins that don't want 
to deal with the Ctrl Panel.

The collective() method actually reads the groupby CGI parameter and dispatches to 
_collective_host() or _collective_service(), depending on which the user specified (the default 
is service).

=cut

sub collective {
	my $self = shift;
	my $q = $self->query();
	if ($q->param('groupby') eq 'service') {
		return $self->_collective_service();		
	} else {
		return $self->_collective_host();
	}
}


=head2 _collective_host()

The _collective_host() method provides the Collective display grouped by host.

=cut 

sub _collective_host {
	my $self = shift;
	my $dbh = $self->dbh();
	my $q = $self->query();
	my $config = $self->loadParams('host');

	my $register_threshold = time() - 360;

	my $sql = <<STATUSSQL;
SELECT host, 
	worker_class, 
	worker_version, 
	process_id, 
	register_time,
	start_time
FROM helios_worker_registry_tb
WHERE register_time > ?
ORDER BY host, worker_class
STATUSSQL
	
	my $sth = $dbh->prepare($sql);
	unless ($sth) { throw Error::Simple($dbh->errstr);	}

	$sth->execute($register_threshold) or throw Error::Simple($dbh->errstr());

	my @collective;
	my @dbresult;
	my $current_host;
	my $first_result = 1;
	my $last_host = undef;
	while ( my $result = $sth->fetchrow_arrayref() ) {
		if ($first_result) {
			$last_host = $result->[0];
			$first_result = 0;
		}
		if ($result->[0] ne $last_host) {
			push(@collective, $current_host);
			undef $current_host;
			$last_host = $result->[0];
		}
		
		my $date_parts = $self->splitEpochDate($result->[4]);
		$current_host->{HOST} = $result->[0];

		# calc uptime
		my $uptime_string = '';
		{
			use integer;
			my $uptime = time() - $result->[5];
			my $uptime_days = $uptime/86400;
			my $uptime_hours = ($uptime % 86400)/3600;
			my $uptime_mins = (($uptime % 86400) % 3600)/60;
			if ($uptime_days != 0) { $uptime_string .= $uptime_days.'d '; }
			if ($uptime_hours != 0) { $uptime_string .= $uptime_hours.'h '; }
			if ($uptime_mins != 0) { $uptime_string .= $uptime_mins.'m '; }
		}

		# max_workers
		my $max_workers = 1;
		if ( defined($config->{ $result->[0] }->{ $result->[1] }->{MAX_WORKERS}) ) {
			$max_workers = $config->{ $result->[0] }->{ $result->[1] }->{MAX_WORKERS};
		} 

		# figure out status (normal/overdrive/holding/halting)
		my $status;
		my $halt_status = 0;
		my $hold_status = 0;
		my $overdrive_status = 0;
		if ( (defined( $config->{$result->[0] }->{ $result->[1] }->{OVERDRIVE}) && ($config->{$result->[0] }->{ $result->[1] }->{OVERDRIVE} == 1) ) ||
			(defined( $config->{'*'}->{ $result->[1] }->{OVERDRIVE}) && ($config->{'*'}->{ $result->[1] }->{OVERDRIVE} == 1) ) ) {
			$overdrive_status = 1;
			$status = "Overdrive";
		}
		if ( (defined( $config->{$result->[0] }->{ $result->[1] }->{HOLD}) && ($config->{$result->[0] }->{ $result->[1] }->{HOLD} == 1) ) ||
			(defined( $config->{'*'}->{ $result->[1] }->{HOLD}) && ($config->{'*'}->{ $result->[1] }->{HOLD} == 1) ) ) {
			$hold_status = 1;
			$status = "HOLDING";
		}
		if ( defined( $config->{$result->[0] }->{ $result->[1] }->{HALT}) ||
				defined( $config->{'*'}->{ $result->[1] }->{HALT}) ) {
			$halt_status = 1;
			$status = "HALTING";
		}
		push(@{ $current_host->{SERVICES} }, 
				{	HOST            => $result->[0],
					SERVICE_CLASS   => $result->[1],
					SERVICE_VERSION => $result->[2],
					PROCESS_ID      => $result->[3],
					REGISTER_TIME   => $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS},
					UPTIME          => $uptime_string,
					STATUS          => $status,
					MAX_WORKERS     => $max_workers,
					OVERDRIVE       => $overdrive_status,
					HOLDING         => $hold_status,
					HALTING         => $halt_status,
				});
	}
	push(@collective, $current_host);
	
	my $tmpl = $self->load_tmpl('collective_host.html', die_on_bad_params => 0);
	$tmpl->param(TITLE => 'Helios - Collective View');
	$tmpl->param(COLLECTIVE => \@collective);
	return $tmpl->output();	
}


=head2 _collective_service()

The _collective_service() method provides the Collective display grouped by service.

=cut

sub _collective_service {
	my $self = shift;
	my $dbh = $self->dbh();
	my $q = $self->query();
	my $config = $self->loadParams('worker_class');

	my $register_threshold = time() - 360;

	my $sql = <<STATUSSQL;
SELECT worker_class AS service,
	host, 
	worker_version AS version, 
	process_id, 
	register_time,
	start_time
FROM helios_worker_registry_tb
WHERE register_time > ?
ORDER BY service, host
STATUSSQL
	
	my $sth = $dbh->prepare($sql);
	unless ($sth) { throw Error::Simple($dbh->errstr);	}

	$sth->execute($register_threshold) or throw Error::Simple($dbh->errstr());

	my @collective;
	my @dbresult;
	my $current_service;
	my $first_result = 1;
	my $last_service = undef;
#t	print $q->header();		
	while ( my $result = $sth->fetchrow_arrayref() ) {
#t		print join("|", @$result),"<br>\n";		
		if ($first_result) {
			$last_service = $result->[0];
			$first_result = 0;
		}
		if ($result->[0] ne $last_service) {
			push(@collective, $current_service);
			undef $current_service;
			$last_service = $result->[0];
		}
		
		my $date_parts = $self->splitEpochDate($result->[4]);
		$current_service->{SERVICE_CLASS} = $result->[0];

		# calc uptime
		my $uptime_string = '';
		{
			use integer;
			my $uptime = time() - $result->[5];
			my $uptime_days = $uptime/86400;
			my $uptime_hours = ($uptime % 86400)/3600;
			my $uptime_mins = (($uptime % 86400) % 3600)/60;
			if ($uptime_days != 0) { $uptime_string .= $uptime_days.'d '; }
			if ($uptime_hours != 0) { $uptime_string .= $uptime_hours.'h '; }
			if ($uptime_mins != 0) { $uptime_string .= $uptime_mins.'m '; }
		}

		# max_workers
		my $max_workers = 1;
		if ( defined($config->{ $result->[0] }->{ '*' }->{MAX_WORKERS}) ) {
			$max_workers = $config->{ $result->[0] }->{ '*' }->{MAX_WORKERS};
		} 
		if ( defined($config->{ $result->[0] }->{ $result->[1] }->{MAX_WORKERS}) ) {
			$max_workers = $config->{ $result->[0] }->{ $result->[1] }->{MAX_WORKERS};
		} 

		# figure out status (normal/overdrive/holding/halting)
		my $status;
		my $halt_status = 0;
		my $hold_status = 0;
		my $overdrive_status = 0;
		# determine overdrive status
		if ( defined($config->{$result->[0]}->{'*'}->{OVERDRIVE}) && ($config->{$result->[0]}->{'*'}->{OVERDRIVE} == 1) ) {
			$overdrive_status = 1;
		}
		if ( defined($config->{$result->[0]}->{$result->[1]}->{OVERDRIVE}) ) {
			$overdrive_status = $config->{$result->[0]}->{$result->[1]}->{OVERDRIVE};
		}

		# determine holding status
		if ( defined($config->{$result->[0]}->{'*'}->{HOLD}) && ($config->{$result->[0]}->{'*'}->{HOLD} == 1) ) {
			$hold_status = 1;
		}
		if ( defined($config->{$result->[0]}->{$result->[1]}->{HOLD}) ) {
			$hold_status = $config->{$result->[0]}->{$result->[1]}->{HOLD};
		}


		# determine halt status; if it's even defined, that means the service instance is HALTing
		if ( defined( $config->{$result->[0] }->{ '*' }->{HALT}) ||
				defined( $config->{$result->[0]}->{ $result->[1] }->{HALT}) ) {
			$halt_status = 1;
			$status = "HALTING";
		}
		push(@{ $current_service->{HOSTS} }, 
				{	HOST            => $result->[1],
					SERVICE_CLASS   => $result->[0],
					SERVICE_VERSION => $result->[2],
					PROCESS_ID      => $result->[3],
					REGISTER_TIME   => $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS},
					UPTIME          => $uptime_string,
					STATUS          => $status,
					MAX_WORKERS     => $max_workers,
					OVERDRIVE       => $overdrive_status,
					HOLDING         => $hold_status,
					HALTING         => $halt_status,
				});
	}
	push(@collective, $current_service);
	
	my $tmpl = $self->load_tmpl('collective_service.html', die_on_bad_params => 0);
	$tmpl->param(TITLE => 'Helios - Collective View');
	$tmpl->param(COLLECTIVE => \@collective);
	return $tmpl->output();	
}




=head1 OTHER METHODS

These are auxiliary/utility methods used by the run mode methods.

=head2 splitEpochDate($epoch_seconds)

Given a datetime in epoch seconds, this method returns a hashref containing the component date 
parts.  The keys of the hash follow Oracle naming conventions because that is what the author was 
most familiar with:

 YYYY  four-digit year
 MM    two-digit month
 DD    two-digit day
 HH    twenty-four hour 
 HH12  twelve hour
 HH24  twenty-four hour
 MI    two-digit minutes
 SS    two-digit seconds
 AMPM  ante/post meridium

=cut

sub splitEpochDate {
	my $self = shift;
	my $epoch_secs = shift;

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($epoch_secs);

	my $return_date;

	$return_date->{YYYY} = sprintf("%04d", $year + 1900);
	$return_date->{MM} = sprintf("%02d", $mon+1);
	$return_date->{DD} = sprintf("%02d", $mday);
	$return_date->{MI} = sprintf("%02d", $min);
	$return_date->{SS} = sprintf("%02d", $sec);

	# hours
	if ($hour == 12) {
		$return_date->{AMPM} = 'PM';
		$return_date->{HH12} = '12';
		$return_date->{HH24} = '12';
		$return_date->{HH} = '12';
	} elsif ($hour == 0) {
		$return_date->{AMPM} = 'AM';
		$return_date->{HH12} = '12';
		$return_date->{HH24} = '00';
		$return_date->{HH} = '12';
	} elsif ($hour > 12) {
		$return_date->{AMPM} = 'PM';
		$return_date->{HH12} = sprintf("%02d", $hour - 12);
		$return_date->{HH24} = sprintf("%02d", $hour);
		$return_date->{HH} = sprintf("%02d", $hour);
	} else {
		# hour is AM
		$return_date->{AMPM} = 'AM';
		$return_date->{HH12} = sprintf("%02d", $hour);
		$return_date->{HH24} = sprintf("%02d", $hour);
		$return_date->{HH} = sprintf("%02d", $hour);
	}

	return $return_date;
}


=head2 loadClassMap([$keyfield])

Load the contents of the helios_class_map table into memory, returning it as a hashref.  If 
$keyfield is specified (job_type, job_class), it will be the key field in the hash.  If 
$keyfield is not specified, job_type is the default.

=cut

sub loadClassMap {
	my $self = shift;
	my $keyfield = @_ ? shift : 'job_type';
	my $dbh = $self->dbh();

	my $classmap;
	my $sql = "SELECT job_type, job_class FROM helios_class_map ";

	my $sth = $dbh->prepare($sql);
	unless($sth) { throw Error::Simple($dbh->errstr); }

	$sth->execute() or throw Error::Simple($dbh->errstr());

	while (my $result = $sth->fetchrow_arrayref() ) {
		if ($keyfield eq 'job_class') {
			$classmap->{$result->[1]} = $result->[0];
		} else {
			$classmap->{$result->[0]} = $result->[1];
		}
	}
	return $classmap;
}


=head2 loadFuncMap

Load the contents of the funcmap table into memory, because it's small and lots of methods 
need it.  THe funcmap table associates a funcid with a service class name for internal purposes.

=cut

sub loadFuncMap {
	my $self = shift;
	my $dbh = $self->dbh();

	my $funcmap;

	my $sql = "SELECT funcid, funcname FROM funcmap";
	my $sth = $dbh->prepare($sql);
	unless($sth) { throw Error::Simple($dbh->errstr); }

	$sth->execute() or throw Error::Simple($dbh->errstr());

	while (my $result = $sth->fetchrow_arrayref() ) {
		$funcmap->{$result->[0]} = $result->[1];
		$funcmap->{$result->[1]} = $result->[0];
	}
	return $funcmap;
}


=head2 loadParams([$keyfield])

Returns a hashref data structure containing all of the Helios config params.  The keyfield can be 
either 'worker_class' or 'host' ('worker_class' is the default).

=cut

sub loadParams {
	my $self = shift;
	my $keyfield = @_ ? shift : 'worker_class';
	my $dbh = $self->dbh();
	$dbh->{FetchHashKeyName} = 'NAME_lc';
	my $keyfield2;
	my $config;

	if ($keyfield eq 'worker_class') {
		$keyfield2 = 'host';
	} else {
		$keyfield2 = 'worker_class';
	}

	my $sql = "SELECT $keyfield, $keyfield2, param, value FROM helios_params_tb ORDER BY $keyfield, $keyfield2";
	my $sth = $dbh->prepare($sql);
	unless ($sth) { throw Error::Simple($dbh->errstr()); }
	$sth->execute() or throw Error::Simple($dbh->errstr());

	while(my $result = $sth->fetchrow_arrayref()) {
		$config->{ $result->[0] }->{ $result->[1] }->{ $result->[2] } = $result->[3];
	}

	return $config;
}


=head2 modParam($action, $worker_class, $host, $param, [$value])

Modify Helios config parameters.  Used by ctrl_panel() and collective() displays.

Valid values for $action:

=over 4

=item add

Add the given parameter for the given class and host

=item delete

Delete the given parameter for the given class and host

=item modify

Modify the given parameter for the given class and host with a new value.  Effectively the same 
as a delete followed by an add.

=back

Worker class is the name of the class.

Host is the name of the host.  Use '*' to make the parameter global to all instances of the worker 
class.

Returns a true value if successful and throws an Error::Simple exception otherwise.

=cut

sub modParam {
	my $self = shift;
	my $dbh = $self->dbh();
	my $action = shift;
	my $worker_class = shift;
	my $host = shift;
	my $param = shift;
	my $value = shift;
	
	my $sql;

	unless ($worker_class && $host && $param && $action) {
		throw Error::Simple("Worker class ($worker_class), host ($host), param ($param), and action ($action) required");
	}

	SWITCH: {
		if ($action eq 'add') {
			$sql = 'INSERT INTO helios_params_tb (host, worker_class, param, value) VALUES (?,?,?,?)';
			$dbh->do($sql, undef, $host, $worker_class, $param, $value) or throw Error::Simple('modParam add FAILURE: '.$dbh->errstr);
			last SWITCH;
		}
		if ($action eq 'delete') {
			$sql = 'DELETE FROM helios_params_tb WHERE host = ? AND worker_class = ? AND param = ?';
			$dbh->do($sql, undef, $host, $worker_class, $param) or throw Error::Simple('modParam delete FAILURE: '.$dbh->errstr);
			last SWITCH;
		}
		if ($action eq 'modify') {
			$self->modParam('delete', $worker_class, $host, $param);
			$self->modParam('add', $worker_class, $host, $param, $value);
			last SWITCH;
		}
		throw Error::Simple("modParam invalid action: $action");
	}

	return 1;
}




1;
__END__

=head1 SEE ALSO

L<Helios::Service>, L<helios.pl>, <CGI::Application>, L<HTML::Template>

=head1 AUTHOR 

Andrew Johnson, <lajandy at cpan dotorg>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-9 by CEB Toolbox, Inc.

This library is free software; you can redistribute it and/or modify it under the same terms as 
Perl itself, either Perl version 5.8.0 or, at your option, any later version of Perl 5 you may 
have available.

=head1 WARRANTY 

This software comes with no warranty of any kind.

=cut
