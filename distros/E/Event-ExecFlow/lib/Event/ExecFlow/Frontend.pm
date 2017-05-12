package Event::ExecFlow::Frontend;

use strict;
use Carp;

sub new {
    my $class = shift;

    my $self = bless {}, $class;
    
    return $self;
}

sub start_job {
    my $self = shift;
    my ($job) = @_;
    
    $job->set_frontend($self);
    $job->start;

    1;
}

#---------------------------------------------------------------------
# Dummy implementation, needs to by overridden by application class
#---------------------------------------------------------------------

sub report_job_added {
    my $self = shift;
    my ($job) = @_;
    1;
}

sub report_job_start {
    my $self = shift;
    my ($job) = @_;
    1;
}

sub report_job_progress {
    my $self = shift;
    my ($job) = @_;
    1;
}

sub report_job_error {
    my $self = shift;
    my ($job) = @_;
    1;
}

sub report_job_warning {
    my $self = shift;
    my ($job, $message) = @_;
    
    $message ||= $job->get_warning_message;

    1;
}

sub report_job_finished {
    my $self = shift;
    my ($job) = @_;
    1;
}

sub log {
    my $self = shift;
    my ($msg) = @_;
}

1;

__END__

=head1 NAME

Event::ExecFlow::Frontend - Abstract base class for custom frontends

=head1 SYNOPSIS

  #-- Derived from Event::ExecFlow::Frontend
  my $frontend = MyApp::GUI::Frontent->new();
  my $job      = Event::ExecFlow::Job::Command->new ( ... );
  $frontend->start_job($job);

  #-- Later the following methods are called and need to
  #-- by implemented by you
  $frontend->report_job_start($job);
  $frontend->report_job_progress($job);
  $frontend->report_job_error($job);
  $frontend->report_job_warning($job);
  $frontend->report_job_finished($job);
  $frontend->log($message);
  
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
