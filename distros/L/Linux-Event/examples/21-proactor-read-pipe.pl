#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event::Loop;

pipe(my $r, my $w) or die "pipe failed: $!";

my $loop = Linux::Event::Loop->new(model => 'proactor', backend => 'uring');

syswrite($w, "hello from proactor
") or die "syswrite failed: $!";
close $w;

$loop->read(
  fh          => $r,
  len         => 4096,
  on_complete => sub ($op, $result, $data) {
    die $op->error->message if $op->failed;

    chomp(my $line = $result->{data});
    say "read bytes=$result->{bytes} eof=$result->{eof} line=$line";
    $loop->stop;
  },
);

$loop->run;
