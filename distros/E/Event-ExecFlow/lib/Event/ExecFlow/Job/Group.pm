package Event::ExecFlow::Job::Group;

use base qw( Event::ExecFlow::Job );

use strict;
use Scalar::Util qw(weaken);

sub get_type                    { "group" }

sub get_jobs                    { shift->{jobs}                         }
sub get_fail_with_members       { shift->{fail_with_members}            }
sub get_stop_on_failure         { shift->{stop_on_failure}              }
sub get_parallel                { shift->{parallel}                     }
sub get_scheduler               { shift->{scheduler}                    }
sub get_member_finished_callbacks { shift->{member_finished_callbacks}  }

sub set_jobs                    { shift->{jobs}                 = $_[1] }
sub set_fail_with_members       { shift->{fail_with_members}    = $_[1] }
sub set_stop_on_failure         { shift->{stop_on_failure}      = $_[1] }
sub set_parallel                { shift->{parallel}             = $_[1] }
sub set_member_finished_callbacks { shift->{member_finished_callbacks} = $_[1] }

sub new {
    my $class = shift;
    my %par = @_;
    my  ($jobs, $fail_with_members, $stop_on_failure) =
    @par{'jobs','fail_with_members','stop_on_failure'};
    my  ($parallel, $scheduler, $member_finished_callbacks) =
    @par{'parallel','scheduler','member_finished_callbacks'};

    $jobs              = [] unless defined $jobs;
    $fail_with_members = 1  unless defined $fail_with_members;
    $stop_on_failure   = 1  unless defined $stop_on_failure;

    my $self = $class->SUPER::new(@_);

    for my $cb ( $member_finished_callbacks ) {
        $cb ||= Event::ExecFlow::Callbacks->new;
        $cb   = Event::ExecFlow::Callbacks->new($cb) if ref $cb eq 'CODE';
    }

    $self->set_jobs($jobs);
    $self->set_fail_with_members($fail_with_members);
    $self->set_stop_on_failure($stop_on_failure);
    $self->set_parallel($parallel);
    $self->set_scheduler($scheduler);
    $self->set_member_finished_callbacks($member_finished_callbacks);

    return $self;
}

sub set_frontend {
    my $self = shift;
    my ($frontend) = @_;
    
    $self->SUPER::set_frontend($frontend);

    $_->set_frontend($frontend) for @{$self->get_jobs};
   
    return $frontend;
}

sub set_scheduler {
    my $self = shift;
    my ($scheduler) = @_;
    
    $self->{scheduler} = $scheduler;
    
    foreach my $job ( @{$self->get_jobs} ) {
        $job->set_scheduler($scheduler)
            if $job->get_type eq 'group';
    }
    
    return $scheduler;
}

sub get_exec_type {
    my $self = shift;
    my $job = $self->get_next_job;
    return "sync" if not $job;
    return $job->get_exec_type;
}

sub get_diskspace_consumed {
    my $self = shift;
    
    my $sum = $self->SUPER::get_diskspace_consumed;
    
    $sum += $_->get_diskspace_consumed for @{$self->get_jobs};
    
    return $sum;
}

sub get_diskspace_freed {
    my $self = shift;
    
    my $sum = $self->SUPER::get_diskspace_freed;
    
    $sum += $_->get_diskspace_freed for @{$self->get_jobs};
    
    return $sum;
}

sub init {
    my $self = shift;

    $self->SUPER::init();

    foreach my $job ( @{$self->get_jobs} ) {
        $job->set_group($self);
        weaken($job->{group});
        $self->add_child_post_callback($job);
    }

    $self->set_progress_max($self->get_job_cnt);

    1;
}

sub reset_non_finished_jobs {
    my $self = shift;
    
    if ( $self->get_state ne 'finished' ) {
        $self->set_state("waiting");
        $self->set_cancelled(0);
        $self->set_error_message();
        $self->get_frontend->report_job_progress($self);
    }
    
    foreach my $job ( @{$self->get_jobs} ) {
        if ( $job->get_state ne 'finished' ) {
            $job->set_state("waiting");
            $job->set_cancelled(0);
            $job->set_error_message();
            $self->get_frontend->report_job_progress($job);
        }
        $job->reset_non_finished_jobs if $job->get_type eq 'group';
    }

    1;
}

sub get_job_cnt {
    my $self = shift;

    my $cnt = 0;
    foreach my $job ( @{$self->get_jobs} ) {
        $cnt += $job->get_job_cnt;
    }
    
    return $cnt;
}

sub init_progress_state {
    my $self = shift;
    
    my $progress_cnt = 0;
    foreach my $job ( @{$self->get_jobs} ) {
        if ( $job->get_type eq 'group' ) {
            $job->init_progress_state;
            $progress_cnt += $job->get_progress_cnt;
        }
        else {
            ++$progress_cnt if $job->get_state eq 'finished' ||
                               $job->get_state eq 'error';
        }
    }

    $self->set_progress_cnt($progress_cnt);
    $self->set_progress_max($self->get_job_cnt);

    $self->set_state("finished")
        if $self->get_progress_cnt == $self->get_progress_max;

    1;
}

sub set_group_in_all_childs {
    my $self = shift;

    foreach my $job ( @{$self->get_jobs} ) {
        if ( $job->get_type eq 'group' ) {
            $job->set_group($self);
            weaken($job->{group});
            $job->set_group_in_all_childs;
        }
        else {
            $job->set_group($self);
            weaken($job->{group});
        }
    }

    1;
}

sub increase_progress_max {
    my $self = shift;
    my ($add) = @_;

    my $job = $self;
    while ( $job ) {
        $job->set_progress_max($job->get_progress_max + $add);
        $job = $job->get_group;
    }

    1;
}

sub decrease_progress_max {
    my $self = shift;
    my ($del) = @_;

    my $job = $self;
    while ( $job ) {
        $job->set_progress_max($job->get_progress_max - $del);
        $job = $job->get_group;
    }
    
    1;
}

sub increase_progress_cnt {
    my $self = shift;
    my ($add) = @_;

    my $job = $self;
    while ( $job ) {
        $job->set_progress_cnt($job->get_progress_cnt + $add);
        $job = $job->get_group;
    }

    1;
}

sub decrease_progress_cnt {
    my $self = shift;
    my ($del) = @_;

    my $job = $self;
    while ( $job ) {
        $job->set_progress_cnt($job->get_progress_cnt - $del);
        $job = $job->get_group;
    }
    
    1;
}

sub add_job {
    my $self = shift;
    my ($job) = @_;
    
    push @{$self->get_jobs}, $job;
    
    $job->set_frontend($self->get_frontend);
    $job->set_group($self);
    weaken($job->{group});

    my $job_cnt = $job->get_job_cnt;
    $self->increase_progress_max($job_cnt) if $job_cnt != 0;

    if ( $self->get_state eq 'finished' ||
         $self->get_state eq 'error' ) {
        $self->set_state("waiting");
    }

    $self->add_child_post_callback($job);

    $self->get_frontend->report_job_added($job);

    1;
}

sub remove_job {
    my $self = shift;
    my ($job) = @_;
    
    my $jobs = $self->get_jobs;
    
    my $i;
    for ( $i=0; $i < @{$jobs}; ++$i ) {
        last if $jobs->[$i] eq $job;
    }
    
    die "Job with ID ".$job->get_id." no member of this group"
        if $i == @{$jobs};

    splice @{$jobs}, $i, 1;

    my $job_cnt = $job->get_job_cnt;
    $self->decrease_progress_max($job_cnt) if $job_cnt != 0;

    $self->get_frontend->report_job_removed($job);

    1;
}

sub get_job_by_name {
    my $self = shift;
    my ($job_name) = @_;
    
    foreach my $job ( @{$self->get_jobs} ) {
        return $job if $job->get_name eq $job_name;
    }
    
    die "Job '$job_name' not member of group '".$self->get_name."'";
}

sub execute {
    my $self = shift;
    my %par = @_;
    my ($skip) = $par{'skip'};
    
    $skip = "" if ! defined $skip;

    my $blocked_job;
    while ( 1 ) {
        if (      $self->get_cancelled
             ||   $self->all_jobs_finished
             || ( $self->get_error_message &&
                  $self->get_stop_on_failure ) ) {
            $self->execution_finished;
            if ( $self->get_scheduler &&
                 $self->get_scheduler->is_exclusive ) {
                $self->get_scheduler->run;
            }
            return;
        }

        return if $self->get_scheduler &&
                  $self->get_scheduler->is_exclusive;
    
        my $job = $self->get_next_job(blocked=>$blocked_job);
        next if defined $job && "$job" eq "$skip";

        if ( !$job ) {
            $self->try_reschedule_jobs(skip => $skip);
            last;
        }

        if ( $self->get_scheduler ) {
            my $state = $self->get_scheduler->schedule_job($job);
            return if $state eq 'sched-blocked';
            if ( $state eq 'job-blocked' ) {
                $blocked_job = $job;
                next;
            }
            die "Illegal scheduler state '$state'"
                unless $state eq 'ok';
        }

        $self->start_child_job($job);

        last if !$self->get_parallel;
    }
    
    1;    
}

sub try_reschedule_jobs {
    my $self = shift;
    my %par = @_;
    my ($skip) = $par{'skip'};

    my $executed = 0;
    foreach my $job ( @{$self->get_jobs} ) {
        next if "$job" eq "$skip";

        # Parallel execution groups which are running now
        # probably can execute more job, so give it a try.
        if ( $job->get_type  eq 'group'   &&
             $job->get_state eq 'running' &&
             $job->get_parallel ) {
            $job->execute;
            $executed = 1;
        }
    }
    
    if ( !$executed && $self->get_group ) {
        $self->get_group->execute(skip => $self);
    }
    
    1;
}

sub cancel {
    my $self = shift;
    
    $self->set_cancelled(1);
    $_->get_state eq 'running' && $_->cancel for @{$self->get_jobs};
    
    1;
}

sub pause_job {
    my $self = shift;
    
    $_->get_state eq 'running' && $_->pause for @{$self->get_jobs};
    
    1;
}

sub reset {
    my $self = shift;
    
    foreach my $job ( @{$self->get_jobs} ) {
        if ( $job->reset ) {
            $self->decrease_progress_cnt($job->get_job_cnt);
        }
    }
    
    $self->get_frontend->report_job_progress($self);

    return $self->SUPER::reset() if $self->get_progress_cnt == 0;

    0;
}

sub add_child_post_callback {
    my $self = shift;
    my ($job) = @_;
    
    if ( $job->{_post_callbacks_added} ) {
return;
        require Carp;
        Carp::confess($job->get_info.": callbacks added twice!");
    }
    $job->{_post_callbacks_added} = 1;
    
    $job->get_post_callbacks->add( sub {
        my ($job) = @_;
        $self->child_job_finished($job);
        1;
    });

    1;
}

sub start_child_job {
    my $self = shift;
    my ($job) = @_;
    
    $Event::ExecFlow::DEBUG && print "Group->start_child_job(".$job->get_info.")\n";

    $self->set_progress_cnt(0) unless defined $self->get_progress_cnt;
    $self->get_frontend->report_job_progress($self);

    $job->start;

    1;
}

sub child_job_finished {
    my $self = shift;
    my ($job) = @_;
    
    $Event::ExecFlow::DEBUG && print "Group->child_job_finished(".$job->get_info.")\n";

    $self->get_member_finished_callbacks->execute()
        if $self->get_member_finished_callbacks;

    if ( $job->get_error_message && !$job->get_cancelled ) {
        if  ( $self->get_fail_with_members ) {
            $self->set_state("error");
            $self->add_job_error_message($job);
            $self->get_frontend->report_job_error($self);
        }
    }

    if ( $self->get_scheduler ) {
        $self->get_scheduler->job_finished($job);
    }

    $self->execute;

    1;
}

sub add_job_error_message {
    my $self = shift;
    my ($job) = @_;

    my $error_message = $self->get_error_message || "";

    $error_message .=
        "Job '".$job->get_info."' ".
        "failed with error message:\n".
        $job->get_error_message."\n".
        ("-"x80)."\n";

    $self->set_error_message($error_message);

    1;
}

sub get_first_job {
    my $self = shift;
    return $self->get_jobs->[0];
}

sub get_next_job {
    my $self = shift;
    my %par = @_;
    my ($blocked) = $par{'blocked'};

    $blocked = "" if ! defined $blocked;

    my $next_job;    
    foreach my $job ( @{$self->get_jobs} ) {
        next if defined $job && "$job" eq "$blocked";
        $Event::ExecFlow::DEBUG && print "Group(".$self->get_info.")->get_next_job: check ".$job->get_info."=>".$job->get_state."\n";
        if ( $job->get_state eq 'waiting' &&
             $self->dependencies_ok($job) ) {
            $next_job = $job;
            last;
        }
    }
    
    $Event::ExecFlow::DEBUG && print "Group(".$self->get_info.")->get_next_job=".
        ($next_job ? $next_job->get_info : "NOJOB")."\n";
    
    return $next_job;
}

sub dependencies_ok {
    my $self = shift;
    my ($job) = @_;

    foreach my $dep_job_name ( @{$job->get_depends_on} ) {
        my $dep_job = $self->get_job_by_name($dep_job_name);
        $Event::ExecFlow::DEBUG && print "Job(".$job->get_info.")->dependencies_ok: check ".$dep_job->get_info." =>".$dep_job->get_state."\n";
        return if $dep_job->get_state ne 'finished';
    }

    return 1;    
}

sub all_jobs_finished {
    my $self = shift;

    foreach my $job ( @{$self->get_jobs} ) {
        return 0 if $job->get_state eq 'waiting' ||
                    $job->get_state eq 'error' ||
                    $job->get_state eq 'running';
    }
    
    return 1;
}

sub get_max_diskspace_consumed {
    my $self = shift;
    my ($currently_consumed, $max_consumed) = @_;

    foreach my $job ( @{$self->get_jobs} ) {
        ($currently_consumed, $max_consumed) =
            $job->get_max_diskspace_consumed
                ($currently_consumed, $max_consumed);
    }

    return ($currently_consumed, $max_consumed);
}

sub backup_state {
    my $self = shift;
    
    my $data_href = $self->SUPER::backup_state();
    
    delete $data_href->{jobs};
    delete $data_href->{scheduler};
    delete $data_href->{member_finished_callbacks};

    my $jobs = $self->get_jobs;
    foreach my $job ( @{$jobs} ) {
        push @{$data_href->{jobs}}, 
            $job->backup_state;
    }
    
    return $data_href;
}

sub restore_state {
    my $self = shift;
    my ($data_href) = @_;

    my $jobs = $self->get_jobs;
    
    $self->SUPER::restore_state($data_href);
    
    my $job_states = delete $self->{jobs};

    my $i = 0;
    foreach my $job ( @{$jobs} ) {
        $job->restore_state($job_states->[$i]);
        ++$i;
    }
    
    $self->set_jobs($jobs);

    1;
}

sub add_stash_to_all_jobs {
    my $self = shift;
    my ($add_stash) = @_;

    $self->add_stash($add_stash);
    
    foreach my $job ( @{$self->get_jobs} ) {
        if ( $job->get_type eq 'group' ) {
            $job->add_stash_to_all_jobs($add_stash);
        }
        else {
            $job->add_stash($add_stash);
        }
    }
}

sub traverse_all_jobs {
    my $self = shift;
    my ($code) = @_;

    foreach my $job ( @{$self->get_jobs} ) {
        $code->($job);
        if ( $job->get_type eq 'group' ) {
            $job->traverse_all_jobs($code);
        }
    }

    1;    
}

sub get_job_with_id {
    my $self = shift;
    my ($job_id) = @_;
    
    my $job;
    $self->traverse_all_jobs(sub{
        $job = $_[0] if $_[0]->get_id eq $job_id;
    });

    return $job;
}

1;

__END__

=head1 NAME

Event::ExecFlow::Job::Group - Build a group of jobs

=head1 SYNOPSIS

  Event::ExecFlow::Job::Group->new (
    jobs              => List of job group members,
    fail_with_members => Boolean whether group should fail with its members,
    stop_on_failure   => Boolean whether execuction should stop on failure,
    parallel          => Boolean whether members may be executed in parallel,
    scheduler         => Scheduler object for add. control of par. execution,
    ...
    Event::ExecFlow::Job attributes
  );

=head1 DESCRIPTION

Use this module to group together jobs of any type, including groups,
which results in arbitrary complex nested job plans.

=head1 OBJECT HIERARCHY

  Event::ExecFlow

  Event::ExecFlow::Job
  +--- Event::ExecFlow::Job::Group

  Event::ExecFlow::Frontend
  Event::ExecFlow::Callbacks

=head1 ATTRIBUTES

Attributes can by accessed at runtime using the common get_ATTR(),
set_ATTR() style accessors.

[ FIXME: describe all attributes in detail ]

=head1 METHODS

[ FIXME: describe all methods in detail ]

=head1 AUTHORS

 Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2006 by Jörn Reder.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Library General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307
USA.

=cut
