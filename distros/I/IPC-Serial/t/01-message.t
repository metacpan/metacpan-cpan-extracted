#!perl -T
# -*-cperl-*-
#
# 01-message.t - Test IPC::Serial messaging
# Copyright (c) 2016-2017 Ashish Gulhati <ipc-serial at hash.neo.tc>

use Test::More tests => 21;
use IPC::Serial;

SKIP: {
  skip "IPC::Serial tests require 2 serial ports connected by a null modem cable.\nSet IPCSERIALTEST variable to enable tests",
    21 unless $ENV{IPCSERIALTEST};

  my $henry = new IPC::Serial (Port => '/dev/cuaU0');
  my $lisa = new IPC::Serial (Port => '/dev/cuaU1');

  skip "IPC::Serial Objects not initialized", 21 unless $henry and $lisa;

  ok ($henry, 'Henry created');
  ok ($lisa, 'Lisa created');

  my ($s, $h, $l) = init();

  if (fork) {
    ok($henry->sendmsg($s), sent($s));
    while (my $msg = $henry->getmsg) {
      if ($h->{$msg}) {
	ok(1, rcvd($msg));
	ok($henry->sendmsg($h->{$msg}), sent($h->{$msg}));
      }
      if ($msg =~ /bucket/) {
	sleep 1; $henry->close; exit
      }
    }
  }
  else {
    while (my $msg = $lisa->getmsg) {
      last if $msg =~ /But/;
      if ($l->{$msg}) {
	$lisa->sendmsg($l->{$msg});
      }
    }
    $lisa->close; exit;
  }
};

sub sent {
  my $line = shift; $line =~ s/\,.*//; "H: $line"
}

sub rcvd {
  my $line = shift; $line =~ s/\,.*//; "L: $line"
}

sub init {
  my @song  = ( "There's a hole in the bucket, dear Liza, dear Liza, There's a hole in the bucket, dear Liza, a hole."
		=> "Then fix it, dear Henry, dear Henry, dear Henry, Then fix it, dear Henry, dear Henry, fix it."
		=> "With what shall I fix it, dear Liza, dear Liza? With what shall I fix it, dear Liza, with what?"
		=> "With straw, dear Henry, dear Henry, dear Henry, With straw, dear Henry, dear Henry, with straw."
		=> "The straw is too long, dear Liza, dear Liza, The straw is too long, dear Liza, too long."
		=> "Then cut it, dear Henry, dear Henry, dear Henry, Then cut it, dear Henry, dear Henry, cut it."
		=> "With what shall I cut it, dear Liza, dear Liza? With what shall I cut it, dear Liza, with what?"
		=> "With an axe, dear Henry, dear Henry, dear Henry, With an axe, dear Henry, dear Henry, an axe."
		=> "The axe is too dull, dear Liza, dear Liza, The axe is too dull, dear Liza, too dull."
		=> "Then sharpen it, dear Henry, dear Henry, dear Henry, Then sharpen it, dear Henry, dear Henry, hone it."
		=> "With what shall I sharpen it, dear Liza, dear Liza? With what shall I hone it, dear Liza, with what?"
		=> "With a stone, dear Henry, dear Henry, dear Henry, With a stone, dear Henry, dear Henry, a stone."
		=> "The stone is too dry, dear Liza, dear Liza, The stone is too dry, dear Liza, too dry."
		=> "Then wet it, dear Henry, dear Henry, dear Henry, Then wet it, dear Henry, dear Henry, moisten it."
		=> "With what shall I wet it, dear Liza, dear Liza? With what shall I moisten it, dear Liza, with what?"
		=> "With water, dear Henry, dear Henry, dear Henry, With water, dear Henry, dear Henry, try water."
		=> "In what shall I carry it, dear Liza, dear Liza? In what shall I carry it, dear Liza, in what?"
		=> "In a bucket, dear Henry, dear Henry, dear Henry, In a bucket, dear Henry, dear Henry, in a bucket."
		=> "But... There's a hole in my bucket, dear Liza, dear Liza, There's a hole in my bucket, dear Liza, a hole."
	      );
  my %h = @song[1..$#song]; my %l = @song;
  return ($song[0], \%h, \%l);
}
