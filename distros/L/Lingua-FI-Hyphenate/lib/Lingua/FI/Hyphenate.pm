package Lingua::FI::Hyphenate;

=head1 NAME

Lingua::FI::Hyphenate - Finnish hyphenation (suomen tavutus)

=head1 NIMI

Lingua::FI::Hyphenate - suomen tavutus

=head1 SYNOPSIS

    use Lingua::FI::Hyphenate qw(tavuta);

    my @tavut = tavuta("kodeissansakaan");

    print "@tavut\n"; # will print "ko deis san sa kaan\n";

=head1 KÄYTTÖ

    use Lingua::FI::Hyphenate qw(tavuta);

    my @tavut = tavuta("kodeissansakaan");

    print "@tavut\n"; # tulostaa "ko deis san sa kaan\n";

=head1 DESCRIPTION

tavuta() returns as a list the syllables of its Finnish input list.

The used character set is ISO 8859-1, of which the Finnish word
characters the vowels are

    aeiouyäåö AEIOUYÅÄÖ

and the consonants are

    bcdfghjklmnpqrstvwxz BCDFGHJKLMNPQRSTVWXZ

The rules for syllable divisions are:

=over 4

=item *

B<Before> any consonant-vowel pair I<except> when the said consonant is
the latter consonant of a syllable-initial consonant-consonant pair.

=item *

B<Between> any vowel-vowel pair I<except> when the vowel pair is a
Finnish diphthong, that is any of the I<ai au ei eu ey ie iu iy oi ou
ui uo yi yö äi äy öi öy>.

=back

=head1 KUVAUS

tavuta() palauttaa listana suomenkielisen syötelistansa tavut.

Käytetty merkistö on ISO 8859-1, suomenkieliset vokaalit ovat

    aeiouyäåö AEIOUYÅÄÖ

ja konsonantit ovat

    bcdfghjklmnpqrstvwxz BCDFGHJKLMNPQRSTVWXZ

Tavujakosäännöt ovat:

=over 4

=item *

B<Ennen> jokaista konsonantti-vokaali-paria I<paitsi> kun mainittu
konsonantti on tavunalkuisen konsonantti-konsonantti-parin jälkimmäinen.

=item *

Jokaisen vokaali-vokaali-parin B<välissä> I<paitsi> kun vokaalipari on
suomen diftongi, eli jokin seuraavista: I<ai au ei eu ey ie iu iy
oi ou ui uo yi yö äi äy öi öy>.

=head1 CAVEAT

tavuta() works only for single words.  Compound words may get wrongly
hyphenated, especially when the first component ends in a consonant
and the second component begins with a vowel.  For example,
"kaivosaukko" ('the opening of a mine', compound of "kaivos", 'mine',
and "aukko", 'opening') will be wrongly hyphenated as "kai-vo-sauk-ko"
('well otter').  Caveat hyphenator.

You may hint the correct word/syllable division by inserting a "-" at
the right places.  In fact, any non-Finnish word characters are
removed and replaced with syllable divisions.

=head1 VAROITUS

tavuta() toimii vain yksittäisille sanoille.  Sanaliitot saattavat
tavuttua väärin, varsinkin jos ensimmäinen osa päättyy konsonanttiin
ja toinen osa alkaa vokaalilla.  Esimerkiksi "kaivosaukko" tavuttuu
väärin: "kai-vo-sauk-ko".  Tarkkavaisuutta tavutukseen.

Voit antaa tavutusvihjeitä käyttämällä "-"-merkkiä sopivissa kohdissa.
Itse asiassa kaikki paitsi kirjaimet poistetaan ja korvataan tavurajoilla.

=head1 AUTHOR

Jarkko Hietaniemi <jhi@iki.fi>

=head1 COPYRIGHT

Copyright 2001 Jarkko Hietaniemi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 TEKIJÄ

Jarkko Hietaniemi <jhi@iki.fi>

=head1 TEKIJÄNOIKEUS

Copyright 2001 Jarkko Hietaniemi

=head1 LISENSSI

Tämä kirjastomoduli on vapaa; voit jakaa ja/tai muuttaa sitä samojen
ehtojen mukaisesti kuin Perliä itseään.

=cut

use strict;

use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION = '0.04';

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(tavuta);

# Hardcode the character classes instead of depending on locales.

my $v = "aeiouyäåöAEIOUYÅÄÖ";
my $k = "bcdfghjklmnpqrstvwxzBCDFGHJKLMNPQRSTVWXZ";
my $V = "[$v]";
my $K = "[$k]";

my $VU = 0;

sub tavuta {
    my (@sanat) = @_;

    my @tavut = @sanat;

    # Anything not a letter is a syllable division.

    @tavut = map { split /[^$v$k]+/ } @tavut;

    # Syllable division before any KV.
    # Exception: the rare loanword-based ^KK syllables.

    @tavut = map { split /(?=(?<!^$K)$K$V)/ } @tavut;

    # Syllable division between any VV pair
    # that is not a Finnish diphtong.

    @tavut = map { split /(.*?[aA])(?=[eoEO])/ }       @tavut;
    @tavut = map { split /(.*?[eiEI])(?=[aoäöAOÄÖ])/ } @tavut;
    @tavut = map { split /(.*?[ouOU])(?=[aeAE])/ }     @tavut;
    @tavut = map { split /(.*?[yäYÄ])(?=[eäEÄ])/ }     @tavut;
    @tavut = map { split /(.*?[öÖ])(?=[eE])/ }         @tavut;

    if ($VU) {
	# TO DO - TEKEMÄTTÄ.
    }

    @tavut;
}

1;
