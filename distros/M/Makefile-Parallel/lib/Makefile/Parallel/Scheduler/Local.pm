package Makefile::Parallel::Scheduler::Local;

use base qw(Makefile::Parallel::Scheduler);

use strict;
use warnings;
use Cwd;
use Proc::Simple;
use Data::Dumper;

sub new {
    my ($class, $self) = @_;

    $self ||= {};
    $self->{running} = 0;
    $self->{max}   ||= 1;

    bless $self, $class;
}

sub launch {
    my ($self, $job, $debug) = @_;

    my $me = `whoami`;
    chomp($me);

    my $temp = "/tmp/$me#$job->{rule}{id}";
    open F, ">$temp";

    # Number of cpus
    $job->{cpus} ||= 1;

    # Launch the process
    my $proc = Proc::Simple->new();
    if    ($job->{action}[0]{shell}) {
	print F "#!/bin/sh\n";

        print F "#PBS -l walltime=$job->{walltime}\n";
	print F "#PBS -l nodes=1:ppn=$job->{cpus}\n";
        print F "#\n";

	print F "cd " . cwd() . "\n";	
        print F join("\n",map { $_->{shell} ? ($_->{shell}):() } @{$job->{action} });
	close F;

        $proc->start("/bin/sh $temp");
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

        $proc->start("/usr/bin/perl $temp");
    }

    # If we are in debug mode, copy the file to log dir
    `cp $temp log/$me#$job->{rule}{id}.sh` if $debug;

    $job->{proc} = $proc;
    $job->{temp} = $temp;

    $self->{running}++;
}

sub poll {
    my ($self, $job, $logger) = @_;

    my $res = $job->{proc}->poll();

    $self->{running}-- unless $res;
    return $res;
}

sub interrupt {
    my ($self, $job) = @_;

    $self->{running}--;
    $job->{proc}->kill();
}

sub get_id {
    my ($self, $job) = @_;

    $job->{proc}->pid;
}

sub can_run {
    my ($self) = @_;

    $self->{running} != $self->{max};
}

sub clean {
    my ($self, $queue) = @_;

    for my $job (@{$queue}) {
	unlink $job->{temp} if $job->{temp};
    }
    return;
}

sub get_dead_job_info {
    my ($self, $job) = @_;

    $job->{exitstatus} = $job->{proc}->exit_status();
    # TODO: get realtime.. it's not too difficult
}

1;
