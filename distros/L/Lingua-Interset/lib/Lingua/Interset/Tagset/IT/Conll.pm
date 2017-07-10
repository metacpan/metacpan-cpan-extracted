# ABSTRACT: Driver for the Italian tagset of the CoNLL 2007 Shared Task (derived from the ISST, Italian Syntactic-Semantic Treebank).
# Copyright © 2011, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Copyright © 2011 Loganathan Ramasamy <ramasamy@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::IT::Conll;
use strict;
use warnings;
our $VERSION = '3.005';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::Conll';



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'it::conll';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # PART OF SPEECH ####################
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # S = common noun (presidente, anno, giorno, mondo, tempo)
            'S'  => ['pos' => 'noun', 'nountype' => 'com'],
            # SP = proper noun (Italia, Milano, Nanni, Mayo, Allende)
            'SP' => ['pos' => 'noun', 'nountype' => 'prop'],
            # SW = foreign word (publishing, desktop, le, Tour, hard)
            'SW' => ['pos' => 'noun', 'foreign' => 'yes'],
            # SA = abbreviated noun (L., mq, km, cm, tel.)
            'SA' => ['pos' => 'noun', 'abbr' => 'yes'],
            # A = adjective (vero, stesso, nuovo, scorso, lungo)
            'A'  => ['pos' => 'adj'],
            # AP = possessive determiner (suo, mio, nostro, proprio, tuo, vostro)
            'AP' => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes'],
            # RD = definite article (il, lo, i, gli, la, le, l')
            'RD' => ['pos' => 'adj', 'prontype' => 'art', 'definite' => 'def'],
            # RI = indefinite article (un, uno, una, un')
            'RI' => ['pos' => 'adj', 'prontype' => 'art', 'definite' => 'ind'],
            # PD = demonstrative pronoun (lo, quello, questo, ciò, stesso)
            'PD' => ['pos' => 'noun', 'prontype' => 'dem'],
            # PI = indefinite pronoun (uno, tutto, altro, nessuno, qualcuno)
            'PI' => ['pos' => 'noun', 'prontype' => 'ind|tot|neg'],
            # PP = possessive pronoun (tuo, lo, nostro, miei, suoi, tuoi, sua, tua)
            ###!!! How do AP and PP differ? There are very few occurrences of PP.
            'PP' => ['pos' => 'noun', 'prontype' => 'prs', 'poss' => 'yes'],
            # PQ = personal pronoun (mi, io, me, ti, te, tu, lo, lui, l', li, la, lei, le, ci, noi, vi, voi, si, gli, ne, se, s', loro)
            'PQ' => ['pos' => 'noun', 'prontype' => 'prs'],
            # PR = relative pronoun (che, cui, quanto, qual)
            'PR' => ['pos' => 'noun', 'prontype' => 'rel'],
            # PT = interrogative pronoun (che, chi, quanto)
            'PT' => ['pos' => 'noun', 'prontype' => 'int'],
            # DD = demonstrative determiner (questo, quel, quest', quell', tale, tal)
            'DD' => ['pos' => 'adj', 'prontype' => 'dem'],
            # DE = ??? (very few occurrences) (che, quali)
            'DE' => ['pos' => 'adj', 'prontype' => 'prn'],
            # DI = indefinite determiner (tutto, altro, certo, alcun, nessun)
            'DI' => ['pos' => 'adj', 'prontype' => 'ind|tot|neg'],
            # DR = relative determiner (quale)
            'DR' => ['pos' => 'adj', 'prontype' => 'rel'],
            # DT = interrogative determiner (qual, quanta, quante, quale, quali, che)
            'DT' => ['pos' => 'adj', 'prontype' => 'int'],
            # N = cardinal numeral (due, tre, mila, cinque, quattro)
            'N'  => ['pos' => 'num', 'numtype' => 'card'],
            # NO = ordinal numeral (primo, secondo, terzo, quarto, quinto)
            'NO' => ['pos' => 'adj', 'numtype' => 'ord'],
            # V = verb (essere, fare, dire, aver, avere)
            'V'  => ['pos' => 'verb'],
            # B = adverb (non, più, dove, c', solo, sempre)
            'B'  => ['pos' => 'adv'],
            # E = preposition (di, a, in, per, con)
            'E'  => ['pos' => 'adp', 'adpostype' => 'prep'],
            # C = conjunction (e, che, anche, ma, o)
            'C'  => ['pos' => 'conj'],
            # I = interjection (ah, grazie, ahimè, vabbè, eh)
            'I'  => ['pos' => 'int'],
            # PU = punctuation (, . " : ?)
            'PU' => ['pos' => 'punc'],
            # X = unknown (/, d', 6', 34', 11'06'')
            'X'  => []
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''    => { 'nountype' => { 'prop' => 'SP',
                                                                              '@'    => { 'abbr' => { 'yes' => 'SA',
                                                                                                      '@'    => { 'foreign' => { 'yes' => 'SW',
                                                                                                                                 '@'       => 'S' }}}}}},
                                                   'prs' => { 'poss' => { 'yes' => 'PP',
                                                                          '@'    => 'PQ' }},
                                                   'int' => 'PT',
                                                   'rel' => 'PR',
                                                   'dem' => 'PD',
                                                   'ind' => 'PI',
                                                   'tot' => 'PI',
                                                   'neg' => 'PI' }},
                       'adj'  => { 'prontype' => { ''    => { 'numtype' => { 'ord' => 'NO',
                                                                             '@'   => 'A' }},
                                                   'art' => { 'definite' => { 'def' => 'RD',
                                                                              '@'   => 'RI' }},
                                                   'dem' => 'DD',
                                                   'ind' => 'DI',
                                                   'tot' => 'DI',
                                                   'neg' => 'DI',
                                                   'prn' => 'DE',
                                                   'int' => 'DT',
                                                   'rel' => 'DR',
                                                   'prs' => 'AP' }},
                       'num'  => 'N',
                       'verb' => 'V',
                       'adv'  => 'B',
                       'adp'  => 'E',
                       'conj' => 'C',
                       'int'  => 'I',
                       'punc' => 'PU',
                       '@'    => 'X' }
        }
    );
    # GENDER ####################
    $atoms{gen} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'M' => 'masc',
            'F' => 'fem',
            'N' => '' # undistinguishable
        }
    );
    # NUMBER ####################
    $atoms{num} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'S' => 'sing',
            'P' => 'plur',
            'N' => '' # undistinguishable
        }
    );
    # DEGREE OF COMPARISON ####################
    $atoms{sup} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            # absolute superlative (gravissimo, chiarissimo, bellissimo, ultimissimo, massimo)
            'S' => 'abs'
        }
    );
    # PERSON ####################
    $atoms{per} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            '1' => '1',
            '2' => '2',
            '3' => '3'
        }
    );
    # VERB FORM AND MOOD ####################
    $atoms{mod} = $self->create_atom
    (
        'surfeature' => 'mod',
        'decode_map' =>
        {
            # infinitive (essere, fare, dire, aver, avere)
            'F' => ['verbform' => 'inf'],
            # indicative (è, ha, può, fa, dice)
            'I' => ['verbform' => 'fin', 'mood' => 'ind'],
            # subjunctive (sia, possa, abbia, vada, venga)
            'C' => ['verbform' => 'fin', 'mood' => 'sub'],
            # conditional (sarebbe, potrebbe, avrebbe, dovrebbe, vorrebbe)
            'D' => ['verbform' => 'fin', 'mood' => 'cnd'],
            # imperative (vedi, ricorda-, rilassati, cerca, ripeti)
            'M' => ['verbform' => 'fin', 'mood' => 'imp'],
            # participle (stato, fatto, detto, venduto, visto)
            'P' => ['verbform' => 'part'],
            # gerund (portando, cercando, lavorando, dando, parlando)
            'G' => ['verbform' => 'ger']
        },
        'encode_map' =>
        {
            'verbform' => { 'inf'  => 'F',
                            'part' => 'P',
                            'ger'  => 'G',
                            '@'    => { 'mood' => { 'ind' => 'I',
                                                    'imp' => 'M',
                                                    'sub' => 'C',
                                                    'cnd' => 'D',
                                                    '@'   => 'I' }}}
        }
    );
    # TENSE ####################
    $atoms{tmp} = $self->create_simple_atom
    (
        'intfeature' => 'tense',
        'simple_decode_map' =>
        {
            # present / presente (ho, sono, so, credo, voglio)
            'P' => 'pres',
            # future / futuro (farò, sarò, crederò, terrò, cercherò)
            'F' => 'fut',
            # imperfect past / imperfetto (avevo, sentivo, ero, volevo, andavo)
            'I' => 'imp',
            # remote past / passato remoto (riaprii, consegnai, rimasi, passai, entrai)
            'R' => 'past'
        }
    );
    return \%atoms;
}



#------------------------------------------------------------------------------
# Creates the list of all surface CoNLL features that can appear in the FEATS
# column. This list will be used in decode().
#------------------------------------------------------------------------------
sub _create_features_all
{
    my $self = shift;
    my @features = ('gen', 'num', 'sup', 'per', 'mod', 'tmp');
    return \@features;
}



#------------------------------------------------------------------------------
# Creates the list of surface CoNLL features that can appear in the FEATS
# column with particular parts of speech. This list will be used in encode().
#------------------------------------------------------------------------------
sub _create_features_pos
{
    my $self = shift;
    my %features =
    (
        'A'  => ['gen', 'num', 'sup'],
        'B'  => ['sup'],
        'D'  => ['gen', 'num'],
        'E'  => ['gen', 'num'],
        'N'  => ['gen', 'num'],
        'P'  => ['gen', 'num', 'per'],
        'R'  => ['gen', 'num'],
        'S'  => ['gen', 'num'],
        'SA' => ['gen', 'num'],
        'V'  => ['gen', 'num', 'per', 'mod', 'tmp'],
        '@'  => []
    );
    return \%features;
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $fs = $self->decode_conll($tag);
    # Default feature values. Used to improve collaboration with other drivers.
    # ... nothing yet ...
    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $atoms = $self->atoms();
    my $subpos = $atoms->{pos}->encode($fs);
    my $pos = $subpos =~ m/^(PU|SA)$/ ? $subpos : substr($subpos, 0, 1);
    my $feature_names = $self->get_feature_names($pos);
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names);
    # Some parts of speech require gender and number even if their values are N (not known/distinguishable).
    # Other parts of speech prefer empty features but they can take gender and number if it is known.
    $tag =~ s/^(E\tE|N\tN|N\tNO)\tgen=N\|num=N$/$1\t_/;
    $tag =~ s/^V\tV\tgen=N\|(.*mod=[^P])/V\tV\t$1/;
    $tag =~ s/^V\tV\tnum=N\|(.*mod=[^P])/V\tV\t$1/;
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus, 168 tags found.
# After cleaning: 166
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
A	A	gen=F|num=P
A	A	gen=F|num=P|sup=S
A	A	gen=F|num=S
A	A	gen=F|num=S|sup=S
A	A	gen=M|num=N
A	A	gen=M|num=P
A	A	gen=M|num=P|sup=S
A	A	gen=M|num=S
A	A	gen=M|num=S|sup=S
A	A	gen=N|num=N
A	A	gen=N|num=P
A	A	gen=N|num=S
A	AP	gen=F|num=P
A	AP	gen=F|num=S
A	AP	gen=M|num=P
A	AP	gen=M|num=S
A	AP	gen=N|num=P
B	B	_
B	B	sup=S
C	C	_
D	DD	gen=F|num=P
D	DD	gen=F|num=S
D	DD	gen=M|num=P
D	DD	gen=M|num=S
D	DD	gen=N|num=S
D	DE	gen=N|num=N
D	DE	gen=N|num=P
D	DI	gen=F|num=P
D	DI	gen=F|num=S
D	DI	gen=M|num=P
D	DI	gen=M|num=S
D	DI	gen=N|num=N
D	DI	gen=N|num=P
D	DI	gen=N|num=S
D	DR	gen=N|num=S
D	DT	gen=F|num=P
D	DT	gen=F|num=S
D	DT	gen=M|num=S
D	DT	gen=N|num=N
D	DT	gen=N|num=P
D	DT	gen=N|num=S
E	E	_
E	E	gen=F|num=P
E	E	gen=F|num=S
E	E	gen=M|num=P
E	E	gen=M|num=S
E	E	gen=N|num=S
I	I	_
N	N	_
N	N	gen=F|num=P
N	N	gen=N|num=S
N	NO	_
N	NO	gen=F|num=P
N	NO	gen=F|num=S
N	NO	gen=M|num=P
N	NO	gen=M|num=S
P	PD	gen=F|num=P
P	PD	gen=F|num=S
P	PD	gen=M|num=P
P	PD	gen=M|num=S
P	PD	gen=N|num=N
P	PD	gen=N|num=P
P	PI	gen=F|num=P
P	PI	gen=F|num=S
P	PI	gen=M|num=P
P	PI	gen=M|num=S
P	PI	gen=N|num=N
P	PI	gen=N|num=P
P	PI	gen=N|num=S
P	PP	gen=F|num=S
P	PP	gen=M|num=P
P	PP	gen=M|num=S
P	PQ	gen=F|num=N
P	PQ	gen=F|num=N|per=3
P	PQ	gen=F|num=P|per=3
P	PQ	gen=F|num=S
P	PQ	gen=F|num=S|per=3
P	PQ	gen=M|num=P
P	PQ	gen=M|num=P|per=3
P	PQ	gen=M|num=S
P	PQ	gen=M|num=S|per=3
P	PQ	gen=N|num=N
P	PQ	gen=N|num=N|per=3
P	PQ	gen=N|num=P|per=1
P	PQ	gen=N|num=P|per=2
P	PQ	gen=N|num=P|per=3
P	PQ	gen=N|num=S
P	PQ	gen=N|num=S|per=1
P	PQ	gen=N|num=S|per=2
P	PQ	gen=N|num=S|per=3
P	PR	gen=M|num=P
P	PR	gen=M|num=S
P	PR	gen=N|num=N
P	PR	gen=N|num=P
P	PR	gen=N|num=S
P	PT	gen=M|num=S
P	PT	gen=N|num=N
P	PT	gen=N|num=S
PU	PU	_
R	RD	gen=F|num=P
R	RD	gen=F|num=S
R	RD	gen=M|num=P
R	RD	gen=M|num=S
R	RD	gen=N|num=S
R	RI	gen=F|num=S
R	RI	gen=M|num=S
S	S	gen=F|num=N
S	S	gen=F|num=P
S	S	gen=F|num=S
S	S	gen=M|num=N
S	S	gen=M|num=P
S	S	gen=M|num=S
S	S	gen=N|num=N
S	S	gen=N|num=P
S	S	gen=N|num=S
S	SP	gen=N|num=N
S	SW	gen=N|num=N
SA	SA	gen=N|num=N
V	V	gen=F|num=P|mod=P|tmp=R
V	V	gen=F|num=S|mod=P|tmp=R
V	V	gen=M|num=P|mod=P|tmp=R
V	V	gen=M|num=S|mod=P|tmp=R
V	V	gen=N|num=P|mod=P|tmp=P
V	V	gen=N|num=S|mod=P|tmp=P
V	V	mod=F
V	V	mod=G
V	V	num=P|per=1|mod=C|tmp=I
V	V	num=P|per=1|mod=C|tmp=P
V	V	num=P|per=1|mod=D|tmp=P
V	V	num=P|per=1|mod=I|tmp=F
V	V	num=P|per=1|mod=I|tmp=I
V	V	num=P|per=1|mod=I|tmp=P
V	V	num=P|per=1|mod=I|tmp=R
V	V	num=P|per=2|mod=C|tmp=I
V	V	num=P|per=2|mod=C|tmp=P
V	V	num=P|per=2|mod=I|tmp=F
V	V	num=P|per=2|mod=I|tmp=P
V	V	num=P|per=2|mod=M|tmp=P
V	V	num=P|per=3|mod=C|tmp=I
V	V	num=P|per=3|mod=C|tmp=P
V	V	num=P|per=3|mod=D|tmp=P
V	V	num=P|per=3|mod=I|tmp=F
V	V	num=P|per=3|mod=I|tmp=I
V	V	num=P|per=3|mod=I|tmp=P
V	V	num=P|per=3|mod=I|tmp=R
V	V	num=S|per=1|mod=C|tmp=I
V	V	num=S|per=1|mod=C|tmp=P
V	V	num=S|per=1|mod=D|tmp=P
V	V	num=S|per=1|mod=I|tmp=F
V	V	num=S|per=1|mod=I|tmp=I
V	V	num=S|per=1|mod=I|tmp=P
V	V	num=S|per=1|mod=I|tmp=R
V	V	num=S|per=2|mod=C|tmp=P
V	V	num=S|per=2|mod=D|tmp=P
V	V	num=S|per=2|mod=I|tmp=F
V	V	num=S|per=2|mod=I|tmp=I
V	V	num=S|per=2|mod=I|tmp=P
V	V	num=S|per=2|mod=M|tmp=P
V	V	num=S|per=3|mod=C|tmp=I
V	V	num=S|per=3|mod=C|tmp=P
V	V	num=S|per=3|mod=D|tmp=P
V	V	num=S|per=3|mod=I|tmp=F
V	V	num=S|per=3|mod=I|tmp=I
V	V	num=S|per=3|mod=I|tmp=P
V	V	num=S|per=3|mod=I|tmp=R
X	X	_
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/ \s+/\t/sg;
    my @list = split(/\r?\n/, $list);
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::IT::Conll - Driver for the Italian tagset of the CoNLL 2007 Shared Task (derived from the ISST, Italian Syntactic-Semantic Treebank).

=head1 VERSION

version 3.005

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::IT::Conll;
  my $driver = Lingua::Interset::Tagset::IT::Conll->new();
  my $fs = $driver->decode("S\tS\tgen=M|num=S");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('it::conll', "S\tS\tgen=M|num=S");

=head1 DESCRIPTION

Interset driver for the Italian tagset of the CoNLL 2007 Shared Task.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For Italian,
these values are derived from the tagset of the Italian Syntactic-Semantic Treebank (ISST).

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::Conll>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
