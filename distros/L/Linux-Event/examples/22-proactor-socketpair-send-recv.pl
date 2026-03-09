#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Socket qw(AF_UNIX SOCK_STREAM);
use Linux::Event::Loop;

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, 0)
  or die "socketpair failed: $!";

my $loop = Linux::Event::Loop->new(model => 'proactor', backend => 'uring');

$loop->send(
  fh          => $a,
  buf         => "ping
",
  flags       => 0,
  on_complete => sub ($op, $result, $data) {
    die $op->error->message if $op->failed;
    say "sent bytes=$result->{bytes}";
  },
);

$loop->recv(
  fh          => $b,
  len         => 4096,
  flags       => 0,
  on_complete => sub ($op, $result, $data) {
    die $op->error->message if $op->failed;
    chomp(my $line = $result->{data});
    say "received bytes=$result->{bytes} eof=$result->{eof} line=$line";
    $loop->stop;
  },
);

$loop->run;
