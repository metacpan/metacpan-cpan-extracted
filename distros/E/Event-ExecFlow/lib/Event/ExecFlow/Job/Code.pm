package Event::ExecFlow::Job::Code;

use base qw( Event::ExecFlow::Job );

use strict;

sub get_exec_type               { "sync" }
sub get_type                    { "code" }

sub get_code                    { shift->{code}                         }
sub set_code                    { shift->{code}                 = $_[1] }

sub new {
    my $class = shift;
    my %par = @_;
    my ($code) = $par{'code'};

    my $self = $class->SUPER::new(@_);

    $self->set_code($code);

    return $self;
}

sub execute {
    my $self = shift;
    
    my $code = $self->get_code;
    
    eval { $code->($self) };
    $self->set_error_message($@) if $@;
    
    $self->execution_finished;
    
    1;
}

sub cancel {
    my $self = shift;

    $self->set_cancelled(1);

    1;
}

sub pause_job {
    my $self = shift;

    1;
}

sub backup_state {
    my $self = shift;
    
    my $data_href = $self->SUPER::backup_state();
    
    delete $data_href->{code};
    
    return $data_href;
}

1;

__END__

=head1 NAME

Event::ExecFlow::Job::Code - Execute a closure

=head1 SYNOPSIS

  Event::ExecFlow::Job::Code->new (
    code     => Closure to execute,
    ...
    Event::ExecFlow::Job attributes
  );

=head1 DESCRIPTION

Use this module for execution of arbitrary Perl code
(passed as a closure) inside an Event::ExecFlow.

=head1 OBJECT HIERARCHY

  Event::ExecFlow

  Event::ExecFlow::Job
  +--- Event::ExecFlow::Job::Code

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
