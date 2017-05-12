package Event::ExecFlow::Job;

use strict;
use Carp;

use Locale::TextDomain $Event::ExecFlow::locale_textdomain;

sub get_id                      { shift->{id}                           }
sub get_title                   { shift->{title}                        }
sub get_name                    { shift->{name}                         }
sub get_depends_on              { shift->{depends_on}                   }
sub get_state                   { shift->{state}                        }
sub get_cancelled               { shift->{cancelled}                    }
sub get_error_message           { shift->{error_message}                }
sub get_warning_message         { shift->{warning_message}              }
sub get_progress_max            { shift->{progress_max}                 }
sub get_progress_cnt            { shift->{progress_cnt}                 }
sub get_progress_start_time     { shift->{progress_start_time}          }
sub get_progress_end_time       { shift->{progress_end_time}            }
sub get_progress_ips            { shift->{progress_ips}                 }
sub get_no_progress             { shift->{no_progress}                  }
sub get_last_progress           { shift->{last_progress}                }
sub get_last_percent_logged     { shift->{last_percent_logged}          }
sub get_pre_callbacks           { shift->{pre_callbacks}                }
sub get_post_callbacks          { shift->{post_callbacks}               }
sub get_error_callbacks         { shift->{error_callbacks}              }
sub get_warning_callbacks       { shift->{warning_callbacks}            }
sub get_frontend                { shift->{frontend}                     }
sub get_group                   { shift->{group}                        }
sub get_diskspace_consumed      { shift->{diskspace_consumed}           }
sub get_diskspace_freed         { shift->{diskspace_freed}              }
sub get_stash                   { shift->{stash}                        }
sub get_paused                  { shift->{paused}                       }
sub get_paused_seconds          { shift->{paused_seconds}               }
sub get_paused_start_time       { shift->{paused_start_time}            }
sub get_skipped                 { shift->{skipped}                      }

sub set_title                   { shift->{title}                = $_[1] }
sub set_name                    { shift->{name}                 = $_[1] }
sub set_state                   { shift->{state}                = $_[1] }
sub set_error_message           { shift->{error_message}        = $_[1] }
sub set_warning_message         { shift->{warning_message}      = $_[1] }
sub set_progress_max            { shift->{progress_max}         = $_[1] }
sub set_progress_cnt            { shift->{progress_cnt}         = $_[1] }
sub set_progress_start_time     { shift->{progress_start_time}  = $_[1] }
sub set_progress_end_time       { shift->{progress_end_time}    = $_[1] }
sub set_progress_ips            { shift->{progress_ips}         = $_[1] }
sub set_no_progress             { shift->{no_progress}          = $_[1] }
sub set_last_progress           { shift->{last_progress}        = $_[1] }
sub set_last_percent_logged     { shift->{last_percent_logged}  = $_[1] }
sub set_pre_callbacks           { shift->{pre_callbacks}        = $_[1] }
sub set_post_callbacks          { shift->{post_callbacks}       = $_[1] }
sub set_error_callbacks         { shift->{error_callbacks}      = $_[1] }
sub set_warning_callbacks       { shift->{warning_callbacks}    = $_[1] }
sub set_frontend                { shift->{frontend}             = $_[1] }
sub set_group                   { shift->{group}                = $_[1] }
sub set_diskspace_consumed      { shift->{diskspace_consumed}   = $_[1] }
sub set_diskspace_freed         { shift->{diskspace_freed}      = $_[1] }
sub set_stash                   { shift->{stash}                = $_[1] }
sub set_paused                  { shift->{paused}               = $_[1] }
sub set_paused_seconds          { shift->{paused_seconds}       = $_[1] }
sub set_paused_start_time       { shift->{paused_start_time}    = $_[1] }
sub set_skipped                 { shift->{skipped}              = $_[1] }

sub set_depends_on {
    my $self = shift;
    my ($jobs_lref) = @_;
    
    my @job_names = map { ref $_ ? $_->get_name : $_ } @{$jobs_lref};
    $self->{depends_on} = \@job_names;
    
    return \@job_names;
}

sub set_cancelled {
    my $self = shift;
    my ($cancelled) = @_;
    $self->{cancelled} = $cancelled;
    $self->set_state($cancelled ? "cancelled":"waiting");
    return $cancelled;
}

sub finished_ok {
    my $self = shift;
    return !$self->get_cancelled &&
           !$self->get_error_message;
}

my $JOB_ID = (time - 1140691085) * 1_000_000;

sub new {
    my $class = shift;
    my %par = @_;
    my  ($title, $name, $depends_on, $pre_callbacks) =
    @par{'title','name','depends_on','pre_callbacks'};
    my  ($post_callbacks, $error_callbacks, $warning_callbacks) =
    @par{'post_callbacks','error_callbacks','warning_callbacks'};
    my  ($progress_cnt, $progress_max, $progress_ips, $no_progress) =
    @par{'progress_cnt','progress_max','progress_ips','no_progress'};
    my  ($diskspace_consumed, $diskspace_freed, $stash, $frontend) =
    @par{'diskspace_consumed','diskspace_freed','stash','frontend'};

    my $id = ++$JOB_ID;

    $depends_on ||= [];
    $stash      ||= {};
    $name       ||= '~'.$id;

    croak "Job '$name' depends on itself"
        if grep { $_ eq $name } @{$depends_on};

    for my $cb ( $pre_callbacks,   $post_callbacks,
                 $error_callbacks, $warning_callbacks ) {
        $cb ||= Event::ExecFlow::Callbacks->new;
        $cb   = Event::ExecFlow::Callbacks->new($cb) if ref $cb eq 'CODE';
    }

    my $self = bless {
        id                      => $id,
        title                   => $title,
        name                    => $name,
        depends_on              => $depends_on,
        state                   => 'waiting',
        diskspace_consumed      => $diskspace_consumed,
        diskspace_freed         => $diskspace_freed,
        progress_cnt            => $progress_cnt,
        progress_max            => $progress_max,
        progress_ips            => $progress_ips,
        no_progress             => $no_progress,
        pre_callbacks           => $pre_callbacks,
        post_callbacks          => $post_callbacks,
        error_callbacks         => $error_callbacks,
        warning_callbacks       => $warning_callbacks,
        stash                   => $stash,
        frontend                => $frontend,
        paused_seconds          => 0,
        last_percent_logged     => 0,
        group                   => undef,
    }, $class;
    
    $self->set_depends_on($depends_on);
    
    return $self;
}

sub init {
    my $self = shift;
    
    return if $self->get_state ne 'waiting' &&
              $self->get_state ne 'running';
    
    $self->set_state("waiting");
    $self->set_progress_start_time(time);
    $self->set_progress_end_time();
    $self->set_cancelled();
    $self->set_error_message();
    $self->set_last_percent_logged(0);
    $self->set_last_progress();
    $self->set_progress_cnt(0);

    1;
}

sub start {
    my $self = shift;
    
    $Event::ExecFlow::DEBUG && print "Job->start(".$self->get_info.")\n";

    if ( !$self->get_frontend ) {
        require Event::ExecFlow::Frontend;
        $self->set_frontend(Event::ExecFlow::Frontend->new);
    }
    
    $self->init;
    $self->set_state("running");

    $self->get_frontend->report_job_start($self);
    
    $self->get_pre_callbacks->execute($self);
    
    if ( $self->get_error_message ) {
        $self->execution_finished;
        return 0;
    }
    
    if ( $self->get_warning_message ) {
        $self->get_warning_callbacks->execute($self);
        $self->get_frontend->report_job_warning($self);
    }

    if ( $self->get_skipped ) { # may be set by pre_callbacks
        $self->execution_finished;
        return 0;
    }

    $self->execute;
    
    1;
}

sub reset {
    my $self = shift;
    
    return if $self->get_state eq 'running' or
              $self->get_state eq 'waiting';
    
    $self->set_state("waiting");
    $self->set_progress_start_time();
    $self->set_progress_end_time();
    $self->set_cancelled();
    $self->set_error_message();
    $self->set_last_percent_logged(0);
    $self->set_last_progress();
    $self->set_progress_cnt(0);
    
    $self->get_frontend->report_job_progress($self);

    1;
}

sub cancel {
    die "Missing implementation for method cancel() of object ".shift;
}

sub execute {
    die "Missing implementation for method execute() of object ".shift;
}

sub pause {
    my $self = shift;
    
    $self->set_paused(!$self->get_paused);
    $self->pause_job;

    if ( $self->get_paused ) {
        $self->set_paused_start_time(time);
    }
    else {
        my $start_time = $self->get_paused_start_time;
        my $duration   = time - $start_time;
        $self->set_paused_seconds($duration + $self->get_paused_seconds);
        $self->set_paused_start_time();
    }

    1;    
}

sub execution_finished {
    my $self = shift;

    $Event::ExecFlow::DEBUG && print "Job->execution_finished(".$self->get_info.")\n";

    $self->set_progress_end_time(time);
    $self->get_frontend->report_job_progress($self);

    if ( !$self->get_cancelled ) {
        if ( $self->get_error_message ) {
            $self->set_state("error");
        }
        else {
            $self->set_state("finished");
        }
    }

    $self->get_post_callbacks->execute($self);

    $self->set_state("error") if $self->get_error_message;

    $self->get_frontend->report_job_finished($self);

    if ( !$self->get_cancelled ) {
        if ( $self->get_error_message ) {
            $self->get_error_callbacks->execute($self);
            $self->get_frontend->report_job_error($self);
        }        

        if ( $self->get_warning_message ) {
            $self->get_warning_callbacks->execute($self);
            $self->get_frontend->report_job_warning($self);
        }
    }

    if ( $self->get_type ne 'group' and $self->get_state eq 'finished' ) {
        my $parent = $self;
        while ( $parent = $parent->get_group ) {
            $parent->set_progress_cnt($parent->get_progress_cnt+1);
            $self->get_frontend->report_job_progress($parent);
        }
    }

    1;
}

sub emit_warning_message {
    my $self = shift;
    my ($warning) = @_;
    
    $self->get_frontend->report_job_warning($self, $warning);
    
    1;
}

sub get_job_cnt { 1 }

sub get_info {
    my $self = shift;
    return $self->get_title || $self->get_name || "Unnamed";
}

sub get_progress_fraction {
    my $self = shift;
    my $max = $self->get_progress_max || 0;
    my $cnt = $self->get_progress_cnt || 0;
    return $max == 0 ? 0 : $cnt / $max;
}

sub get_progress_percent {
    my $self = shift;
    return sprintf("%.2f", 100 * $self->get_progress_fraction);
}

sub get_progress_text {
    my $self = shift;
    return $self->get_info.": ".$self->get_progress_stats;
}

sub get_progress_stats {
    my $self = shift;

    my $cancelled = $self->get_cancelled ? "[".__("Cancelled")."]" : "";
    $cancelled  ||= $self->get_error_message ? "[".__("Error")."]" : "";
    $cancelled  ||= $self->get_skipped ? "[".__("Skipped")."]" : "";

    return __("Waiting")." ".$cancelled if $self->get_state eq 'waiting';

    my $cnt       = $self->get_progress_cnt;
    my $max       = $self->get_progress_max || 1;
    my $time      = ( time - $self->get_progress_start_time
                           - $self->get_paused_seconds );
    my $ips_label = $self->get_progress_ips;
    my $ips       = "";

    if ( $self->get_progress_end_time ) {
        $time = $self->get_progress_end_time
              - $self->get_progress_start_time
              - $self->get_paused_seconds;
        my $text = __x( "Duration: {time}", time => $self->format_time($time) );
        if ( $ips_label ) {
            $time ||= 1;
            $text .= ", $ips_label: ".sprintf( "%2.1f", $cnt / $time );
        }
        return $text." ".$cancelled;
    }

    return $cancelled if $self->get_no_progress;
    return __("Initializing")." ".$cancelled if ! defined $cnt;

    $ips = sprintf( ", %2.1f $ips_label", $cnt / $time )
        if $ips_label && $time;

    my $elapsed = "";
    $elapsed = ", "
        . __x( "elapsed {time}", time => $self->format_time($time) )
            if $self->get_type ne 'group';

    my $percent = $self->get_progress_percent.'%';
    $percent .= __" finished" if $self->get_type eq 'group';

    my $eta = "";
    $eta = ", ETA: "
        . $self->format_time( int( $time * $max / $cnt ) - $time + 1 )
        if $time > 5 && $cnt != 0 && $self->get_type ne 'group';

    my $int_percent = int( $cnt / $max * 100 );

    if ( $int_percent > $self->get_last_percent_logged + 10 ) {
        $int_percent = int( $int_percent / 10 ) * 10;
        $self->set_last_percent_logged($int_percent);
        my $line = $self->get_info . ": "
                . __x( "{percent}PERCENT done.",
                percent => $int_percent );
        $line =~ s/PERCENT/%/;
        $self->log($line);
    }

    $cancelled = " ".$cancelled if $cancelled;

    return "$percent$ips$elapsed$eta$cancelled";
}

sub format_time {
    my $self = shift;
    my ($time) = @_;

    my ($h, $m, $s);
    $h = int($time/3600);
    $m = int(($time-$h*3600)/60);
    $s = $time % 60;

    return sprintf ("%02d:%02d", $m, $s) if $h == 0;
    return sprintf ("%02d:%02d:%02d", $h, $m, $s);
}

sub log {
    my $self = shift;
    $self->get_frontend->log(@_);
    1;
}

sub progress_has_changed {
    my $self = shift;

    my $last_progress = $self->get_last_progress||"";
    my $curr_progress = $self->get_progress_cnt."/".$self->get_progress_max;

    if ( $last_progress ne $curr_progress ) {
        $self->set_last_progress($curr_progress);
        return 1;
    }
    else {
        return 0;
    }

}

sub frontend_signal {
    my $self = shift;
    my ($signal, @args) = @_;
    
    my $method = "signal_$signal";
    $self->get_frontend->$method(@args);
    
    1;
}

sub get_max_diskspace_consumed {
    my $self = shift;
    my ($currently_consumed, $max_consumed) = @_;

    $currently_consumed += $self->get_diskspace_consumed;

    if ( $currently_consumed > $max_consumed ) {
        $max_consumed = $currently_consumed;
    }

    $currently_consumed -= $self->get_diskspace_freed;
    
    return ($currently_consumed, $max_consumed);
}

sub backup_state {
    my $self = shift;
    
    my %data = %{$self};
    
    delete @data{
        qw(
            pre_callbacks
            post_callbacks
            error_callbacks
            warning_callbacks
            frontend
            group
            _post_callbacks_added
        )
    };

    $data{type} = $self->get_type;

    return \%data;
}

sub restore_state {
    my $self = shift;
    my ($data_href) = @_;
    
    if ( $data_href->{type} ne $self->get_type ) {
        die "Can't restore job state due to data type mismatch: ".
            "Job type=".$self->get_type.", ".
            "Data type=".$data_href->{type};
    }

    foreach my $key ( keys %{$data_href} ) {
        $self->{$key} = $data_href->{$key};
    }

    delete $self->{type};

    $self->set_state("waiting")
        if $self->get_state eq 'running';
    
    1;
}

sub add_stash {
    my $self = shift;
    my ($add_stash) = @_;
    
    my $stash = $self->get_stash;
    
    while ( my ($k, $v) = each %{$add_stash} ) {
        $stash->{$k} = $v;
    }
    
    1;
}

sub get_job_with_id {
    my $self = shift;
    my ($job_id) = @_;
    return $self if $job_id eq $self->get_id;
    return;
}

1;

__END__

=head1 NAME

Event::ExecFlow::Job - Abstract base class for all job classes

=head1 SYNOPSIS

  Event::ExecFlow::Job->new (
    title                => Descriptive title,
    name                 => Internal short name,
    depends_on           => Names of jobs, this job depends on,
    progress_max         => Maximum expected progress value,
    progress_ips         => String to show as "items per second",
    no_progress          => Job has no progress state at all,
    pre_callbacks        => Callbacks executed before job starts,
    post_callbacks       => Callbacks executed after job finished,
    error_callbacks      => Callbacks executed if job had errors,
    warning_callbacks    => Callbacks executed if job had warnings,
    stash                => A custom data hash stored with the job,
  );

=head1 DESCRIPTION

This is an abstract base class and usually not used directly from the
application. For daily programming the attributes defined in this
class are most important, since they are common to all Jobs of the
Event::ExecFlow framework.

=head1 OBJECT HIERARCHY

  Event::ExecFlow

  Event::ExecFlow::Job
  +--- Event::ExecFlow::Job::Group
  +--- Event::ExecFlow::Job::Command
  +--- Event::ExecFlow::Job::Code

  Event::ExecFlow::Frontend
  Event::ExecFlow::Callbacks
  Event::ExecFlow::Scheduler
  +--- Event::ExecFlow::Scheduler::SimpleMax

=head1 ATTRIBUTES

Attributes may be set with the new() constructor passed as a hash and
accessed at runtime using the common get_ATTR(), set_ATTR()
style accessors.

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
