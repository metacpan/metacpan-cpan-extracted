#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Fatal;
use Test::Refcount;

use Fcntl qw( SEEK_SET SEEK_END );
use File::Temp qw( tempfile );

use IO::Async::Loop;

use IO::Async::OS;

use IO::Async::FileStream;

use constant AUT => $ENV{TEST_QUICK_TIMERS} ? 0.1 : 1;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

sub mkhandles
{
   my ( $rd, $filename ) = tempfile( "tmpfile.XXXXXX", UNLINK => 1 );
   open my $wr, ">", $filename or die "Cannot reopen file for writing - $!";

   $wr->autoflush( 1 );

   return ( $rd, $wr, $filename );
}

{
   my ( $rd, $wr ) = mkhandles;

   my @lines;
   my $initial_size;

   my $filestream = IO::Async::FileStream->new(
      interval => 0.1 * AUT,
      read_handle => $rd,
      on_read => sub {
         my $self = shift;
         my ( $buffref, $eof ) = @_;

         push @lines, $1 while $$buffref =~ s/^(.*\n)//;
         return 0;
      },
      on_initial => sub { ( undef, $initial_size ) = @_ },
   );

   ok( defined $filestream, '$filestream defined' );
   isa_ok( $filestream, "IO::Async::FileStream", '$filestream isa IO::Async::FileStream' );

   is_oneref( $filestream, 'reading $filestream has refcount 1 initially' );

   $loop->add( $filestream );

   is_refcount( $filestream, 2, '$filestream has refcount 2 after adding to Loop' );

   is( $initial_size, 0, '$initial_size is 0' );

   $wr->syswrite( "message\n" );

   is_deeply( \@lines, [], '@lines before wait' );

   wait_for { scalar @lines };

   is_deeply( \@lines, [ "message\n" ], '@lines after wait' );

   $loop->remove( $filestream );
}

# on_initial
{
   my ( $rd, $wr ) = mkhandles;

   $wr->syswrite( "Some initial content\n" );

   my @lines;
   my $initial_size;

   my $filestream = IO::Async::FileStream->new(
      interval => 0.1 * AUT,
      read_handle => $rd,
      on_read => sub {
         my $self = shift;
         my ( $buffref, $eof ) = @_;

         push @lines, $1 while $$buffref =~ s/^(.*\n)//;
         return 0;
      },
      on_initial => sub { ( undef, $initial_size ) = @_ },
   );

   $loop->add( $filestream );

   is( $initial_size, 21, '$initial_size is 21' );

   $wr->syswrite( "More content\n" );

   wait_for { scalar @lines };

   is_deeply( \@lines, [ "Some initial content\n", "More content\n" ], 'All content is visible' );

   $loop->remove( $filestream );
}

# seek_to_last
{
   my ( $rd, $wr ) = mkhandles;

   $wr->syswrite( "Some skipped content\nWith a partial line" );

   my @lines;

   my $filestream = IO::Async::FileStream->new(
      interval => 0.1 * AUT,
      read_handle => $rd,
      on_read => sub {
         my $self = shift;
         my ( $buffref, $eof ) = @_;

         return 0 unless( $$buffref =~ s/^(.*\n)// );

         push @lines, $1;
         return 1;
      },
      on_initial => sub {
         my $self = shift;
         # Give it a tiny block size, forcing it to have to seek harder to find the \n
         ok( $self->seek_to_last( "\n", blocksize => 8 ), 'FileStream successfully seeks to last \n' );
      },
   );

   $loop->add( $filestream );

   $wr->syswrite( " finished here\n" );

   wait_for { scalar @lines };

   is_deeply( \@lines, [ "With a partial line finished here\n" ], 'Partial line completely returned' );

   $loop->remove( $filestream );
}

# on_initial can skip content
{
   my ( $rd, $wr ) = mkhandles;

   $wr->syswrite( "Some skipped content\n" );

   my @lines;

   my $filestream = IO::Async::FileStream->new(
      interval => 0.1 * AUT,
      read_handle => $rd,
      on_read => sub {
         my $self = shift;
         my ( $buffref, $eof ) = @_;

         return 0 unless( $$buffref =~ s/^(.*\n)// );

         push @lines, $1;
         return 1;
      },
      on_initial => sub { my $self = shift; $self->seek( 0, SEEK_END ); },
   );

   $loop->add( $filestream );

   $wr->syswrite( "Additional content\n" );

   wait_for { scalar @lines };

   is_deeply( \@lines, [ "Additional content\n" ], 'Initial content is skipped' );

   $loop->remove( $filestream );
}

# Truncation
{
   my ( $rd, $wr ) = mkhandles;

   my @lines;
   my $truncated;

   my $filestream = IO::Async::FileStream->new(
      interval => 0.1 * AUT,
      read_handle => $rd,
      on_read => sub {
         my $self = shift;
         my ( $buffref, $eof ) = @_;

         return 0 unless( $$buffref =~ s/^(.*\n)// );

         push @lines, $1;
         return 1;
      },
      on_truncated => sub { $truncated++ },
   );

   $loop->add( $filestream );

   $wr->syswrite( "Some original lines\nin the file\n" );

   wait_for { scalar @lines };
   
   $wr->truncate( 0 );
   sysseek( $wr, 0, SEEK_SET );
   $wr->syswrite( "And another\n" );

   wait_for { @lines == 3 };

   is( $truncated, 1, 'File content truncation detected' );
   is_deeply( \@lines,
      [ "Some original lines\n", "in the file\n", "And another\n" ],
      'All three lines read' );

   $loop->remove( $filestream );
}

# Follow by name
SKIP: {
   skip "OS is unable to rename open files", 7 unless IO::Async::OS->HAVE_RENAME_OPEN_FILES;

   my ( undef, $wr, $filename ) = mkhandles;

   my @lines;

   my $filestream = IO::Async::FileStream->new(
      interval => 0.1 * AUT,
      filename => $filename,
      on_read => sub {
         my $self = shift;
         my ( $buffref, $eof ) = @_;

         push @lines, $1 while $$buffref =~ s/^(.*\n)//;
         return 0;
      },
   );

   ok( defined $filestream, '$filestream defined for filenaem' );
   isa_ok( $filestream, "IO::Async::FileStream", '$filestream isa IO::Async::FileStream' );

   is_oneref( $filestream, 'reading $filestream has refcount 1 initially' );

   $loop->add( $filestream );

   is_refcount( $filestream, 2, '$filestream has refcount 2 after adding to Loop' );

   $wr->syswrite( "message\n" );
   wait_for { scalar @lines };

   is_deeply( \@lines, [ "message\n" ], '@lines after wait' );
   shift @lines;

   $wr->syswrite( "last line of old file\n" );
   close $wr;
   rename( $filename, "$filename.old" ) or die "Cannot rename $filename - $!";
   END { defined $filename and -f $filename and unlink $filename }
   END { defined $filename and -f "$filename.old" and unlink "$filename.old" }
   open $wr, ">", $filename or die "Cannot reopen $filename for writing - $!";
   $wr->syswrite( "first line of new file\n" );

   wait_for { scalar @lines };
   is_deeply( $lines[0], "last line of old file\n", '@lines sees last line of old file' );
   wait_for { scalar @lines >= 2 };
   is_deeply( $lines[1], "first line of new file\n", '@lines sees first line of new file' );

   $loop->remove( $filestream );
}

# Subclass
my @sub_lines;

{
   my ( $rd, $wr ) = mkhandles;

   my $filestream = TestStream->new(
      interval => 0.1 * AUT,
      read_handle => $rd,
   );

   ok( defined $filestream, 'subclass $filestream defined' );
   isa_ok( $filestream, "IO::Async::FileStream", '$filestream isa IO::Async::FileStream' );

   is_oneref( $filestream, 'subclass $filestream has refcount 1 initially' );

   $loop->add( $filestream );

   is_refcount( $filestream, 2, 'subclass $filestream has refcount 2 after adding to Loop' );

   $wr->syswrite( "message\n" );

   is_deeply( \@sub_lines, [], '@sub_lines before wait' );

   wait_for { scalar @sub_lines };

   is_deeply( \@sub_lines, [ "message\n" ], '@sub_lines after wait' );

   $loop->remove( $filestream );
}

done_testing;

package TestStream;
use base qw( IO::Async::FileStream );

sub on_read
{
   my $self = shift;
   my ( $buffref ) = @_;

   return 0 unless $$buffref =~ s/^(.*\n)//;

   push @sub_lines, $1;
   return 1;
}
