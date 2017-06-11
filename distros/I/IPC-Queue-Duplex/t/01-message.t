#!perl
# -*-cperl-*-
#
# 01-message.t - Test IPC::Queue::Duplex messaging
# Copyright (c) 2016 Ashish Gulhati <ipc-qd at hash dot neomailbox.ch>

use Test::More tests => 21;
use IPC::Queue::Duplex;

my $henry = new IPC::Queue::Duplex ( Dir => '/tmp' );
my $lisa = new IPC::Queue::Duplex ( Dir => '/tmp' );

SKIP: {
  skip "IPC::Queue::Duplex Objects not initialized", 21 unless $henry and $lisa;

  ok ($henry, 'Henry created');
  ok ($lisa, 'Lisa created');

  my ($s, $h, $l) = init();

  if (fork) {
    my $id = $henry->add($s);
    ok($id, sent($s));
    while (my $response = $id->response) {
      if ($h->{$response}) {
	ok(1, rcvd($response));
	$id = $henry->add($h->{$response});
	ok($id, sent($h->{$response}));
      }
      if ($response =~ /bucket/) {
	sleep 1; exit
      }
    }
  }
  else {
    while (1) {
      if (my $job = $lisa->get) {
	my $request = $job->{Request};
	$job->delete, last if $request =~ /But/;
	if ($l->{$request}) {
	  $job->finish($l->{$request});
	}
      }
    }
    exit;
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
