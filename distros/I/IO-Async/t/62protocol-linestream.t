#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Refcount;

use IO::Async::Loop;

use IO::Async::OS;

use IO::Async::Protocol::LineStream;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair or die "Cannot create socket pair - $!";

# Need sockets in nonblocking mode
$S1->blocking( 0 );
$S2->blocking( 0 );

my @lines;

my $linestreamproto = IO::Async::Protocol::LineStream->new(
   handle => $S1,
   on_read_line => sub {
      my $self = shift;

      push @lines, $_[0];
   },
);

ok( defined $linestreamproto, '$linestreamproto defined' );
isa_ok( $linestreamproto, "IO::Async::Protocol::LineStream", '$linestreamproto isa IO::Async::Protocol::LineStream' );

is_oneref( $linestreamproto, '$linestreamproto has refcount 1 initially' );

$loop->add( $linestreamproto );

is_refcount( $linestreamproto, 2, '$linestreamproto has refcount 2 after adding to Loop' );

$S2->syswrite( "message\r\n" );

is_deeply( \@lines, [], '@lines before wait' );

wait_for { scalar @lines };

is_deeply( \@lines, [ "message" ], '@lines after wait' );

undef @lines;
my @new_lines;
$linestreamproto->configure( 
   on_read_line => sub {
      my $self = shift;

      push @new_lines, $_[0];
   },
);

$S2->syswrite( "new\r\nlines\r\n" );

wait_for { scalar @new_lines };

is( scalar @lines, 0, '@lines still empty after on_read replace' );
is_deeply( \@new_lines, [ "new", "lines" ], '@new_lines after on_read replace' );

$linestreamproto->write_line( "response" );

my $response = "";
wait_for_stream { $response =~ m/\r\n/ } $S2 => $response;

is( $response, "response\r\n", 'response written by protocol' );

my @sub_lines;

$linestreamproto = TestProtocol::Stream->new(
   handle => $S1,
);

ok( defined $linestreamproto, 'subclass $linestreamproto defined' );
isa_ok( $linestreamproto, "IO::Async::Protocol::LineStream", '$linestreamproto isa IO::Async::Protocol::LineStream' );

is_oneref( $linestreamproto, 'subclass $linestreamproto has refcount 1 initially' );

$loop->add( $linestreamproto );

is_refcount( $linestreamproto, 2, 'subclass $linestreamproto has refcount 2 after adding to Loop' );

$S2->syswrite( "message\r\n" );

is_deeply( \@sub_lines, [], '@sub_lines before wait' );

wait_for { scalar @sub_lines };

is_deeply( \@sub_lines, [ "message" ], '@sub_lines after wait' );

undef @lines;

$loop->remove( $linestreamproto );

undef $linestreamproto;

done_testing;

package TestProtocol::Stream;
use base qw( IO::Async::Protocol::LineStream );

sub on_read_line
{
   my $self = shift;

   push @sub_lines, $_[0];
}
