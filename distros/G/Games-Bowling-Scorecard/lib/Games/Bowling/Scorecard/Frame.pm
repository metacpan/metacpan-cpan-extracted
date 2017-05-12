use strict;
use warnings;

package Games::Bowling::Scorecard::Frame;
{
  $Games::Bowling::Scorecard::Frame::VERSION = '0.105';
}
# ABSTRACT: one frame on a scorecard


use Carp ();


sub new {
  my ($class) = @_;

  bless {
    balls => [],
    score => 0,

    done    => 0,
    pending => 0,
  } => $class;
}


sub record { ## no critic Ambiguous
  my ($self, $ball) = @_;

  if ($self->is_done) {
    if ($self->is_pending) {
      $self->{pending}--;
      $self->{score} += $ball;
      return;
    } else {
      Carp::croak "two balls already recorded for frame";
    }
  }

  $self->roll_ok($ball);

  push @{ $self->{balls} }, $ball;
  $self->{score} += $ball;

  $self->_check_done;
  $self->_check_pending;
}

sub _check_pending {
  my ($self) = @_;
  return unless $self->is_done;

  my @balls = $self->balls;

  return $self->{pending} = 2 if @balls == 1 and $balls[0] == 10;
  return $self->{pending} = 1 if @balls == 2 and $balls[0] + $balls[1] == 10;
}

sub _check_done {
  my ($self) = @_;

  my @balls = $self->balls;

  $self->{done} = 1 if (@balls == 1 and $balls[0] == 10) or @balls == 2;
}


sub roll_ok {
  my ($self, $ball) = @_;

  Carp::croak "the frame is done" if $self->is_done;
  Carp::croak "you can't bowl an undefined number of pins!" if !defined $ball;
  Carp::croak "you can't bowl more than 10 on a single ball" if $ball > 10;
  Carp::croak "you can't bowl less than 0 on a single ball" if $ball < 0;
  Carp::croak "you can't knock down a partial pin" if $ball != int($ball);

  my $i = 0;
  $i += $_ for $self->balls, $ball;

  Carp::croak "bowling a $ball would bring the frame above 10" if $i > 10;
}


sub score {
  my ($self) = @_;
  return $self->{score};
}


sub is_pending {
  my ($self) = @_;
  return $self->{pending};
}


sub is_done {
  my ($self) = @_;
  return $self->{done};
}


sub balls {
  my ($self) = @_;
  return @{ $self->{balls} };
}

300;

__END__

=pod

=head1 NAME

Games::Bowling::Scorecard::Frame - one frame on a scorecard

=head1 VERSION

version 0.105

=head1 DESCRIPTION

A frame is one attempt to knock down all ten pins -- unless it's the tenth
frame, in which case it's so goofy that you need to use a different class,
L<Games::Bowling::Scorecard::Frame::TenPinTenth>.  A frame is done when you've
bowled twice or knocked down all the pins, and it's pending until its score can
be definitively be stated.

=head1 METHODS

=head2 new

This method returns a new frame object.

=head2 record

  $frame->record($ball);

This method records a single ball against the frame.  This method is used for
both the current frame and for pending frames.  It updates the frame's score
and whether the frame is done or pending.

=head2 roll_ok

  $frame->roll_ok($ball);

This method asserts that given value is an acceptable number to score next in
this frame.  It checks that:

  * the frame is not already done
  * $ball is defined, an integer, and between 0 and 10
  * $ball would not bring the total number of pins downed above 10

=head2 score

This method returns the current score for the frame, even if the frame is not
done or is pending further balls.

=head2 is_pending

This method returns true if the frame is pending more balls -- that is, it
returns true for strikes or spares which have not yet recorded the results of
subsequent balls.

=head2 is_done

This method returns true if the frame is done.

=head2 balls

This method returns the balls recorded against the frame, each ball returned as
the number of pins it knocked down.  In scalar context, it returns the number
of balls recoded against the frame.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
