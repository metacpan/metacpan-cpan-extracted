package Games::Boggle;

=head1 NAME

Games::Boggle - find words on a boggle board

=head1 SYNOPSIS

  use Games::Boggle;

	my $board = Games::Boggle->new("TRTO XIHP TEEB MQYP");

	foreach my $word (@wordlist) {
		print "OK $word\n" if $board->has_word($word);
	}

=head1 DESCRIPTION

This module lets you set up a Boggle board, and then query it for whether
or not it is possible to find words on that board.

=head1 METHODS

=head2 new

	my $board = Games::Boggle->new("TRTO XIHP TEEB MEQP");

You initialize the board with a series of 16 letters representing the
letters that are shown. Optional spaces may be inserted to make the
board string more readable.

A 'Qu' should be entered solely as a 'Q'. 

=head2 has_word

		print "OK $word\n" if $board->has_word('tithe');
		print "NOT OK $word\n" unless $board->has_word('queen');

Given any word, we return whether or not that word can be found on the
board following the normal rules of Boggle.

In scalar context this returns the number of possible ways of finding
this word. In list context it returns the starting squares from which this
word can be found (but only once per square, no matter how many times it
can be found there).

Words containing the letter Q should be entered in full ('Queen', rather
than 'qeen'). Words containing a 'Q' not immediately followed by a 'U'
are never playable.

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Games-Boggle@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2002-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

Advanced Perl Programming, 2nd Edition, by Simon Cozens

=cut

$VERSION = '1.01';

use strict;
use warnings;

sub _unique {
  my %list = map { $_ => 1 } @_;
  return sort { $a <=> $b } keys %list;
}

my $play = [
 [1 .. 16],
 [2,5,6],[1,3,5..7],[2,4,6..8],[3,7,8],
 [1,2,6,9,10],[1..3,5,7,9..11],[2..4,6,8,10..12],[3,4,7,11,12],
 [5,6,10,13,14],[5..7,9,11,13..15],[6..8,10,12,14..16],[7,8,11,15,16],
 [9,10,14],[9..11,13,15],[10..12,14,16],[11,12,15]
];

sub new {
  my ($class, $string) = @_;
  my @board = grep /\S/, split //, uc $string;
  bless {
    _board => ["-", @board],
    _has  => { map { $_ => 1 } @board },
   }, $class;
}

sub has_word {
  my $self = shift;
  my $word = uc shift;
  return if $word =~ /Q(?!U)/; # Can't have lone Q in boggle.
  $word =~ s/QU/Q/;
  return unless $self->_have_letters($word);
  my @starts = _can_play($self->{_board}, $word, 0);
  return wantarray ? _unique @starts : scalar @starts;
}

# Quick sanity check to stop us looking for words with letters we don't
# have. We don't check to ensure that we have ENOUGH copies of each
# letter in the word, as that is considerably slower.
sub _have_letters {
  my ($self, $word) = @_;
  while (my $let = chop $word) { return unless $self->{_has}->{$let}; }
  return 1;
}

sub _can_play {
  my ($board, $word, $posn) = @_;
  if (length $word > 1) {
    my $last = chop $word;
    return map {
      local $board->[$_] = "-";
      _can_play($board, $word, $_);
    } _can_play($board, $last, $posn);
  }
  return grep $board->[$_] eq $word, @{ $play->[$posn] };
}

return q/
 AGGReGaTeD HeRBS ALLoW EXoTiC FLaVoR; OVeRZeaLouS PeoPLe ReaLiZe We USe
  PReMiXeD CaViaR & DRiNK UP HuMBLeD GRoG IN MeGaDoSeS
/;
