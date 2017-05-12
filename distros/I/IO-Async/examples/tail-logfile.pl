#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::FileStream;

my $FILE = shift @ARGV or die "Need FILE";

my $loop = IO::Async::Loop->new;

open my $fh, "<", $FILE or die "Cannot open $FILE for reading - $!";
my $filestream = IO::Async::FileStream->new(
   read_handle => $fh,
   on_initial => sub {
      my ( $self ) = @_;
      $self->seek_to_last( "\n" );
   },
   on_read => sub {
      my ( undef, $buffref ) = @_;

      while( $$buffref =~ s/^(.*)\n// ) {
         print "$FILE: $1\n";
      }

      return 0;
   },
);
$loop->add( $filestream );

$loop->run;
