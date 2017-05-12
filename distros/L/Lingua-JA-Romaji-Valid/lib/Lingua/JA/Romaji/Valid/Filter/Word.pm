package Lingua::JA::Romaji::Valid::Filter::Word;

use strict;
use warnings;

sub new { bless {}, shift }

sub normalize_n_with_apostrophe {
  my ($self, $word_ref) = @_;

  $$word_ref =~ s/n\\?'([aeiouy])/n$1/g;

  return 1;
}

sub normalize_n_with_hyphen {
  my ($self, $word_ref) = @_;

  $$word_ref =~ s/n\\?[\-]([aeiouy])/n$1/g;

  return 1;
}

sub normalize_oh {
  my ($self, $word_ref) = @_;

  # strictly speaking, this may be wrong (eg. o-hira, not oh-ira)
  # but both cases should be valid in the end.
  $$word_ref =~ s/oh/o/g;

  return 1;
}

sub normalize_long_vowel_with_h {
  my ($self, $word_ref) = @_;

  # strictly speaking, this may be wrong (eg. o-hira, not oh-ira)
  # but both cases should be valid in the end.
  $$word_ref =~ s/([aeiou])h/$1/g;

  return 1;
}

sub normalize_long_vowel_with_symbols {
  my ($self, $word_ref) = @_;

  # strictly speaking, this may be wrong (eg. o-hira, not oh-ira)
  # but both cases should be valid in the end.
  $$word_ref =~ s/([aeiou])\\?[_\-^]/$1/g;

  return 1;
}

sub prohibit_initial_n {
  my ($self, $word_ref) = @_;

  return ( $$word_ref =~ /^n(?:[^aeiouy])/ ) ? 0 : 1;
}

sub prohibit_initial_wo {
  my ($self, $word_ref) = @_;

  return ( $$word_ref =~ /^wo/ ) ? 0 : 1;
}

1;

__END__

=head1 NAME

Lingua::JA::Romaji::Valid::Filter::Word

=head1 DESCRIPTION

Lingua::JA::Romaji::Valid splits a given word into pieces,
but some of the filters should be applied before splitting.

=head1 METHODS

=head2 new

creates an object. 

=head2 normalize_n_with_apostrophe

an apostrophe between "n" and vowels is important if you
want to know if the "n" is a syllabic "n" or the first
part of a kana. However, it doesn't matter if the phrase
is valid romanization or not. This filter cuts off the
apostrophes between "n" and vowels to make validation
easier.

=head2 normalize_n_with_hyphen

cuts off the hyphen between "n" and vowels.

=head2 normalize_oh

Long "o" may be exprssed by "oh" in passport Hepburn (and
vulgar romanizations). This filter cuts off the "h"s
following "o". This might be wrong assumption in some cases
(eg. the "h" in O-hira, one of the late prime ministers,
should not be cut off), but anyway it doesn't affect the
result.

=head2 normalize_long_vowel_with_h

cuts off the "h"s following vowels.

=head2 normalize_long_vowel_with_symbols

cuts off the underscores, hyphens or circumflexes following
vowels to denote they are long.

=head2 prohibit_initial_n

Ordinary Japanese names don't start with syllabic "n".

=head2 prohibit_initial_wo

Ordinary Japanese names don't start with a particle "wo".

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
