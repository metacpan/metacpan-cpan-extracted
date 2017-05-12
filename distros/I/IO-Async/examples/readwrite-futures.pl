#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Stream;

my $loop = IO::Async::Loop->new;

$loop->add( my $stdin  = IO::Async::Stream->new_for_stdin( on_read => sub { 0 } ) );
$loop->add( my $stdout = IO::Async::Stream->new_for_stdout );

$stdout->write( sub {
   return undef if $stdin->is_read_eof;
   return $stdin->read_atmost( 64 * 1024 );
})->get;
