package Games::Trackword;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '1.09';

#----------------------------------------------------------------------------

=head1 NAME

Games::Trackword - Find words on a Trackword grid.

=head1 SYNOPSIS

  use Games::Trackword;

  my $board = Games::Trackword->new('TRA WKC ORD');

  foreach my $word (@wordlist) {
    print "OK $word\n" if $board->has_word($word);
  }

=head1 DESCRIPTION

This module lets you set up a Trackword grid and query whether or not it is
possible to find words on that grid.

Note that although Trackword is similar to Boggle, you are not restricted by
the size of the grid and you cannot move diagonally between each letter, you
may only move up/down or left/right.

=cut

my @directions = ([-1,0],[0,-1],[1,0],[0,1]);

sub new {
	my ($class, $string) = @_;
	bless {
		_board => _ring_fence($string),
		_has  => { map { $_ => 1 } grep /\S/, split //, uc $string },
	}, $class;
}

sub qu {
  my $self = shift;
  my $this = shift;

  $self->{_qu} = 1;	# Boggle style
  $self->{_qu} = 0	if(defined $this && !$this);
}

sub has_word {
	my $self = shift;
	my $word = uc shift;
	my $board = $self->{_board};

	if($self->{_qu}) {
		return if $word =~ /Q(?!U)/; # Can't have lone Q in boggle.
		$word =~ s/QU/Q/;
	}

	return unless $self->_have_letters($word);

	my $last = chop $word;
	my $rows = scalar(@$board)-1;
	foreach my $posy (0..$rows) {
		my $cols = scalar(@{ $board->[$posy] })-1;
		foreach my $posx (0..$cols) {
			if($board->[$posy][$posx] eq $last) {
				return 1	if(_can_play($board, $word.$last, $posy, $posx));
			}
		}
	}

	return 0;
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
	my ($board, $word, $posy, $posx) = @_;
	if (length $word > 1) {
		my $last = chop $word;
		if($board->[$posy][$posx] eq $last) {
			local $board->[$posy][$posx] = "-";
			foreach my $dir (@directions) {
				return 1	if(_can_play($board, $word, $posy+$dir->[0], $posx+$dir->[1]));
			}
		}
		return 0;
	}
	return ($board->[$posy][$posx] eq $word) ? 1 : 0;
}

sub _ring_fence {
	my @block = split /\s/, uc $_[0];
	my $width = length($block[0])+2;
	push my @board, [('-') x $width],
	                (map {['-',split(//),'-']} @block),
	                [('-') x $width];
	return \@board;
}

1;

__END__

=head1 METHODS

=over 4

=item new

  my $board = Games::Trackword->new('TRA WKC ORD');

  # TRA
  # WKC
  # ORD

You initialize the board with a series of letter blocks representing the
letters that are shown on the grid. Spaces (or non alphabetics) may be
inserted to make the board string more readable.

Grids bigger than 3x3, are simply represented by long strings separated by spaces:

  my $board4 = Games::Trackword->new('TRAC ROWK DTR WKCA');
  my $board5 = Games::Trackword->new('TRACK TDROW RACKW RTDRO ACKWO');

=item qu

  $board->qu();  # Boggle rules
  $board->qu(0);  # Trackword rules (default)

Use if 'Qu' should be represented as a 'Q' (as per Boggle). In this instance
words containing the letter Q should be entered in full ('Queen', rather
than 'qeen'). Note that in Boggle words containing a 'Q' not immediately
followed by a 'U' are never playable.

=item has_word

  print "OK $word\n" if $board->has_word('tithe');
  print "NOT OK $word\n" unless $board->has_word('queen');

Given any word, we return whether or not that word can be found on the
board following the normal rules of Trackword (and Boggle).

=back

=head1 BUGS, PATCHES & FIXES

By its very nature the size of grid is the only limiting factor of this
module. If you can create a grid that is too large to fit in memory, the
author recommends that you not to do that!

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please submit a bug to the RT system (see link below). However,
it would help greatly if you are able to pinpoint problems or even supply a
patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me by sending an email
to barbie@cpan.org .

RT: L<http://rt.cpan.org/Public/Dist/Display.html?Name=Games-Trackword>

=head1 ACKNOWLEDGEMENTS

The original idea for this came from my disappointment that Tony Bowden's
Games::Boggle module couldn't handle Trackword style grids (typically 3x3)
and bigger, and also forced the use of Qu rather Q & U. Much of the code
here steals from Tony's module.

See L<Games::Boggle> if you want a traditional Boggle rules module.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT

  Copyright (C) 2003-2014 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut

