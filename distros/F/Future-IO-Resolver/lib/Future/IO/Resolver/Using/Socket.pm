#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2026 -- leonerd@leonerd.org.uk

package Future::IO::Resolver::Using::Socket 0.03;

use v5.20;
use warnings;

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use Future::IO 0.19 qw( POLLIN );
use Future::Utils qw( repeat );

# We don't want to import these as they'll get in the way of our named methods
use Socket qw();  # getaddrinfo getnameinfo

=head1 NAME

C<Future::IO::Resolver::Using::Socket> - implement L<Future::IO::Resolver> by wrapping the functions provided by L<Socket>

=head1 DESCRIPTION

This module provides a backend implementation for L<Future::IO::Resolver>
which uses the regular L<Socket> functions to perform lookups. In order to
operate asynchronously, these calls are made from a forked side-car process.

This should not be used directly, but is instead made available via the main
dispatch methods in C<Future::IO::Resolver> itself.

=cut

sub _serialise ( @values )
{
   if( !@values ) { return "\0" }
   if( @values > 255 ) { die "Cannot serialise list; too big" }

   return pack( "C", scalar @values ) .
      join( "", map { _serialise1( $_ ) } @values );
}

sub _serialise1 ( $v )
{
   if( !defined $v ) {
      return "U";
   }
   my $r = ref $v // "";
   if( $r eq "ARRAY" ) {
      return "[" . _serialise( @$v );
   }
   if( $r eq "HASH" ) {
      return "{" . _serialise( %$v );
   }
   if( $v =~ m/^-?\d+$/ ) {
      return "i" . pack( "i", $v );
   }
   else {
      my $l = length $v;
      return "s" . pack( "C", $l ) . $v if $l < 256;
      return "S" . pack( "I", $l ) . $v;
   }
}

sub _deserialise ( $sr )
{
   my $count = unpack( "C", substr $$sr, 0, 1, "" );
   my @v;
   push @v, _deserialise1( $sr ) for 1 .. $count;
   return @v;
}

sub _deserialise1 ( $sr )
{
   my $c = substr( $$sr, 0, 1, "" );
   if( $c eq "U" ) {
      return undef;
   }
   if( $c eq "{" ) {
      return +{
         _deserialise( $sr )
      };
   }
   if( $c eq "i" ) {
      return unpack( "i", substr( $$sr, 0, 4, "" ) );
   }
   if( $c eq "s" or $c eq "S" ) {
      my $l = ( $c eq "s" ) ? unpack( "C", substr( $$sr, 0, 1, "" ) ) :
                              unpack( "I", substr( $$sr, 0, 4, "" ) );
      return substr( $$sr, 0, $l, "" );
   }

   die "TODO: deserialise type $c";
}

my %resolvers;

sub run_in_child ( $rd, $wr )
{
   while( !eof $rd ) {
      $rd->read( my $buf, 4 );
      my $len = unpack "I", $buf;

      $buf = "";
      $rd->read( $buf, $len - length $buf, length $buf ) while $len > length $buf;

      my ( $func, @args ) = _deserialise( \$buf );

      my $code = $resolvers{$func};
      if( $code ) {
         my @result = $code->( @args );

         $wr->print( pack "I/a*", _serialise( @result ) );
      }
      else {
         $wr->print( pack "I/a*", _serialise( -1, "Unrecognised resolver func '$func'" ) );
      }
   }
}

my $runf;
my $wrpipe;
my @result_queue;

sub _start ()
{
   pipe( my $child_rd, $wrpipe ) or
      die "Cannot pipe() - $!";
   pipe( my $rdpipe, my $child_wr ) or
      die "Cannot pipe() - $!";
   $rdpipe->blocking(0);
   $wrpipe->blocking(0);
   $wrpipe->autoflush(1);

   defined( my $pid = fork() ) or
      die "Cannot fork() - $!";

   if( !$pid ) {
      # child
      undef $wrpipe;
      undef $rdpipe;

      $child_wr->autoflush(1);

      run_in_child( $child_rd, $child_wr );

      POSIX::_exit(5);
   }

   # parent
   undef $child_rd;
   undef $child_wr;

   my $waitf = Future::IO->waitpid( $pid )
      ->then( sub ( $wstatus ) {
         warn my $msg = "Future::IO::Resolver::Using::Socket child process died: $wstatus\n";
         $_->fail( $msg ) for @result_queue;
         undef $runf;
      } );

   my $recvf = Future::Utils::repeat {
      Future::IO->read_exactly( $rdpipe, 4 )->then( sub ( $buf ) {
         my $len = unpack "I", $buf;
         Future::IO->read_exactly( $rdpipe, $len );
      })->then( sub ( $buf ) {
         my $f = shift @result_queue or
            warn "ARGH no result future!";
         $f->done( $buf ) if $f;
         Future->done;
      });
   } while => sub ( $f ) { !$f->failure };

   return Future->wait_any( $waitf, $recvf );
}

sub _call ( $func, @args )
{
   $runf //= _start();

   $wrpipe->print( pack "I/a*", _serialise( $func, @args ) );

   push @result_queue, my $f = $runf->new;
   return $f->then( sub ( $buf ) {
      my ( $err, @result ) = _deserialise( \$buf );
      if( !$err ) {
         return Future->done( @result );
      }
      else {
         return Future->fail( "$result[0]\n", $func => );
      }
   } );
}

$resolvers{getaddrinfo} = sub ( @args ) {
   my ( $err, @res ) = Socket::getaddrinfo( @args );
   if( $err ) { return ( $err+0, "$err" ); }
   else       { return ( 0, @res ); }
};

sub getaddrinfo ( $, %args )
{
   my $host    = delete $args{host};
   my $service = delete $args{service};
   my %hints;
   $hints{$_} = delete $args{$_} for qw( family socktype protocol flags );

   return _call( getaddrinfo => $host, $service, \%hints );
}

$resolvers{getnameinfo} = sub ( @args ) {
   my ( $err, @res ) = Socket::getnameinfo( @args );
   if( $err ) { return ( $err+0, "$err" ); }
   else       { return ( 0, @res ); }
};

sub getnameinfo ( $, %args )
{
   my $addr  = delete $args{addr};
   my $flags = delete $args{flags} // 0;

   return _call( getnameinfo => $addr, $flags );
}

=head1 TODO

=over 4

=item *

The C<pipe()> + C<fork()> mechanism used internally should be extracted into a
shared helper module, as none of it is specific to name resolvers. It can then
be expanded to permit possibly multiple workers, etc. This would be similar to
the way that L<IO::Async::Resolver> uses L<IO::Async::Function>.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
