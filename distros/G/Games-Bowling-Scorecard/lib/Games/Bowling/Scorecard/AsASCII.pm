use v5.24.0;
use warnings;
package Games::Bowling::Scorecard::AsASCII 0.106;
# ABSTRACT: format a bowling scorecard as ASCII text

#pod =head1 SYNOPSIS
#pod
#pod   use Games::Bowling::Scorecard;
#pod
#pod   my $card = Games::Bowling::Scorecard->new;
#pod
#pod   $card->record(6,1);  # slow start
#pod   $card->record(7,2);  # getting better
#pod   $card->record(10);   # strike!
#pod   $card->record(9,1);  # picked up a spare
#pod   $card->record(10) for 1 .. 3; # turkey!
#pod   $card->record(0,0);  # clearly distracted by something
#pod   $card->record(8,2);  # amazingly picked up 7-10 split
#pod   $card->record(10, 9, 1); # pick up a bonus spare
#pod
#pod   print Games::Bowling::Scorecard::AsText->card_as_text($card);
#pod
#pod The above outputs:
#pod
#pod   +-----+-----+-----+-----+-----+-----+-----+-----+-----+-------+
#pod   | 6 1 | 7 2 | X   | 9 / | X   | X   | X   | - - | 8 / | X 9 / |
#pod   |   7 |  16 |  36 |  56 |  86 | 106 | 116 | 116 | 136 |   156 |
#pod
#pod =head1 WARNING
#pod
#pod This module's interface is almost certain to change, whenever the author gets
#pod around to it.
#pod
#pod =head1 DESCRIPTION
#pod
#pod So, you've written a bowling record-keeper and now you want to print out
#pod scorecards to your dynamic Gopher site.  Games::Bowling::Scorecard has taken
#pod care of the scoring, but now you need to worry about all those slashes and
#pod dashes and X's
#pod
#pod =method card_as_text
#pod
#pod   my $text = Games::Bowling::Scorecard::AsText->card_as_text($card);
#pod
#pod Given a scorecard, this method returns a three-line text version of the card,
#pod using standard notation.  A total is kept only through the last non-pending
#pod frame.
#pod
#pod =cut

use Carp ();

sub card_as_text {
  my ($self, $card) = @_;

  my $hdr = '+-----+-----+-----+-----+-----+-----+-----+-----+-----+-------+';
  my $balls  = '';
  my $scores = '';

  my @frames = $card->frames;
  INDEX: for my $i (0 .. 8) {
    my $frame = $frames[ $i ];
    unless ($frame) {
      $_  .= '|     ' for $balls, $scores;
      next INDEX;
    }

    $balls .= sprintf '| %s ', $self->_two_balls($frame->balls);

    my $score = $card->score_through($i + 1);
    $scores .= defined $score
             ? sprintf '| %3u ', $score
             : '|     ';
  }

  TENTH: for (1) {
    my $frame = $frames[ 9 ];

    unless ($frame) {
      $_ .= '|       |' for $balls, $scores;
      last TENTH;
    }

    $balls .= sprintf '| %s |', $self->_three_balls($frame->balls);

    my $score = $card->score_through(10);

    $scores .= defined $score
             ? sprintf '|   %3u |', $score
             : '|       |';
  }

  return "$hdr\n"
       . "$balls\n"
       . "$scores\n";
}

sub _two_balls {
  my ($self, $b1, $b2) = @_;

  return '   ' unless defined $b1;

  sprintf '%s %s',
    $b1 == 10 ? 'X' : $b1 || '-',
    $b1 == 10 ? ' ' : defined $b2 ? $b1 + $b2 == 10 ? '/' : $b2 || '-' : ' ';
}

sub _three_balls {
  my ($self, $b1, $b2, $b3) = @_;

  return '     ' unless defined $b1;

  if ($b1 == 10) {
    return 'X    ' unless defined $b2;

    return sprintf 'X X %s', defined $b3 ? $b3 == 10 ? 'X' : $b3 || '-' : ' '
      if $b2 == 10;

    return sprintf 'X %s', $self->_two_balls($b2, $b3);
  } elsif (not defined $b2) {
    return sprintf '%s    ', $b1 || '-';
  } elsif ($b1 + $b2 == 10) {
    return sprintf '%s %s',
      $self->_two_balls($b1, $b2),
      defined $b3 ? $b3 == 10 ? 'X' : $b3 || '-' : ' ';
  } else {
    return sprintf '%s  ', $self->_two_balls($b1, $b2);
  }
}

300;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Bowling::Scorecard::AsASCII - format a bowling scorecard as ASCII text

=head1 VERSION

version 0.106

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

  print Games::Bowling::Scorecard::AsText->card_as_text($card);

The above outputs:

  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-------+
  | 6 1 | 7 2 | X   | 9 / | X   | X   | X   | - - | 8 / | X 9 / |
  |   7 |  16 |  36 |  56 |  86 | 106 | 116 | 116 | 136 |   156 |

=head1 DESCRIPTION

So, you've written a bowling record-keeper and now you want to print out
scorecards to your dynamic Gopher site.  Games::Bowling::Scorecard has taken
care of the scoring, but now you need to worry about all those slashes and
dashes and X's

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

=head2 card_as_text

  my $text = Games::Bowling::Scorecard::AsText->card_as_text($card);

Given a scorecard, this method returns a three-line text version of the card,
using standard notation.  A total is kept only through the last non-pending
frame.

=head1 WARNING

This module's interface is almost certain to change, whenever the author gets
around to it.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
