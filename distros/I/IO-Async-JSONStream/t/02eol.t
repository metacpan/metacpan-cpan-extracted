#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

use IO::Async::JSONStream;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socketpair - $!";

my $jsonstream = IO::Async::JSONStream->new(
   handle => $S1,
   on_json => sub {},
   on_json_error => sub {},
);

$loop->add( $jsonstream );

$jsonstream->configure(
   eol => "\x0d\x0a",
);

$jsonstream->write_json( [] );

my $stream = "";
wait_for_stream { $stream =~ m/.*\x0d\x0a/ } $S2 => $stream;

is( $stream, "[]\x0d\x0a", 'Stream written with CRLF EOL' );

$S2->syswrite( "[]\x0d\x0a" );

is_deeply( $jsonstream->read_json->get, [],
           'Stream reads with CRLF EOL' );

done_testing;
