package Makefile::Parallel::Scheduler::PBS;

use base qw(Makefile::Parallel::Scheduler);

use strict;
use warnings;
use Cwd;
use Proc::Reliable;
use Data::Dumper;
use Time::Interval;
sub launch{
    my ($self, $job, $debug) = @_;

    my $me = `whoami`;
    chomp($me);

    # Create the PBS script
    open F, ">/tmp/$me#$job->{rule}{id}.sh";

    # Number of cpus
    $job->{cpus} ||= 1;

    if ($job->{action}[0]{shell}) {
        print F "#!/bin/sh\n";

        if ($self->{mail}) {
            print F "#PBS -m e -M $self->{mail}\n";
        }

        print F "#PBS -l walltime=$job->{walltime}\n";
        print F "#PBS -l nodes=1:ppn=$job->{cpus}\n";
        print F "#\n";

        print F "cd " . cwd() . "\n";
        print F join("\n",map { $_->{shell}?$_->{shell}:() }  @{$job->{action} });
        close F;
    }
    elsif ($job->{action}[0]{perl}) {  
        print F "#!/usr/bin/perl\n";

        print F "#PBS -l walltime=$job->{walltime}\n";
        print F "#PBS -l nodes=1:ppn=$job->{cpus}\n";
        print F "#\n";

        print F "chdir qq{" . cwd() . "};\n";
        print F $job->{perl};
        print F $job->{action}[0]{perl};
        close F;
    }
    else {
	die "Action type not supported.\n";
    }

    # If we are in debug mode, copy the file to log dir
    `cp /tmp/$me#$job->{rule}{id}.sh log/$me#$job->{rule}{id}.sh` if $debug;

    # Launch the process
    sleep 1;
    my $proc = Proc::Reliable->new();
    
    my ($stdout, $stderr, $status, undef) = $proc->run("qsub /tmp/$me#$job->{rule}{id}.sh");

    # Only save the id
    $stdout =~ /^(\d+)/;
    $job->{proc} = $1;
}

sub poll {
    my ($self, $job, $logger) = @_;

    # I do not have any idea how we can have a job running without
    # this proc information, but the truth is that that is
    # happening :-S
	return 0 unless $job->{proc};

    my $me = `whoami`;
    chomp($me);

    my $proc = Proc::Reliable->new();
    my (undef, undef, $status, undef) = $proc->run("qstat $job->{proc}");

    if($status == 39168){
        unlink "/tmp/$me#$job->{rule}{id}.sh";
        return 0;
    }

    $logger->warn("qstat failed with code $status while polling for $job->{rule}{id}") if $status;
    return 1; 
}

sub interrupt {
    my ($self, $job) = @_;

    `qdel $job->{proc}`;
}

sub get_id {
    my ($self, $job) = @_;

    $job->{proc};
}

sub can_run {
    my ($self) = @_;

    return 1;
}

sub clean {
    my ($self, $queue) = @_;

    my $me = `whoami`;
    chomp($me);

    for my $job (@{$queue}) {
        my $id = $job->{rule}->{id};

        # If there are expands, expand it in the lazy way :D
        $id .= '*' if($job->{rule}{vars});

        # Remove the remporary files
        `rm -f $me#$id.sh.o*`;
        `rm -f $me#$id.sh.e*`;
    }
}

sub get_dead_job_info {
    my ($self, $job) = @_;

    my $proc = Proc::Reliable->new();
    $proc->num_tries(3);
    $proc->time_btw_tries(1);
    my ($stdout, $stderr, $status, undef) = $proc->run("tracejob $job->{proc}");
    
    # Parse exit_status
    if($stdout =~ /Exit_status\=(-?\d+)/m) {
        $job->{exitstatus} = $1;
    } 

    if($stdout =~ /resources_used\.walltime\=(\d+)\:(\d+)\:(\d+)/m) {
        my $time = $1 * 3600;
        $time   += $2 * 60;
        $time   += $3;

        $job->{realtime} = parseInterval(seconds => $time, Small => 1);
    }
}

1;
