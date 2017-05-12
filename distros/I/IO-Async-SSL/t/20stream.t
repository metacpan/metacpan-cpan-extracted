#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Test;

use IO::Async::Loop;
use IO::Async::SSL;

my $loop = IO::Async::Loop->new;

testing_loop( $loop );

my $listen_sock;
my $a_stream;

$loop->SSL_listen(
   family  => "inet",
   host    => "localhost",
   service => "4433",

   SSL_key_file  => "t/privkey.pem",
   SSL_cert_file => "t/server.pem",

   on_listen => sub { $listen_sock = shift },
   on_stream => sub { $a_stream = shift },

   on_resolve_error => sub { die "Cannot resolve - $_[-1]\n" },
   on_listen_error  => sub { die "Cannot listen - $_[-1]\n" },
   on_ssl_error     => sub { die "SSL error - $_[-1]\n" },
);

wait_for { defined $listen_sock };

my $c_stream;

$loop->SSL_connect(
   family  => "inet",
   host    => "localhost",
   service => "4433",

   SSL_verify_mode => 0,

   on_stream => sub { $c_stream = shift },

   on_resolve_error => sub { die "Cannot resolve - $_[-1]\n" },
   on_connect_error => sub { die "Cannot connect\n" },
   on_ssl_error     => sub { die "SSL error - $_[-1]\n" },
);

wait_for { defined $c_stream and defined $a_stream };

my @c_lines;
$c_stream->configure(
   on_read => sub {
      my ( $self, $buffref, $closed ) = @_;
      push @c_lines, $1 while $$buffref =~ s/^(.*)\n//;
      return 0;
   },
);
$loop->add( $c_stream );

my @a_lines;
$a_stream->configure(
   on_read => sub {
      my ( $self, $buffref, $closed ) = @_;
      push @a_lines, $1 while $$buffref =~ s/^(.*)\n//;
      return 0;
   },
);
$loop->add( $a_stream );

$a_stream->write( "Send a line\n" );

wait_for { @c_lines };

is( $c_lines[0], "Send a line", 'Line received by openssl' );

$c_stream->write( "Reply a line\n" );

wait_for { @a_lines };

is( $a_lines[0], "Reply a line", 'Line received by local socket' );

done_testing;
