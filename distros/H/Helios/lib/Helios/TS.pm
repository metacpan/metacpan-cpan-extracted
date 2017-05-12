package Helios::TS;

use 5.008;
use strict;
use warnings;
use base qw(TheSchwartz);
use fields qw(active_worker_class);        # new fields for this subclass
use Carp qw( croak );
use List::Util qw( shuffle );
use Helios::TS::Job;

use constant OK_ERRORS => { map { $_ => 1 } Data::ObjectDriver::Errors->UNIQUE_CONSTRAINT, };

our $VERSION = '2.80';

# FILE CHANGE HISTORY
# (This code is modified from the original TheSchwartz.pm where noted.)
# [LH] [2012-07-11]: driver_for(): Changed driver creation to use Helios driver 
# to cache database connections.
# [LH] [2013-09-21]: find_job_for_workers(): Added code to enable job 
# prioritization.
# [LH] [2013-10-04]: Implemented "virtual jobtypes" - funcmap entries without 
# actual TheSchwartz::Worker subclasses to back them up.  Switched to using
# Helios::TS::Job instead of base TheSchwartz::Job because of this.
# [LH] [2013-10-04]: work_once(): Commented out call to 
# temporarily_remove_ability() because we do not think the issue it solves is 
# a concern for Helios::TS (Oracle's indexes do not exhibit the issue t_r_a() 
# is supposed to solve, and we're not sure MySQL indexes do anymore either).  
# [LH] [2013-10-04]: Fix for Helios bug [RT79690], which appears to be a DBD 
# problem where a LOB becomes unbound in a query.
# [LH] [2013-11-24]: Removed old code already commented out. 

our $T_AFTER_GRAB_SELECT_BEFORE_UPDATE;
our $T_LOST_RACE;
our $FIND_JOB_BATCH_SIZE = 50;

# BEGIN CODE COPYRIGHT (C) 2013 LOGICAL HELION, LLC.
# [LH] [2013-10-04]: Virtual jobtypes: Helios::TS->{active_worker_class} 
# attribute and accessors for it.
sub new {
	my $class = shift;
	my %params = @_;
	my $self = fields::new($class);
	$self->SUPER::new(@_);                # init base fields
	if ( defined($params{active_worker_class})) {
		$self->{active_worker_class} = $params{active_worker_class};
	}
    return $self;
}

sub active_worker_class {
	my Helios::TS $hts = shift;
	return $hts->{active_worker_class};
}
sub set_active_worker_class {
	my Helios::TS $hts = shift;
	$hts->{active_worker_class} = shift;
}
# END CODE COPYRIGHT (C) 2013 LOGICAL HELION, LLC.


sub driver_for {
    my Helios::TS $client = shift;
    my($hashdsn) = @_;
    my $driver;
    my $t = time;
    my $cache_duration = $client->{driver_cache_expiration};
    if ($cache_duration && $client->{cached_drivers}{$hashdsn}{create_ts} && $client->{cached_drivers}{$hashdsn}{create_ts} + $cache_duration > $t) {
        $driver = $client->{cached_drivers}{$hashdsn}{driver};
    } else {
        my $db = $client->{databases}{$hashdsn}
            or croak "Ouch, I don't know about a database whose hash is $hashdsn";
        if ($db->{driver}) {
            $driver = $db->{driver};
        } else {
			# [LH] 2012-07-11: Changed driver creation to use Helios driver to 
			# cache database connections.
            $driver = Helios::ObjectDriver::DBI->new(
                        dsn      => $db->{dsn},
                        username => $db->{user},
                        password => $db->{pass},
                      );
        }
        $driver->prefix($db->{prefix}) if exists $db->{prefix};

        if ($cache_duration) {
            $client->{cached_drivers}{$hashdsn}{driver} = $driver;
            $client->{cached_drivers}{$hashdsn}{create_ts} = $t;
        }
    }
    return $driver;
}


sub find_job_for_workers {
    my Helios::TS $client = shift;
    my($worker_classes) = @_;
    $worker_classes ||= $client->{current_abilities};
    for my $hashdsn ($client->shuffled_databases) {
        ## If the database is dead, skip it.
        next if $client->is_database_dead($hashdsn);

        my $driver = $client->driver_for($hashdsn);
        my $unixtime = $driver->dbd->sql_for_unixtime;

        my @jobs;
        eval {
            ## Search for jobs in this database where:
            ## 1. funcname is in the list of abilities this $client supports;
            ## 2. the job is scheduled to be run (run_after is in the past);
            ## 3. no one else is working on the job (grabbed_until is in
            ##    in the past).
            my @ids = map { $client->funcname_to_id($driver, $hashdsn, $_) }
                      @$worker_classes;

# BEGIN CODE Copyright (C) 2012-3 by Logical Helion, LLC.
			# [LH] [2013-09-21]: Added code to enable job prioritization.
			my $direction = 'descend';
			if ( $client->prioritize eq 'low' ) {
				$direction = 'ascend';
			}
# END CODE Copyright (C) 2012-3 by Logical Helion, LLC.

# [LH] [2013-10-04]: Implemented "virtual jobtypes" - funcmap entries without 
# actual TheSchwartz::Worker subclasses to back them up.  Switched to using
# Helios::TS::Job instead of base TheSchwartz::Job because of this.
            @jobs = $driver->search('Helios::TS::Job' => {
                    funcid        => \@ids,
                    run_after     => \ "<= $unixtime",
                    grabbed_until => \ "<= $unixtime",
                }, { limit => $FIND_JOB_BATCH_SIZE,
                    ( $client->prioritize ? ( sort => 'priority',
                    direction => $direction ) : () )
                }
            );
        };
        if ($@) {
            unless (OK_ERRORS->{ $driver->last_error || 0 }) {
                $client->mark_database_as_dead($hashdsn);
            }
        }

        # for test harness race condition testing
        $T_AFTER_GRAB_SELECT_BEFORE_UPDATE->() if $T_AFTER_GRAB_SELECT_BEFORE_UPDATE;

        my $job = $client->_grab_a_job($hashdsn, @jobs);
        return $job if $job;
    }
}


sub _grab_a_job {
    my Helios::TS $client = shift;
    my $hashdsn = shift;
    my $driver = $client->driver_for($hashdsn);

    ## Got some jobs! Randomize them to avoid contention between workers.
    my @jobs = shuffle(@_);

  JOB:
    while (my $job = shift @jobs) {
# BEGIN CODE COPYRIGHT (C) 2013 LOGICAL HELION, LLC.
		# [LH] [2013-10-04] [RT79690] Check the job to see that it has an arg() 
		# value. If it doesn't, throw it away and get a new one.  This won't  
		# prevent the LOB from unbinding, but it will work around it in a 
		# relatively transparent way.
		unless ( ref($job->arg()) ) { 
			next; 
		}
# END CODE COPYRIGHT (C) 2013 LOGICAL HELION, LLC.
        ## Convert the funcid to a funcname, based on this database's map.
        $job->funcname( $client->funcid_to_name($driver, $hashdsn, $job->funcid) );

        ## Update the job's grabbed_until column so that
        ## no one else takes it.
#        my $worker_class = $job->funcname;
# BEGIN CODE COPYRIGHT (C) 2013 LOGICAL HELION, LLC.
		# [LH] [2013-10-04] The worker class is the "Active Worker Class" if 
		# it's set.  Otherwise, assume it's just the job's jobtype (funcname).
		my $worker_class = $client->{active_worker_class} || $job->funcname;
# END CODE COPYRIGHT (C) 2013 LOGICAL HELION, LLC.
        my $old_grabbed_until = $job->grabbed_until;

        my $server_time = $client->get_server_time($driver)
            or die "expected a server time";

        $job->grabbed_until($server_time + ($worker_class->grab_for || 1));

        ## Update the job in the database, and end the transaction.
        if ($driver->update($job, { grabbed_until => $old_grabbed_until }) < 1) {
            ## We lost the race to get this particular job--another worker must
            ## have got it and already updated it. Move on to the next job.
            $T_LOST_RACE->() if $T_LOST_RACE;
            next JOB;
        }

        ## Now prepare the job, and return it.
        my $handle = TheSchwartz::JobHandle->new({
            dsn_hashed => $hashdsn,
            jobid      => $job->jobid,
        });
        $handle->client($client);
        $job->handle($handle);
        return $job;
    }

    return undef;
}


sub work_once {
	# [LH] [2013-10-04] Using Helios::TS not TheSchwartz.
    my Helios::TS $client = shift;
    my $job = shift;  # optional specific job to work on

    ## Look for a job with our current set of abilities. Note that the
    ## list of current abilities may not be equal to the full set of
    ## abilities, to allow for even distribution between jobs.
    $job ||= $client->find_job_for_workers;

    ## If we didn't find anything, restore our full abilities, and try
    ## again.
    if (!$job &&
        @{ $client->{current_abilities} } < @{ $client->{all_abilities} }) {
        $client->restore_full_abilities;
        $job = $client->find_job_for_workers;
    }

	# [LH] [2013-10-04]: Virtual Jobtypes: Use the active_worker_class 
	# instead of the job's funcname if active_worker_class is set.
	my $class = $client->{active_worker_class} || ($job ? $job->funcname : undef);

    if ($job) {
        my $priority = $job->priority ? ", priority " . $job->priority : "";
# BEGIN CODE COPYRIGHT (C) 2013 LOGICAL HELION, LLC.
		if ($client->{active_worker_class}) {
			$job->{active_worker_class} = $client->{active_worker_class};			
		}
# END CODE COPYRIGHT (C) 2013 LOGICAL HELION, LLC.
        $job->debug("TheSchwartz::work_once got job of class '$class'$priority");
    } else {
        $client->debug("TheSchwartz::work_once found no jobs");
    }

    ## If we still don't have anything, return.
    return unless $job;

    ## Now that we found a job for this particular funcname, remove it
    ## from our list of current abilities. So the next time we look for a
    ## we'll find a job for a different funcname. This prevents starvation of
    ## high funcid values because of the way MySQL's indexes work.
	# [LH] [2013-10-04]: work_once(): Commented out call to 
	# temporarily_remove_ability() because we do not think the issue it solves is 
	# a concern for Helios::TS (Oracle's indexes do not exhibit the issue t_r_a() 
	# is supposed to solve, and we're not sure MySQL indexes do anymore either).  
#    $client->temporarily_remove_ability($class);

    $class->work_safely($job);

    ## We got a job, so return 1 so work_until_done (which calls this method)
    ## knows to keep looking for jobs.
    return 1;
}


1;
__END__

=head1 NAME

Helios::TS - TheSchwartz subclass for Helios

=head1 DESCRIPTION

Helios::TS is a TheSchwartz subclass for Helios.  It helps Helios implement
features at the job queuing level.

Most of this code was taken from TheSchwartz and modified to fix bugs and add 
features to work better with Helios.  As such, most of the code in this module 
is Six Apart code with certain Logical Helion modifications.

=head1 COPYRIGHT, LICENSE & WARRANTY

This software is Copyright 2007, Six Apart Ltd, cpan@sixapart.com. All
rights reserved.

TheSchwartz is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

TheSchwartz comes with no warranty of any kind.

Certain portions of this software, where noted, are Copyright (C) 2012-3 by
Logical Helion, LLC.  These portions are free software; you can redistribute 
them and/or modify them under the same terms as Perl itself, either Perl 
version 5.8.0 or, at your option, any later version of Perl 5 you may have 
available.  These software portions come with no warranty of any kind.

=cut
