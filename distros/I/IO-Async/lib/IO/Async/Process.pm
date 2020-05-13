#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2018 -- leonerd@leonerd.org.uk

package IO::Async::Process;

use strict;
use warnings;
use base qw( IO::Async::Notifier );

our $VERSION = '0.77';

use Carp;

use Socket qw( SOCK_STREAM );

use Future;

use IO::Async::OS;

=head1 NAME

C<IO::Async::Process> - start and manage a child process

=head1 SYNOPSIS

 use IO::Async::Process;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my $process = IO::Async::Process->new(
    command => [ "tr", "a-z", "n-za-m" ],
    stdin => {
       from => "hello world\n",
    },
    stdout => {
       on_read => sub {
          my ( $stream, $buffref ) = @_;
          while( $$buffref =~ s/^(.*)\n// ) {
             print "Rot13 of 'hello world' is '$1'\n";
          }

          return 0;
       },
    },

    on_finish => sub {
       $loop->stop;
    },
 );

 $loop->add( $process );

 $loop->run;

Also accessible via the L<IO::Async::Loop/open_process> method:

 $loop->open_process(
    command => [ "/bin/ping", "-c4", "some.host" ],

    stdout => {
       on_read => sub {
          my ( $stream, $buffref, $eof ) = @_;
          while( $$buffref =~ s/^(.*)\n// ) {
             print "PING wrote: $1\n";
          }
          return 0;
       },
    },

    on_finish => sub {
       my $process = shift;
       my ( $exitcode ) = @_;
       my $status = ( $exitcode >> 8 );
       ...
    },
 );

=head1 DESCRIPTION

This subclass of L<IO::Async::Notifier> starts a child process, and invokes a
callback when it exits. The child process can either execute a given block of
code (via C<fork(2)>), or a command.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_finish $exitcode

Invoked after the process has exited by normal means (i.e. an C<exit(2)>
syscall from a process, or C<return>ing from the code block), and has closed
all its file descriptors.

=head2 on_exception $exception, $errno, $exitcode

Invoked when the process exits by an exception from C<code>, or by failing to
C<exec(2)> the given command. C<$errno> will be a dualvar, containing both
number and string values. After a successful C<exec()> call, this condition
can no longer happen.

Note that this has a different name and a different argument order from
C<< Loop->open_process >>'s C<on_error>.

If this is not provided and the process exits with an exception, then
C<on_finish> is invoked instead, being passed just the exit code.

Since this is just the results of the underlying C<< $loop->spawn_child >>
C<on_exit> handler in a different order it is possible that the C<$exception>
field will be an empty string. It will however always be defined. This can be
used to distinguish the two cases:

 on_exception => sub {
    my $self = shift;
    my ( $exception, $errno, $exitcode ) = @_;

    if( length $exception ) {
       print STDERR "The process died with the exception $exception " .
          "(errno was $errno)\n";
    }
    elsif( ( my $status = W_EXITSTATUS($exitcode) ) == 255 ) {
       print STDERR "The process failed to exec() - $errno\n";
    }
    else {
       print STDERR "The process exited with exit status $status\n";
    }
 }

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $process = IO::Async::Process->new( %args )

Constructs a new C<IO::Async::Process> object and returns it.

Once constructed, the C<Process> will need to be added to the C<Loop> before
the child process is started.

=cut

sub _init
{
   my $self = shift;
   $self->SUPER::_init( @_ );

   $self->{to_close}   = {};
   $self->{finish_futures} = [];
}

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 on_finish => CODE

=head2 on_exception => CODE

CODE reference for the event handlers.

Once the C<on_finish> continuation has been invoked, the C<IO::Async::Process>
object is removed from the containing L<IO::Async::Loop> object.

The following parameters may be passed to C<new>, or to C<configure> before
the process has been started (i.e. before it has been added to the C<Loop>).
Once the process is running these cannot be changed.

=head2 command => ARRAY or STRING

Either a reference to an array containing the command and its arguments, or a
plain string containing the command. This value is passed into perl's
C<exec(2)> function.

=head2 code => CODE

A block of code to execute in the child process. It will be called in scalar
context inside an C<eval> block.

=head2 setup => ARRAY

Optional reference to an array to pass to the underlying C<Loop>
C<spawn_child> method.

=head2 fdI<n> => HASH

A hash describing how to set up file descriptor I<n>. The hash may contain the
following keys:

=over 4

=item via => STRING

Configures how this file descriptor will be configured for the child process.
Must be given one of the following mode names:

=over 4

=item pipe_read

The child will be given the writing end of a C<pipe(2)>; the parent may read
from the other.

=item pipe_write

The child will be given the reading end of a C<pipe(2)>; the parent may write
to the other. Since an EOF condition of this kind of handle cannot reliably be
detected, C<on_finish> will not wait for this type of pipe to be closed.

=item pipe_rdwr

Only valid on the C<stdio> filehandle. The child will be given the reading end
of one C<pipe(2)> on STDIN and the writing end of another on STDOUT. A single
Stream object will be created in the parent configured for both filehandles.

=item socketpair

The child will be given one end of a C<socketpair(2)>; the parent will be
given the other. The family of this socket may be given by the extra key
called C<family>; defaulting to C<unix>. The socktype of this socket may be
given by the extra key called C<socktype>; defaulting to C<stream>. If the
type is not C<SOCK_STREAM> then a L<IO::Async::Socket> object will be
constructed for the parent side of the handle, rather than
L<IO::Async::Stream>.

=back

Once the filehandle is set up, the C<fd> method (or its shortcuts of C<stdin>,
C<stdout> or C<stderr>) may be used to access the
L<IO::Async::Handle>-subclassed object wrapped around it.

The value of this argument is implied by any of the following alternatives.

=item on_read => CODE

The child will be given the writing end of a pipe. The reading end will be
wrapped by an L<IO::Async::Stream> using this C<on_read> callback function.

=item into => SCALAR

The child will be given the writing end of a pipe. The referenced scalar will
be filled by data read from the child process. This data may not be available
until the pipe has been closed by the child.

=item from => STRING

The child will be given the reading end of a pipe. The string given by the
C<from> parameter will be written to the child. When all of the data has been
written the pipe will be closed.

=item prefork => CODE

Only valid for handles with a C<via> of C<socketpair>. The code block runs
after the C<socketpair(2)> is created, but before the child is forked. This
is handy for when you adjust both ends of the created socket (for example, to
use C<setsockopt(3)>) from the controlling parent, before the child code runs.
The arguments passed in are the L<IO::Socket> objects for the parent and child
ends of the socket.

 $prefork->( $localfd, $childfd )

=back

=head2 stdin => ...

=head2 stdout => ...

=head2 stderr => ...

Shortcuts for C<fd0>, C<fd1> and C<fd2> respectively.

=head2 stdio => ...

Special filehandle to affect STDIN and STDOUT at the same time. This
filehandle supports being configured for both reading and writing at the same
time.

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( on_finish on_exception )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   # All these parameters can only be configured while the process isn't
   # running
   my %setup_params;
   foreach (qw( code command setup stdin stdout stderr stdio ), grep { m/^fd\d+$/ } keys %params ) {
      $setup_params{$_} = delete $params{$_} if exists $params{$_};
   }

   if( $self->is_running ) {
      keys %setup_params and croak "Cannot configure a running Process with " . join ", ", keys %setup_params;
   }

   defined( exists $setup_params{code} ? $setup_params{code} : $self->{code} ) +
      defined( exists $setup_params{command} ? $setup_params{command} : $self->{command} ) <= 1 or
      croak "Cannot have both 'code' and 'command'";

   foreach (qw( code command setup )) {
      $self->{$_} = delete $setup_params{$_} if exists $setup_params{$_};
   }

   $self->configure_fd( 0, %{ delete $setup_params{stdin}  } ) if $setup_params{stdin};
   $self->configure_fd( 1, %{ delete $setup_params{stdout} } ) if $setup_params{stdout};
   $self->configure_fd( 2, %{ delete $setup_params{stderr} } ) if $setup_params{stderr};

   $self->configure_fd( 'io', %{ delete $setup_params{stdio} } ) if $setup_params{stdio};

   # All the rest are fd\d+
   foreach ( keys %setup_params ) {
      my ( $fd ) = m/^fd(\d+)$/ or croak "Expected 'fd\\d+'";
      $self->configure_fd( $fd, %{ $setup_params{$_} } );
   }

   $self->SUPER::configure( %params );
}

# These are from the perspective of the parent
use constant FD_VIA_PIPEREAD  => 1;
use constant FD_VIA_PIPEWRITE => 2;
use constant FD_VIA_PIPERDWR  => 3; # Only valid for stdio pseudo-fd
use constant FD_VIA_SOCKETPAIR => 4;

my %via_names = (
   pipe_read  => FD_VIA_PIPEREAD,
   pipe_write => FD_VIA_PIPEWRITE,
   pipe_rdwr  => FD_VIA_PIPERDWR,
   socketpair => FD_VIA_SOCKETPAIR,
);

sub configure_fd
{
   my $self = shift;
   my ( $fd, %args ) = @_;

   $self->is_running and croak "Cannot configure fd $fd in a running Process";

   if( $fd eq "io" ) {
      exists $self->{fd_opts}{$_} and croak "Cannot configure stdio since fd$_ is already defined" for 0 .. 1;
   }
   elsif( $fd == 0 or $fd == 1 ) {
      exists $self->{fd_opts}{io} and croak "Cannot configure fd$fd since stdio is already defined";
   }

   my $opts = $self->{fd_opts}{$fd} ||= {};
   my $via = $opts->{via};

   my ( $wants_read, $wants_write );

   if( my $via_name = delete $args{via} ) {
      defined $via and
         croak "Cannot change the 'via' mode of fd$fd now that it is already configured";

      $via = $via_names{$via_name} or
         croak "Unrecognised 'via' name of '$via_name'";
   }

   if( my $on_read = delete $args{on_read} ) {
      $opts->{handle}{on_read} = $on_read;

      $wants_read++;
   }
   elsif( my $into = delete $args{into} ) {
      $opts->{handle}{on_read} = sub {
         my ( undef, $buffref, $eof ) = @_;
         $$into .= $$buffref if $eof;
         return 0;
      };

      $wants_read++;
   }

   if( defined( my $from = delete $args{from} ) ) {
      $opts->{from} = $from;

      $wants_write++;
   }

   if( defined $via and $via == FD_VIA_SOCKETPAIR ) {
      $self->{fd_opts}{$fd}{$_} = delete $args{$_} for qw( family socktype prefork );
   }

   keys %args and croak "Unexpected extra keys for fd $fd - " . join ", ", keys %args;

   if( !defined $via ) {
      $via = FD_VIA_PIPEREAD  if  $wants_read and !$wants_write;
      $via = FD_VIA_PIPEWRITE if !$wants_read and  $wants_write;
      $via = FD_VIA_PIPERDWR  if  $wants_read and  $wants_write;
   }
   elsif( $via == FD_VIA_PIPEREAD ) {
      $wants_write and $via = FD_VIA_PIPERDWR;
   }
   elsif( $via == FD_VIA_PIPEWRITE ) {
      $wants_read and $via = FD_VIA_PIPERDWR;
   }
   elsif( $via == FD_VIA_PIPERDWR or $via == FD_VIA_SOCKETPAIR ) {
      # Fine
   }
   else {
      die "Need to check fd_via{$fd}\n";
   }

   $via == FD_VIA_PIPERDWR and $fd ne "io" and
      croak "Cannot both read and write simultaneously on fd$fd";

   defined $via and $opts->{via} = $via;
}

sub _prepare_fds
{
   my $self = shift;
   my ( $loop ) = @_;

   my $fd_handle = $self->{fd_handle};
   my $fd_opts   = $self->{fd_opts};

   my $finish_futures = $self->{finish_futures};

   my @setup;

   foreach my $fd ( keys %$fd_opts ) {
      my $opts   = $fd_opts->{$fd};
      my $via    = $opts->{via};

      my $handle = $self->fd( $fd );

      my $key = $fd eq "io" ? "stdio" : "fd$fd";
      my $write_only;

      if( $via == FD_VIA_PIPEREAD ) {
         my ( $myfd, $childfd ) = IO::Async::OS->pipepair or croak "Unable to pipe() - $!";
         $myfd->blocking( 0 );

         $handle->configure( read_handle => $myfd );

         push @setup, $key => [ dup => $childfd ];
         $self->{to_close}{$childfd->fileno} = $childfd;
      }
      elsif( $via == FD_VIA_PIPEWRITE ) {
         my ( $childfd, $myfd ) = IO::Async::OS->pipepair or croak "Unable to pipe() - $!";
         $myfd->blocking( 0 );
         $write_only++;

         $handle->configure( write_handle => $myfd );

         push @setup, $key => [ dup => $childfd ];
         $self->{to_close}{$childfd->fileno} = $childfd;
      }
      elsif( $via == FD_VIA_PIPERDWR ) {
         $key eq "stdio" or croak "Oops - should only be FD_VIA_PIPERDWR on stdio";
         # Can't use pipequad here for now because we need separate FDs so we
         # can ->close them properly
         my ( $myread, $childwrite ) = IO::Async::OS->pipepair or croak "Unable to pipe() - $!";
         my ( $childread, $mywrite ) = IO::Async::OS->pipepair or croak "Unable to pipe() - $!";
         $_->blocking( 0 ) for $myread, $mywrite;

         $handle->configure( read_handle => $myread, write_handle => $mywrite );

         push @setup, stdin => [ dup => $childread ], stdout => [ dup => $childwrite ];
         $self->{to_close}{$childread->fileno}  = $childread;
         $self->{to_close}{$childwrite->fileno} = $childwrite;
      }
      elsif( $via == FD_VIA_SOCKETPAIR ) {
         my ( $myfd, $childfd ) = IO::Async::OS->socketpair( $opts->{family}, $opts->{socktype} ) or croak "Unable to socketpair() - $!";
         $myfd->blocking( 0 );

         $opts->{prefork}->( $myfd, $childfd ) if $opts->{prefork};

         $handle->configure( handle => $myfd );

         if( $key eq "stdio" ) {
            push @setup, stdin => [ dup => $childfd ], stdout => [ dup => $childfd ];
         }
         else {
            push @setup, $key => [ dup => $childfd ];
         }
         $self->{to_close}{$childfd->fileno} = $childfd;
      }
      else {
         croak "Unsure what to do with fd_via==$via";
      }

      $self->add_child( $handle );

      unless( $write_only ) {
         push @$finish_futures, $handle->new_close_future;
      }
   }

   return @setup;
}

sub _add_to_loop
{
   my $self = shift;
   my ( $loop ) = @_;

   $self->{code} or $self->{command} or
      croak "Require either 'code' or 'command' in $self";

   $self->can_event( "on_finish" ) or
      croak "Expected either an on_finish callback or to be able to ->on_finish";

   my @setup;
   push @setup, @{ $self->{setup} } if $self->{setup};

   push @setup, $self->_prepare_fds( $loop );

   my $finish_futures = delete $self->{finish_futures};

   my ( $exitcode, $dollarbang, $dollarat );
   push @$finish_futures, my $exit_future = $loop->new_future;

   $self->{pid} = $loop->spawn_child(
      code    => $self->{code},
      command => $self->{command},

      setup => \@setup,

      on_exit => $self->_capture_weakself( sub {
         ( my $self, undef, $exitcode, $dollarbang, $dollarat ) = @_;

         $self->debug_printf( "EXIT status=0x%04x", $exitcode ) if $self;
         $exit_future->done unless $exit_future->is_cancelled;
      } ),
   );
   $self->{running} = 1;

   $self->SUPER::_add_to_loop( @_ );

   $_->close for values %{ delete $self->{to_close} };

   my $is_code = defined $self->{code};

   my $f = $self->finish_future;

   $self->{_finish_future} = Future->needs_all( @$finish_futures )
      ->on_done( $self->_capture_weakself( sub {
         my $self = shift or return;

         $self->debug_printf( "FINISH status=0x%04x%s", $exitcode,
            join " ", '', ( $dollarbang ? '$!' : '' ), ( $dollarat ? '$@' : '' )
         );

         $self->{exitcode} = $exitcode;
         $self->{dollarbang} = $dollarbang;
         $self->{dollarat}   = $dollarat;

         undef $self->{running};

         if( $is_code ? $dollarat eq "" : $dollarbang == 0 ) {
            $self->invoke_event( on_finish => $exitcode );
         }
         else {
            $self->maybe_invoke_event( on_exception => $dollarat, $dollarbang, $exitcode ) or
               # Don't have a way to report dollarbang/dollarat
               $self->invoke_event( on_finish => $exitcode );
         }

         $f->done( $exitcode );

         $self->remove_from_parent;
      } ),
   );
}

sub DESTROY
{
   my $self = shift;
   $self->{_finish_future}->cancel if $self->{_finish_future};
}

sub notifier_name
{
   my $self = shift;
   if( length( my $name = $self->SUPER::notifier_name ) ) {
      return $name;
   }

   return "nopid" unless my $pid = $self->pid;
   return "[$pid]" unless $self->is_running;
   return "$pid";
}

=head1 METHODS

=cut

=head2 finish_future

   $f = $process->finish_future

I<Since version 0.75.>

Returns a L<Future> that completes when the process finishes. It will yield
the exit code from the process.

=cut

sub finish_future
{
   my $self = shift;
   return $self->{finish_future} //= $self->loop->new_future;
}

=head2 pid

   $pid = $process->pid

Returns the process ID of the process, if it has been started, or C<undef> if
not. Its value is preserved after the process exits, so it may be inspected
during the C<on_finish> or C<on_exception> events.

=cut

sub pid
{
   my $self = shift;
   return $self->{pid};
}

=head2 kill

   $process->kill( $signal )

Sends a signal to the process

=cut

sub kill
{
   my $self = shift;
   my ( $signal ) = @_;

   kill $signal, $self->pid or croak "Cannot kill() - $!";
}

=head2 is_running

   $running = $process->is_running

Returns true if the Process has been started, and has not yet finished.

=cut

sub is_running
{
   my $self = shift;
   return $self->{running};
}

=head2 is_exited

   $exited = $process->is_exited

Returns true if the Process has finished running, and finished due to normal
C<exit(2)>.

=cut

sub is_exited
{
   my $self = shift;
   return defined $self->{exitcode} ? ( $self->{exitcode} & 0x7f ) == 0 : undef;
}

=head2 exitstatus

   $status = $process->exitstatus

If the process exited due to normal C<exit(2)>, returns the value that was
passed to C<exit(2)>. Otherwise, returns C<undef>.

=cut

sub exitstatus
{
   my $self = shift;
   return defined $self->{exitcode} ? ( $self->{exitcode} >> 8 ) : undef;
}

=head2 exception

   $exception = $process->exception

If the process exited due to an exception, returns the exception that was
thrown. Otherwise, returns C<undef>.

=cut

sub exception
{
   my $self = shift;
   return $self->{dollarat};
}

=head2 errno

   $errno = $process->errno

If the process exited due to an exception, returns the numerical value of
C<$!> at the time the exception was thrown. Otherwise, returns C<undef>.

=cut

sub errno
{
   my $self = shift;
   return $self->{dollarbang}+0;
}

=head2 errstr

   $errstr = $process->errstr

If the process exited due to an exception, returns the string value of
C<$!> at the time the exception was thrown. Otherwise, returns C<undef>.

=cut

sub errstr
{
   my $self = shift;
   return $self->{dollarbang}."";
}

=head2 fd

   $stream = $process->fd( $fd )

Returns the L<IO::Async::Stream> or L<IO::Async::Socket> associated with the
given FD number. This must have been set up by a C<configure> argument prior
to adding the C<Process> object to the C<Loop>.

The returned object have its read or write handle set to the other end of a
pipe or socket connected to that FD number in the child process. Typically,
this will be used to call the C<write> method on, to write more data into the
child, or to set an C<on_read> handler to read data out of the child.

The C<on_closed> event for these streams must not be changed, or it will break
the close detection used by the C<Process> object and the C<on_finish> event
will not be invoked.

=cut

sub fd
{
   my $self = shift;
   my ( $fd ) = @_;

   return $self->{fd_handle}{$fd} ||= do {
      my $opts = $self->{fd_opts}{$fd} or
         croak "$self does not have an fd Stream for $fd";

      my $handle_class;
      if( defined $opts->{socktype} && IO::Async::OS->getsocktypebyname( $opts->{socktype} ) != SOCK_STREAM ) {
         require IO::Async::Socket;
         $handle_class = "IO::Async::Socket";
      }
      else {
         require IO::Async::Stream;
         $handle_class = "IO::Async::Stream";
      }

      my $handle = $handle_class->new(
         notifier_name => $fd eq "0"  ? "stdin" :
                          $fd eq "1"  ? "stdout" :
                          $fd eq "2"  ? "stderr" :
                          $fd eq "io" ? "stdio" : "fd$fd",
         %{ $opts->{handle} },
      );

      if( defined $opts->{from} ) {
         $handle->write( $opts->{from},
            on_flush => sub {
               my ( $handle ) = @_;
               $handle->close_write;
            },
         );
      }

      $handle
   };
}

=head2 stdin

=head2 stdout

=head2 stderr

=head2 stdio

   $stream = $process->stdin

   $stream = $process->stdout

   $stream = $process->stderr

   $stream = $process->stdio

Shortcuts for calling C<fd> with 0, 1, 2 or C<io> respectively, to obtain the
L<IO::Async::Stream> representing the standard input, output, error, or
combined input/output streams of the child process.

=cut

sub stdin  { shift->fd( 0 ) }
sub stdout { shift->fd( 1 ) }
sub stderr { shift->fd( 2 ) }
sub stdio  { shift->fd( 'io' ) }

=head1 EXAMPLES

=head2 Capturing the STDOUT stream of a process

By configuring the C<stdout> filehandle of the process using the C<into> key,
data written by the process can be captured.

 my $stdout;
 my $process = IO::Async::Process->new(
    command => [ "writing-program", "arguments" ],
    stdout => { into => \$stdout },
    on_finish => sub {
       my $process = shift;
       my ( $exitcode ) = @_;
       print "Process has exited with code $exitcode, and wrote:\n";
       print $stdout;
    }
 );

 $loop->add( $process );

Note that until C<on_finish> is invoked, no guarantees are made about how much
of the data actually written by the process is yet in the C<$stdout> scalar.

See also the C<run_child> method of L<IO::Async::Loop>.

To handle data more interactively as it arrives, the C<on_read> key can
instead be used, to provide a callback function to invoke whenever more data
is available from the process.

 my $process = IO::Async::Process->new(
    command => [ "writing-program", "arguments" ],
    stdout => {
       on_read => sub {
          my ( $stream, $buffref ) = @_;
          while( $$buffref =~ s/^(.*)\n// ) {
             print "The process wrote a line: $1\n";
          }

          return 0;
       },
    },
    on_finish => sub {
       print "The process has finished\n";
    }
 );

 $loop->add( $process );

If the code to handle data read from the process isn't available yet when
the object is constructed, it can be supplied later by using the C<configure>
method on the C<stdout> filestream at some point before it gets added to the
Loop. In this case, C<stdin> should be configured using C<pipe_read> in the
C<via> key.

 my $process = IO::Async::Process->new(
    command => [ "writing-program", "arguments" ],
    stdout => { via => "pipe_read" },
    on_finish => sub {
       print "The process has finished\n";
    }
 );

 $process->stdout->configure(
    on_read => sub {
       my ( $stream, $buffref ) = @_;
       while( $$buffref =~ s/^(.*)\n// ) {
          print "The process wrote a line: $1\n";
       }

       return 0;
    },
 );

 $loop->add( $process );

=head2 Sending data to STDIN of a process

By configuring the C<stdin> filehandle of the process using the C<from> key,
data can be written into the C<STDIN> stream of the process.

 my $process = IO::Async::Process->new(
    command => [ "reading-program", "arguments" ],
    stdin => { from => "Here is the data to send\n" },
    on_finish => sub { 
       print "The process has finished\n";
    }
 );

 $loop->add( $process );

The data in this scalar will be written until it is all consumed, then the
handle will be closed. This may be useful if the program waits for EOF on
C<STDIN> before it exits.

To have the ability to write more data into the process once it has started.
the C<write> method on the C<stdin> stream can be used, when it is configured
using the C<pipe_write> value for C<via>:

 my $process = IO::Async::Process->new(
    command => [ "reading-program", "arguments" ],
    stdin => { via => "pipe_write" },
    on_finish => sub { 
       print "The process has finished\n";
    }
 );

 $loop->add( $process );

 $process->stdin->write( "Here is some more data\n" );

=head2 Setting socket options

By using the C<prefork> code block you can change the socket receive buffer
size at both ends of the socket before the child is forked (at which point it
would be too late for the parent to be able to change the child end of the
socket).

 use Socket qw( SOL_SOCKET SO_RCVBUF );

 my $process = IO::Async::Process->new(
    command => [ "command-to-read-from-and-write-to", "arguments" ],
    stdio => {
       via => "socketpair",
       prefork => sub {
          my ( $parentfd, $childfd ) = @_;

          # Set parent end of socket receive buffer to 3 MB
          $parentfd->setsockopt(SOL_SOCKET, SO_RCVBUF, 3 * 1024 * 1024);
          # Set child end of socket receive buffer to 3 MB
          $childfd ->setsockopt(SOL_SOCKET, SO_RCVBUF, 3 * 1024 * 1024);
       },
    },
 );

 $loop->add( $process );

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
