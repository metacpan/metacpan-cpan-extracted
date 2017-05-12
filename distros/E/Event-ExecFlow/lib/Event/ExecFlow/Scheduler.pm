package Event::ExecFlow::Scheduler;

use strict;

sub is_exclusive { 0 }

sub schedule_job { die ref(shift)." missing schedule_job() implementation" }
sub job_finished { die ref(shift)." missing job_finished() implementation" }

1;

__END__

=head1 NAME

Event::ExecFlow::Scheduler - Abstract class for parallel scheduling

=head1 SYNOPSIS

  #-- Create a new Scheduler object
  my $scheduler = Event::ExecFlow::Scheduler::XYZ->new ( ... );

  #-- Attach scheduler to a group job with parallel execution
  $group_job->set_parallel(1);
  $group_job->set_scheduler($scheduler);

  #-- The following methods gets called by Event::ExecFlow
  #-- at runtime
  $scheduler->schedule_job($job);
  $scheduler->job_finished($job);

=head1 DESCRIPTION

This abstract base class represents just an interface which
needs to be implemented by custom schedulers for controlling
the execution of jobs in a Event::ExecFlow::Group which has
the parallel option set.

Event::ExecFlow ships a very simple example for a scheduler
which just limits the maximum number of parallel executed
jobs: Event::ExecFlow::Scheduler::SimpleMax.

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
