#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Fatal;
use Test::Refcount;

use IO::File;
use POSIX qw( ECONNRESET );

use IO::Async::Loop;

use IO::Async::OS;

use IO::Async::Stream;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

sub mkhandles
{
   my ( $rd, $wr ) = IO::Async::OS->pipepair or die "Cannot pipe() - $!";
   # Need handles in nonblocking mode
   $rd->blocking( 0 );
   $wr->blocking( 0 );

   return ( $rd, $wr );
}

{
   my ( $rd, $wr ) = mkhandles;

   my @lines;

   my $stream = IO::Async::Stream->new( 
      read_handle => $rd,
      on_read => sub {
         my $self = shift;
         my ( $buffref, $eof ) = @_;

         push @lines, $1 while $$buffref =~ s/^(.*\n)//;
         return 0;
      },
   );

   ok( defined $stream, 'reading $stream defined' );
   isa_ok( $stream, "IO::Async::Stream", 'reading $stream isa IO::Async::Stream' );

   is_oneref( $stream, 'reading $stream has refcount 1 initially' );

   $loop->add( $stream );

   is_refcount( $stream, 2, 'reading $stream has refcount 2 after adding to Loop' );

   $wr->syswrite( "message\n" );

   is_deeply( \@lines, [], '@lines before wait' );

   wait_for { scalar @lines };

   is_deeply( \@lines, [ "message\n" ], '@lines after wait' );

   undef @lines;

   $wr->syswrite( "return" );

   $loop->loop_once( 0.1 ); # nothing happens

   is_deeply( \@lines, [], '@lines partial still empty' );

   $wr->syswrite( "\n" );

   wait_for { scalar @lines };

   is_deeply( \@lines, [ "return\n" ], '@lines partial completed now received' );

   undef @lines;

   $wr->syswrite( "hello\nworld\n" );
   wait_for { scalar @lines };

   is_deeply( \@lines, [ "hello\n", "world\n" ], '@lines two at once' );

   undef @lines;
   my @new_lines;
   $stream->configure( 
      on_read => sub {
         my $self = shift;
         my ( $buffref, $eof ) = @_;

         push @new_lines, $1 while $$buffref =~ s/^(.*\n)//;
         return 0;
      },
   );

   $wr->syswrite( "new\nlines\n" );

   wait_for { scalar @new_lines };

   is( scalar @lines, 0, '@lines still empty after on_read replace' );
   is_deeply( \@new_lines, [ "new\n", "lines\n" ], '@new_lines after on_read replace' );

   is_refcount( $stream, 2, 'reading $stream has refcount 2 before removing from Loop' );

   $loop->remove( $stream );

   is_oneref( $stream, 'reading $stream refcount 1 finally' );
}

# Abstract reading with reader function
{
   my ( $rd, $wr ) = mkhandles;
   my $buffer = "Here is the contents\n";

   my @lines;
   my $stream = IO::Async::Stream->new(
      read_handle => $rd,
      reader => sub {
         my $self = shift;
         my $more = substr( $buffer, 0, $_[2], "" );
         $_[1] .= $more;
         return length $more;
      },
      on_read => sub {
         my $self = shift;
         my ( $buffref, $eof ) = @_;

         push @lines, $1 while $$buffref =~ s/^(.*\n)//;
         return 0;
      },
   );

   $loop->add( $stream );

   # make it readready
   $wr->syswrite( "1" );

   wait_for { scalar @lines };

   is_deeply( \@lines, [ "Here is the contents\n" ], '@lines from stream with abstract reader' );

   $loop->remove( $stream );
}

# ->want_readready_for_write
{
   my ( $rd, $wr ) = mkhandles;

   my $reader_called;
   my $writer_called;
   my $stream = IO::Async::Stream->new(
      handle => $rd,
      on_read => sub { return 0; }, # ignore reading
      reader => sub { $reader_called++; sysread( $rd, $_[2], $_[3] ) },
      writer => sub { $writer_called++; return 1 },
   );

   $loop->add( $stream );

   # Hacky hack - make the stream want to write, but don't mark the stream write-ready
   $stream->write( "A" );
   $stream->want_writeready_for_write( 0 );
   # End hack

   # make it readready
   $wr->syswrite( "1" );

   wait_for { $reader_called };

   ok( !$writer_called, 'writer not yet called before ->want_readready_for_write' );

   $stream->want_readready_for_write( 1 );

   undef $reader_called;
   $wr->syswrite( "2" );
   wait_for { $reader_called && $writer_called };

   ok( $writer_called, 'writer now invoked with ->want_readready_for_write' );

   $loop->remove( $stream );
}

{
   my ( $rd, $wr ) = mkhandles;

   my @chunks;

   my $stream = IO::Async::Stream->new(
      read_handle => $rd,
      read_len => 2,
      on_read => sub {
         my ( $self, $buffref, $eof ) = @_;
         push @chunks, $$buffref;
         $$buffref = "";
      },
   );

   $loop->add( $stream );

   $wr->syswrite( "partial" );

   wait_for { scalar @chunks };

   is_deeply( \@chunks, [ "pa" ], '@lines with read_len=2 without read_all' );

   wait_for { @chunks == 4 };

   is_deeply( \@chunks, [ "pa", "rt", "ia", "l" ], '@lines finally with read_len=2 without read_all' );

   undef @chunks;
   $stream->configure( read_all => 1 );

   $wr->syswrite( "partial" );

   wait_for { scalar @chunks };

   is_deeply( \@chunks, [ "pa", "rt", "ia", "l" ], '@lines with read_len=2 with read_all' );

   $loop->remove( $stream );
}

{
   my ( $rd, $wr ) = mkhandles;

   my $no_on_read_stream;
   ok( !exception { $no_on_read_stream = IO::Async::Stream->new( read_handle => $rd ) },
       'Allowed to construct a Stream without an on_read handler' );
   ok( exception { $loop->add( $no_on_read_stream ) },
       'Not allowed to add an on_read-less Stream to a Loop' );
}

# Subclass
my @sub_lines;

{
   my ( $rd, $wr ) = mkhandles;

   my $stream = TestStream->new(
      read_handle => $rd,
   );

   ok( defined $stream, 'reading subclass $stream defined' );
   isa_ok( $stream, "IO::Async::Stream", 'reading $stream isa IO::Async::Stream' );

   is_oneref( $stream, 'subclass $stream has refcount 1 initially' );

   $loop->add( $stream );

   is_refcount( $stream, 2, 'subclass $stream has refcount 2 after adding to Loop' );

   $wr->syswrite( "message\n" );

   is_deeply( \@sub_lines, [], '@sub_lines before wait' );

   wait_for { scalar @sub_lines };

   is_deeply( \@sub_lines, [ "message\n" ], '@sub_lines after wait' );

   $loop->remove( $stream );
}

# Dynamic on_read chaining
{
   my ( $rd, $wr ) = mkhandles;

   my $outer_count = 0;
   my $inner_count = 0;

   my $record;

   my $stream = IO::Async::Stream->new(
      read_handle => $rd,
      on_read => sub {
         my ( $self, $buffref, $eof ) = @_;
         $outer_count++;

         return 0 unless $$buffref =~ s/^(.*\n)//;

         my $length = $1;

         return sub {
            my ( $self, $buffref, $eof ) = @_;
            $inner_count++;

            return 0 unless length $$buffref >= $length;

            $record = substr( $$buffref, 0, $length, "" );

            return undef;
         }
      },
   );

   is_oneref( $stream, 'dynamic reading $stream has refcount 1 initially' );

   $loop->add( $stream );

   $wr->syswrite( "11" ); # No linefeed yet
   wait_for { $outer_count > 0 };
   is( $outer_count, 1, '$outer_count after idle' );
   is( $inner_count, 0, '$inner_count after idle' );

   $wr->syswrite( "\n" );
   wait_for { $inner_count > 0 };
   is( $outer_count, 2, '$outer_count after received length' );
   is( $inner_count, 1, '$inner_count after received length' );

   $wr->syswrite( "Hello " );
   wait_for { $inner_count > 1 };
   is( $outer_count, 2, '$outer_count after partial body' );
   is( $inner_count, 2, '$inner_count after partial body' );

   $wr->syswrite( "world" );
   wait_for { $inner_count > 2 };
   is( $outer_count, 3, '$outer_count after complete body' );
   is( $inner_count, 3, '$inner_count after complete body' );
   is( $record, "Hello world", '$record after complete body' );

   $loop->remove( $stream );

   is_oneref( $stream, 'dynamic reading $stream has refcount 1 finally' );
}

# ->push_on_read
{
   my ( $rd, $wr ) = mkhandles;

   my $base;
   my $stream = IO::Async::Stream->new( read_handle => $rd,
      on_read => sub {
         my ( $self, $buffref ) = @_;
         $base = $$buffref; $$buffref = "";
         return 0;
      },
   );

   $loop->add( $stream );

   my $firstline;
   $stream->push_on_read(
      sub {
         my ( $stream, $buffref, $eof ) = @_;
         return 0 unless $$buffref =~ s/(.*)\n//;
         $firstline = $1;
         return undef;
      }
   );

   my $eightbytes;
   $stream->push_on_read(
      sub {
         my ( $stream, $buffref, $eof ) = @_;
         return 0 unless length $$buffref >= 8;
         $eightbytes = substr( $$buffref, 0, 8, "" );
         return undef;
      }
   );

   $wr->syswrite( "The first line\nABCDEFGHIJK" );

   wait_for { defined $firstline and defined $eightbytes };

   is( $firstline,  "The first line", '$firstline from ->push_on_read CODE' );
   is( $eightbytes, "ABCDEFGH",       '$eightbytes from ->push_on_read CODE' );
   is( $base,       "IJK",            '$base from ->push_on_read CODE' );

   $loop->remove( $stream );
}

# EOF
{
   my ( $rd, $wr ) = mkhandles;

   my $eof = 0;
   my $partial;

   my $stream = IO::Async::Stream->new( read_handle => $rd,
      on_read => sub {
         my ( undef, $buffref, $eof ) = @_;
         $partial = $$buffref if $eof;
         return 0;
      },
      on_read_eof => sub { $eof++ },
   );

   $loop->add( $stream );

   $wr->syswrite( "Incomplete" );

   $wr->close;

   ok( !$stream->is_read_eof, '$stream ->is_read_eof before wait' );
   is( $eof, 0, 'EOF indication before wait' );

   wait_for { $eof };

   ok( $stream->is_read_eof, '$stream ->is_read_eof after wait' );
   is( $eof, 1, 'EOF indication after wait' );
   is( $partial, "Incomplete", 'EOF stream retains partial input' );

   ok( !defined $stream->loop, 'EOF stream no longer member of Loop' );
   ok( !defined $stream->read_handle, 'Stream no longer has a read_handle' );
}

# Disabled close_on_read_eof
{
   my ( $rd, $wr ) = mkhandles;

   my $eof = 0;
   my $partial;

   my $stream = IO::Async::Stream->new( read_handle => $rd,
      on_read => sub {
         my ( undef, $buffref, $eof ) = @_;
         $partial = $$buffref if $eof;
         return 0;
      },
      on_read_eof => sub { $eof++ },
      close_on_read_eof => 0,
   );

   $loop->add( $stream );

   $wr->syswrite( "Incomplete" );

   $wr->close;

   is( $eof, 0, 'EOF indication before wait' );

   wait_for { $eof };

   is( $eof, 1, 'EOF indication after wait' );
   is( $partial, "Incomplete", 'EOF stream retains partial input' );

   ok( defined $stream->loop, 'EOF stream still member of Loop' );
   ok( defined $stream->read_handle, 'Stream still has a read_handle' );
}

# Close
{
   my ( $rd, $wr ) = mkhandles;

   my $closed = 0;
   my $loop_during_closed;

   my $stream = IO::Async::Stream->new( read_handle => $rd,
      on_read   => sub { },
      on_closed => sub {
         my ( $self ) = @_;
         $closed = 1;
         $loop_during_closed = $self->loop;
      },
   );

   is_oneref( $stream, 'closing $stream has refcount 1 initially' );

   $loop->add( $stream );

   is_refcount( $stream, 2, 'closing $stream has refcount 2 after adding to Loop' );

   is( $closed, 0, 'closed before close' );

   $stream->close;

   is( $closed, 1, 'closed after close' );
   is( $loop_during_closed, $loop, 'loop during closed' );

   ok( !defined $stream->loop, 'Stream no longer member of Loop' );

   is_oneref( $stream, 'closing $stream refcount 1 finally' );
}

# ->read Futures
{
   my ( $rd, $wr ) = mkhandles;

   my $stream = IO::Async::Stream->new( read_handle => $rd,
      on_read => sub {
         my ( $self, $buffref ) = @_;
         die "Base on_read invoked with data in the buffer" if length $$buffref;
         return 0;
      },
   );

   $loop->add( $stream );

   my $f_atmost = $stream->read_atmost( 256 );

   $wr->syswrite( "Some data\n" );
   wait_for { $f_atmost->is_ready };

   is( scalar $f_atmost->get, "Some data\n", '->read_atmost' );

   my $f_exactly   = $stream->read_exactly( 4 );
   my $f_until_qr  = $stream->read_until( qr/[A-Z][a-z]*/ );
   my $f_until_str = $stream->read_until( "\n" );

   $wr->syswrite( "Here is the First line of input\n" );

   wait_for { $f_exactly->is_ready and $f_until_qr->is_ready and $f_until_str->is_ready };

   is( scalar $f_exactly->get,   "Here", '->read_exactly' );
   is( scalar $f_until_qr->get,  " is the First", '->read_until regexp' );
   is( scalar $f_until_str->get, " line of input\n", '->read_until str' );

   my $f_first = $stream->read_until( "\n" );
   my $f_second = $stream->read_until( "\n" );
   $f_first->cancel;

   $wr->syswrite( "For the second\n" );

   wait_for { $f_second->is_ready };

   is( scalar $f_second->get, "For the second\n", 'Second ->read_until recieves data after first is ->cancelled' );

   my $f_until_eof = $stream->read_until_eof;

   $wr->syswrite( "And the rest of it" );
   $wr->close;

   wait_for { $f_until_eof->is_ready };

   is( scalar $f_until_eof->get, "And the rest of it", '->read_until_eof' );

   # No need to remove as ->close did it
}

# RT101774
{
   my ( $rd, $wr ) = mkhandles;

   my $stream = IO::Async::Stream->new( read_handle => $rd,
      on_read => sub { 0 },
   );

   $loop->add( $stream );

   $wr->syswrite( "lalaLALA" );

   my $f = wait_for_future $stream->read_exactly( 4 )->then( sub {
      $stream->read_exactly( 4 );
   });

   is( scalar $f->get, "LALA", 'chained ->read_exactly' );

   $loop->remove( $stream );
}

# watermarks
{
   my ( $rd, $wr ) = mkhandles;

   my $high_hit = 0;
   my $low_hit  = 0;

   my $stream = IO::Async::Stream->new(
      read_handle => $rd,
      on_read => sub { 0 }, # we'll work by Futures
      read_high_watermark => 8,
      read_low_watermark  => 4,
      on_read_high_watermark => sub { $high_hit++ },
      on_read_low_watermark  => sub { $low_hit++ },
   );

   $loop->add( $stream );

   $wr->syswrite( "1234567890" );

   wait_for { $high_hit };
   ok( 1, "Reading too much hits high watermark" );

   is( $stream->read_exactly( 8 )->get, "12345678", 'Stream->read_exactly yields bytes' );

   is( $low_hit, 1, 'Low watermark hit after ->read' );
}

# Errors
{
   my ( $rd, $wr ) = mkhandles;
   $wr->syswrite( "X" ); # ensuring $rd is read-ready

   no warnings 'redefine';
   local *IO::Handle::sysread = sub {
      $! = ECONNRESET;
      return undef;
   };

   my $read_errno;

   my $stream = IO::Async::Stream->new(
      read_handle => $rd,
      on_read => sub {},
      on_read_error  => sub { ( undef, $read_errno ) = @_ },
   );

   $loop->add( $stream );

   wait_for { defined $read_errno };

   cmp_ok( $read_errno, "==", ECONNRESET, 'errno after failed read' );

   my $f = wait_for_future $stream->read_atmost( 256 );

   cmp_ok( ( $f->failure )[-1], "==", ECONNRESET, 'failure from ->read_atmost after failed read' );

   $loop->remove( $stream );
}

{
   binmode STDIN; # Avoid harmless warning in case -CS is in effect
   my $stream = IO::Async::Stream->new_for_stdin;
   is( $stream->read_handle, \*STDIN, 'Stream->new_for_stdin->read_handle is STDIN' );
}

done_testing;

package TestStream;
use base qw( IO::Async::Stream );

sub on_read
{
   my $self = shift;
   my ( $buffref, $eof ) = @_;

   return 0 unless $$buffref =~ s/^(.*\n)//;

   push @sub_lines, $1;
   return 1;
}
