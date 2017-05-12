package Event::ExecFlow::Job::Command;

use base qw( Event::ExecFlow::Job );

use Locale::TextDomain $Event::ExecFlow::locale_textdomain;

use strict;
use AnyEvent;

# prevent warnings from AnyEvent
{ package AnyEvent::Impl::Event::CondVar;
  package AnyEvent::Impl::Event::Glib; }

sub get_type                    { "command" }
sub get_exec_type               { "async"   }

#------------------------------------------------------------------------

sub get_command                 { shift->{command}                      }
sub get_fetch_output            { shift->{fetch_output}                 }
sub get_node                    { shift->{node}                         }
sub get_output                  { shift->{output}                       }
sub get_progress_parser         { shift->{progress_parser}              }
sub get_got_exec_ok             { shift->{got_exec_ok}                  }
sub get_configure_callback      { shift->{configure_callback}           }

sub set_command                 { shift->{command}              = $_[1] }
sub set_fetch_output            { shift->{fetch_output}         = $_[1] }
sub set_node                    { shift->{node}                 = $_[1] }
sub set_output                  { shift->{output}               = $_[1] }
sub set_progress_parser         { shift->{progress_parser}      = $_[1] }
sub set_got_exec_ok             { shift->{got_exec_ok}          = $_[1] }
sub set_configure_callback      { shift->{configure_callback}   = $_[1] }

#------------------------------------------------------------------------

sub get_pids                    { shift->{pids}                         }
sub get_fh                      { shift->{fh}                           }
sub get_watcher                 { shift->{watcher}                      }
sub get_executed_command        { shift->{executed_command}             }

sub set_pids                    { shift->{pids}                 = $_[1] }
sub set_fh                      { shift->{fh}                   = $_[1] }
sub set_watcher                 { shift->{watcher}              = $_[1] }
sub set_executed_command        { shift->{executed_command}     = $_[1] }

#------------------------------------------------------------------------

sub new {
    my $class = shift;
    my %par = @_;
    my  ($command, $fetch_output, $node, $progress_parser) =
    @par{'command','fetch_output','node','progress_parser'};
    my  ($configure_callback) =
    $par{'configure_callback'};

    my $self = $class->SUPER::new(@_);

    $self->set_command($command);
    $self->set_fetch_output($fetch_output);
    $self->set_node($node);
    $self->set_progress_parser($progress_parser);
    $self->set_configure_callback($configure_callback);

    return $self;
}

sub init {
    my $self = shift;
    
    $self->SUPER::init();
    
    $self->set_pids([]);
    $self->set_fh();
    $self->set_watcher();
    $self->set_output("");

    1;
}

sub execute {
    my $self = shift;

    $self->open_pipe;

    1;
}

sub open_pipe {
    my $self = shift;

    my $command = $self->get_command;

    if ( ref $command eq 'CODE' ) {
        $Event::ExecFlow::JOB = $self;
        $command = $command->($self);
        $Event::ExecFlow::JOB = undef;
    }

    if ( $self->get_configure_callback ) {
        my $cb = $self->get_configure_callback;
        $command = &$cb($command);
    }

    if ( $self->get_node ) {
        $command = $self->get_node->prepare_command($command, $self);
    }

    $command =~ s/\s+$//;

    my $execflow = $command =~ /execflow/ ? "" : "execflow ";
    $command = $execflow.$command;
    $command .= " && echo EXECFLOW_OK" if $command !~ /EXECFLOW_OK/;

    $self->log (__x("Executing command: {command}", command => $command));
    $Event::ExecFlow::DEBUG && print "Command(".$self->get_info."): command=$command\n";

    $self->set_executed_command($command);

    local $ENV{LC_ALL} = "C";
    local $ENV{LANG}   = "C";

    my $pid = open (my $fh, "( $command ) 2>&1 |")
        or die "can't fork '$command'";

    my $watcher = AnyEvent->io ( fh => $fh, poll => 'r', cb => sub {
        $self->command_progress;
    });

    push @{$self->get_pids}, $pid;
    $self->set_fh($fh);
    $self->set_watcher($watcher);

    return $fh;
}

sub close_pipe {
    my $self = shift;
    
    $self->set_watcher(undef);
    
    close($self->get_fh);
    $self->set_fh(undef);
    $self->set_pids([]);

    if ( !$self->get_error_message && !$self->get_got_exec_ok ) {
        $self->set_error_message(
            "Command exits with failure code:\n".
            "Command: ".$self->get_executed_command."\n\n".
            "Output: ".$self->get_output
        );
    }
    
    1;
}

sub command_progress {
    my $self = shift;
    
    my $fh = $self->get_fh;

    #-- read and check for eof
    my $buffer;
    if ( !sysread($fh, $buffer, 4096) ) {
        $self->close_pipe;
        $self->execution_finished;
        return;
    }
    
    #-- get job's PID
    my ($pid) = ( $buffer =~ /EXEC_FLOW_JOB_PID=(\d+)/ );
    if ( defined $pid ) {
        push @{$self->get_pids}, $pid;
        $buffer =~ s/EXEC_FLOW_JOB_PID=(\d+)\n//;
    }

    #-- succesfully executed?
    if ( $buffer =~ s/EXECFLOW_OK\n// ) {
        $self->set_got_exec_ok(1);
    }

    #-- store output
    if ( $self->get_fetch_output ) {
	    $self->{output} .= $buffer;
    } else {
	    $self->{output} = substr($self->{output}.$buffer,-16384);
    }

    #-- parse output & report progress
    my $progress_parser = $self->get_progress_parser;
    if ( ref $progress_parser eq 'CODE' ) {
        $progress_parser->($self, $buffer);
    }
    elsif ( ref $progress_parser eq 'Regexp' ) {
        if ( $buffer =~ $progress_parser ) {
            $self->set_progress_cnt($1);
        }
    }

    $self->get_frontend->report_job_progress($self)
        if $self->progress_has_changed;

    1;
}

sub cancel {
    my $self = shift;

    $self->set_cancelled(1);

    my $pids = $self->get_pids;
    return unless @{$pids};

    kill 9, @{$pids};

    $self->log(__x("Sending signal 9 to PID(s)")." ".join(", ", @{$pids}));

    1;
}

sub pause_job {
    my $self = shift;

    my $signal;
    if ( $self->get_paused ) {
        $signal = "STOP";
    }
    else {
        $signal = "CONT";
    }

    my $pids = $self->get_pids;
    kill $signal, @{$pids} if @{$pids};
   
    1;
}

sub backup_state {
    my $self = shift;
    
    my $data_href = $self->SUPER::backup_state();
    
    delete $data_href->{configure_callback};
    delete $data_href->{progress_parser};
    delete $data_href->{node};
    delete $data_href->{watcher};
    delete $data_href->{fh};
    delete $data_href->{command}
        if ref $data_href->{command} eq 'CODE';

    return $data_href;
}

1;

__END__

=head1 NAME

Event::ExecFlow::Job::Command - External command for async execution

=head1 SYNOPSIS

  Event::ExecFlow::Job::Command->new (
    command              => Shell command to be executed,
    fetch_output         => Boolean if output should be fetched,
    progress_parser      => A closure or regex for progress parsing,
    configure_callback   => A closure to configure the command
                            before execution,
    ...
    Event::ExecFlow::Job attributes
  );

=head1 DESCRIPTION

Use this module for asynchronous execution of an external command
with Event::ExecFlow.

=head1 OBJECT HIERARCHY

  Event::ExecFlow

  Event::ExecFlow::Job
  +--- Event::ExecFlow::Job::Command

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
