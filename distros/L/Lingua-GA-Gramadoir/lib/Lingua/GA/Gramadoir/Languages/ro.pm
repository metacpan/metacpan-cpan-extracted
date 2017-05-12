package Lingua::GA::Gramadoir::Languages::ro;
# Mesajele în limba română pentru pachetul gramadoir.
# Copyright (C) 2003 Free Software Foundation, Inc.
# Acest fişier este distribuit sub aceeaşi licenţă ca pachetul gramadoir.
# Eugen Hoanca <eugenh@urban-grafx.ro>, 2003.
#
#msgid ""
#msgstr ""
#"Project-Id-Version: gramadoir 0.3\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-09-05 17:20-0500\n"
#"PO-Revision-Date: 2003-10-28 12:23+0200\n"
#"Last-Translator: Eugen Hoanca <eugenh@urban-grafx.ro>\n"
#"Language-Team: Romanian <translation-team-ro@lists.sourceforge.net>\n"
#"MIME-Version: 1.0\n"
#"Content-Type: text/plain; charset=ISO-8859-2\n"
#"Content-Transfer-Encoding: 8bit\n"

use strict;
use warnings;
use utf8;
use base qw(Lingua::GA::Gramadoir::Languages);
use vars qw(%Lexicon);

%Lexicon = (
    "Line %d: [_1]\n"
 => "Linia %d: [_1]\n",

    "unrecognized option [_1]"
 => "opţiune necunoscută [_1].",

    "option [_1] requires an argument"
 => "opţiunea [_1] necesită un parametru",

    "option [_1] does not allow an argument"
 => "opţiunea [_1] nu permite parametri",

    "error parsing command-line options"
 => "error parsing command-line options",

    "Unable to set output color to [_1]"
 => "Unable to set output color to [_1]",

    "Language [_1] is not supported."
 => "Limba [_1] nu este suportată.",

    "An Gramadoir"
 => "Un Gramadoir",

    "Try [_1] for more information."
 => "Încercaţi [_1] pentru mai multe informaţii.",

    "version [_1]"
 => "versiunea [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Acesta este software liber; citiţi sursele pentru condiţiile de copiere.  NU există\nNICI o garanţie; nici măcar pentru VANDABILITATE SAU MODIFICARE ÎNTR-UN SCOP PRIVAT,\npe întinderea permisă de lege.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Folosire: [_1] ~[OPŢIUNI~] ~[FIŞIERE~]",

    "Options for end-users:"
 => "Options for end-users:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan       raportează toate erorile (i.e. nu se foloseşte ~/.neamhshuim)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=ENC  specifică codarea(encoding) de textului ce urmează a fi verificat",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=ENC   specify the character encoding for output",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx choose the language for error messages",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=COLOR   specify the color to use for highlighting errors",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       scrie cuvintele greşite la ieşirea standard",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       suggest corrections for misspellings",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=FILE  write output to FILE",

    "    --help         display this help and exit"
 => "    --help         afişează acest help şi iese",

    "    --version      output version information and exit"
 => "    --version      afişează informaţii despre versiune şi iese",

    "Options for developers:"
 => "Options for developers:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          output a simple XML format for use with other applications",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         produce output HTML pentru vizualizarea într-un browser de web",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   do not resolve ambiguous parts of speech by frequency",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          scrie secvenţă XML marcat(tagged) la ieşirea standard, pentru debugging",

    "If no file is given, read from standard input."
 => "Dacă nu este furnizat nici un fişier, se citeşte de la intrarea standard.",

    "Send bug reports to <[_1]>."
 => "Trimiteţi rapoarte de bug-uri la <[_1]>.",

    "There is no such file."
 => "Nu a existat acest fişier.",

    "Is a directory"
 => "E un director.",

    "Permission denied"
 => "Permisiune neacordată.",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: avertisment: problemă la închiderea [_2]\n",

    "Currently checking [_1]"
 => "În prezent se verifică [_1]",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     report unresolved ambiguities, sorted by frequency",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        find disambiguation rules via Brill's unsupervised algorithm",

    "[_1]: problem reading the database\n"
 => "[_1]: problemă în citirea bazei de date\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: `[_2]' corupt la [_3]\n",

    "conversion from [_1] is not supported"
 => "Limba [_1] nu este suportată.",

    "[_1]: illegal grammatical code\n"
 => "[_1]: cod gramatical incorect\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: nu există codecuri de gramatică: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "opţiune necunoscută [_1].",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Valid word but extremely rare in actual usage. Is this the word you want?",

    "Repeated word"
 => "Repeated word",

    "Unusual combination of words"
 => "Unusual combination of words",

    "The plural form is required here"
 => "The plural form is required here",

    "The singular form is required here"
 => "The singular form is required here",

    "Plural adjective required"
 => "Plural adjective required",

    "Comparative adjective required"
 => "Comparative adjective required",

    "Definite article required"
 => "Definite article required",

    "Unnecessary use of the definite article"
 => "Unnecessary use of the definite article",

    "No need for the first definite article"
 => "No need for the first definite article",

    "Unnecessary use of the genitive case"
 => "Indulgenţă(lenition) nenecesară",

    "The genitive case is required here"
 => "The genitive case is required here",

    "You should use the present tense here"
 => "Ar trebui să folosiţi mai bine /[_1]/ aici",

    "You should use the conditional here"
 => "Ar trebui să folosiţi mai bine /[_1]/ aici",

    "It seems unlikely that you intended to use the subjunctive here"
 => "It seems unlikely that you intended to use the subjunctive here",

    "Usually used in the set phrase /[_1]/"
 => "Usually used in the set phrase /[_1]/",

    "You should use /[_1]/ here instead"
 => "Ar trebui să folosiţi mai bine /[_1]/ aici",

    "Non-standard form of /[_1]/"
 => "Formă nestandardizată: mai bine folosiţi  /[_1]/?",

    "Derived from a non-standard form of /[_1]/"
 => "Derived from a non-standard form of /[_1]/",

    "Derived incorrectly from the root /[_1]/"
 => "Derived incorrectly from the root /[_1]/",

    "Unknown word"
 => "Cuvânt necunoscut",

    "Unknown word: /[_1]/?"
 => "Cuvânt necunoscut",

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
 => "Lipseşte prefixul /h/",

    "Prefix /t/ missing"
 => "Lipseşte prefixul /t/",

    "Prefix /d'/ missing"
 => "Lipseşte prefixul /h/",

    "Unnecessary prefix /h/"
 => "Unnecessary prefix /h/",

    "Unnecessary prefix /t/"
 => "Unnecessary prefix /t/",

    "Unnecessary prefix /d'/"
 => "Indulgenţă(lenition) nenecesară",

    "Unnecessary prefix /b'/"
 => "Indulgenţă(lenition) nenecesară",

    "Unnecessary initial mutation"
 => "Indulgenţă(lenition) nenecesară",

    "Initial mutation missing"
 => "Mutaţie iniţială lipsă",

    "Unnecessary lenition"
 => "Indulgenţă(lenition) nenecesară",

    "The second lenition is unnecessary"
 => "The second lenition is unnecessary",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Often the preposition /[_1]/ causes lenition, but this case is unclear",

    "Lenition missing"
 => "Indulgenţă(lenition) lipsă",

    "Unnecessary eclipsis"
 => "Indulgenţă(lenition) nenecesară",

    "Eclipsis missing"
 => "Eclipsare(eclipsis) lipsă",

    "The dative is used only in special phrases"
 => "The dative is used only in special phrases",

    "The dependent form of the verb is required here"
 => "The dependent form of the verb is required here",

    "Unnecessary use of the dependent form of the verb"
 => "Indulgenţă(lenition) nenecesară",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "The synthetic (combined) form, ending in /[_1]/, is often used here",

    "Second (soft) mutation missing"
 => "Mutaţie iniţială lipsă",

    "Third (breathed) mutation missing"
 => "Mutaţie iniţială lipsă",

    "Fourth (hard) mutation missing"
 => "Mutaţie iniţială lipsă",

    "Fifth (mixed) mutation missing"
 => "Mutaţie iniţială lipsă",

    "Fifth (mixed) mutation after 'th missing"
 => "Mutaţie iniţială lipsă",

    "Aspirate mutation missing"
 => "Mutaţie iniţială lipsă",

    "This word violates the rules of Igbo vowel harmony"
 => "This word violates the rules of Igbo vowel harmony",

    "#~ \"    --teanga=XX    specify the language of the text to be checked \"#~ \"(default=ga)\""
 => "#~ \"    --teanga=XX    specifică limba textului care urmează a fi verificat\"#~ \"(implicit=ga)\"",

    "Unknown word (ignoring remainder in this sentence)"
 => "#~ \"Cuvânt necunoscut (se ignoră marcajul(remainder) în această propoziţie)\"",

    "[_1]: out of memory\n"
 => "[_1]: Memorie plină\n",

    "[_1]: warning: check size of [_2]: %d?\n"
 => "[_1]: avertisment: verificaţi mărimea lui [_2]: %d?\n",

    "problem with the `cuardach' command\n"
 => "problemă cu comanda `cuardach'\n",

);
1;
