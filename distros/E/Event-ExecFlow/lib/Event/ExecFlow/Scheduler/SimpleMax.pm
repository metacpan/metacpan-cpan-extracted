package Event::ExecFlow::Scheduler::SimpleMax;

use strict;
use base qw ( Event::ExecFlow::Scheduler );

sub get_max                     { shift->{max}                          }
sub get_cnt                     { shift->{cnt}                          }

sub set_max                     { shift->{max}                  = $_[1] }
sub set_cnt                     { shift->{cnt}                  = $_[1] }

sub new {
    my $class = shift;
    my %par = @_;
    my ($max) = $par{'max'};

    return bless {
        max     => $max,
        cnt     => 0,
    }, $class;
}

sub schedule_job {
    my $self = shift;
    my ($job) = @_;

    my $state;
    if ( $self->get_cnt >= $self->get_max ) {
        $state = 'sched-blocked';
    }
    elsif ( $job->get_type ne 'group' ) {
        ++$self->{cnt};
        $state = 'ok';
    }
    else {
        $state = 'ok';
    }
    
    return $state;
}

sub job_finished {
    my $self = shift;
    my ($job) = @_;
    --$self->{cnt} if $job->get_type ne 'group';
    1;
}

1;

__END__

=head1 NAME

Event::ExecFlow::Scheduler::SimpleMax - Limit number of parallel executed jobs

=head1 SYNOPSIS

  #-- Create a new Scheduler object
  my $scheduler = Event::ExecFlow::Scheduler::SimpleMax->new( max => 5 );

  #-- Attach scheduler to a group job
  $group_job->set_parallel(1);
  $group_job->set_scheduler($scheduler);

=head1 DESCRIPTION

This is a simple scheduler which just limits the maximum number
of parallel executed jobs. It's mainly an example implementation
of the Event::ExecFlow::Scheduler interface, not really of big
practical use ;)

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
