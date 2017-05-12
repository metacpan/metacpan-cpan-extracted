package Lingua::GA::Gramadoir::Languages::af;
# An Gramadóir - The Grammarian
# Copyright (C) 2004 Free Software Foundation, Inc.
# This file is distributed under the same license as the PACKAGE package.
# Petri Jooste <rkwjpj@puk.ac.za>, 2004.
#
#msgid ""
#msgstr ""
#"Project-Id-Version: gramadoir 0.4\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-09-05 17:20-0500\n"
#"PO-Revision-Date: 2004-03-02 16:38+0200\n"
#"Last-Translator: Petri Jooste <rkwjpj@puk.ac.za>\n"
#"Language-Team: Afrikaans <i18n@af.org.za>\n"
#"MIME-Version: 1.0\n"
#"Content-Type: text/plain; charset=iso-8859-1\n"
#"Content-Transfer-Encoding: 8bit\n"

use strict;
use warnings;
use utf8;
use base qw(Lingua::GA::Gramadoir::Languages);
use vars qw(%Lexicon);

%Lexicon = (
    "Line %d: [_1]\n"
 => "Reël %d: [_1]\n",

    "unrecognized option [_1]"
 => "onbekende opsie [_1]",

    "option [_1] requires an argument"
 => "opsie [_1]: benodig 'n parameter",

    "option [_1] does not allow an argument"
 => "opsie [_1] laat nie 'n parameter toe nie",

    "error parsing command-line options"
 => "error parsing command-line options",

    "Unable to set output color to [_1]"
 => "Unable to set output color to [_1]",

    "Language [_1] is not supported."
 => "Taal [_1] word nie ondersteun nie.",

    "An Gramadoir"
 => "An Gramadóir",

    "Try [_1] for more information."
 => "Probeer [_1] vir meer inligting.",

    "version [_1]"
 => "weergawe [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Hierdie is vry sagteware; sien die bronkode vir kopieervoorwaardes.  Daar is GEEN\nwaarborg nie; selfs nie eers vir MERCHANTABILITY of GESKIKTHEID VIR 'N SPESIFIEKE DOEL nie,\ntot die mate wat deur die wet toegelaat word.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Gebruik so: [_1] ~[OPSIES~] ~[LÊERS~]",

    "Options for end-users:"
 => "Opsies vir eindgebruikers:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan       wys alle foute (d.w.s. ignoreer die lêer ~/.neamhshuim)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=ENC  spesifiseer die karakterkodering van die teks wat nagegaan moet word",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=ENC   specify the character encoding for output",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx choose the language for error messages",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=COLOR   specify the color to use for highlighting errors",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       skryf spelfoute na standaardafvoer",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       maak suggesties vir spelfoute",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=FILE  write output to FILE",

    "    --help         display this help and exit"
 => "    --help         wys hierdie hulpteks en stop",

    "    --version      output version information and exit"
 => "    --version      wys weergawe-inligting en stop",

    "Options for developers:"
 => "Opsies vir ontwikkelaars:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          output a simple XML format for use with other applications",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         produseer HTML-afvoer wat met 'n webblaaier bekyk kan word",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   moenie frekwensie gebruik om dubbelsinnige woordsoorte op te los nie",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          skryf die XML-stroom met merkers na standaardafvoer, vir ontfouting",

    "If no file is given, read from standard input."
 => "As geen lêer gegee is nie, lees van standaardtoevoer",

    "Send bug reports to <[_1]>."
 => "Stuur foutverslae aan <[_1]>.",

    "There is no such file."
 => "Daardie lêer bestaan nie.",

    "Is a directory"
 => "Dit is 'n lêergids",

    "Permission denied"
 => "Toegang geweier",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: waarskuwing: problem met toemaak van [_2]\n",

    "Currently checking [_1]"
 => "[_1] word tans nagegaan",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     wys onopgeloste dubbelsinnighede, gesorteer volgens frekwensie",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        wys alle merkers, gesorteer volgens frekwensie (vir unigram-xx.txt)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        bepaal reëls vir ondubbelsinnigmaking deur Brill se toesiglose algoritme",

    "[_1]: problem reading the database\n"
 => "[_1]: probleem met lees van databasis\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: `[_2]' is korrup by at [_3]\n",

    "conversion from [_1] is not supported"
 => "Omsetting van [_1] word nie ondersteun nie",

    "[_1]: illegal grammatical code\n"
 => "[_1]: ongeldige grammatika-kode\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: geen grammatika-kodes: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "onbekende opsie [_1]",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Geldige woord, maar baie seldsaam",

    "Repeated word"
 => "Herhaalde woord",

    "Unusual combination of words"
 => "Ongewone kombinasie van woorde",

    "The plural form is required here"
 => "Die genitief word hier benodig",

    "The singular form is required here"
 => "Die genitief word hier benodig",

    "Plural adjective required"
 => "Vergelykende adjektief benodig",

    "Comparative adjective required"
 => "Vergelykende adjektief benodig",

    "Definite article required"
 => "Definite article required",

    "Unnecessary use of the definite article"
 => "Onnodige gebruik van die bepaalde lidwoord",

    "No need for the first definite article"
 => "Onnodige gebruik van die bepaalde lidwoord",

    "Unnecessary use of the genitive case"
 => "Onnodige gebruik van die bepaalde lidwoord",

    "The genitive case is required here"
 => "Die genitief word hier benodig",

    "You should use the present tense here"
 => "U moet hier eerder /[_1]/ gebruik",

    "You should use the conditional here"
 => "U moet hier eerder /[_1]/ gebruik",

    "It seems unlikely that you intended to use the subjunctive here"
 => "It seems unlikely that you intended to use the subjunctive here",

    "Usually used in the set phrase /[_1]/"
 => "Word normaalweg gebruik in die vaste konstruksie /[_1]/",

    "You should use /[_1]/ here instead"
 => "U moet hier eerder /[_1]/ gebruik",

    "Non-standard form of /[_1]/"
 => "Nie-standaardvorm: gebruik miskien /[_1]/?",

    "Derived from a non-standard form of /[_1]/"
 => "Derived from a non-standard form of /[_1]/",

    "Derived incorrectly from the root /[_1]/"
 => "Derived incorrectly from the root /[_1]/",

    "Unknown word"
 => "Onbekende woord",

    "Unknown word: /[_1]/?"
 => "Onbekende woord",

    "Valid word but /[_1]/ is more common"
 => "Valid word but /[_1]/ is more common",

    "Not in database but apparently formed from the root /[_1]/"
 => "Not in database but apparently formed from the root /[_1]/",

    "The word /[_1]/ is not needed"
 => "The word /[_1]/ is not needed",

    "Do you mean /[_1]/?"
 => "Do you mean /[_1]/?",

    "Derived form of common misspelling /[_1]/?"
 => "Derived form of common misspelling /[_1]/?",

    "Not in database but may be a compound /[_1]/?"
 => "Not in database but may be a compound /[_1]/?",

    "Not in database but may be a non-standard compound /[_1]/?"
 => "Not in database but may be a non-standard compound /[_1]/?",

    "Possibly a foreign word (the sequence /[_1]/ is highly improbable)"
 => "Possibly a foreign word (the sequence /[_1]/ is highly improbable)",

    "Gender disagreement"
 => "Gender disagreement",

    "Number disagreement"
 => "Number disagreement",

    "Case disagreement"
 => "Case disagreement",

    "Prefix /h/ missing"
 => "Voorvoegsel /h/ ontbreek",

    "Prefix /t/ missing"
 => "Voorvoegsel /t/ ontbreekkdesu is weg",

    "Prefix /d'/ missing"
 => "Voorvoegsel /h/ ontbreek",

    "Unnecessary prefix /h/"
 => "Onnodige voorvoegsel /h/",

    "Unnecessary prefix /t/"
 => "Onnodige voorvoegsel /t/",

    "Unnecessary prefix /d'/"
 => "Onnodige voorvoegsel /h/",

    "Unnecessary prefix /b'/"
 => "Onnodige voorvoegsel /h/",

    "Unnecessary initial mutation"
 => "Onnodige linisie",

    "Initial mutation missing"
 => "Aanvangsmutasie ontbreek",

    "Unnecessary lenition"
 => "Onnodige linisie",

    "The second lenition is unnecessary"
 => "The second lenition is unnecessary",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Often the preposition /[_1]/ causes lenition, but this case is unclear",

    "Lenition missing"
 => "Lenisie ontbreek",

    "Unnecessary eclipsis"
 => "Onnodige linisie",

    "Eclipsis missing"
 => "Eklips ontbreek",

    "The dative is used only in special phrases"
 => "The dative is used only in special phrases",

    "The dependent form of the verb is required here"
 => "Die genitief word hier benodig",

    "Unnecessary use of the dependent form of the verb"
 => "Onnodige gebruik van die bepaalde lidwoord",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "The synthetic (combined) form, ending in /[_1]/, is often used here",

    "Second (soft) mutation missing"
 => "Aanvangsmutasie ontbreek",

    "Third (breathed) mutation missing"
 => "Aanvangsmutasie ontbreek",

    "Fourth (hard) mutation missing"
 => "Aanvangsmutasie ontbreek",

    "Fifth (mixed) mutation missing"
 => "Aanvangsmutasie ontbreek",

    "Fifth (mixed) mutation after 'th missing"
 => "Aanvangsmutasie ontbreek",

    "Aspirate mutation missing"
 => "Aanvangsmutasie ontbreek",

    "This word violates the rules of Igbo vowel harmony"
 => "This word violates the rules of Igbo vowel harmony",

    "#~ \"    --aspell       suggest corrections for misspellings (requires GNU \"#~ \"aspell)\""
 => "#~ \"    --aspell       maak suggesties vir spelfoute (benodig GNU aspell)\"",

    "#~ \"    --teanga=XX    specify the language of the text to be checked \"#~ \"(default=ga)\""
 => "#~ \"    --teanga=XX    spesifiseer die taal van die teks wat nagegaan moet \"#~ \"word (verstek=ga)\"",

    "aspell-[_1] is not installed"
 => "aspell-[_1] is nie geïnstalleer nie",

    "Unknown word (ignoring remainder in this sentence)"
 => "Onbekende woord (die res van die sin word geïgnoreer)",

    "[_1]: out of memory\n"
 => "[_1]: te min geheue\n",

    "[_1]: warning: check size of [_2]: %d?\n"
 => "[_1]: waarskuwing: gaan die groote na van [_2]: %d?\n",

    "problem with the `cuardach' command\n"
 => "probleem met die `cuardach' bevel\n",

);
1;
