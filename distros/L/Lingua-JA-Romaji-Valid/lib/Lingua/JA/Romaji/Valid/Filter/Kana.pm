package Lingua::JA::Romaji::Valid::Filter::Kana;

use strict;
use warnings;

sub new { bless {}, shift }

sub normalize_syllabic_n_m {
  my ($self, $kana_ref) = @_;

  $$kana_ref =~ s/^n([cdfghjklnrstvwyz])/$1/;
  $$kana_ref =~ s/^m([bmp])/$1/;

  return 1;
}

sub normalize_syllabic_n {
  my ($self, $kana_ref) = @_;

  $$kana_ref =~ s/^n([bcdfghjklmnprstvwyz])/$1/;

  return 1;
}

sub normalize_syllabic_nn {
  my ($self, $kana_ref) = @_;

  $$kana_ref =~ s/^nn([bcdfghjklmnprstvwyz])/$1/;

  return 1;
}

sub normalize_syllabic_m {
  my ($self, $kana_ref) = @_;

  $$kana_ref =~ s/^m([bmp])/$1/;

  return 1;
}

sub normalize_geminate_tch {
  my ($self, $kana_ref) = @_;

  $$kana_ref =~ s/^([bdfghjklprstvz])\1/$1/;
  $$kana_ref =~ s/^tch/ch/;

  return 1;
}

sub normalize_geminate_cch {
  my ($self, $kana_ref) = @_;

  $$kana_ref =~ s/^tch/ch/;
  $$kana_ref =~ s/^([bcdfghjklprstvz])\1/$1/;

  return 1;
}

sub normalize_geminate {
  my ($self, $kana_ref) = @_;

  $$kana_ref =~ s/^([bcdfghjklprstvz])\1/$1/;

  return 1;
}

sub prohibit_foreign_kanas {
  my ($self, $kana_ref) = @_;

  return if $$kana_ref =~ /^v/;
  return if $$kana_ref =~ /^[kg]w/;
  return if $$kana_ref =~ /y[ie]$/;
  return if $$kana_ref =~ /w[^a]$/;
  return if $$kana_ref =~ /(?:f|ts)[^u]$/;
  return if $$kana_ref =~ /(?:j|ch|sh)e$/;

  return 1;
}

1;

__END__

=head1 NAME

Lingua::JA::Romaji::Valid::Filter::Kana

=head1 DESCRIPTION

Lingua::JA::Romaji::Valid splits a given word into pieces,
and each of them should have consonant(s) and a vowel (or
an "n" without a vowel for the last piece). Thus syllabic
"n" and geminate consonants would be prepended to the
following piece, that means, "shinbun" would be split into
"shi", "nbu" and "n", and "sapporo" would be split into "sa",
"ppo", and "ro". Filtering methods in this module would cut
off these prepended syllabic "n" and geminate consonants to
make validation easier.

=head1 METHODS

=head2 new

creates an object. 

=head2 normalize_syllabic_n_m

cuts off an "n" prepended to a kana which starts with
consonants other than "b", "m", and "p", and cuts off
an "m" prepended to a kana which starts with "b", "m",
or "p". Traditional (and railway/passport)
Hepburn use this. This may be natural for the Westerners,
but this also means syllabic "n", which has one distinct
kana representation, may be rendered in two ways, and
thus, is thought unnatural by Japanese people.

=head2 normalize_syllabic_n

cuts off an "n" prepended to a kana, which starts with
consonants, even if the consonants are "b", "m", or "p".
Revised Hepburn and ISO romanizations use this.

=head2 normalize_syllabic_nn

cuts off a double "n" ("nn") prepended to a kana. This
is a vulgar and unauthorized expression of syllabic "n"
but this may be clearer, as we also have "n" plus a vowel
kana combinations. ::Liberal supports this by default.

=head2 normalize_syllabic_m

just cuts off an "m" prepended to a kana which starts
with "b", "m", or "p". 

=head2 normalize_geminate_tch

cuts off one of the geminate (double) consonants of the
piece, and "t" prepended to a kana which starts with "ch".
Hepburns uses this.

=head2 normalize_geminate_cch

cuts off one of the geminate (double) consonants of the
piece, even if the piece has "cch" combination. This
also is a vulgar and unauthorized expression of geminate
(double) consonants, but relatively well-known as it is
simpler.

=head2 normalize_geminate

cuts off one of the geminate (double) consonants of the
piece. This doesn't care "t" before "ch", as ISO rules
don't have kanas which start with "ch".

=head2 prohibit_foreign_kanas

Ordinary Japanese names don't have kanas which start
with "v" or "kw". With this filter, such kind of uncommon
expressions are banned even if the validation rule you
specified allows them.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
