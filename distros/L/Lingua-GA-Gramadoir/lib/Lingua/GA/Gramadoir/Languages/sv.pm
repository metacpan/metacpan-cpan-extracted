package Lingua::GA::Gramadoir::Languages::sv;
# Copyright (C) 2005 Kevin P. Scannell
# This file is distributed under the same license as the gramadoir package.
# Daniel Nylander <po@danielnylander.se>, 2005
#
#msgid ""
#msgstr ""
#"Project-Id-Version: gramadoir 0.6\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-09-05 17:20-0500\n"
#"PO-Revision-Date: 2006-01-11 21:38+0100\n"
#"Last-Translator: Daniel Nylander <po@danielnylander.se>\n"
#"Language-Team: Swedish <tp-sv@listor.tp-sv.se>\n"
#"MIME-Version: 1.0\n"
#"Content-Type: text/plain; charset=utf-8\n"
#"Content-Transfer-Encoding: 8bit\n"

use strict;
use warnings;
use utf8;
use base qw(Lingua::GA::Gramadoir::Languages);
use vars qw(%Lexicon);

%Lexicon = (
    "Line %d: [_1]\n"
 => "Rad %d: [_1]\n",

    "unrecognized option [_1]"
 => "okänd flagga [_1]",

    "option [_1] requires an argument"
 => "flaggan [_1] kräver ett argument",

    "option [_1] does not allow an argument"
 => "flaggan [_1] tillåter inte ett argument",

    "error parsing command-line options"
 => "fel vid tolkning av kommandoradsflaggor",

    "Unable to set output color to [_1]"
 => "Kunde inte sätta färg till [_1] för utdata",

    "Language [_1] is not supported."
 => "Språket [_1] stöds inte.",

    "An Gramadoir"
 => "En Gramadoir",

    "Try [_1] for more information."
 => "Försök med [_1] för mer information.",

    "version [_1]"
 => "version [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Detta är fri programvara; se källkoden för villkor för kopiering.  Det finns INGEN\ngaranti; inte ens för SÄLJBARHET eller LÄMPLIGHET FÖR NÅGOT SPECIELLT ÄNDAMÅL,\ntill den omfattning som tillåts enligt lag.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Användning: [_1] ~[FLAGGOR~] ~[FILER~]",

    "Options for end-users:"
 => "Flaggor för slutanvändare:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan       rapportera alla fel (alltså, använd inte ~/.neamhshuim)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=KOD  ange teckenkodning av texten som ska kontrolleras",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=KOD   ange teckenkodning för utdata",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx välj språk för felmeddelanden",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=FÄRG    ange färgen att använda för att framhäva fel",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       skriv felstavade ord till standard ut",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       föreslå rättningar till felstavningar",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=FIL   skriv utdata till FIL",

    "    --help         display this help and exit"
 => "    --help         visa denna hjälptext och avsluta",

    "    --version      output version information and exit"
 => "    --version      skriv ut versionsinformation och avsluta",

    "Options for developers:"
 => "Flaggor för utvecklare:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          skriv ut ett enkelt XML-format för användning med andra program",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         producera HTML-utdata för visning i en webbläsare",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   slå inte upp tvetydiga delar av talet efter frekvens",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          write tagged XML stream to standard output, for debugging",

    "If no file is given, read from standard input."
 => "Om ingen fil angivits, läs från standard in.",

    "Send bug reports to <[_1]>."
 => "Skicka felrapporter till <[_1]>.",

    "There is no such file."
 => "Det finns ingen sådan fil.",

    "Is a directory"
 => "Är en katalog",

    "Permission denied"
 => "Åtkomst nekad",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: varning: problem vid stängning av [_2]\n",

    "Currently checking [_1]"
 => "Kontrollerar för närvarande [_1]",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     report unresolved ambiguities, sorted by frequency",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        find disambiguation rules via Brill's unsupervised algorithm",

    "[_1]: problem reading the database\n"
 => "[_1]: problem vid läsning av databas\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: \"[_2]\" skadad vid [_3]\n",

    "conversion from [_1] is not supported"
 => "konvertering från [_1] stöds ej",

    "[_1]: illegal grammatical code\n"
 => "[_1]: otillåten grammatisk kod\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: inga grammatiska koder: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "[_1]: okänt felmakro: [_2]\n",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Giltigt ord men mycket ovanlig i aktuell användning",

    "Repeated word"
 => "Upprepat ord",

    "Unusual combination of words"
 => "Ovanlig kombination av ord",

    "The plural form is required here"
 => "Pluralformen krävs här",

    "The singular form is required here"
 => "Singularformen krävs här",

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
 => "Unnecessary use of the genitive case",

    "The genitive case is required here"
 => "The genitive case is required here",

    "You should use the present tense here"
 => "Du bör använda /[_1]/ här istället",

    "You should use the conditional here"
 => "Du bör använda /[_1]/ här istället",

    "It seems unlikely that you intended to use the subjunctive here"
 => "It seems unlikely that you intended to use the subjunctive here",

    "Usually used in the set phrase /[_1]/"
 => "Usually used in the set phrase /[_1]/",

    "You should use /[_1]/ here instead"
 => "Du bör använda /[_1]/ här istället",

    "Non-standard form of /[_1]/"
 => "Icke-standard form av /[_1]/",

    "Derived from a non-standard form of /[_1]/"
 => "Derived from a non-standard form of /[_1]/",

    "Derived incorrectly from the root /[_1]/"
 => "Derived incorrectly from the root /[_1]/",

    "Unknown word"
 => "Okänt ord",

    "Unknown word: /[_1]/?"
 => "Okänt ord: /[_1]/?",

    "Valid word but /[_1]/ is more common"
 => "Valid word but /[_1]/ is more common",

    "Not in database but apparently formed from the root /[_1]/"
 => "Not in database but apparently formed from the root /[_1]/",

    "The word /[_1]/ is not needed"
 => "Ordet /[_1]/ behövs inte",

    "Do you mean /[_1]/?"
 => "Menar du /[_1]/?",

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
 => "Prefix /h/ saknas",

    "Prefix /t/ missing"
 => "Prefix /t/ saknas",

    "Prefix /d'/ missing"
 => "Prefix /d'/ saknas",

    "Unnecessary prefix /h/"
 => "Onödigt prefix /h/",

    "Unnecessary prefix /t/"
 => "Onödigt prefix /t/",

    "Unnecessary prefix /d'/"
 => "Onödigt prefix /d'/",

    "Unnecessary prefix /b'/"
 => "Onödigt prefix /d'/",

    "Unnecessary initial mutation"
 => "Unnecessary initial mutation",

    "Initial mutation missing"
 => "Initial mutation missing",

    "Unnecessary lenition"
 => "Unnecessary lenition",

    "The second lenition is unnecessary"
 => "The second lenition is unnecessary",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Often the preposition /[_1]/ causes lenition, but this case is unclear",

    "Lenition missing"
 => "Lenition missing",

    "Unnecessary eclipsis"
 => "Unnecessary eclipsis",

    "Eclipsis missing"
 => "Eclipsis missing",

    "The dative is used only in special phrases"
 => "The dative is used only in special phrases",

    "The dependent form of the verb is required here"
 => "The dependent form of the verb is required here",

    "Unnecessary use of the dependent form of the verb"
 => "Unnecessary use of the dependent form of the verb",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "The synthetic (combined) form, ending in /[_1]/, is often used here",

    "Second (soft) mutation missing"
 => "Second (soft) mutation missing",

    "Third (breathed) mutation missing"
 => "Third (breathed) mutation missing",

    "Fourth (hard) mutation missing"
 => "Fourth (hard) mutation missing",

    "Fifth (mixed) mutation missing"
 => "Fifth (mixed) mutation missing",

    "Fifth (mixed) mutation after 'th missing"
 => "Fifth (mixed) mutation after 'th missing",

    "Aspirate mutation missing"
 => "Aspirate mutation missing",

    "This word violates the rules of Igbo vowel harmony"
 => "This word violates the rules of Igbo vowel harmony",

);
1;
