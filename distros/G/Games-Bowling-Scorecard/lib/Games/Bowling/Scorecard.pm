use strict;
use warnings;
package Games::Bowling::Scorecard;
{
  $Games::Bowling::Scorecard::VERSION = '0.105';
}
# ABSTRACT: score your bowling game easily


use Games::Bowling::Scorecard::Frame;


sub new {
  my ($class) = @_;

  my $self = bless { frames => [ ] } => $class;

  return $self;
}


sub frames {
  my ($self) = @_;

  return @{ $self->{frames} };
}


sub current_frame {
  my ($self) = @_;

  return if $self->is_done;

  my @frames = $self->frames;

  my $frame = pop @frames;

  return $self->_next_frame if !$frame || $frame->is_done;

  return $frame;
}

sub _next_frame {
  my ($self) = @_;

  my $frame = $self->frames == 9
            ? do {
                require Games::Bowling::Scorecard::Frame::TenPinTenth;
                Games::Bowling::Scorecard::Frame::TenPinTenth->new;
              }
            : Games::Bowling::Scorecard::Frame->new;

  push @{ $self->{frames} }, $frame;

  return $frame;
}


sub pending_frames {
  my ($self) = @_;

  my @pending_frames = grep { $_->is_pending } $self->frames;
}


sub record { ## no critic Ambiguous
  my ($self, @balls) = @_;

  for my $ball (@balls) {
    Carp::croak "can't record more balls on a completed scorecard"
      if $self->is_done;

    for my $pending ($self->pending_frames) {
      $pending->record($ball);
    }

    $self->current_frame->record($ball);
  }
}


sub score {
  my ($self) = @_;

  my $score = 0;
  $score += $_->score for $self->frames;

  return $score;
}


sub score_through {
  my ($card, $n) = @_;

  Carp::croak "frame out of range" unless $n >= 1 and $n <= 10;

  my @frames = $card->frames;
  my $score = 0;

  INDEX: for my $idx (0 .. $n - 1) {
    my $frame = $frames[ $idx ];
    return undef if $frame->is_pending or not $frame->is_done;

    $score += $frame->score;
  }

  return $score;
}


sub is_done {
  my ($self) = @_;

  my @frames = $self->frames;

  return (@frames == 10 and $frames[9]->is_done);
}


300;

__END__

=pod

=head1 NAME

Games::Bowling::Scorecard - score your bowling game easily

=head1 VERSION

version 0.105

=head1 SYNOPSIS

  use Games::Bowling::Scorecard;

  my $card = Games::Bowling::Scorecard->new;

  $card->record(6,1);  # slow start
  $card->record(7,2);  # getting better
  $card->record(10);   # strike!
  $card->record(9,1);  # picked up a spare
  $card->record(10) for 1 .. 3; # turkey!
  $card->record(0,0);  # clearly distracted by something
  $card->record(8,2);  # amazingly picked up 7-10 split
  $card->record(10, 9, 1); # pick up a bonus spare

  printf "total score: %u\n", $card->score; # total score: 156, lousy!

=head1 DESCRIPTION

Scoring ten-pin bowling can be confusing for new players.  Frames can't always
be scored until several frames later, and then there's that weird tenth frame.
Modern bowling alleys incorporate computer scoring into the pin cleanup
mechanism, so it's easy to just concentrate on throwing a perfect game and not
on grease-pencilling the sheet for the overhead.

What's one to do, though, when bowling cantaloupes at beer bottles in one's
back yard?  Now, with Games::Bowling::Scorecard, it's easy to improvise a
scoring device -- maybe on a mobile phone running Symbian Perl.

=head1 METHODS

=head2 new

This returns a new scorecard object.  It does not take any arguments.

=head2 frames

  my @frames = $card->frames;

This method returns all of the frames for the game.  This will return all
frames in which scores have been recorded, and possibly one final frame with no
recorded balls.  It will never return any frames after that.

Frames are returned as Games::Bowling::Scorecard::Frame objects.

=head2 current_frame

The current frame is the frame into which the next ball will be recorded.  If
the card is done, this method returns false.

=head2 pending_frames

This method returns any completed frames the score of which has not yet been
finalized.  This includes spares and strikes, before the next ball or balls
have been recorded.

=head2 record

  $card->record(@balls);

This method makes a record of a ball or balls.  It is passed a list of bowling
results, each being a number of pins knocked down by the ball.

For example:

  $card->record(0, 0);  # two gutter balls

  $card->record(6, 4);  # a spare

  $card->record( (0, 0) x 10); # the worst game you could play

  $card->record( (10) x 12 ); # a perfect game

An exception will be raised if this method is called on a scorecard that's
done.

=head2 score

This method returns the current score.  It will include the tentative score for
all pending frames.

=head2 score_through

  my $score = $card->score_through($n)

This method returns the score as of the end of the I<n>th frame.  If that
frame's cannot be definitively stated, because it is pending or not done, undef
is returned.

=head2 is_done

This returns true if the scorecard is done.  The scorecard is done if its
contents indicate that the player's game is over.

=head1 TODO

=over 4

=item *

maybe a way to indicate a split

=back

=head1 SECRET ORIGINS

In late 2006, I hadn't bowled in something like ten years.  I got a Wii, and
while I recognized the little triangle and X marks on the Wii Sports Bowling
scorecard, I couldn't remember how on earth scoring worked.  Once I thought I
had a handle on it, I thought writing this would be a good way to cement it in
my mind.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
