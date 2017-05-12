#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009 -- leonerd@leonerd.org.uk

package IPC::PerlSSH::Library::Run;

use strict;
use warnings;

use IPC::PerlSSH::Library;

our $VERSION = '0.17';

=head1 NAME

C<IPC::PerlSSH::Library::Run> - a library of command running functions for
C<IPC::PerlSSH>

=head1 SYNOPSIS

 use IPC::PerlSSH;

 my $ips = IPC::PerlSSH->new( Host => "over.there" );

 $ips->use_library( "Run", qw( system system_out system_in ) );

 my ( $result, $out ) = $ips->call( "system_out", qw( ip addr ls ) );
 $out == 0 or die "ip failed\n";

 for (split m/\n/, $out ) {
    # some processing here...
 }

 my $result = $ips->call( "system", qw( ip addr add 1.2.3.4/28 dev eth0 ) );

 # To execute a shell command, send a single string
 my $result = $ips->call( "system_in", "1", 
    "echo >/proc/sys/net/ipv4/ip_forward"
 );

=head1 DESCRIPTION

This module provides a library of functions for executing processes on the
remote system. As well as a basic C<system()>-like wrapper, there are also
functions for passing data in to the executed process's STDIN stream, reading
from its STDOUT stream, or both simultaneously.

Each of these functions will only return once the remote process has exited.
If interaction with the process is required while it is running, a remote pipe
open may be performed instead using functions in L<IPC::PerlSSH::Library::IO>.

=cut

# Have to protect the STDIN/STDOUT streams
# Don't capture the STDERR stream unless caller asked for it

init q[
sub system_inouterr {
   my ( $capture_stderr, $stdin, $path, @args ) = @_;

   pipe( my $rd0, my $wr0 ) or die "Cannot pipe() - $!";
   pipe( my $rd1, my $wr1 ) or die "Cannot pipe() - $!";
   pipe( my $rd2, my $wr2 ) or die "Cannot pipe() - $!" if $capture_stderr;

   defined( my $kid = fork ) or die "Cannot fork - ()\n";
   if( $kid == 0 ) {
      open STDIN,  "<&=", $rd0; close $rd0; close $wr0;
      open STDOUT, ">&=", $wr1; close $rd1; close $wr1;
      if( $capture_stderr ) {
         open STDERR, ">&=", $wr2; close $rd2; close $wr2;
      }
      exec $path, @args;
      exit -1;
   }

   close $rd0;
   close $wr1;
   close $wr2 if $capture_stderr;

   my $stdout = "";
   my $stderr = "";
   my $fn0 = fileno $wr0;
   my $fn1 = fileno $rd1;
   my $fn2 = fileno $rd2 if $capture_stderr;

   local $SIG{PIPE} = "IGNORE";

   while(1) {
      undef $wr0 unless length $stdin;
      last unless $wr0 or $rd1 or $rd2;
      my ( $rv, $wv ) = ('') x 2;
      vec( $wv, $fn0, 1 ) = 1 if $wr0;
      vec( $rv, $fn1, 1 ) = 1 if $rd1;
      vec( $rv, $fn2, 1 ) = 1 if $rd2;

      select $rv, $wv, undef, undef or die "Cannot select() - $!";

      if( vec( $wv, $fn0, 1 ) ) {
         my $n = syswrite( $wr0, $stdin, 8192 ) or undef $wr0;
         substr( $stdin, 0, $n ) = "" if $n;
      }
      if( vec( $rv, $fn1, 1 ) ) {
         sysread( $rd1, $stdout, 8192, length $stdout ) or undef $rd1;
      }
      if( vec( $rv, $fn2, 1 ) ) {
         sysread( $rd2, $stderr, 8192, length $stderr ) or undef $rd2;
      }
   }

   waitpid $kid, 0;
   return $?, $stdout, $stderr if $capture_stderr;
   return $?, $stdout;
}
];

=head1 FUNCTIONS

The following four functions do not redirect the C<STDERR> stream of the
invoked program, allowing it to pass unhindered back through the F<ssh>
connection to the local program.

=cut

=head2 system

Execute a program with the given arguments, returning its exit status.

 my $exitstatus = $ips->call( "system", $path, @args );

To obtain the exit value, use C<WEXITSTATUS> from C<POSIX>.

=cut

func system => q{ ( system_inouterr( 0, "", @_ ) )[0] };

=head2 system_in

Execute a program with the given arguments, passing in a string to its STDIN,
and returning its exit status

 my $exitstatus = $ips->call( "system_in", $stdin, $path, @args );

=cut

func system_in => q{ ( system_inouterr( 0, @_ ) )[0] };

=head2 system_out

Execute a program with the given arguments, returning its exit status and what
it wrote on STDOUT.

 my ( $exitstatus, $stdout ) = $ips->call( "system_out", $path, @args );

=cut

func system_out => q{ system_inouterr( 0, "", @_ ) };

=head2 system_inout

Execute a program with the given arguments, passing in a string to its STDIN,
and returning its exit status and what it wrote on STDOUT.

 my ( $exitstatus, $stdout ) =
    $ips->call( "system_inout", $stdin, $path, @args )

=cut

func system_inout => q{ system_inouterr( 0, @_ ) };

=pod

The following four functions capture the invoked program's C<STDERR> stream.

=cut

=head2 system_err

Execute a program with the given arguments, returning its exit status and what
it wrote on STDERR.

 my ( $exitstatus, $stderr ) = $ips->call( "system_err", $path, @args );

=cut

func system_err => q{ ( system_inouterr( 1, "", @_ ) )[0,2] };

=head2 system_inerr

Execute a program with the given arguments, passing in a string to its STDIN,
and returning its exit status and what it wrote on STDERR.

 my ( $exitstatus, $stderr ) =
    $ips->call( "system_inerr", $stdin, $path, @args );

=cut

func system_inerr => q{ ( system_inouterr( 1, @_ ) )[0,2] };

=head2 system_outerr

Execute a program with the given arguments, returning its exit status and what
it wrote on STDOUT and STDERR.

 my ( $exitstatus, $stdout, $stderr ) =
    $ips->call( "system_outerr", $path, @args );

=cut

func system_outerr => q{ system_inouterr( 1, "", @_ ) };

=head2 system_inouterr

Execute a program with the given arguments, passing in a string to its STDIN,
and returning its exit status and what it wrote on STDOUT and STDERR.

 my ( $exitstatus, $stdout, $stderr ) =
    $ips->call( "system_inouterr", $stdin, $path, @args )

=cut

func system_inouterr => q{ system_inouterr( 1, @_ ) };

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
