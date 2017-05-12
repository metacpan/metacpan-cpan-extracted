#!perl -T

use strict;
use warnings;

use Test::More tests => 52;

my $class = 'Games::Bowling::Scorecard::Frame::TenPinTenth';

use_ok($class);

{ # let's bowl an open frame
  my $frame = $class->new;

  isa_ok($frame, $class);

  is($frame->score, 0,     "frames start with a zero score");
  ok(! $frame->is_done,    "frames do not start done");
  ok(! $frame->is_pending, "frames do not start pending");

  $frame->record(5);
  is($frame->score, 5,     "one ball for five pins: tentative score 5");
  ok(! $frame->is_done,    "one ball for five pins: not done yet");
  ok(! $frame->is_pending, "one ball for five pins: not pending");

  $frame->record(3);
  is($frame->score, 8,     "bowled 5/3: score 8");
  ok($frame->is_done,      "after two balls, we're done");
  ok(! $frame->is_pending, "an open frame doesn't end up pending");
}

{ # let's bowl a spare
  my $frame = $class->new;

  isa_ok($frame, $class);

  is($frame->score, 0,     "frames start with a zero score");
  ok(! $frame->is_done,    "frames do not start done");
  ok(! $frame->is_pending, "frames do not start pending");

  $frame->record(5);
  is($frame->score, 5,     "one ball for five pins: tentative score 5");
  ok(! $frame->is_done,    "one ball for five pins: not done yet");
  ok(! $frame->is_pending, "one ball for five pins: not pending");

  $frame->record(5);
  is($frame->score, 10,    "bowled 5/5: score 10");
  ok(! $frame->is_done,    "in the 10th, a spare doesn't mean we're done");
  ok(! $frame->is_pending, "but we're not pending!");
  
  # and then let's record the extra ball
  $frame->record(6);
  is($frame->score, 16,    "recording 6 after a spare, we're at 16");
  ok($frame->is_done,      "in the 10th, a spare is done after a bonus ball");
  ok(! $frame->is_pending, "and we're still not pending");
}

{ # let's bowl a strike!
  my $frame = $class->new;

  isa_ok($frame, $class);

  is($frame->score, 0,     "frames start with a zero score");
  ok(! $frame->is_done,    "frames do not start done");
  ok(! $frame->is_pending, "frames do not start pending");

  $frame->record(10);
  is($frame->score, 10,    "a strike!  tentative score: 10");
  ok(! $frame->is_done,    "in the 10th, we're not done even after a strike");
  ok(! $frame->is_pending, "but we're not pending");

  # first extra ball score
  $frame->record(5);
  is($frame->score, 15,    "a 5 after a strike; tentative score: 15");
  ok(! $frame->is_done,    "we're still not done");
  ok(! $frame->is_pending, "but we are still not pending either");
  
  # second extra ball score
  $frame->record(4);
  is($frame->score, 19,    "a 4 after a 5 after a strike: score 19");
  ok($frame->is_done,      "...and now we're done");
  ok(! $frame->is_pending, "...and now we're STILL not pending");
}

{ # let's bowl three strikes in the third; yeah, we rock
  my $frame = $class->new;

  isa_ok($frame, $class);

  is($frame->score, 0,     "frames start with a zero score");
  ok(! $frame->is_done,    "frames do not start done");
  ok(! $frame->is_pending, "frames do not start pending");

  $frame->record(10);
  is($frame->score, 10,    "a strike!  tentative score: 10");
  ok(! $frame->is_done,    "in the 10th, we're not done even after a strike");
  ok(! $frame->is_pending, "but we're not pending");

  eval { $frame->roll_ok(10) };
  is($@, '', "it is OK to roll more than 10 pins, total, in the tenth frame");

  eval { $frame->roll_ok(11) };
  like($@, qr/more than 10/, "but it's still not okay to roll an ELEVEN");

  # first extra ball score
  $frame->record(10);
  is($frame->score, 20,    "two strikes in a row; tentative score: 10");
  ok(! $frame->is_done,    "we're still not done");
  ok(! $frame->is_pending, "but we are still not pending either");
  
  # second extra ball score
  $frame->record(10);
  is($frame->score, 30,    "a turkey in the tenth gives a frame score of 30");
  ok($frame->is_done,      "...and now we're done");
  ok(! $frame->is_pending, "...and now we're STILL not pending");
}
