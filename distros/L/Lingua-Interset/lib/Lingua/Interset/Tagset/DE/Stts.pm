# ABSTRACT: Driver for the Stuttgart-Tübingen Tagset of German.
# Copyright © 2008, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::DE::Stts;
use strict;
use warnings;
our $VERSION = '3.008';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Atom';



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'de::stts';
}



#------------------------------------------------------------------------------
# This block will be called before object construction. It will build the
# decoding and encoding maps for this particular tagset.
# Then it will pass all the attributes to the constructor.
#------------------------------------------------------------------------------
around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;
    # Call the default BUILDARGS in Moose::Object. It will take care of distinguishing between a hash reference and a plain hash.
    my $attr = $class->$orig(@_);
    # Construct decode_map in the form expected by Atom.
    my %dm =
    (
        # common noun / normales Nomen
        'NN'     => ['pos' => 'noun', 'nountype' => 'com'],
        # proper noun / Eigenname
        'NE'     => ['pos' => 'noun', 'nountype' => 'prop'],
        # truncated first part of a compound / Kompositions-Erstglied
        # "be- [und entladen]", "Ein- [und Ausgang]", "Damen- [und Herrenbekleidung]"
        'TRUNC'  => ['hyph' => 'yes'],
        # attributive adjective / attributives Adjektiv
        # modifies a noun
        # all inflected adjectives belong here; some uninflected as well
        'ADJA'   => ['pos' => 'adj'], ###!!! synpos => 'attr' ... we want to get rid of synpos
        # predicative or adverbial adjective / prädikatives oder adverbiales Adjektiv
        # also if modifying another adjective
        'ADJD'   => ['pos' => 'adj', 'variant' => 'short'], ###!!! synpos => 'pred' ... we want to get rid of synpos
        # article / Artikel
        'ART'    => ['pos' => 'adj', 'prontype' => 'art'],
        # irreflexive personal pronoun / irreflexives Personalpronomen
        # "ich", "du", "er", "sie", "es", "wir", "ihr"
        # "mir", "mich", "dir", ... when used irreflexively ("er begegnet mir hier")
        # "meiner", ... when it is genitive of "ich" (and not a possessive pronoun)
        'PPER'   => ['pos' => 'noun', 'prontype' => 'prs'],
        # reflexive personal pronoun / reflexives Personalpronomen
        # "mir", "mich", "dir", "dich", ... when used reflexively ("ich freue mich daran")
        # "einander" ("sie mögen sich einander")
        'PRF'    => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes'],
        # possessive pronoun / Possessivpronomen
        # PPOSAT: "mein", "dein", "sein", "ihr", "unser", "euer" ... "ihr Kleid", "euer Auto"
        # PPOSS: "[das ist] meins"
        'PPOSAT' => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes'],
        'PPOSS'  => ['pos' => 'noun', 'prontype' => 'prs', 'poss' => 'yes'],
        # demonstrative pronoun / Demonstrativpronomen
        # PDS: "dies [ist ein Buch]", "jenes [ist schwierig]"
        # PDAT: "dieses [Buch]", "jene [Frage]"
        # (demonstrative) pronominal adverb / (Demonstrativ-) Pronominaladverb
        # PAV: "darauf", "hierzu", "deswegen", "außerdem"
        'PDS'    => ['pos' => 'noun', 'prontype' => 'dem'],
        'PDAT'   => ['pos' => 'adj', 'prontype' => 'dem'],
        'PAV'    => ['pos' => 'adv', 'prontype' => 'dem'],
        # interrogative pronoun / Interrogativpronomen
        # PWS: "wer", "was" ... "was ist los?", "wer ist da?"
        # PWAT: "wessen", "welche", ...
        # PWAV: "wann", "wo", "warum", "worüber", "weshalb" ...
        'PWS'    => ['pos' => 'noun', 'prontype' => 'int'],
        'PWAT'   => ['pos' => 'adj', 'prontype' => 'int'],
        'PWAV'   => ['pos' => 'adv', 'prontype' => 'int'],
        # relative pronoun / Relativpronomen
        # PRELS: "was", "welcher" ... "[derjenige], welcher", "[das], was"
        # PRELAT: "dessen" ... "[der Mann,] dessen [Hut]"
        'PRELS'  => ['pos' => 'noun', 'prontype' => 'rel'],
        'PRELAT' => ['pos' => 'adj', 'prontype' => 'rel'],
        # indefinite pronoun / Indefinitpronomen
        # PIS: "etwas", "nichts", "irgendwas", "man"
        # PIAT: "etliche [Dinge]", "zuviele [Fragen]", "etwas [Schokolade]"
        # PIDAT: with determiner: "all [die Bücher]", "solch [eine Frage]", "beide [Fragen]", "viele [Leute]"
        'PIS'    => ['pos' => 'noun', 'prontype' => 'ind|tot|neg'],
        'PIAT'   => ['pos' => 'adj', 'prontype' => 'ind|tot|neg'],
        'PIDAT'  => ['pos' => 'adj', 'prontype' => 'ind|tot|neg', 'adjtype' => 'pdt'],
        # cardinal number / Kardinalzahl
        'CARD'   => ['pos' => 'num', 'numtype' => 'card'],
        # verb / Verb
        # VVFIN VVIMP VVINF VVIZU VVPP VAFIN VAIMP VAINF VAPP VMFIN VMINF VMPP
        'VAFIN'  => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'fin', 'mood' => 'ind'],
        'VAIMP'  => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'fin', 'mood' => 'imp'],
        'VAINF'  => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'inf'],
        'VAPP'   => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'part', 'aspect' => 'perf'],
        'VMFIN'  => ['pos' => 'verb', 'verbtype' => 'mod', 'verbform' => 'fin', 'mood' => 'ind'],
        'VMINF'  => ['pos' => 'verb', 'verbtype' => 'mod', 'verbform' => 'inf'],
        'VMPP'   => ['pos' => 'verb', 'verbtype' => 'mod', 'verbform' => 'part', 'aspect' => 'perf'],
        'VVFIN'  => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'ind'],
        'VVIMP'  => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'imp'],
        'VVINF'  => ['pos' => 'verb', 'verbform' => 'inf'],
        # infinitive with the incorporated "zu" marker: "abzukommen"
        'VVIZU'  => ['pos' => 'verb', 'verbform' => 'inf', 'other' => {'verbform' => 'infzu'}],
        'VVPP'   => ['pos' => 'verb', 'verbform' => 'part', 'aspect' => 'perf'],
        # adverb / Adverb
        # "dort", "da", "heute", "dann", "gerne", "sehr", "darum", "sonst", "ja", "aber", "denn"
        # "miteinander", "nebeneinander", ...
        # "erstens", "zweitens", "drittens", ...
        # "einmal", "zweimal", "dreimal", ...
        # "bzw.", "u.a.", "z.B."
        'ADV'    => ['pos' => 'adv'],
        # adposition / Adposition
        # APPR APPRART APPO APZR
        'APPR'    => ['pos' => 'adp', 'adpostype' => 'prep'],
        # preposition with article / Präposition mit Artikel
        # "zum", "zur", "aufs", "vom", "im"
        'APPRART' => ['pos' => 'adp', 'adpostype' => 'prep', 'prontype' => 'art'],
        # postposition / Postposition
        # "[der Straße] entlang"
        # beware: same word in "entlang [der Straße]" is preposition
        'APPO'    => ['pos' => 'adp', 'adpostype' => 'post'],
        # second part of circumposition / zweiter Teil einer Zirkumposition
        # (the first part is tagged as preposition)
        # "[von dieser Stelle] an"
        'APZR'    => ['pos' => 'adp', 'adpostype' => 'circ'],
        # conjunction / Konjunktion
        # KOUI KOUS KON KOKOM
        # subordinating conjunction with infinitive / unterordnende Konjunktion mit Infinitiv
        # "ohne [zu]", "statt [zu]"
        'KOUI'    => ['pos' => 'conj', 'conjtype' => 'sub', 'other' => {'conjtype' => 'zu'}],
        # subordinating conjunction with sentence / unterordnende Konjunktion mit Satz
        # "daß", "weil", "wenn", "obwohl", "als", "damit"
        'KOUS'    => ['pos' => 'conj', 'conjtype' => 'sub'],
        # coordinating conjunction / nebenordnende Konjunktion
        # "und", "oder", "entweder ... oder", "weder ... noch", "denn", "aber", "doch", "jedoch"
        'KON'     => ['pos' => 'conj', 'conjtype' => 'coor'],
        # comparative particle without sentence / Vergleichspartikel ohne Satz
        # "als", "wie"
        'KOKOM'   => ['pos' => 'conj', 'conjtype' => 'comp'],
        # particle / Partikel
        # PTKZU PTKNEG PTKVZ PTKA PTKANT
        # "zu" before infinitive or future participle / "zu" vor Infinitiv oder Partizipien Futur
        # "[ohne] zu [wollen]", "[in der] zu [zerstörenden Stadt]"
        'PTKZU'   => ['pos' => 'part', 'parttype' => 'inf'],
        # negation particle / Negationspartikel
        # "nicht"
        'PTKNEG'  => ['pos' => 'part', 'polarity' => 'neg'],
        # separated verb prefix / abgetrennter Verbzusatz
        # "[er hört] auf", "[er kommt] herbei"
        'PTKVZ'   => ['pos' => 'part', 'parttype' => 'vbp'],
        # particle with adjective or adverb / Partikel bei Adjektiv oder Adverb
        # "am [besten]", "[er ist] zu [groß]", "[er fährt] zu [schnell]"
        'PTKA'    => ['pos' => 'part'],
        # response particle / Antwortpartikel
        # "ja", "nein", "danke", "bitte", "doch"
        'PTKANT'  => ['pos' => 'part', 'parttype' => 'res'],
        # interjection / Interjektion
        'ITJ'     => ['pos' => 'int'],
        # punctuation / Interpunktion
        # comma / Komma
        '$,'      => ['pos' => 'punc', 'punctype' => 'comm'],
        # sentence-internal, non-comma / satzintern, nicht Komma
        # ( ) [ ] { } "
        '$('      => ['pos' => 'punc', 'punctype' => 'brck'], # )
        # sentence-final
        # . ! ? : ;
        '$.'      => ['pos' => 'punc', 'punctype' => 'peri'],
        # foreign-language material / Fremdsprachliches Material
        # "[der spanische Film] Mujer de [Benjamin]"
        'FM'      => ['foreign' => 'yes'],
        # non-word / Nichtwort
        # "[das Modell] DX3E"
        'XY'      => []
    );
    # Construct encode_map in the form expected by Atom.
    my %em =
    (
        'pos' => { 'noun' => { 'prontype' => { ''    => { 'nountype' => { 'prop' => 'NE',
                                                                          '@'    => 'NN' }},
                                               'prs' => { 'reflex' => { 'yes' => 'PRF',
                                                                        '@'      => { 'poss' => { 'yes' => 'PPOSS',
                                                                                                  '@'    => 'PPER' }}}},
                                               'dem' => 'PDS',
                                               'int' => 'PWS',
                                               'rel' => 'PRELS',
                                               'ind' => 'PIS',
                                               'tot' => 'PIS',
                                               'neg' => 'PIS',
                                               '@'   => 'PIS' }},
                   'adj'  => { 'adjtype' => { 'pdt' => 'PIDAT',
                                              '@'   => { 'prontype' => { ''    => { 'variant' => { 'short' => 'ADJD',
                                                                                                   '@'     => 'ADJA' }},
                                                                         'prs' => 'PPOSAT',
                                                                         'art' => 'ART',
                                                                         'dem' => 'PDAT',
                                                                         'int' => 'PWAT',
                                                                         'rel' => 'PRELAT',
                                                                         '@'   => 'PIAT' }}}},
                   'num'  => 'CARD',
                   'verb' => { 'verbtype' => { 'aux' => { 'verbform' => { 'fin'  => { 'mood' => { 'imp' => 'VAIMP',
                                                                                                  '@'   => 'VAFIN' }},
                                                                          'part' => 'VAPP',
                                                                          '@'    => 'VAINF' }},
                                               'mod' => { 'verbform' => { 'fin'  => 'VMFIN',
                                                                          'part' => 'VMPP',
                                                                          '@'    => 'VMINF' }},
                                               '@'   => { 'verbform' => { 'fin'  => { 'mood' => { 'imp' => 'VVIMP',
                                                                                                  '@'   => 'VVFIN' }},
                                                                          'part' => 'VVPP',
                                                                          '@'    => { 'other/verbform' => { 'infzu' => 'VVIZU',
                                                                                                            '@'     => 'VVINF' }}}}}},
                   'adv'  => { 'prontype' => { 'dem' => 'PAV',
                                               'int' => 'PWAV',
                                               '@'   => 'ADV' }},
                   'adp'  => { 'adpostype' => { 'post' => 'APPO',
                                                'circ' => 'APZR',
                                                '@'    => { 'prontype' => { 'art' => 'APPRART',
                                                                            '@'   => 'APPR' }}}},
                   'conj' => { 'conjtype' => { 'sub'  => { 'other/conjtype' => { 'zu' => 'KOUI',
                                                                                 '@'  => 'KOUS' }},
                                               'comp' => 'KOKOM',
                                               '@'    => 'KON' }},
                   'part' => { 'parttype' => { 'inf' => 'PTKZU',
                                               'vbp' => 'PTKVZ',
                                               'res' => 'PTKANT',
                                               '@'   => { 'polarity' => { 'neg' => 'PTKNEG',
                                                                          '@'   => 'PTKA' }}}},
                   'int'  => 'ITJ',
                   'punc' => { 'punctype' => { 'comm' => '$,',
                                               'peri' => '$.',
                                               '@'    => '$(' #)
                                                              }},
                   '@'    => { 'hyph' => { 'yes' => 'TRUNC',
                                           '@'    => { 'foreign' => { 'yes' => 'FM',
                                                                      '@'       => 'XY' }}}}}
    );
    # Now add the references to the attribute hash.
    $attr->{surfeature} = 'pos';
    $attr->{decode_map} = \%dm;
    $attr->{encode_map} = \%em;
    $attr->{tagset}     = 'de::stts';
    return $attr;
};



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure. In addition to Atom, we just need to identify the tagset of
# origin (it is not crucial because we do not use the 'other' feature but it
# is customary).
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $fs = $self->SUPER::decode($tag);
    $fs->set_tagset('de::stts');
    return $fs;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::DE::Stts - Driver for the Stuttgart-Tübingen Tagset of German.

=head1 VERSION

version 3.008

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::DE::Stts;
  my $driver = Lingua::Interset::Tagset::DE::Stts->new();
  my $fs = $driver->decode('NN');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('de::stts', 'NN');

=head1 DESCRIPTION

Interset driver for the Stuttgart-Tübingen Tagset of German.

=head1 SEE ALSO

L<Lingua::Interset>
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Atom>,
L<Lingua::Interset::Tagset::DE::Conll>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
