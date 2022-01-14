#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Test::Future::IO::Impl;

use strict;
use warnings;

our $VERSION = '0.11';

use Test::More;
use Test::Builder;

use Errno qw( EINVAL EPIPE );
use IO::Handle;
use Time::HiRes qw( time );

use Exporter 'import';
our @EXPORT = qw( run_tests );

=head1 NAME

C<Test::Future::IO::Impl> - acceptance tests for C<Future::IO> implementations

=head1 SYNOPSIS

   use Test::More;
   use Test::Future::IO::Impl;

   use Future::IO;
   use Future::IO::Impl::MyNewImpl;

   run_tests 'sleep';

   done_testing;

=head1 DESCRIPTION

This module contains a collection of acceptance tests for implementations of
L<Future::IO>.

=cut

=head1 FUNCTIONS

=cut

my $errstr_EPIPE = do {
   # On MSWin32 we don't get EPIPE, but EINVAL
   local $! = $^O eq "MSWin32" ? EINVAL : EPIPE; "$!";
};

my $errstr_ECONNREFUSED = do {
   local $! = Errno::ECONNREFUSED; "$!";
};

sub time_about(&@)
{
   my ( $code, $want_time, $name ) = @_;
   my $test = Test::Builder->new;

   my $t0 = time();
   $code->();
   my $t1 = time();

   my $got_time = $t1 - $t0;
   $test->ok(
      $got_time >= $want_time * 0.9 && $got_time <= $want_time * 1.5, $name
   ) or
      $test->diag( sprintf "Test took %.3f seconds", $got_time );
}

=head2 run_tests

   run_tests @suitenames

Runs a collection of tests against C<Future::IO>. It is expected that the
caller has already loaded the specific implementation module to be tested
against before this function is called.

=cut

sub run_tests
{
   foreach my $test ( @_ ) {
      my $code = __PACKAGE__->can( "run_${test}_test" )
         or die "Unrecognised test suite name $test";
      __PACKAGE__->$code();
   }
}

=head1 TEST SUITES

The following test suite names may be passed to the L</run_tests> function:

=cut

=head2 accept

Tests the C<< Future::IO->accept >> method.

=cut

sub run_accept_test
{
   require IO::Socket::INET;

   my $serversock = IO::Socket::INET->new(
      Type      => Socket::SOCK_STREAM(),
      LocalPort => 0,
      Listen    => 1,
   ) or die "Cannot socket()/listen() - $@";

   $serversock->blocking( 0 );

   my $f = Future::IO->accept( $serversock );

   my $sockname = $serversock->sockname;

   my $clientsock = IO::Socket::INET->new(
      Type => Socket::SOCK_STREAM(),
   ) or die "Cannot socket() - $@";
   $clientsock->connect( $sockname ) or die "Cannot connect() - $@";

   my $acceptedsock = $f->get;

   ok( $clientsock->peername eq $acceptedsock->sockname, 'Accepted socket address matches' );
}

=head2 connect

Tests the C<< Future::IO->connect >> method.

=cut

sub run_connect_test
{
   require IO::Socket::INET;

   my $serversock = IO::Socket::INET->new(
      Type      => Socket::SOCK_STREAM(),
      LocalPort => 0,
      Listen    => 1,
   ) or die "Cannot socket()/listen() - $@";

   my $sockname = $serversock->sockname;

   # ->connect success
   {
      my $clientsock = IO::Socket::INET->new(
         Type => Socket::SOCK_STREAM(),
      ) or die "Cannot socket() - $@";
      $clientsock->blocking( 0 );

      my $f = Future::IO->connect( $clientsock, $sockname );

      $f->get;

      my $acceptedsock = $serversock->accept;
      ok( $clientsock->peername eq $acceptedsock->sockname, 'Accepted socket address matches' );
   }

   $serversock->close;
   undef $serversock;

   # ->connect fails
   {
      my $clientsock = IO::Socket::INET->new(
         Type => Socket::SOCK_STREAM(),
      ) or die "Cannot socket() - $@";
      $clientsock->blocking( 0 );

      my $f = Future::IO->connect( $clientsock, $sockname );

      ok( !eval { $f->get; 1 }, 'Future::IO->connect fails on closed server' );

      is_deeply( [ $f->failure ],
         [ "connect: $errstr_ECONNREFUSED\n", connect => $clientsock, $errstr_ECONNREFUSED ],
         'Future::IO->connect failure' );
   }
}

=head2 sleep

Tests the C<< Future::IO->sleep >> method.

=cut

sub run_sleep_test
{
   my $test = Test::Builder->new;

   time_about sub {
      Future::IO->sleep( 0.2 )->get;
   }, 0.2, 'Future::IO->sleep( 0.2 ) sleeps 0.2 seconds';

   time_about sub {
      my $f1 = Future::IO->sleep( 0.1 );
      my $f2 = Future::IO->sleep( 0.3 );
      $f1->cancel;
      $f2->get;
   }, 0.3, 'Future::IO->sleep can be cancelled';

   {
      my $f1 = Future::IO->sleep( 0.1 );
      my $f2 = Future::IO->sleep( 0.3 );

      is( $f2->await, $f2, '->await returns Future' );
      ok( $f2->is_ready, '$f2 is ready after ->await' );
      ok( $f1->is_ready, '$f1 is also ready after ->await' );
   }

   time_about sub {
      Future::IO->alarm( time() + 0.2 )->get;
   }, 0.2, 'Future::IO->alarm( now + 0.2 ) sleeps 0.2 seconds';
}

=head2 sysread

Tests the C<< Future::IO->sysread >> method.

=cut

sub run_sysread_test
{
   # ->sysread yielding bytes
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

      $wr->autoflush();
      $wr->print( "BYTES" );

      my $f = Future::IO->sysread( $rd, 5 );

      is( scalar $f->get, "BYTES", 'Future::IO->sysread yields bytes from pipe' );
   }

   # ->sysread yielding EOF
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";
      $wr->close; undef $wr;

      my $f = Future::IO->sysread( $rd, 1 );

      is_deeply( [ $f->get ], [], 'Future::IO->sysread yields nothing on EOF' );
   }

   # TODO: is there a nice portable way we can test for an IO error?

   # ->sysread can be cancelled
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

      $wr->autoflush();
      $wr->print( "BYTES" );

      my $f1 = Future::IO->sysread( $rd, 3 );
      my $f2 = Future::IO->sysread( $rd, 3 );

      $f1->cancel;

      is( scalar $f2->get, "BYT", 'Future::IO->sysread can be cancelled' );
   }
}

=head2 syswrite

Tests the C<< Future::IO->syswrite >> method.

=cut

sub run_syswrite_test
{
   # ->syswrite success
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

      my $f = Future::IO->syswrite( $wr, "BYTES" );

      is( scalar $f->get, 5, 'Future::IO->syswrite yields written count' );

      $rd->read( my $buf, 5 );
      is( $buf, "BYTES", 'Future::IO->syswrite wrote bytes' );
   }

   # ->syswrite yielding EAGAIN
   SKIP: {
      $^O eq "MSWin32" and skip "MSWin32 doesn't do EAGAIN properly", 2;

      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";
      $wr->blocking( 0 );

      # Attempt to fill the pipe
      $wr->syswrite( "X" x 4096 ) for 1..256;

      my $f = Future::IO->syswrite( $wr, "more" );

      ok( !$f->is_ready, '$f is still pending' );

      # Now make some space
      $rd->read( my $buf, 4096 );

      is( scalar $f->get, 4, 'Future::IO->syswrite yields written count' );
   }

   # ->syswrite yielding EPIPE
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";
      $rd->close; undef $rd;

      local $SIG{PIPE} = 'IGNORE';

      my $f = Future::IO->syswrite( $wr, "BYTES" );

      ok( !eval { $f->get }, 'Future::IO->syswrite fails on EPIPE' );

      is_deeply( [ $f->failure ],
         [ "syswrite: $errstr_EPIPE\n", syswrite => $wr, $errstr_EPIPE ],
         'Future::IO->syswrite failure for EPIPE' );
   }

   # ->syswrite can be cancelled
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

      my $f1 = Future::IO->syswrite( $wr, "BY" );
      my $f2 = Future::IO->syswrite( $wr, "TES" );

      $f1->cancel;

      is( scalar $f2->get, 3, 'Future::IO->syswrite after cancelled one still works' );

      $rd->read( my $buf, 3 );
      is( $buf, "TES", 'Cancelled Future::IO->syswrite did not write bytes' );
   }
}

=head2 waitpid

Tests the C<< Future::IO->waitpid >> method.

=cut

sub run_waitpid_test
{
   # pre-exit
   {
      defined( my $pid = fork() ) or die "Unable to fork() - $!";
      if( $pid == 0 ) {
         # child
         exit 3;
      }

      Time::HiRes::sleep 0.1;

      my $f = Future::IO->waitpid( $pid );
      is( scalar $f->get, ( 3 << 8 ), 'Future::IO->waitpid yields child wait status for pre-exit' );
   }

   # post-exit
   {
      defined( my $pid = fork() ) or die "Unable to fork() - $!";
      if( $pid == 0 ) {
         # child
         Time::HiRes::sleep 0.1;
         exit 4;
      }

      my $f = Future::IO->waitpid( $pid );
      is( scalar $f->get, ( 4 << 8 ), 'Future::IO->waitpid yields child wait status for post-exit' );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
