package Lingua::YALI::LanguageIdentifier;
# ABSTRACT: Module for language identification.

use strict;
use warnings;
use File::ShareDir;
use File::Glob;
use Carp;
use Moose;

our $VERSION = '0.015'; # VERSION

extends 'Lingua::YALI::Identifier';

has '_languages' => (is => 'rw', isa => 'ArrayRef');
has '_language_model' => (is => 'rw', isa => 'HashRef');





sub add_language
{
    my ($self, @languages) = @_;

    # lazy loading
    if ( ! defined($self->_languages) ) {
        $self->get_available_languages();
    }

    # register languages
    my $added_languages = 0;
    for my $lang (@languages) {
        if ( ! defined($self->{_language_model}->{$lang}) ) {
            croak("Unknown language $lang");
        }
        $added_languages += $self->add_class($lang, $self->{_language_model}->{$lang});
    }

    return $added_languages;
}


sub remove_language
{
    my ($self, @languages) = @_;

    # lazy loading
    if ( ! defined($self->_languages) ) {
        $self->get_available_languages();
    }

    # remove languages
    my $removed_languages = 0;
    for my $lang (@languages) {
        if ( ! defined($self->{_language_model}->{$lang}) ) {
            croak("Unknown language $lang");
        }
        $removed_languages += $self->remove_class($lang);
    }

    return $removed_languages;
}


sub get_languages
{
    my $self = shift;
    return $self->get_classes();
}


sub get_available_languages
{
    my $self = shift;

    # Get a module's shared files directory
    if ( ! defined($self->_languages) ) {

        my $dir = "share/";
        eval { $dir = File::ShareDir::dist_dir('Lingua-YALI'); };

        my @languages = ();

        for my $file (File::Glob::bsd_glob($dir . "/*.yali.gz")) {
            my $language = $file;
            $language =~ s/\Q$dir\E.//;
            $language =~ s/.yali.gz//;

            push(@languages, $language);
            $self->{_language_model}->{$language} = $file;
        }
        $self->_languages(\@languages);
#        print STDERR join("\t", @languages), "\n";
    }

    return $self->_languages;
}




# for lang in `ls lib/auto/Lingua/YALI/ | cut -f1 -d.`; do name=`webAPI.sh GET $lang name | cut -f3-`; echo -e "=item * $lang - $name\n"; done




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::YALI::LanguageIdentifier - Module for language identification.

=head1 VERSION

version 0.015

=head1 SYNOPSIS

This modul is for language identification and can identify 122 languages.

    use Lingua::YALI::LanguageIdentifier;

    # create identifier and register languages
    my $identifier = Lingua::YALI::LanguageIdentifier->new();
    $identifier->add_language("ces", "eng")

    # identify string
    my $result = $identifier->identify_string("CPAN, the Comprehensive Perl Archive Network, is an archive of modules written in Perl.");
    print "The most probable language is " . $result->[0]->[0] . ".\n";
    # prints out The most probable language is eng.

More examples is presented in L<Lingua::YALI::Examples|Lingua::YALI::Examples>.

=head1 METHODS

=head2 add_language

    my $added_languages = $identifier->add_languages(@languages)

Registers new languages C<@languages> for identification and returns
the amount of newly added languages. Languages are identified by their
ISO 639-3 code.

It croaks when unsupported language is used.

    print $identifier->add_languages("ces", "deu", "eng") . "\n";
    # prints out 3
    print $identifier->add_languages("ces", "slk") . "\n";
    # prints out 1

=head2 remove_language

    my $removed_languages = $identifier->remove_languages(@languages)

Remove languages C<@languages> and returns the amount of removed languages.

It croaks when unsupported language is used.

    print $identifier->add_languages("ces", "deu", "eng")
    # prints out 3
    print $identifier->remove_languages("ces", "slk") . "\n";
    # prints out 1
    print $identifier->remove_languages("ces", "slk") . "\n";
    # prints out 0

=head2 get_languages

    my \@languages = $identifier->get_languages();

Returns all registered languages.

=head2 get_available_languages

    my \@languages = $identifier->get_available_languages();

Returns all available languages. Currently there is 122 languages (L</LANGUAGES>).

=head2 identify_file

    my $result = $identifier->identify_file($file)

Identifies language for file C<$file>.

For more details look at method L<Lingua::YALI::Identifier/identify_file>.

=head2 identify_string

    my $result = $identifier->identify_string($string)

Identifies language for string C<$string>.

For more details look at method L<Lingua::YALI::Identifier/identify_string>.

=head2 identify_handle

    my $result = $identifier->identify_handle($fh)

Identifies language for handle C<$fh>.

For more details look at method L<Lingua::YALI::Identifier/identify_handle>.

=head1 LANGUAGES

More details about supported languages may be found at L<http://ufal.mff.cuni.cz/~majlis/w2c/download.html>.

=over

=item * afr - Afrikaans

=item * als - Tosk Albanian

=item * amh - Amharic

=item * ara - Arabic

=item * arg - Aragonese

=item * arz - Egyptian Arabic

=item * ast - Asturian

=item * aze - Azerbaijani

=item * bcl - Central Bicolano

=item * bel - Belarusian

=item * ben - Bengali

=item * bos - Bosnian

=item * bpy - Bishnupriya

=item * bre - Breton

=item * bug - Buginese

=item * bul - Bulgarian

=item * cat - Catalan

=item * ceb - Cebuano

=item * ces - Czech

=item * chv - Chuvash

=item * cos - Corsican

=item * cym - Welsh

=item * dan - Danish

=item * deu - German

=item * diq - Dimli (individual language)

=item * ell - Modern Greek (1453-)

=item * eng - English

=item * epo - Esperanto

=item * est - Estonian

=item * eus - Basque

=item * fao - Faroese

=item * fas - Persian

=item * fin - Finnish

=item * fra - French

=item * fry - Western Frisian

=item * gan - Gan Chinese

=item * gla - Scottish Gaelic

=item * gle - Irish

=item * glg - Galician

=item * glk - Gilaki

=item * guj - Gujarati

=item * hat - Haitian

=item * hbs - Serbo-Croatian

=item * heb - Hebrew

=item * hif - Fiji Hindi

=item * hin - Hindi

=item * hrv - Croatian

=item * hsb - Upper Sorbian

=item * hun - Hungarian

=item * hye - Armenian

=item * ido - Ido

=item * ina - Interlingua (International Auxiliary Language Association)

=item * ind - Indonesian

=item * isl - Icelandic

=item * ita - Italian

=item * jav - Javanese

=item * jpn - Japanese

=item * kan - Kannada

=item * kat - Georgian

=item * kaz - Kazakh

=item * kor - Korean

=item * kur - Kurdish

=item * lat - Latin

=item * lav - Latvian

=item * lim - Limburgan

=item * lit - Lithuanian

=item * lmo - Lombard

=item * ltz - Luxembourgish

=item * mal - Malayalam

=item * mar - Marathi

=item * mkd - Macedonian

=item * mlg - Malagasy

=item * mon - Mongolian

=item * mri - Maori

=item * msa - Malay (macrolanguage)

=item * mya - Burmese

=item * nap - Neapolitan

=item * nds - Low German

=item * nep - Nepali

=item * new - Newari

=item * nld - Dutch

=item * nno - Norwegian Nynorsk

=item * nor - Norwegian

=item * oci - Occitan (post 1500)

=item * oss - Ossetian

=item * pam - Pampanga

=item * pms - Piemontese

=item * pnb - Western Panjabi

=item * pol - Polish

=item * por - Portuguese

=item * que - Quechua

=item * ron - Romanian

=item * rus - Russian

=item * sah - Yakut

=item * scn - Sicilian

=item * sco - Scots

=item * slk - Slovak

=item * slv - Slovenian

=item * spa - Spanish

=item * sqi - Albanian

=item * srp - Serbian

=item * sun - Sundanese

=item * swa - Swahili (macrolanguage)

=item * swe - Swedish

=item * tam - Tamil

=item * tat - Tatar

=item * tel - Telugu

=item * tgk - Tajik

=item * tgl - Tagalog

=item * tha - Thai

=item * tur - Turkish

=item * ukr - Ukrainian

=item * urd - Urdu

=item * uzb - Uzbek

=item * vec - Venetian

=item * vie - Vietnamese

=item * vol - Volapük

=item * war - Waray (Philippines)

=item * wln - Walloon

=item * yid - Yiddish

=item * yor - Yoruba

=item * zho - Chinese

=back

=head1 SEE ALSO

=over

=item * Identifier for own models is L<Lingua::YALI::Identifier|Lingua::YALI::Identifier>.

=item * There is also command line tool L<yali-language-identifier|Lingua::YALI::yali-language-identifier> with similar functionality.

=item * Source codes are available at L<https://github.com/martin-majlis/YALI>.

=back

=head1 AUTHOR

Martin Majlis <martin@majlis.cz>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Martin Majlis.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
