package Lingua::GA::Gramadoir::Languages::nl;
# Dutch translations for gramadoir-0.7.
# Copyright (C) 2008 Kevin P. Scannell (msgids)
# This file is distributed under the same license as the gramadoir package.
#
# Anneke Bart <barta@slu.edu>, 2003.
# Benno Schulenberg <benno@vertaalt.nl>, 2008.
#msgid ""
#msgstr ""
#"Project-Id-Version: gramadoir-0.7\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-09-05 17:20-0500\n"
#"PO-Revision-Date: 2008-08-17 23:44+0200\n"
#"Last-Translator: Benno Schulenberg <benno@vertaalt.nl>\n"
#"Language-Team: Dutch <vertaling@vrijschrift.org>\n"
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
 => "Regel %d: [_1]\n",

    "unrecognized option [_1]"
 => "onbekende optie [_1]",

    "option [_1] requires an argument"
 => "optie [_1] vereist een argument",

    "option [_1] does not allow an argument"
 => "optie [_1] staat geen argumenten toe",

    "error parsing command-line options"
 => "fout tijdens ontleden van opdrachtregelopties",

    "Unable to set output color to [_1]"
 => "Kan uitvoerkleur niet op [_1] instellen",

    "Language [_1] is not supported."
 => "Taal [_1] wordt niet ondersteund.",

    "An Gramadoir"
 => "An Gramadóir",

    "Try [_1] for more information."
 => "Typ [_1] voor meer informatie.",

    "version [_1]"
 => "versie [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Dit is vrije software; zie de programmatekst voor de kopieervoorwaarden.\nEr is GEEN ENKELE garantie, zelfs niet voor VERHANDELBAARHEID of\nGESCHIKTHEID VOOR EEN BEPAALD DOEL, voorzover de wet dit toestaat.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Gebruik:  [_1] ~[OPTIE...~] ~[BESTAND...~]",

    "Options for end-users:"
 => "Opties voor eindgebruikers:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan       alle fouten vermelden (dus niet ~/.neamhshuim gebruiken)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=CODERING    de tekenset van de te controleren tekst",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=CODERING     te gebruiken tekenset in de uitvoer",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=TT    te gebruiken taal voor de foutmeldingen",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=KLEUR   te gebruiken kleur voor het markeren van fouten",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       verkeerd gespelde woorden naar standaarduitvoer schrijven",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       correcties suggereren voor spelfouten",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=BESTAND   uitvoer naar dit bestand schrijven",

    "    --help         display this help and exit"
 => "    --help         deze hulptekst tonen en stoppen",

    "    --version      output version information and exit"
 => "    --version      programmaversie tonen en stoppen",

    "Options for developers:"
 => "Opties voor ontwikkelaars:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          eenvoudige XML-uitvoer produceren voor andere programma's",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         HTML-uitvoer produceren om in webbrowser te bekijken",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   dubbelzinnigheden niet oplossen met behulp van frequenties",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          XML-stroom naar standaarduitvoer schrijven, voor debuggen",

    "If no file is given, read from standard input."
 => "Als er geen bestand gegeven is, wordt standaardinvoer gelezen.",

    "Send bug reports to <[_1]>."
 => "Rapporteer gebreken in het programma aan <[_1]>;\nmeld fouten in de vertaling aan <vertaling\@vrijschrift.org>.",

    "There is no such file."
 => "Dit bestand bestaat niet.",

    "Is a directory"
 => "Is een map",

    "Permission denied"
 => "Toegang geweigerd",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: Waarschuwing: probleem tijdens sluiten van [_2]\n",

    "Currently checking [_1]"
 => "Controleren van [_1]",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     onopgeloste dubbelzinnigheden vermelden,\n                     gesorteerd op frequentie",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        alle tags uitvoeren, gesorteerd op frequentie                      (voor unigram-xx.txt)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        disambigueringsregels vinden via Brills algoritme",

    "[_1]: problem reading the database\n"
 => "[_1]: Probleen tijdens lezen van de databank\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: '[_2]' is beschadigd op [_3]\n",

    "conversion from [_1] is not supported"
 => "conversie vanuit '[_1]' wordt niet ondersteund",

    "[_1]: illegal grammatical code\n"
 => "[_1]: ongeldige grammaticacode\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: geen grammaticacodes: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "[_1]: onbekende foutenmacro: [_2]\n",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Correct woord, maar erg zeldzaam in normaal gebruik.  Is dit het gewenste woord?",

    "Repeated word"
 => "Herhaald woord",

    "Unusual combination of words"
 => "Ongebruikelijke combinatie van woorden",

    "The plural form is required here"
 => "Het meervoud is hier vereist",

    "The singular form is required here"
 => "Het enkelvoud is hier vereist",

    "Plural adjective required"
 => "Een bijvoeglijk naamwoord in het meervoud is vereist",

    "Comparative adjective required"
 => "Een vergelijkende trap is vereist",

    "Definite article required"
 => "Bepaald lidwoord is vereist",

    "Unnecessary use of the definite article"
 => "Onnodig gebruik van bepaald lidwoord",

    "No need for the first definite article"
 => "Het eerste bepaald lidwoord is onnodig",

    "Unnecessary use of the genitive case"
 => "Onnodig gebruik van de genitief",

    "The genitive case is required here"
 => "De genitief is hier vereist",

    "You should use the present tense here"
 => "Hier zou de tegenwoordige tijd gebruikt moeten worden",

    "You should use the conditional here"
 => "Hier zou de tegenwoordige tijd gebruikt moeten worden",

    "It seems unlikely that you intended to use the subjunctive here"
 => "Het lijkt onwaarschijnlijk dat u hier de aanvoegende wijs bedoelde",

    "Usually used in the set phrase /[_1]/"
 => "Wordt gewoonlijk gebruikt in de staande uitdrukking /[_1]/",

    "You should use /[_1]/ here instead"
 => "Gebruik hier /[_1]/ in de plaats",

    "Non-standard form of /[_1]/"
 => "Niet-standaardvorm van /[_1]/",

    "Derived from a non-standard form of /[_1]/"
 => "Afgeleid van een niet-standaardvorm van /[_1]/",

    "Derived incorrectly from the root /[_1]/"
 => "Onjuiste afleiding van stam /[_1]/",

    "Unknown word"
 => "Onbekend woord",

    "Unknown word: /[_1]/?"
 => "Onbekend woord: /[_1]/?",

    "Valid word but /[_1]/ is more common"
 => "Correct woord, maar /[_1]/ wordt meer gebruikt",

    "Not in database but apparently formed from the root /[_1]/"
 => "Zit niet in de databank, maar blijkbaar gevormd van de stam /[_1]/",

    "The word /[_1]/ is not needed"
 => "Het woord /[_1]/ is onnodig",

    "Do you mean /[_1]/?"
 => "Bedoelde u /[_1]/?",

    "Derived form of common misspelling /[_1]/?"
 => "Afgeleide vorm van gebruikelijke foutspelling /[_1]/?",

    "Not in database but may be a compound /[_1]/?"
 => "Zit niet in de databank, maar zou een /[_1]/-samenstelling kunnen zijn?",

    "Not in database but may be a non-standard compound /[_1]/?"
 => "Zit niet in de databank, maar zou een ongebruikelijke /[_1]/-samenstelling kunnen zijn?",

    "Possibly a foreign word (the sequence /[_1]/ is highly improbable)"
 => "Mogelijk een buitenlands woord (de reeks /[_1]/ is hoogst onwaarschijnlijk)",

    "Gender disagreement"
 => "Geslachten verschillen",

    "Number disagreement"
 => "Aantallen verschillen",

    "Case disagreement"
 => "Naamvallen verschillen",

    "Prefix /h/ missing"
 => "Voorvoegsel /h/ ontbreekt",

    "Prefix /t/ missing"
 => "Voorvoegsel /t/ ontbreekt",

    "Prefix /d'/ missing"
 => "Voorvoegsel /d'/ ontbreekt",

    "Unnecessary prefix /h/"
 => "Onnodig voorvoegsel /h/",

    "Unnecessary prefix /t/"
 => "Onnodig voorvoegsel /t/",

    "Unnecessary prefix /d'/"
 => "Onnodig voorvoegsel /d'/",

    "Unnecessary prefix /b'/"
 => "Onnodig voorvoegsel /b'/",

    "Unnecessary initial mutation"
 => "Onnodige beginmutatie",

    "Initial mutation missing"
 => "Beginmutatie ontbreekt",

    "Unnecessary lenition"
 => "Onnodige lenitie (verzachting)",

    "The second lenition is unnecessary"
 => "De tweede lenitie (verzachting) is onnodig",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Het voorzetsel /[_1]/ veroorzaakt meestal lenitie, maar dit geval is onduidelijk",

    "Lenition missing"
 => "Lenitie (verzachting) ontbreekt",

    "Unnecessary eclipsis"
 => "Onnodige eclipsis",

    "Eclipsis missing"
 => "Eclipsis ontbreekt",

    "The dative is used only in special phrases"
 => "De datief wordt alleen in speciale gevallen gebruikt",

    "The dependent form of the verb is required here"
 => "De afhankelijke vorm van het werkwoord is hier vereist",

    "Unnecessary use of the dependent form of the verb"
 => "Onnodig gebruik van de afhankelijke vorm van het werkwoord",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "De synthetische (gecombineerde) vorm, eindigend op /[_1]/, wordt hier meestal gebruikt",

    "Second (soft) mutation missing"
 => "Tweede (zachte) mutatie ontbreekt",

    "Third (breathed) mutation missing"
 => "Derde (stemloze) mutatie ontbreekt",

    "Fourth (hard) mutation missing"
 => "Vierde (harde) mutatie ontbreekt",

    "Fifth (mixed) mutation missing"
 => "Vijfde (gemengde) mutatie ontbreekt",

    "Fifth (mixed) mutation after 'th missing"
 => "Vijfde (gemengde) mutatie na 'th ontbreekt",

    "Aspirate mutation missing"
 => "Aspiratiemutatie ontbreekt",

    "This word violates the rules of Igbo vowel harmony"
 => "Dit woord overtreedt de regels van de Igbo-klinkerharmonie",

    "Valid word but more often found in place of /[_1]/"
 => "Correct woord, maar vaker gevonden in de plaats van /[_1]/",

);
1;
