package Event::ExecFlow::Callbacks;

use strict;

sub get_cb_list                 { shift->{cb_list}                      }
sub set_cb_list                 { shift->{cb_list}              = $_[1] }

sub new {
    my $class = shift;
    my @cb_list = @_;

    my $self = bless {
        cb_list     => \@cb_list,
    }, $class;
    
    return $self;
}

sub prepend {
    my $self = shift;
    my (@cb) = @_;
    
    unshift @{$self->get_cb_list}, @cb;
    
    return $self;
}

sub add {
    my $self = shift;
    my (@cb) = @_;
    
    push @{$self->get_cb_list}, @cb;
    
    return $self;
}

sub execute {
    my $self = shift;
    my ($job) = @_;
    
    foreach my $cb ( @{$self->get_cb_list} ) {
        eval { $cb->(@_) };
print "Catched Callbacks Exception: $@" if $@;
        if ( $@ ) {
            $job->set_error_message($@);
            return 0;
        }
    }
    
        
    1;
}

1;

__END__

=head1 NAME

Event::ExecFlow::Callbacks - Callbacks attached to jobs

=head1 SYNOPSIS

  #-- Create a new Callbacks object
  my $callbacks = Event::ExecFlow::Callbacks->new (
    sub { print "sub called\n" },
    sub { print "another sub of this called\n" },
  );

  #-- Attach callbacks to a job
  $job->set_pre_callbacks($callbacks);
  
  #-- Add more subs
  $callbacks->add(sub { print "a sub added later\n" });
  $callbacks->prepend(sub { print "a sub prepended to the list of subs } );

  #-- the execute() methods is executed later by Event::ExecFlow
  $callbacks->execute($job);
  
=head1 DESCRIPTION

This class represents one or more closures which can be attached as
callbacks to an Event::ExecFlow::Job.

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
