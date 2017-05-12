#!/usr/bin/perl

BEGIN {
    require FindBin;
}

use strict;
use warnings;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../t/lib";

use Benchmark   qw[timethese];
use HTTP::Body  qw[];
use IO::File    qw[O_RDONLY];
use PAML        qw[LoadFile];

my $headers = LoadFile("t/data/multipart/003-headers.pml");

my $run = sub {
      my $bsize   = shift;
      my $content = IO::File->new( "$FindBin::Bin/../t/data/multipart/003-content.dat", O_RDONLY );
      my $body    = HTTP::Body->new( $headers->{'Content-Type'}, $headers->{'Content-Length'} );

      binmode($content);

      while ( $content->sysread( my $buffer, $bsize ) ) {
          $body->add($buffer);
      }

      unless ( $body->state eq 'done' ) {
          die 'baaaaaaaaad';
      }
};


timethese( 1_000, {
    'HTTP::Body  256' => sub {  $run->(256) },
    'HTTP::Body 1024' => sub { $run->(1024) },
    'HTTP::Body 4096' => sub { $run->(4096) },
    'HTTP::Body 8192' => sub { $run->(8192) },
});
