package Lingua::PT::Hyphenate;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	hyphenate
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	hyphenate
);

our $VERSION = '1.05';

=head1 NAME

Lingua::PT::Hyphenate - Separates Portuguese words in syllables

=head1 SYNOPSIS

  use Lingua::PT::Hyphenate;

  @syllables = hyphenate("teste")   # @syllables now hold ('tes', 'te')

  # or

  $word = new Lingua::PT::Hyphenate;
  @syllables = $word->hyphenate;

=head1 DESCRIPTION

Separates Portuguese words into syllables.

=cut

my ($vowel,$consonant,$letter,$oc_fr);
my ($ditongo,$ditongos,@regex);

BEGIN {

  $vowel     = qr/[aeiou„‚·‡ÍÈÌÛıÙ˙√¡…Õ”’‘ ¬⁄]/i;
  $consonant = qr/[zxcvbnmsdfghjlqrtpÁ«]/i;
  $letter    = qr/[aeiou„‚·‡ÍÈÌÛıÙ˙√¡¬… Õ”’‘⁄zxcvbnmsdfghjlqrtpÁ«]/i;
  $oc_fr     = qr/[ctpgdbfv]/i;

  my @ditongos = qw(ia ua uo ai ei oi ou ai ae au ao Èi ei am$
                    ui oi Ûi ou „i „e „o iu eu en ıe ui em$);

  $ditongo = join "|", @ditongos;
  $ditongo = qr/$ditongo/i;

  $ditongos = join "|", map { /(.)(.*)/ ; "$1(?=$2)" } @ditongos;
  $ditongos = qr/$ditongos/i;

=head1 ALGORITHM

The algorithm has several steps, but all of them consist on marking
points of the word that either are to be separated or that are not
allowed to be
separated.

After all those main steps are fulfilled, the marks for non-separation
are removed and the word is finally splitted by the other marks and
returned as an array.

=cut

  @regex = (
    [ qr/[gq]u(?=$vowel)/i,                                  '.' ],
    [ qr/$letter(?=${consonant}s)/i,                         '.' ],
    [ qr/[cln](?=h)/i,                                       '.' ],
    [ qr/(?<=$consonant)$oc_fr(?=[lr])/i,                    '.' ],
    [ qr/^sub(?=$consonant)/i,                               '|' ],
    [ qr/(?<=$consonant)$consonant(?=$consonant)/i,          '|' ],
    [ qr/$ditongo(?=$ditongo)/i,                             '|' ],
    [ qr/$vowel(?=$ditongo)/i,                               '|' ],
    [ qr/$ditongos/i,                                        '.' ],
    [ qr/$vowel(?=$vowel)/i,                                 '|' ],
    [ qr/$oc_fr(?=[lr])/i,                                   '.' ],
    [ qr/${letter}\.?$consonant(?=${consonant}\.?$letter)/i, '|' ],
    [ qr/$vowel(?=${consonant}\.?$letter)/i,                 '|' ],
  );

}

=head1 METHODS

=head2 new

Creates a new Lingua::PT::Hyphenate object.

  $word = Lingua::PT::Hyphenate->new("palavra");
  # "palavra" is Portuguese for "word"

If you're doing this lots of time, it would probably be better for you
to use the hyphenate function directly (that is, creating a new object
for each word in a long text doesn't seem so bright if you're not
going to use it later on).

=cut

sub new {
  my ($self, $word) = @_;
  bless \$word, $self;
}

=head2 hyphenate

Separates a Portuguese in syllables.

  my @syllables = hyphenate('palavra');
  # @syllables now hold ('pa', 'la', 'vra')

  # or, if you created an object
  my @syllables = $word->hyphenate

=cut

sub hyphenate {
  $_[0] || return ();

  my $word;
  if (ref($_[0]) eq 'Lingua::PT::Hyphenate') {
    my $self = shift;
    $word = $$self;
  }
  else {
    $word = shift;
  }

  $word =~ /^$letter+$/ || return ();

  for my $regex (@regex) {
    $word =~ s/$$regex[0]/${&}$$regex[1]/g;
  }

  $word =~ y/.//d;

  split '\|', $word;
}

1;
__END__

=head1 TO DO

=over 6

=item * A better explanation of the algorithm;

=item * More tests, preferably made by someone else or taken out of some book.

=back

=head1 SEE ALSO

Gramatica Universal da Lingua Portuguesa (Texto Editora)

More tools for the Portuguese language processing can be found at the Natura
project: http://natura.di.uminho.pt

=head1 AUTHOR

Jose Castro, C<< <cog@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jose Castro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
