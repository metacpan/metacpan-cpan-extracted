package Lingua::GA::Gramadoir::Languages::sk;
# translation of gramadoir to Slovak
# Copyright (C) 2004 Kevin P. Scannell.
# This file is distributed under the same license as the gramadoir package.
# Andrej Kacian <andrej@kacian.sk>, 2004, 2005.
#
#msgid ""
#msgstr ""
#"Project-Id-Version: gramadoir 0.6\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-09-05 17:20-0500\n"
#"PO-Revision-Date: 2005-03-05 12:09+0100\n"
#"Last-Translator: Andrej Kacian <andrej@kacian.sk>\n"
#"Language-Team: Slovak <sk-i18n@lists.linux.sk>\n"
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
 => "Riadok %d: [_1]\n",

    "unrecognized option [_1]"
 => "neznáma voľba [_1]",

    "option [_1] requires an argument"
 => "voľba [_1] vyžaduje parameter",

    "option [_1] does not allow an argument"
 => "voľba [_1] nepripúšta parameter",

    "error parsing command-line options"
 => "chyba pri čítaní parametrov príkazového riadku",

    "Unable to set output color to [_1]"
 => "Nepodarilo sa nastaviť farbu výstupu na [_1]",

    "Language [_1] is not supported."
 => "Jazyk [_1] nie je podporovaný.",

    "An Gramadoir"
 => "An Gramadóir",

    "Try [_1] for more information."
 => "Skúste [_1] pre ďalšie informácie.",

    "version [_1]"
 => "verzia [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Toto je voľne šíriteľný program, pozrite si zdrojové súbory. Neposkytuje sa\nžiadna záruka, dokonca ani záruka PREDAJNOSTI alebo VHODNOSTI PRE \nURČITÝ ÚČEL, v rozsahu povolenom zákonom.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Použitie: [_1] ~[VOĽBY~] ~[SÚBORY~]",

    "Options for end-users:"
 => "Voľby pre koncových používateľov:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan       hlásiť všetky chyby (teda nepoužívať ~/.neamhshuim)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=ENC  určenie kódovania overovaného textu",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=ENC   určenie výstupného kódovania",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx určenie jazyka pre chybové hlášky",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=COLOR   určenie farby pre zvýraznenie chýb",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       vypísať nesprávne slová na štandardný výstup",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       navrhnúť opravu nesprávnych slov",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=FILE  zapísať výstup do súboru FILE",

    "    --help         display this help and exit"
 => "    --help         zobrazí tento text a ukončí program",

    "    --version      output version information and exit"
 => "    --version      zobrazí informácie o verzii a ukončí program",

    "Options for developers:"
 => "Voľby pre vývojárov:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          formátovať výstup ako jednoduché XML, pre iné aplikácie",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         vytvorí HTML výstup pre prezeranie vo webovom prehliadači",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   neurčovať význam slov podľa počtu výskytu",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          zapísať označkovaný XML stream na štandardný výstup, pre odlaďovanie",

    "If no file is given, read from standard input."
 => "Ak nie je zadaný žiadny súbor, čítaj zo štandardného vstupu",

    "Send bug reports to <[_1]>."
 => "Odosielať správy o chybe na <[_1]>.",

    "There is no such file."
 => "Taký súbor neexistuje.",

    "Is a directory"
 => "Toto je priečinok",

    "Permission denied"
 => "Prístup nepovolený",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: varovanie: problém pri zatváraní [_2]\n",

    "Currently checking [_1]"
 => "Práve overujem [_1]",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     vypísať slová s nenájdeným významom, zotriedené podľa počtu výskytu",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        vypíše všetky značky, zotriedené podľa počtu výskytu (pre unigram-xx.txt)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        nájsť pravidlá pre určenie významu slov pomocou Brillovho algoritmu",

    "[_1]: problem reading the database\n"
 => "[_1]: problém pri čítaní z databázy\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: `[_2]' poškodené na [_3]\n",

    "conversion from [_1] is not supported"
 => "konverzia z [_1] nie je podporovaná",

    "[_1]: illegal grammatical code\n"
 => "[_1]: neplatný gramatický kód\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: žiadne gramatické kódy: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "[_1]: neznáme chybové makro: [_2]\n",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Platné slovo, ale extrémne vzácne v bežnom použití",

    "Repeated word"
 => "Opakované slovo",

    "Unusual combination of words"
 => "Nezvyklá kombinácia slov",

    "The plural form is required here"
 => "Je tu potrebné množné číslo",

    "The singular form is required here"
 => "Je tu potrebné jednotné číslo",

    "Plural adjective required"
 => "Je potrebné porovnávacie prídavné meno",

    "Comparative adjective required"
 => "Je potrebné porovnávacie prídavné meno",

    "Definite article required"
 => "Je tu potrebný určitý člen",

    "Unnecessary use of the definite article"
 => "Nepotrebné použitie určitého člena",

    "No need for the first definite article"
 => "Nepotrebné použitie určitého člena",

    "Unnecessary use of the genitive case"
 => "Nepotrebné použitie genitívu",

    "The genitive case is required here"
 => "Je tu potrebný genitív",

    "You should use the present tense here"
 => "Mali by ste tu radšej použiť /[_1]/",

    "You should use the conditional here"
 => "Mali by ste tu radšej použiť /[_1]/",

    "It seems unlikely that you intended to use the subjunctive here"
 => "Tu ste pravdepodobne nechceli použiť subjunktív",

    "Usually used in the set phrase /[_1]/"
 => "Väčšinou použité vo fráze /[_1]/",

    "You should use /[_1]/ here instead"
 => "Mali by ste tu radšej použiť /[_1]/",

    "Non-standard form of /[_1]/"
 => "Neštandardná forma /[_1]/",

    "Derived from a non-standard form of /[_1]/"
 => "Odvodené z neštandardnej formy /[_1]/",

    "Derived incorrectly from the root /[_1]/"
 => "Odvodené nesprávne z koreňa /[_1]/",

    "Unknown word"
 => "Neznáme slovo",

    "Unknown word: /[_1]/?"
 => "Neznáme slovo: /[_1]/?",

    "Valid word but /[_1]/ is more common"
 => "Valid word but /[_1]/ is more common",

    "Not in database but apparently formed from the root /[_1]/"
 => "Nenašlo sa v databáze, ale očividne získané z koreňa /[_1]/",

    "The word /[_1]/ is not needed"
 => "Slovo /[_1]/ nie je potrebné",

    "Do you mean /[_1]/?"
 => "Mysleli ste /[_1]/?",

    "Derived form of common misspelling /[_1]/?"
 => "Odvodená forma bežnej gramatickej chyby /[_1]/?",

    "Not in database but may be a compound /[_1]/?"
 => "Nenašlo sa v databáze, môže ísť o zložené slovo /[_1]/?",

    "Not in database but may be a non-standard compound /[_1]/?"
 => "Nenašlo sa v databáze, môže ísť o neštandardné zložené slovo /[_1]/?",

    "Possibly a foreign word (the sequence /[_1]/ is highly improbable)"
 => "Pravdepodobne cudzie slovo (sekvencia /[_1]/ je veľmi nepravdepodobná)",

    "Gender disagreement"
 => "Gender disagreement",

    "Number disagreement"
 => "Number disagreement",

    "Case disagreement"
 => "Case disagreement",

    "Prefix /h/ missing"
 => "Predpona /h/ chýba",

    "Prefix /t/ missing"
 => "Predpona /t/ chýba",

    "Prefix /d'/ missing"
 => "Predpona /d'/ chýba",

    "Unnecessary prefix /h/"
 => "Nepotrebná predpona /h/",

    "Unnecessary prefix /t/"
 => "Nepotrebná predpona /t/",

    "Unnecessary prefix /d'/"
 => "Nepotrebná predpona /d'/",

    "Unnecessary prefix /b'/"
 => "Nepotrebná predpona /d'/",

    "Unnecessary initial mutation"
 => "Nepotrebná počiatočná mutácia",

    "Initial mutation missing"
 => "Počiatočná mutácia chýba",

    "Unnecessary lenition"
 => "Nepotrebná lenícia",

    "The second lenition is unnecessary"
 => "The second lenition is unnecessary",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Predložka /[_1]/ často spôsobuje leníciu, ale tento prípad je nejasný",

    "Lenition missing"
 => "Chýba eklipsa",

    "Unnecessary eclipsis"
 => "Nepotrebná eklipsia",

    "Eclipsis missing"
 => "Chýba eklipsa",

    "The dative is used only in special phrases"
 => "Datív sa používa len v špeciálnych frázach",

    "The dependent form of the verb is required here"
 => "Je tu potrebná závislý tvar slovesa",

    "Unnecessary use of the dependent form of the verb"
 => "Nepotrebné použitie závislého tvaru slovesa",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "Tu sa často používa umelý (kombinovaný) tvar, končiaci na /[_1]/",

    "Second (soft) mutation missing"
 => "Druhá (mäkká) mutácia chýba",

    "Third (breathed) mutation missing"
 => "Tretia (dychová) mutácia chýba",

    "Fourth (hard) mutation missing"
 => "Štvrtá (tvrdá) mutácia chýba",

    "Fifth (mixed) mutation missing"
 => "Piata (zmiešaná) mutácia chýba",

    "Fifth (mixed) mutation after 'th missing"
 => "Chýba piata (zmiešaná) mutácia po 'th",

    "Aspirate mutation missing"
 => "Počiatočná mutácia chýba",

    "This word violates the rules of Igbo vowel harmony"
 => "This word violates the rules of Igbo vowel harmony",

    "Valid word but more often found in place of /[_1]/"
 => "Platné slovo, ale častejšie nájdené namiesto /[_1]/",

);
1;
