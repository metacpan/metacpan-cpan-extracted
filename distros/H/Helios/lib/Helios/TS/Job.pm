package Helios::TS::Job;

use 5.008;
use strict;
use warnings;
use base 'TheSchwartz::Job';

our $VERSION = "2.80";

# FILE CHANGE HISTORY
# (This code is modified from the original TheSchwartz::Job.pm where noted.)
# [LH] [2013-10-04]: Virtual jobtypes: funcmap entries without actual 
# TheSchwartz::Worker subclasses to back them up.  Changed 
# set_exit_status(), failed(), _failed() to use $job->{active_worker_class} 
# instead of $job->funcname if $job->{active_worker_class} is set.  

sub set_exit_status {
    my $job = shift;
    my($exit) = @_;
    # [LH] [2013-10-04]: Use active_worker_class instead of funcname if AWC is set.
    my $class = $job->{active_worker_class} || $job->funcname;
    my $secs = $class->keep_exit_status_for or return;
    my $status = TheSchwartz::ExitStatus->new;
    $status->jobid($job->jobid);
    $status->funcid($job->funcid);
    $status->completion_time(time);
    $status->delete_after($status->completion_time + $secs);
    $status->status($exit);

    my $driver = $job->driver;
    $driver->insert($status);

    # and let's lazily clean some exitstatus while we're here.  but
    # rather than doing this query all the time, we do it 1/nth of the
    # time, and deleting up to n*10 queries while we're at it.
    # default n is 10% of the time, doing 100 deletes.
    my $clean_thres = $TheSchwartz::T_EXITSTATUS_CLEAN_THRES || 0.10;
    if (rand() < $clean_thres) {
        my $unixtime = $driver->dbd->sql_for_unixtime;
        $driver->remove('TheSchwartz::ExitStatus', {
            delete_after => \ "< $unixtime",
        }, {
            nofetch => 1,
            limit   => $driver->dbd->can_delete_with_limit ? int(1 / $clean_thres * 100) : undef,
        });
    }

    return $status;
}


sub failed {
    my ($job, $msg, $ex_status) = @_;
    if ($job->did_something) {
        $job->debug("can't call 'failed' on already finished job");
        return 0;
    }

    ## If this job class specifies that jobs should be retried,
    ## update the run_after if necessary, but keep the job around.

    # [LH] [2013-10-04]: Use active_worker_class instead of funcname if AWC is set.
    my $class       = $job->{active_worker_class} || $job->funcname;
    my $failures    = $job->failures + 1;    # include this one, since we haven't ->add_failure yet
    my $max_retries = $class->max_retries($job);

    $job->debug("job failed.  considering retry.  is max_retries of $max_retries >= failures of $failures?");
    $job->_failed($msg, $ex_status, $max_retries >= $failures, $failures);
}

sub _failed {
    my ($job, $msg, $exit_status, $_retry, $failures) = @_;
    $job->did_something(1);
    $job->debug("job failed: " . ($msg || "<no message>"));

    ## Mark the failure in the error table.
    $job->add_failure($msg);

    if ($_retry) {
	    # [LH] [2013-10-04]: Use active_worker_class instead of funcname if AWC is set.
        my $class = $job->{active_worker_class} || $job->funcname;
        if (my $delay = $class->retry_delay($failures)) {
            $job->run_after(time() + $delay);
        }
        $job->grabbed_until(0);
        $job->driver->update($job);
    } else {
        $job->set_exit_status($exit_status || 1);
        $job->driver->remove($job);
    }
}


1;
__END__

=head1 NAME

Helios::TS::Job - TheSchwartz::Job subclass for Helios

=head1 DESCRIPTION

Helios::TS::Job is a TheSchwartz::Job subclass for Helios.  It helps Helios 
implement features at the job queuing level.

Most of this code was taken from TheSchwartz and modified to fix bugs and add 
features to work better with Helios.  As such, most of the code in this module 
is Six Apart code with certain Logical Helion modifications.

=head1 COPYRIGHT, LICENSE & WARRANTY

This software is Copyright 2007, Six Apart Ltd, cpan@sixapart.com. All
rights reserved.

TheSchwartz is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

TheSchwartz comes with no warranty of any kind.

Certain portions of this software, where noted, are Copyright (C) 2013 by
Logical Helion, LLC.  These portions are free software; you can redistribute 
them and/or modify them under the same terms as Perl itself, either Perl 
version 5.8.0 or, at your option, any later version of Perl 5 you may have 
available.  These software portions come with no warranty of any kind.

=cut
