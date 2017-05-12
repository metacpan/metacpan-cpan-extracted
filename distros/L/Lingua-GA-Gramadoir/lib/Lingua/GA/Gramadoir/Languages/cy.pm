package Lingua::GA::Gramadoir::Languages::cy;
# translation of cy.po to
# Translation of gramadoir.po to Cymraeg
# This file is distributed under the same license as the PACKAGE package.
# Copyright (C) YEAR Kevin P. Scannell.
# Kevin Donnelly <kevin@dotmon.com>, 2005, 2006.
#
#msgid ""
#msgstr ""
#"Project-Id-Version: cy\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-09-05 17:20-0500\n"
#"PO-Revision-Date: 2006-09-10 11:48+0100\n"
#"Last-Translator: Kevin Donnelly <kevin@dotmon.com>\n"
#"Language-Team:  <en@li.org>\n"
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
 => "Llinell %d: [_1]\n",

    "unrecognized option [_1]"
 => "dewisiad anadnabyddus [_1]",

    "option [_1] requires an argument"
 => "mae ymresymiad yn ofynnol ar gyfer dewisiad [_1]",

    "option [_1] does not allow an argument"
 => "nid yw'r dewisiad [_1] yn caniatÃ¡u ymresymiad",

    "error parsing command-line options"
 => "gwall wrth ddosrannu'r dewisiadau llinell orchymyn",

    "Unable to set output color to [_1]"
 => "Methu gosod y lliw allbwn i [_1]",

    "Language [_1] is not supported."
 => "Ni chynhelir yr iaith [_1].",

    "An Gramadoir"
 => "An Gramadoir",

    "Try [_1] for more information."
 => "Ceisiwch [_1] am ragor o wybodaeth.",

    "version [_1]"
 => "fersiwn [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Meddalwedd rhydd yw hwn; gweler y tarddiad ar gyfer amodau copÃ¯o.  Nid oes DIM\ngwarant; nid hyd yn oed ar gyfer MASNACHEIDDRWYDD neu ADDASRWYDD AR GYFER PWRPAS PENODOL, \nhyd yr eithaf a ganiateir gan y gyfraith.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Defnydd: [_1] ~[DEWISIADAU~]~[FFEILIAU~]",

    "Options for end-users:"
 => "Dewisiadau ar gyfer defnyddwyr:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan       adrodd pob gwall (h.y. peidiwch Ã¢ defnyddio ~/.neamhshuim - ffeil anwybyddu)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=AMG  penodi'r amgodiad nodau o'r testun i'w gywiro",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=AMG   penodi'r amgodiad nodau ar gyfer allbwn",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx dewis yr iaith ar gyfer negeseuon gwall",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=LLIW   penodi'r lliw i'w ddefnyddio ar gyfer amlygu gwallau",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       ysgrifennu geiriau a gamsillafwyd i allbwn safonol",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       awgrymu cywiriadau ar gyfer camsillafiadau",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=FFEIL ysgrifennu allbwn i FFEIL",

    "    --help         display this help and exit"
 => "    --help         dangos y cymorth yma a terfynu",

    "    --version      output version information and exit"
 => "    --version      dangos gwybodaeth am y fersiwn a terfynu",

    "Options for developers:"
 => "Dewisiadau ar gyfer datblygwyr:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          allbynnu fformat XML syml i'w defnyddio efo cymhwysiadau eraill",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         cynhyrchu allbwn HTML i'w weld mewn porydd gwe",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   peidio Ã¢ datrys rhannau ymadrodd amwys gan amlder",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          ysgrifennu llif XML wedi'i dagio i allbwn safonol, ar gyfer dadnamu",

    "If no file is given, read from standard input."
 => "Os ni roddir ffeil, fe'i darllenir o fewnbwn safonol.",

    "Send bug reports to <[_1]>."
 => "Anfonwch adroddiadau nam i <[_1]>.",

    "There is no such file."
 => "Nid oes y math ffeil.",

    "Is a directory"
 => "Cyfeiriadur",

    "Permission denied"
 => "Gwrthodwyd caniatÃ¢d",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: rhybudd: problem wrth gau [_2]\n",

    "Currently checking [_1]"
 => "Gwirio [_1] ar hyn o bryd",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     adrodd amwyseddau annatrys, wedi eu trefnu gan amlder",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        allbynnu pob tag, wedi'u trefnu gan amlder (ar gyfer unigram-xx.txt)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        canfod rheolau dileu amwysedd gan ddefnyddio algorithm diarolygiaeth Brill",

    "[_1]: problem reading the database\n"
 => "[_1]: problem wrth ddarllen y gronfa ddata\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: `[_2]' wedi ei lygru wrth [_3]\n",

    "conversion from [_1] is not supported"
 => "ni chynhelir trosi o [_1]",

    "[_1]: illegal grammatical code\n"
 => "[_1]: cÃ´d gramadegol anghyfreithlon\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: dim codau gramadeg: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "[_1]: macro gwall anadnabyddus: [_2]\n",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Gair dilys, ond eithriadol o brin mewn defnydd gwirioneddol",

    "Repeated word"
 => "Gair wedi'i ailadrodd",

    "Unusual combination of words"
 => "Cyfuniad anarferol o eiriau",

    "The plural form is required here"
 => "Mae'r ffurf lluosog yn ofynnol yma",

    "The singular form is required here"
 => "Mae'r ffurf unigol yn ofynnol yma",

    "Plural adjective required"
 => "Mae ansoddair lluosog yn ofynnol",

    "Comparative adjective required"
 => "Mae ansoddair cymharol yn ofynnol",

    "Definite article required"
 => "Mae'r fannod benodol yn ofynnol",

    "Unnecessary use of the definite article"
 => "Defnydd diangen o'r fannod benodol",

    "No need for the first definite article"
 => "Defnydd diangen o'r fannod benodol",

    "Unnecessary use of the genitive case"
 => "Defnydd diangen o'r cyflwr genidol",

    "The genitive case is required here"
 => "Mae'r cyflwr genidol yn ofynnol yma",

    "You should use the present tense here"
 => "Dylech ddefnyddio'r amser presennol yma",

    "You should use the conditional here"
 => "Dylech ddefnyddio'r amser presennol yma",

    "It seems unlikely that you intended to use the subjunctive here"
 => "Mae'n annhebygol y bwriedir defnyddio'r modd dibynnol yma",

    "Usually used in the set phrase /[_1]/"
 => "Defnyddir fel rheol yn yr ymadrodd sefydlog /[_1]/",

    "You should use /[_1]/ here instead"
 => "Dylid defnyddio /[_1]/ yma yn lle",

    "Non-standard form of /[_1]/"
 => "Ffurf ansafonol o /[_1]/",

    "Derived from a non-standard form of /[_1]/"
 => "Deilliwyd o ffurf ansafonol o /[_1]/",

    "Derived incorrectly from the root /[_1]/"
 => "Deilliwyd yn anghywir o'r gwreiddyn /[_1]/",

    "Unknown word"
 => "Gair anhysbys",

    "Unknown word: /[_1]/?"
 => "Gair anhysbys: /[_1]/?",

    "Valid word but /[_1]/ is more common"
 => "Valid word but /[_1]/ is more common",

    "Not in database but apparently formed from the root /[_1]/"
 => "Dim yn y gronfa ddata, ond yn Ã´l pob golwg deilliwyd o'r gwreiddyn /[_1]/",

    "The word /[_1]/ is not needed"
 => "Nid oes angen y gair /[_1]/",

    "Do you mean /[_1]/?"
 => "Ydych yn golygu /[_1]/?",

    "Derived form of common misspelling /[_1]/?"
 => "Ffurf ddeilliedig o'r camsillafiad cyffredin /[_1]/?",

    "Not in database but may be a compound /[_1]/?"
 => "Dim yn y gronfa ddata ond efallai cyfansoddair o /[_1]/?",

    "Not in database but may be a non-standard compound /[_1]/?"
 => "Dim yn y gronfa ddata ond efallai cyfansoddair ansafonol o /[_1]/?",

    "Possibly a foreign word (the sequence /[_1]/ is highly improbable)"
 => "Efallai gair dieithr (mae'r dilyniant /[_1]/ yn annhebygol iawn)",

    "Gender disagreement"
 => "Anghytundeb cenedl",

    "Number disagreement"
 => "Anghytundeb rhif",

    "Case disagreement"
 => "Anghytundeb cyflwr",

    "Prefix /h/ missing"
 => "Rhagddodiad /h/ ar goll",

    "Prefix /t/ missing"
 => "Rhagddodiad /t/ ar goll",

    "Prefix /d'/ missing"
 => "Rhagddodiad /d'/ ar goll",

    "Unnecessary prefix /h/"
 => "Rhagddodiad diangen /h/",

    "Unnecessary prefix /t/"
 => "Rhagddodiad diangen /t/",

    "Unnecessary prefix /d'/"
 => "Rhagddodiad diangen /d'/",

    "Unnecessary prefix /b'/"
 => "Rhagddodiad diangen /d'/",

    "Unnecessary initial mutation"
 => "Treiglad cychwynnol diangen",

    "Initial mutation missing"
 => "Treiglad cychwynnol ar goll",

    "Unnecessary lenition"
 => "Treiglad meddal diangen",

    "The second lenition is unnecessary"
 => "The second lenition is unnecessary",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Gan amlaf, achosa'r arddodiad /[_1]/ dreiglad meddal, ond nid yw'r enghraifft yma yn glir",

    "Lenition missing"
 => "Treiglad meddal ar goll",

    "Unnecessary eclipsis"
 => "Treiglad trwynol diangen",

    "Eclipsis missing"
 => "Treiglad trwynol ar goll",

    "The dative is used only in special phrases"
 => "Defnyddir y cyflwr derbyniol mewn ymadroddion arbennig yn unig",

    "The dependent form of the verb is required here"
 => "Mae ffurf dibynnol y berf yn ofynnol yma",

    "Unnecessary use of the dependent form of the verb"
 => "Defnydd diangen o ffurf ddibynnol y ferf",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "Defnyddir y ffurf synthetig (gyfunol), sy'n gorffen gyda /1/, yn aml yma",

    "Second (soft) mutation missing"
 => "Ail dreiglad (meddal) ar goll",

    "Third (breathed) mutation missing"
 => "Trydydd treiglad (llaes) ar goll",

    "Fourth (hard) mutation missing"
 => "Pedwerydd treiglad (caled) ar goll",

    "Fifth (mixed) mutation missing"
 => "Pumed treiglad (cymysg) ar goll",

    "Fifth (mixed) mutation after 'th missing"
 => "Pumed treiglad (cymysg) ar Ã´l 'th ar goll",

    "Aspirate mutation missing"
 => "Treiglad llaes ar goll",

    "This word violates the rules of Igbo vowel harmony"
 => "Mae'r gair yma yn torri rheolau cytgord llafariaid Igbo",

    "Valid word but more often found in place of /[_1]/"
 => "Gair dilys, ond fel rheol defnyddir yn lle /[_1]/",

);
1;
