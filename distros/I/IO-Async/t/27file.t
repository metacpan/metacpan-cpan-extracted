#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Refcount;

use Fcntl qw( SEEK_SET SEEK_END );
use File::Temp qw( tempfile );

use IO::Async::Loop;

use IO::Async::OS;

use IO::Async::File;

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

   my $size_change;
   my ( $new_size, $old_size );
   my ( $new_stat, $old_stat );
   my $file = IO::Async::File->new(
      interval => 0.1 * AUT,
      handle => $rd,
      on_size_changed => sub {
         ( undef, $new_size, $old_size ) = @_;
         $size_change++;
      },
      on_stat_changed => sub {
         ( undef, $new_stat, $old_stat ) = @_;
      },
   );

   ok( defined $file, '$file defined' );
   isa_ok( $file, "IO::Async::File", '$file isa IO::Async::File' );

   is_oneref( $file, '$file has refcount 1 initially' );

   is( $file->handle, $rd, '$file->handle is $rd' );

   $loop->add( $file );

   is_refcount( $file, 2, '$file has refcount 2 after adding to Loop' );

   $wr->syswrite( "message\n" );

   wait_for { $size_change };

   is( $old_size, 0, '$old_size' );
   is( $new_size, 8, '$new_size' );

   isa_ok( $old_stat, "File::stat", '$old_stat isa File::stat' );
   isa_ok( $new_stat, "File::stat", '$new_stat isa File::stat' );

   $loop->remove( $file );
}

# Follow by name
SKIP: {
   skip "OS is unable to rename open files", 3 unless IO::Async::OS->HAVE_RENAME_OPEN_FILES;

   my ( undef, $wr, $filename ) = mkhandles;

   my $devino_changed;
   my ( $old_stat, $new_stat );
   my $file = IO::Async::File->new(
      interval => 0.1 * AUT,
      filename => $filename,
      on_devino_changed => sub {
         ( undef, $new_stat, $old_stat ) = @_;
         $devino_changed++;
      },
   );

   ok( $file->handle, '$file has a ->handle' );

   $loop->add( $file );

   close $wr;
   rename( $filename, "$filename.old" ) or die "Cannot rename $filename - $!";
   END { defined $filename and -f $filename and unlink $filename }
   END { defined $filename and -f "$filename.old" and unlink "$filename.old" }
   open $wr, ">", $filename or die "Cannot reopen $filename for writing - $!";

   wait_for { $devino_changed };

   is( $new_stat->dev, (stat $wr)[0], '$new_stat->dev for renamed file' );
   is( $new_stat->ino, (stat $wr)[1], '$new_stat->ino for renamed file' );

   $loop->remove( $file );
}

done_testing;
