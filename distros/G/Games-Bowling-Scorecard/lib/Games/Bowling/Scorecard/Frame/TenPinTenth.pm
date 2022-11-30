use v5.24.0;
use warnings;

package Games::Bowling::Scorecard::Frame::TenPinTenth 0.106;
use parent qw(Games::Bowling::Scorecard::Frame);
# ABSTRACT: ten pin's weird 10th frame

#pod =head1 DESCRIPTION
#pod
#pod The tenth frame of ten pin bowling is weird.  If you bowl a strike or spare,
#pod you're allowed to throw balls to complete the frame's scoring.  The extra balls
#pod are only counted for bonus points.  In other words, if the first two balls in
#pod the tenth frame are strikes, the second ball is not counted as a "pending"
#pod strike.  If this is confusing, don't worry!  That's why you're using this
#pod module.
#pod
#pod =method is_done
#pod
#pod The tenth frame is done if: (a) three balls have been bowled or (b) two balls
#pod have been bowled, totalling less than ten.
#pod
#pod =cut

sub is_done {
  my ($self) = @_;

  my @balls = $self->balls;

  return 1 if @balls == 3 or @balls == 2 and $balls[0] + $balls[1] < 10;
  return;
}

#pod =method is_pending
#pod
#pod The tenth frame is never pending.  Once it's done, its score is final.
#pod
#pod =cut

sub is_pending {
  return 0;
}

#pod =method roll_ok
#pod
#pod The tenth frame's C<roll_ok> is identical to the standard C<roll_ok>, but
#pod replaces the "can't total more than 10" rule with a more complex rule.
#pod
#pod =cut

sub roll_ok {
  my ($self, $ball) = @_;

  eval { $self->SUPER::roll_ok($ball) };

  if (my $error = $@) {
    return if $error =~ /would bring the frame above 10/;
    die $error;
  }
}

sub _assert_split_ok {
  my ($self, $ball) = @_;

  if ($self->{balls}->@* > 2) {
    Carp::croak "can't record a split on third ball in tenth frame";
  }

  if ($ball >= 9) {
    Carp::croak "you can't split if you knocked down $ball pins!";
  }

  return;
}


300;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Bowling::Scorecard::Frame::TenPinTenth - ten pin's weird 10th frame

=head1 VERSION

version 0.106

=head1 DESCRIPTION

The tenth frame of ten pin bowling is weird.  If you bowl a strike or spare,
you're allowed to throw balls to complete the frame's scoring.  The extra balls
are only counted for bonus points.  In other words, if the first two balls in
the tenth frame are strikes, the second ball is not counted as a "pending"
strike.  If this is confusing, don't worry!  That's why you're using this
module.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 is_done

The tenth frame is done if: (a) three balls have been bowled or (b) two balls
have been bowled, totalling less than ten.

=head2 is_pending

The tenth frame is never pending.  Once it's done, its score is final.

=head2 roll_ok

The tenth frame's C<roll_ok> is identical to the standard C<roll_ok>, but
replaces the "can't total more than 10" rule with a more complex rule.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
