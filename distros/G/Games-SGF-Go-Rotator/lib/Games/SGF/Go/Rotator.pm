package Games::SGF::Go::Rotator;

use strict;
use warnings;

use base 'Games::SGF::Go';
use vars qw($VERSION);
$VERSION = '1.21';

=head1 NAME

Games::SGF::Go::Rotator - subclass of Games::SGF::Go that can rotate the board

=head1 DESCRIPTION

If you have an SGF file of a game that your opponent recorded, it will be
the wrong way up from your perspective, and so harder for you to remember
what's going on when you analyse the game later.  This subclass of
Games::SGF::Go provides extra methods for rotating it.

=head1 SYNOPSIS

  my $sgf = Games::SGF::Go::Rotator->new();
  $sgf->readFile('mygame.sgf');
  $sgf->rotate();  # rotate by 180 degrees, what you'd normally want
  $sgf->rotate90(); # rotate 90 degrees clockwise.

=head1 METHODS

In addition to the methods documented below, all of Games::SGF::Go's
methods are, of course, also available.  Neither of the new methods
take any arguments, and they return the rotated SGF as well as altering
it in-place, for convenience when chaining methods.

=head2 rotate

Rotate the SGF through 180 degrees.

=cut

sub rotate { shift()->rotate90()->rotate90(); }

=head2 rotate90

Rotate the SGF through 90 degrees clockwise.

=cut

sub rotate90 {
  my $self = shift;
  my $text = $self->writeText();

  (my $size = $text) =~ s/.*SZ\[(\d+)\].*/$1/gs;

  # first rotate any [AA] apart from C[AA]
  $text =~ s/([^C])\[([a-z]{2})]/"${1}["._rotate90(_splitcoord($2), $size).']'/eg;
  # now rotate any A{B,E,W}[AA:AA]
  # note this is the only place where [AA:AA] is legal in Go
  $text =~ s/A([BEW])\[([a-z]{2}):([a-z]{2})\]/
             my @first  = _splitcoord(_rotate90(_splitcoord($2), $size));
             my @second = _splitcoord(_rotate90(_splitcoord($3), $size));
             my @northings = sort { $a cmp $b } ($first[0], $second[0]);
             my @eastings  = sort { $a cmp $b } ($first[1], $second[1]);
             "A${1}[$northings[0]$eastings[0]:$northings[1]$eastings[1]]"
           /eg;

  $self->readText($text);

  # ick, diving into the guts - readText adds a new game, this
  # deletes the first game
  shift @{$self->{collection}};

  return $self;
}

# algorithm:
# consider a square NxN board ...
#   abcde    Each 90 degree rotation moves W to X to Y to Z.
# a .W...    So (x1, y1) => (N-y1, x1)
# b ....X
# c .....
# d Z....
# e ...Y.

sub _splitcoord { return split(//, shift()) }

sub _rotate90 {
  my($x, $y, $size) = @_;
  my @letters = (qw(a b c d e f g h i j k l m n o p q r s))[0 .. $size - 1];
  my %letter_to_number = map { $letters[$_] => $_ } (0 .. $size - 1);
  ($x, $y) = map { $letter_to_number{$_} } ($x, $y);

  ($x, $y) = (($size - 1) - $y, $x);

  return join('', map { $letters[$_] } ($x, $y));
}

=head1 BUGS and FEEDBACK

I welcome feedback about my code, including constructive criticism.
Bug reports should be made using L<http://rt.cpan.org/> or by email,
and should include the smallest possible chunk of code, along with
any necessary data, which demonstrates the bug.  Ideally, this
will be in the form of a file which I can drop in to the module's
test suite.

Rotating a game will probably reset the pointer used when navigating
around the file.  This doesn't matter to me.  If it matters to you,
then please submit a patch with tests.

If you have multiple games in a single file, it will probably screw
up.  Again, I don't care.  If you care, then please submit a patch
with tests.

=head1 SEE ALSO

L<Games::SGF::Go>

=head1 THANKS TO ...

Daniel Gilder for pointing out the bug where stuff like AE[aa:ee]
wasn't being rotated, and providing a fix.

=head1 AUTHOR, COPYRIGHT and LICENCE

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

Copyright 2010 David Cantrell E<lt>david@cantrell.org.ukE<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU   
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
