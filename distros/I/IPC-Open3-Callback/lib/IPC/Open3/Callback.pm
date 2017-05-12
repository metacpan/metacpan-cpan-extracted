use strict;
use warnings;

package IPC::Open3::Callback;
$IPC::Open3::Callback::VERSION = '1.19';
# ABSTRACT: An extension to IPC::Open3 that will feed out and err to callbacks instead of requiring the caller to handle them.
# PODNAME: IPC::Open3::Callback

use Data::Dumper;
use Exporter qw(import);
use Hash::Util qw(lock_keys);
use IO::Select;
use IO::Socket;
use IPC::Open3;
use Symbol qw(gensym);

use parent qw(Class::Accessor);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
    qw(out_callback err_callback buffer_output select_timeout buffer_size input_buffer));
__PACKAGE__->mk_ro_accessors(qw(pid last_command last_exit_code));

our @EXPORT_OK = qw(safe_open3);

my $logger;
eval {
    require Log::Log4perl;
    $logger = Log::Log4perl->get_logger('IPC::Open3::Callback');
};
if ($@) {
    require IPC::Open3::Callback::Logger;
    $logger = IPC::Open3::Callback::Logger->get_logger();
}

sub new {
    my ( $class, @args ) = @_;
    return bless( {}, $class )->_init(@args);
}

sub _append_to_buffer {
    my ( $self, $buffer_ref, $data, $flush ) = @_;

    my @lines = split( /\n/, $$buffer_ref . $data, -1 );

    # save the last line in the buffer as it may not yet be a complete line
    $$buffer_ref = $flush ? '' : pop(@lines);

    # return all complete lines
    return @lines;
}

sub _clear_input_buffer {
    my ($self) = shift;
    delete( $self->{input_buffer} );
}

sub DESTROY {
    my ($self) = shift;
    $self->_destroy_child();
}

sub _destroy_child {
    my $self = shift;

    my $pid = $self->get_pid();
    if ($pid) {
        waitpid( $pid, 0 );
        $self->_set_last_exit_code( $? >> 8 );

        $logger->debug(
            sub {
                "Exited '",
                    $self->get_last_command(),
                    "' with code ",
                    $self->get_last_exit_code();
            }
        );
        $self->_set_pid();
    }

    return $self->{last_exit_code};
}

sub _init {
    my ( $self, $args_ref ) = @_;

    $self->{buffer_output}  = undef;
    $self->{buffer_size}    = undef;
    $self->{err_callback}   = undef;
    $self->{input_buffer}   = undef;
    $self->{last_command}   = undef;
    $self->{last_exit_code} = undef;
    $self->{out_callback}   = undef;
    $self->{pid}            = undef;
    $self->{select_timeout} = undef;
    lock_keys( %{$self} );

    if ( defined($args_ref) ) {
        $logger->logdie('parameters must be an hash reference')
            unless ( ( ref($args_ref) ) eq 'HASH' );
        $self->{out_callback}   = $args_ref->{out_callback};
        $self->{err_callback}   = $args_ref->{err_callback};
        $self->{buffer_output}  = $args_ref->{buffer_output};
        $self->{select_timeout} = $args_ref->{select_timeout} || 3;
        $self->{buffer_size}    = $args_ref->{buffer_size} || 1024;
    }
    else {
        $self->{select_timeout} = 3;
        $self->{buffer_size}    = 1024;
    }

    return $self;
}

sub _nix_open3 {
    my ( $in_read, $out_write, $err_write, @command ) = @_;
    my ( $in_write, $out_read, $err_read );

    if ( !$in_read ) {
        $in_read  = gensym();
        $in_write = $in_read;
    }
    if ( !$out_write ) {
        $out_read  = gensym();
        $out_write = $out_read;
    }
    if ( !$err_write ) {
        $err_read  = gensym();
        $err_write = $err_read;
    }

    return ( open3( $in_read, $out_write, $err_write, @command ),
        $in_write, $out_read, $err_read );
}

sub run_command {
    my ( $self, @command ) = @_;

    # if last arg is hashref, its command options not arg...
    my $options = {};
    if ( ref( $command[-1] ) eq 'HASH' ) {
        $options = pop(@command);
    }

    my ($out_callback,   $out_buffer_ref, $err_callback,
        $err_buffer_ref, $buffer_size,    $select_timeout
    );
    $out_callback = $options->{out_callback} || $self->get_out_callback();
    $err_callback = $options->{err_callback} || $self->get_err_callback();
    if ( $options->{buffer_output} || $self->get_buffer_output() ) {
        my $out_temp = '';
        my $err_temp = '';
        $out_buffer_ref = \$out_temp;
        $err_buffer_ref = \$err_temp;
    }
    $buffer_size    = $options->{buffer_size}    || $self->get_buffer_size();
    $select_timeout = $options->{select_timeout} || $self->get_select_timeout();

    $self->_set_last_command( \@command );
    $logger->debug( "Running '", $self->get_last_command(), "'" );
    my ( $pid, $in_fh, $out_fh, $err_fh ) = safe_open3_with(
        $options->{in_handle},
        $options->{out_handle},
        $options->{err_handle}, @command
    );
    $self->_set_pid($pid);

    my $select = IO::Select->new();
    $select->add( $out_fh, $err_fh );
    while ( my @ready = $select->can_read($select_timeout) ) {
        if ( $self->get_input_buffer() ) {
            syswrite( $in_fh, $self->get_input_buffer() );
            $self->_clear_input_buffer();
        }
        foreach my $fh (@ready) {
            my $line;
            my $bytes_read = sysread( $fh, $line, $buffer_size );
            if ( !defined($bytes_read) && !$!{ECONNRESET} ) {
                $logger->error( "sysread failed: ", sub { Dumper(%!) } );
                $logger->logdie( "error in running '", $self->get_last_command(), "': ", $! );
            }
            elsif ( !defined($bytes_read) || $bytes_read == 0 ) {
                $select->remove($fh);
                next;
            }
            else {
                if ( $out_fh && $fh == $out_fh ) {
                    $self->_write_to_callback( $out_callback, $line, $out_buffer_ref, 0 );
                }
                elsif ( $err_fh && $fh == $err_fh ) {
                    $self->_write_to_callback( $err_callback, $line, $err_buffer_ref, 0 );
                }
                else {
                    $logger->logdie('Impossible... somehow got a filehandle I dont know about!');
                }
            }
        }
    }

    # flush buffers
    $self->_write_to_callback( $out_callback, '', $out_buffer_ref, 1 );
    $self->_write_to_callback( $err_callback, '', $err_buffer_ref, 1 );

    return $self->_destroy_child();
}

sub safe_open3 {
    return safe_open3_with( undef, undef, undef, @_ );
}

sub safe_open3_with {
    my ( $in_handle, $out_handle, $err_handle, @command ) = @_;

    my @args = (
        $in_handle  ? '<&' . fileno($in_handle)  : undef,
        $out_handle ? '>&' . fileno($out_handle) : undef,
        $err_handle ? '>&' . fileno($err_handle) : undef, @command
    );
    return ( $^O =~ /MSWin32/ ) ? _win_open3(@args) : _nix_open3(@args);
}

sub send_input {
    my ($self) = @_;
    $self->set_input_buffer(shift);
}

sub _set_last_command {
    my ( $self, $command_ref ) = @_;

    $logger->logdie('the command parameter must be an array reference')
        unless ( ( ref($command_ref) ) eq 'ARRAY' );

    $self->{last_command} = join( ' ', @{$command_ref} );
}

sub _set_last_exit_code {
    my ( $self, $code ) = @_;
    $self->{last_exit_code} = $code;
}

sub _set_pid {
    my ( $self, $pid ) = @_;

    if ( !defined($pid) ) {
        delete( $self->{pid} );
    }
    elsif ( $pid !~ /^\d+$/ ) {
        $logger->logdie('the parameter must be an integer');
    }
    else {
        $self->{pid} = $pid;
    }
}

sub _win_open3 {
    my ( $in_read, $out_write, $err_write, @command ) = @_;

    my ($in_pipe_read,   $in_pipe_write, $out_pipe_read,
        $out_pipe_write, $err_pipe_read, $err_pipe_write
    );
    if ( !$in_read ) {
        ( $in_pipe_read, $in_pipe_write ) = _win_pipe();
        $in_read = '>&' . fileno($in_pipe_read);
    }
    if ( !$out_write ) {
        ( $out_pipe_read, $out_pipe_write ) = _win_pipe();
        $out_write = '<&' . fileno($out_pipe_write);
    }
    if ( !$err_write ) {
        ( $err_pipe_read, $err_pipe_write ) = _win_pipe();
        $err_write = '<&' . fileno($err_pipe_write);
    }

    my $pid = open3( $in_read, $out_write, $err_write, @command );

    return ( $pid, $in_pipe_write, $out_pipe_read, $err_pipe_read );
}

sub _win_pipe {
    my ( $read, $write ) = IO::Socket->socketpair( AF_UNIX, SOCK_STREAM, PF_UNSPEC );
    $read->shutdown(SHUT_WR);     # No more writing for reader
    $write->shutdown(SHUT_RD);    # No more reading for writer

    return ( $read, $write );
}

sub _write_to_callback {
    my ( $self, $callback, $data, $buffer_ref, $flush ) = @_;

    return if ( !defined($callback) );

    my $pid = $self->get_pid();
    if ( !defined($buffer_ref) ) {
        &{$callback}( $data, $pid );
        return;
    }

    foreach my $line ( $self->_append_to_buffer( $buffer_ref, $data, $flush ) ) {
        &{$callback}( $line, $pid );
    }
}

1;

__END__

=pod

=head1 NAME

IPC::Open3::Callback - An extension to IPC::Open3 that will feed out and err to callbacks instead of requiring the caller to handle them.

=head1 VERSION

version 1.19

=head1 SYNOPSIS

  use IPC::Open3::Callback;
  my $runner = IPC::Open3::Callback->new( {
      out_callback => sub {
          my $data = shift;
          my $pid = shift;

          print( "$pid STDOUT: $data\n" );
      },
      err_callback => sub {
          my $data = shift;
          my $pid = shift;

          print( "$pid STDERR: $data\n" );
      } } );
  my $exit_code = $runner->run_command( 'echo Hello World' );

  use IPC::Open3::Callback qw(safe_open3);
  my ($pid, $in, $out, $err) = safe_open3( "echo", "Hello", "world" ); 
  $buffer = '';
  my $select = IO::Select->new();
  $select->add( $out );
  while ( my @ready = $select->can_read( 5 ) ) {
      foreach my $fh ( @ready ) {
          my $line;
          my $bytes_read = sysread( $fh, $line, 1024 );
          if ( ! defined( $bytes_read ) && !$!{ECONNRESET} ) {
              die( "error in running ('echo $echo'): $!" );
          }
          elsif ( ! defined( $bytes_read) || $bytes_read == 0 ) {
              $select->remove( $fh );
              next;
          }
          else {
              if ( $fh == $out ) {
                  $buffer .= $line;
              }
              else {
                  die( "impossible... somehow got a filehandle i dont know about!" );
              }
          }
      }
  } 
  waitpid( $pid, 0 );
  my $exit_code = $? >> 8;
  print( "$pid exited with $exit_code: $buffer\n" ); # 123 exited with 0: Hello World

=head1 DESCRIPTION

This module feeds output and error stream from a command to supplied callbacks.  
Thus, this class removes the necessity of dealing with L<IO::Select> by hand and
also provides a workaround for the bad reputation associated with Microsoft 
Windows' IPC.

=head1 EXPORT_OK

=head2 safe_open3( $command, $arg1, ..., $argN )

Passes the command and arguments on to C<open3> and returns a list containing:

=over 4

=item pid

The process id of the forked process.

=item stdin

An L<IO::Handle> to STDIN for the process.

=item stdout

An L<IO::Handle> to STDOUT for the process.

=item stderr

An L<IO::Handle> to STDERR for the process.

=back

As with C<open3>, it is the callers responsibility to C<waitpid> to
ensure forked processes do not become zombies.

This method works for both *nix and Microsoft Windows OS's.  On a Windows 
system, it will use sockets per 
L<http://www.perlmonks.org/index.pl?node_id=811150>.

=head2 safe_open3_with( $in_handle, $out_handle, $err_handle, $command, $arg1, ..., $argN )

The same as L<safe_open3|/"safe_open3( $command, $arg1, ..., $argN )"> except
that you can specify the handles to be used instead of having C<safe_open3>
generate them.  Each handle can be C<undef>.  In fact, C<safe_open3> just
calls C<safe_open3_with(undef, undef, undef, @command)>.  The return values
are the same except that C<undef> will be returned for each handle 
corresponding to the same stream as a supplied handle.  For example, if you
specify an C<$out_handle> then C<undef> will be returned for the C<STDOUT>
handle.

=head1 CONSTRUCTORS

=head2 new( \%options )

The constructor creates a new Callback object and optionally sets global 
callbacks for C<STDOUT> and C<STDERR> streams from commands that will get run by 
this object (can be overridden per call to 
L<run_command|/"run_command( $command, $arg1, ..., $argN, \%options )">).
The currently available options are:

=over 4

=item out_callback

L<out_callback|/"set_out_callback( &subroutine )">

=item err_callback

L<err_callback|/"set_err_callback( &subroutine )">

=item buffer_output

L<buffer_output|/"set_buffer_output( $boolean )">

=item buffer_size

L<buffer_size|/"set_buffer_size( $bytes )">

=item select_timeout

L<select_timeout|/"set_select_timeout( $seconds )">

=back

=head1 ATTRIBUTES

=head2 get_buffer_output()

=head2 set_buffer_output( $boolean )

A boolean value, if true, will buffer output and send to callback one line
at a time (waits for '\n').  Otherwise, sends text in the same chunks returned
by L<sysread>.

=head2 get_buffer_size()

=head2 set_buffer_size( $bytes )

The size of the read buffer (in bytes) supplied to C<sysread>.

=head2 get_err_callback()

=head2 set_err_callback( &subroutine )

A subroutine that will be called for each chunk of text written to C<STDERR>. 
The subroutine will be called with the same 2 arguments as 
L<out_callback|/"set_out_callback( &subroutine )">.

=head2 get_last_command()

The last command run by the 
L<run_command|/"run_command( $command, $arg1, ..., $argN, \%options )"> method.

=head2 get_last_exit_code()

The exit code of the last command run by the 
L<run_command|/"run_command( $command, $arg1, ..., $argN, \%options )"> method.

=head2 get_out_callback()

=head2 set_out_callback( &subroutine )

A subroutine that will be called whenever a chunk of output is sent to STDOUT by the
opened process. The subroutine will be called with 2 arguments:

=over 4

=item data

A chunk of text written to the stream

=item pid

The pid of the forked process

=back

=head2 get_pid()

Will return the pid of the currently running process.  This pid is set by 
C<run_command> and will be cleared out when the C<run_command> completes.

=head2 get_select_timeout()

=head2 set_select_timeout( $seconds )

The timeout, in seconds, provided to C<IO::Select>, by default 0 meaning no
timeout which will cause the loop to block until output is ready on either
C<STDOUT> or C<STDERR>.

=head1 METHODS

=head2 run_command( $command, $arg1, ..., $argN, \%options )

Will run the specified command with the supplied arguments by passing them on 
to L<safe_open3|/"safe_open3( $command, $arg1, ..., $argN )">.  Arguments can be embedded in the command string and 
are thus optional.

If the last argument to this method is a hashref (C<ref(@_[-1]) eq 'HASH'>), then
it is treated as an options hash.  The supported allowed options are the same
as the L<constructor|/"new( \%options )"> and will be used in preference to the values set by the  
constructor or any of the setters.  These options will be used for this single
call, and will not modify the C<Callback> object itself.  C<run_command> supports
three additional options not supported by the constructor.  They are:

=over 4

=item in_handle 

An C<IO::Handle> from which C<STDIN> will be read.

=item out_handle

An C<IO::Handle> to which C<STDOUT> will be written.

=item err_handle

An C<IO::Handle> to which C<STDERR> will be written.

=back

These handle options can be mixed with regular options and if multiple are
specified on the same stream, the handle version will be used instead of the
callback.

Returns the exit code from the command.

=head1 AUTHORS

=over 4

=item *

Lucas Theisen <lucastheisen@pastdev.com>

=item *

Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<IPC::Open3|IPC::Open3>

=item *

L<IPC::Open3::Callback::Command|IPC::Open3::Callback::Command>

=item *

L<IPC::Open3::Callback::CommandRunner|IPC::Open3::Callback::CommandRunner>

=item *

L<https://github.com/lucastheisen/ipc-open3-callback|https://github.com/lucastheisen/ipc-open3-callback>

=item *

L<http://stackoverflow.com/q/16675950/516433|http://stackoverflow.com/q/16675950/516433>

=back

=for Pod::Coverage send_input

=cut
