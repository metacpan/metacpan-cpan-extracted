package Event::ExecFlow::Frontend::Term;

use base qw( Event::ExecFlow::Frontend );

use AnyEvent;
use strict;

sub get_quiet                   { shift->{quiet}                        }
sub get_nl_needed               { shift->{nl_needed}                    }

sub set_quiet                   { shift->{quiet}                = $_[1] }
sub set_nl_needed               { shift->{nl_needed}            = $_[1] }

sub start_job {
    my $self = shift;
    my ($job) = @_;

    my $w = AnyEvent->condvar;
    $job->get_post_callbacks->add(sub { $w->broadcast });
    $self->SUPER::start_job($job);
    $w->wait;

    1;
}

sub report_job_start {
    my $self = shift;
    my ($job) = @_;

    return if $self->get_quiet;

    $self->new_line;

    print "START    [".$job->get_name."]: ".
          $job->get_progress_text."\n";

    1;
}

sub report_job_progress {
    my $self = shift;
    my ($job) = @_;

    return if $self->get_quiet;

    print "PROGRESS [".$job->get_name."]: ".
          $job->get_progress_text."        \r";

    $self->set_nl_needed(1);

    1;
}

sub report_job_error {
    my $self = shift;
    my ($job) = @_;

    return if $self->get_quiet;

    $self->new_line;

    print "ERROR   [".$job->get_name."]:\n".
          $job->get_error_message."\n";
    
    1;
}

sub report_job_warning {
    my $self = shift;
    my ($job, $message) = @_;
    
    $message ||= $job->get_warning_message;

    $self->new_line;

    print "WARNING [".$job->get_name."]: $message\n";

    1;
}

sub report_job_finished {
    my $self = shift;
    my ($job) = @_;

    return if $self->get_quiet and $job->get_state eq 'finished';
    
    $self->new_line;

    print "\nFINISHED [".$job->get_name."]: ";
    
    print $job->get_cancelled     ? "CANCELLED\n" :
          $job->get_error_message ? "ERROR\n" :
                                    "OK\n";

    1;
}

sub new_line {
    my $self = shift;

    if ( $self->get_nl_needed ) {
        print "\n";
        $self->set_nl_needed(0);
    }

    1;
}

sub log {
    my $self = shift;
    my ($msg) = @_;
    return;
    print "LOG       $msg\n";
    1;
}

1;
