#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Future::IO::System 0.16;

use v5.14;
use warnings;

use Carp;

use Future::IO;

=head1 NAME

C<Future::IO::System> - C<system()>-like methods for L<Future::IO>

=head1 SYNOPSIS

=for highlighter language=perl

   use Future::IO;
   use Future::IO::System;

   my $f = Future::IO::System->system( "cmd", "args go", "here" );
   # $f will become done when the command completes

   my $f = Future::IO::System->system_out( "cmd", "-v" );
   my ( $status, $out ) = $f->get;

   # $status will contain the exit code and $out will contain what it wrote
   # to STDOUT

=head1 DESCRIPTION

This package contains a selection of methods that behave like the core
C<system()> and related functions, running asynchronously via L<Future::IO>.

In particular, the L</system> behaves somewhat like C<CORE::system()> and
L</system_out> behaves somewhat like L<qx()>.

=head2 Portability

In order for this module to work at all, the underlying C<Future::IO>
implementation must support the L<Future::IO/waitpid> method. The default
minimal implementation included with the module does not, but most of the
additional implementations from CPAN will.

In addition, the operation of this module uses techniques that only really
work on full POSIX systems (such as Linux, Mac OS X, the various BSDs, etc).
It is unlikely to work in places like MSWin32.

=cut

# TODO: Print at least some sort of warning if loaded on one of the weird
# non-POSIX OSes

=head1 METHODS

=cut

=head2 run

   ( $exitcode, ... ) = await Future::IO::System->run(
      argv => [ $path, @args ],
      ...
   );

I<Since version 0.12.>

Runs the given C<$path> with the given C<@args> as a sub-process, optionally
with some additional filehandles set up as determined by the other arguments.
The returned L<Future> will yield the C<waitpid()> exit code from the process
when it terminates, and optionally the bytes read from the other filehandles
that were set up.

Takes the following named arguments

=over 4

=item argv => ARRAY

An array reference containing the path and arguments to pass to C<exec()> in
the child process.

=item in => STRING

If defined, create a pipe and assign the reading end to the child process's
STDIN filehandle. The given string will then be written to the pipe, after
which the pipe will be closed.

=item want_out => BOOL

If true, create a pipe and assign the writing end to the child process's
STDOUT filehandle. The returned future will additionally contain all the bytes
read from it until EOF.

=item want_err => BOOL

If true, create a pipe and assign the writing end to the child process's
STDERR filehandle. The returned future will additionally contain all the bytes
read from it until EOF.

=back

The remaining methods in this class are simplified wrappers of this one.

=cut

sub run
{
   shift;
   my %params = @_;

   my $argv     = $params{argv};
   my $want_in  = defined $params{in};
   my $want_out = $params{want_out};
   my $want_err = $params{want_err};

   my @infh;
   pipe( $infh[0], $infh[1] ) or croak "Cannot pipe() - $!"
      if $want_in;

   my @outfh;
   pipe( $outfh[0], $outfh[1] ) or croak "Cannot pipe() - $!"
      if $want_out;

   my @errfh;
   pipe( $errfh[0], $errfh[1] ) or croak "Cannot pipe() - $!"
      if $want_err;

   defined( my $pid = fork() )
      or croak "Cannot fork() - $!";

   if( $pid ) {
      # parent

      my @f;
      push @f, Future::IO->waitpid( $pid );

      if( $want_in ) {
         close $infh[0];
         push @f, Future::IO->syswrite_exactly( $infh[1], $params{in} )
            ->then( sub { close $infh[1]; Future->done() } );
      }

      if( $want_out ) {
         close $outfh[1];
         push @f, Future::IO->sysread_until_eof( $outfh[0] );
      }

      if( $want_err ) {
         close $errfh[1];
         push @f, Future::IO->sysread_until_eof( $errfh[0] );
      }

      return Future->needs_all( @f );
   }
   else {
      # child

      if( $want_in ) {
         close $infh[1];
         POSIX::dup2( $infh[0]->fileno, 0 );
      }

      if( $want_out ) {
         close $outfh[0];
         POSIX::dup2( $outfh[1]->fileno, 1 );
      }

      if( $want_err ) {
         close $errfh[0];
         POSIX::dup2( $errfh[1]->fileno, 2 );
      }

      exec( @$argv ) or
         POSIX::_exit( -1 );
   }
}

=head2 system

   $exitcode = await Future::IO::System->system( $path, @args );

I<Since version 0.12.>

Runs the given C<$path> with the given C<@args> as a sub-process with no extra
filehandles.

=cut

sub system
{
   my $self = shift;
   my @argv = @_;

   return $self->run( argv => \@argv );
}

=head2 system_out

   ( $exitcode, $out ) = await Future::IO::System->system_out( $path, @args );

I<Since version 0.12.>

Runs the given C<$path> with the given C<@args> as a sub-process with a new
pipe as its STDOUT filehandle. The returned L<Future> will additionally yield
the bytes read from the STDOUT pipe.

=cut

sub system_out
{
   my $self = shift;
   my @argv = @_;

   return $self->run( argv => \@argv, want_out => 1 );
}

=head1 TODO

=over 4

=item *

Add some OS portability guard warnings when loading the module on platforms
not known to support it.

=item *

Consider what other features of modules like L<IPC::Run> or
L<IO::Async::Process> to support here. Try not to go overboard.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
