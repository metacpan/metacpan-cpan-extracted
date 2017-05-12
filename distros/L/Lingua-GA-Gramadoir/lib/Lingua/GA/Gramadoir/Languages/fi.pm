package Lingua::GA::Gramadoir::Languages::fi;
# Finnish messages for gramadoir.
# Copyright © 2010 Free Software Foundation, Inc.
# Copyright © 2008 Kevin P. Scannell
# This file is distributed under the same license as the gramadoir package.
# Jorma Karvonen <karvonen.jorma@gmail.com>, 2010, 2012.
#
#msgid ""
#msgstr ""
#"Project-Id-Version: gramadoir 0.7\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-08-17 12:05-0500\n"
#"PO-Revision-Date: 2012-11-27 23:34+0300\n"
#"Last-Translator: Jorma Karvonen <karvonen.jorma@gmail.com>\n"
#"Language-Team: Finnish <translation-team-fi@lists.sourceforge.net>\n"
#"Language: fi\n"
#"MIME-Version: 1.0\n"
#"Content-Type: text/plain; charset=UTF-8\n"
#"Content-Transfer-Encoding: 8bit\n"

use strict;
use warnings;
use utf8;
use base qw(Lingua::GA::Gramadoir::Languages);
use vars qw(%Lexicon);

%Lexicon = (
    "Line %d: [_1]\n"
 => "Rivi %d: [_1]\n",

    "unrecognized option [_1]"
 => "tunnistamaton valitsin [_1]",

    "option [_1] requires an argument"
 => "valitsin [_1] vaatii argumentin",

    "option [_1] does not allow an argument"
 => "valitsin [_1] ei salli argumenttia",

    "error parsing command-line options"
 => "virhe jäsennettäessä komentorivivalitsimia",

    "Unable to set output color to [_1]"
 => "Tulostevärin [_1] asettaminen epäonnistui",

    "Language [_1] is not supported."
 => "Kieltä [_1] ei tueta.",

    "An Gramadoir"
 => "Gramadóir",

    "Try [_1] for more information."
 => "Lisätietoja komennolla [_1].",

    "version [_1]"
 => "versio [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Tämä on vapaa ohjelmisto; katso lähdekoodista kopiointiehdot.  Ohjelmalle EI\nole takuuta; ei edes KAUPALLISUUDELLE tai SOPIVUUDELLE TIETTYYN TARKOITUKSEEN,\nsiinä laajudessa minkä laki sallii.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Käyttö: [_1] ~[VALITSIMET~] ~[TIEDOSTOT~]",

    "Options for end-users:"
 => "Loppukäyttäjän valitsimet:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan       ilmoita kaikki virheet (ts. älä käytä tiedostoa ~/.neamhshuim)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=ENC  määritä tarkistettavan tekstin merkkikoodaus",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=ENC   määritä tulosteen merkkikoodaus",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx valitse virheilmoitusten kieli",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=VÄRI      määritä väri virheiden korostamiseen",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       kirjoita väärinkirjoitetut sanat vakiotulosteeseen",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       suosittele korjauksia väärinkirjoituksiin",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=FILE  kirjoita tuloste tiedostoon FILE",

    "    --help         display this help and exit"
 => "    --help         näytä  tämä opaste ja poistu",

    "    --version      output version information and exit"
 => "    --version      tulosta versiotiedot ja poistu",

    "Options for developers:"
 => "Valitsimet kehittäjille:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          tulosta yksinkertainen XML-muoto muiden sovellusten käyttöön",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         tuota HTML-tuloste webbiselaimelle",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   älä ratkaise monimerkityksellisiä puheen osia esiintymistaajuuden avulla",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          kirjoita tunnisteilla varustettu XML-vuo vakiotulosteeseen vianjäljitystarkoituksiin",

    "If no file is given, read from standard input."
 => "Luetaan vakiosyötteestä jos tiedostoa ei ole annettu.",

    "Send bug reports to <[_1]>."
 => "Ilmoita virheistä (englanniksi) osoitteeseen <[_1]>.\nIlmoita käännösvirheistä osoitteeseen <translation-team-fi\@lists.sourceforge.net>.",

    "There is no such file."
 => "Tiedostoa ei löydy.",

    "Is a directory"
 => "On hakemisto",

    "Permission denied"
 => "Ei oikeuksia",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: varoitus: pulma suljettaessa [_2]\n",

    "Currently checking [_1]"
 => "Parhaillaan tarkistetaan [_1]",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     ilmoita ratkaisemattomista monimerkityksellisyyksistä esiintymistaajuuden mukaan lajiteltuna",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        tulosta kaikki tunnisteet, lajiteltu taajuuden mukaan (tiedostoa unigram-xx.txt varten)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        löydä yksimerkitykselliset säännöt Brillin ohjaamattoman algoritmin kautta",

    "[_1]: problem reading the database\n"
 => "[_1]: pulma luettaessa tietokantaa\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: `[_2]' rikkoutunut osoitteessa [_3]\n",

    "conversion from [_1] is not supported"
 => "muunnosta kohteesta [_1] ei tueta",

    "[_1]: illegal grammatical code\n"
 => "[_1]: virheellinen kieliopillinen koodi\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: ei kielioppikoodeja: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "[_1]: tunnistamaton virhemakro: [_2]\n",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Kelvollinen sana, mutta äärimmäisen harvinainen todellisessa käytössä. Onko tämä sana, jota haluat?",

    "Repeated word"
 => "Toistettu sana",

    "Unusual combination of words"
 => "Epätavallinen sanojen yhdistelmä",

    "The plural form is required here"
 => "Tässä vaaditaan monikkomuotoa",

    "The singular form is required here"
 => "Tässä vaaditaan yksikkömuotoa",

    "Plural adjective required"
 => "Vaaditaan monikollista adjektiivia",

    "Comparative adjective required"
 => "Vaaditaan vertailumuotoadjektiivia",

    "Definite article required"
 => "Vaaditaan määrättyä artikkelia",

    "Unnecessary use of the definite article"
 => "Määrätyn artikkelin tarpeeton käyttö",

    "No need for the first definite article"
 => "Ensimmäiselle määrätylle artikkelille ei ole tarvetta",

    "Unnecessary use of the genitive case"
 => "Genetiivimuodon tarpeeton käyttö",

    "The genitive case is required here"
 => "Tässä vaaditaan genetiivimuotoa",

    "You should use the present tense here"
 => "Tässä pitäisi käyttää preesensiä",

    "It seems unlikely that you intended to use the subjunctive here"
 => "Ei tunnu todennäköiseltä, että tarkoituksesi oli käyttää tässä subjunktiivia",

    "Usually used in the set phrase /[_1]/"
 => "Käytetään tavallisesti joukko-opin lauseessa /[_1]/",

    "You should use /[_1]/ here instead"
 => "Tässä pitäisi sen sijaan käyttää /[_1]/",

    "Non-standard form of /[_1]/"
 => "Epästandardi /[_1]/-muoto",

    "Derived from a non-standard form of /[_1]/"
 => "Periytyy epästandardista /[_1]/-muodosta",

    "Derived incorrectly from the root /[_1]/"
 => "Periytyy virheellisestä sanavartalosta /[_1]/",

    "Unknown word"
 => "Tuntematon sana",

    "Unknown word: /[_1]/?"
 => "Tuntematon sana: /[_1]/?",

    "Valid word but /[_1]/ is more common"
 => "Kelvollinen sana, mutta /[_1]/ on tavallisempi",

    "Not in database but apparently formed from the root /[_1]/"
 => "Ei tietokannassa, mutta ilmeisesti muodostettu sanavartalosta /[_1]/",

    "The word /[_1]/ is not needed"
 => "Sanaa /[_1]/ ei tarvita",

    "Do you mean /[_1]/?"
 => "Tarkoitatko /[_1]/?",

    "Derived form of common misspelling /[_1]/?"
 => "Periytyykö yleisestä väärinkirjoitetusta /[_1]/-muodosta?",

    "Not in database but may be a compound /[_1]/?"
 => "Ei tietokannassa, mutta saattaa olla yhdyssana /[_1]/?",

    "Not in database but may be a non-standard compound /[_1]/?"
 => "Ei tietokannassa, mutta saattaa olla epästandardi yhdyssana /[_1]/?",

    "Possibly a foreign word (the sequence /[_1]/ is highly improbable)"
 => "Mahdollisesti vierassana (sekvenssi /[_1]/ on hyvin epätodennäköinen)",

    "Gender disagreement"
 => "Sukuristiriita",

    "Number disagreement"
 => "Lukuristiriita",

    "Case disagreement"
 => "Sijamuotoristiriita",

    "Prefix /h/ missing"
 => "Etuliite /h/ puuttuu",

    "Prefix /t/ missing"
 => "Etuliite /t/ puuttuu",

    "Prefix /d'/ missing"
 => "Etuliite /d'/ puuttuu",

    "Unnecessary prefix /h/"
 => "Tarpeeton etuliite /h/",

    "Unnecessary prefix /t/"
 => "Tarpeeton etuliite /t/",

    "Unnecessary prefix /d'/"
 => "Tarpeeton etuliite /d'/",

    "Unnecessary prefix /b'/"
 => "Tarpeeton etuliite /b'/",

    "Unnecessary initial mutation"
 => "Turha alustava mutaatio",

    "Initial mutation missing"
 => "Alustava mutaatio puuttuu",

    "Unnecessary lenition"
 => "Turha liudentuminen",

    "The second lenition is unnecessary"
 => "Toinen liudentuminen on turha",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Usein prepositio /[_1]/ aiheuttaa liudentumisen, mutta tämä tapaus on epäselvä",

    "Lenition missing"
 => "Liudentuminen puuttuu",

    "Unnecessary eclipsis"
 => "Tarpeeton elisio",

    "Eclipsis missing"
 => "Mykkä tavu puuttuu",

    "The dative is used only in special phrases"
 => "Datiivia käytetään vain erikoislauseissa",

    "The dependent form of the verb is required here"
 => "Tässä vaaditaan verbin säännöllinen muoto",

    "Unnecessary use of the dependent form of the verb"
 => "Säännöllisen verbin tarpeeton käyttö ",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "Synteettinen (yhdistetty) muoto, lopussa /[_1]/, käytetään usein täällä",

    "Second (soft) mutation missing"
 => "Toinen (pehmeä) mutaatio puuttuu",

    "Third (breathed) mutation missing"
 => "Kolmas (hengähdetty) mutaatio puuttuu",

    "Fourth (hard) mutation missing"
 => "Neljäs (kova) mutaatio puuttuu",

    "Fifth (mixed) mutation missing"
 => "Viides (sekoitettu) mutaatio puuttuu",

    "Fifth (mixed) mutation after 'th missing"
 => "Viides (sekoitettu) mutaatio 'th:n jälkeen puuttuu",

    "Aspirate mutation missing"
 => "aspiraattamutaatio puuttuu",

    "This word violates the rules of Igbo vowel harmony"
 => "Tämä sana rikkoo igbo-kielen vokaaliharmoniasääntöjä",

);
1;
