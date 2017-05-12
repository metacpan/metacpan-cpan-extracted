package Lingua::GA::Gramadoir::Languages::da;
# Danish translation gramadoir.
# Copyright (C) 2009 Kevin P. Scannell & Joe Hansen.
# This file is distributed under the same license as the gramadoir package.
# Joe Hansen <joedalton2@yahoo.dk>, 2009.
# Korrekturlæst af Torben Grøn Helligsø, 2009.
#
#msgid ""
#msgstr ""
#"Project-Id-Version: gramadoir-0.7\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-08-17 12:05-0500\n"
#"PO-Revision-Date: 2009-12-08 14:52+0000\n"
#"Last-Translator: Joe Hansen <joedalton2@yahoo.dk>\n"
#"Language-Team: Danish <dansk@dansk-gruppen.dk>\n"
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
 => "Linje %d: [_1]\n",

    "unrecognized option [_1]"
 => "ikke genkendt tilvalg [_1]",

    "option [_1] requires an argument"
 => "tilvalg [_1] kræver et argument",

    "option [_1] does not allow an argument"
 => "tilvalg [_1] tillader ikke et argument",

    "error parsing command-line options"
 => "fejl ved fortolkning af kommandolinjetilvalg",

    "Unable to set output color to [_1]"
 => "Var ikke i stand til at angive farve på uddata til [_1]",

    "Language [_1] is not supported."
 => "Sprog [_1] er ikke understøttet.",

    "An Gramadoir"
 => "An Gramadóir",

    "Try [_1] for more information."
 => "Prøv [_1] for yderligere information.",

    "version [_1]"
 => "version [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Dette er fri software; se kilden for kopieringsbetingelser.  Der er INGEN\ngaranti; end ikke for SALGBARHED eller EGNETHED TIL ET SPECIFIKT FORMÅL,\nsom indholdt i lovgivningen.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Brug: [_1] ~[TILVALG~] ~[FILER~]",

    "Options for end-users:"
 => "Tilvalg for slutbrugere:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan       rapporter alle fejl (det vil sige brug ikke ~/.neamhshuim)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=ENC  angiv tegnkodningen på teksten der skal undersøges",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=ENC   angiv tegnkodningen på uddata",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx vælg sproget til fejlbeskeder",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=COLOR   angiv farven til brug for fremhævning af fejl",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       skriv stavefejl til standarduddata",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       foreslå rettelser til stavefejl",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=FIL  skriv uddata til FIL",

    "    --help         display this help and exit"
 => "    --help         vis denne hjælp og afslut",

    "    --version      output version information and exit"
 => "    --version      udskriv versioninformation og afslut",

    "Options for developers:"
 => "Tilvalg for udviklere:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          udskriv et simpelt XML-format til brug for andre programmer",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         producer HTML-uddata til visning i en internetbrowser",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   løs ikke tvetydige dele af tale ved hjælp af frekvens",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          skriv opmærket XML-strømme til standarduddata; til fejlsøgning",

    "If no file is given, read from standard input."
 => "Læs fra standardinddata hvis ingen fil er angivet",

    "Send bug reports to <[_1]>."
 => "Send fejlrapporter til <[_1]>.",

    "There is no such file."
 => "Der er ingen sådan fil.",

    "Is a directory"
 => "Er en mappe",

    "Permission denied"
 => "Tilladelse nægtet",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: advarsel: problem med at lukke [_2]\n",

    "Currently checking [_1]"
 => "Undersøger nu [_1]",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     rapporter uløste tvetydninger, sorteret efter frekvens",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        udskriv alle mærker, sorteret efter frekvens (for unigram-xx.txt)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        find tvetydige regler via Brills uovervågede algoritme",

    "[_1]: problem reading the database\n"
 => "[_1]: problem med læsning af databasen\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: `[_2]' korrumperet ved [_3]\n",

    "conversion from [_1] is not supported"
 => "konversion fra [_1] er ikke understøttet",

    "[_1]: illegal grammatical code\n"
 => "[_1]: ugyldig grammatisk kode\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: ingen grammatiske koder: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "[_1]: ukendt fejlmakro: [_2]\n",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Gyldigt ord men meget sjældent i daglig brug. Er du sikker på, at det er ordet, du vil bruge?",

    "Repeated word"
 => "Gentaget ord",

    "Unusual combination of words"
 => "Usædvanlig kombination af ord",

    "The plural form is required here"
 => "Flertalsform er krævet her",

    "The singular form is required here"
 => "Entalsform er krævet her",

    "Plural adjective required"
 => "Tillægsord bøjet i flertal krævet",

    "Comparative adjective required"
 => "Tillægsord bøjet i højere grad krævet",

    "Definite article required"
 => "Bestemt form krævet",

    "Unnecessary use of the definite article"
 => "Unødvendig brug af bestemt form",

    "No need for the first definite article"
 => "Intet behov for den første bestemte artikel",

    "Unnecessary use of the genitive case"
 => "Unødvendig brug af ejefald",

    "The genitive case is required here"
 => "Ejefaldsform er krævet her",

    "You should use the present tense here"
 => "Du bør bruge nutidsformen her",

    "It seems unlikely that you intended to use the subjunctive here"
 => "Det virker usandsynligt, at du forsøgte at bruge konjunktiv her",

    "Usually used in the set phrase /[_1]/"
 => "Normalt brugt i angivelsesfrasen ‘[_1]’",

    "You should use /[_1]/ here instead"
 => "Du bør her bruge ‘[_1]’ i steden for",

    "Non-standard form of /[_1]/"
 => "En form af ‘[_1]’ der ikke er standard",

    "Derived from a non-standard form of /[_1]/"
 => "Afledt af en form af ‘[_1]’ der ikke er standard",

    "Derived incorrectly from the root /[_1]/"
 => "Forkert afledning af roden ‘[_1]’",

    "Unknown word"
 => "Ukendt ord",

    "Unknown word: /[_1]/?"
 => "Ukendt ord: ‘[_1]’?",

    "Valid word but /[_1]/ is more common"
 => "Gyldigt ord men ‘[_1]’ er mere udbredt",

    "Not in database but apparently formed from the root /[_1]/"
 => "Ikke i databasen men tilsyneladende dannet fra roden ‘[_1]’",

    "The word /[_1]/ is not needed"
 => "Der er ikke behov for ordet ‘[_1]’",

    "Do you mean /[_1]/?"
 => "Mener du ‘[_1]’?",

    "Derived form of common misspelling /[_1]/?"
 => "Afledt form af udbredt stavefejl ‘[_1]’?",

    "Not in database but may be a compound /[_1]/?"
 => "Ikke i databasen, men er måske en kombination af ‘[_1]’?",

    "Not in database but may be a non-standard compound /[_1]/?"
 => "Ikke i databasen, men måske er ‘[_1]’ en sammensætning der ikke er standard?",

    "Possibly a foreign word (the sequence /[_1]/ is highly improbable)"
 => "Muligvis et fremmedord (sekvensen ‘[_1]’ er meget usandsynlig)",

    "Gender disagreement"
 => "Forskel på køn",

    "Number disagreement"
 => "Forskel på antal",

    "Case disagreement"
 => "Forskel på store/små bogstaver",

    "Prefix /h/ missing"
 => "Præfikset ‘h’ mangler",

    "Prefix /t/ missing"
 => "Præfikset ‘t’ mangler",

    "Prefix /d'/ missing"
 => "Præfikset ‘d'’ mangler",

    "Unnecessary prefix /h/"
 => "Unødvendigt præfiks ‘h’",

    "Unnecessary prefix /t/"
 => "Unødvendigt præfiks ‘t’",

    "Unnecessary prefix /d'/"
 => "Unødvendigt præfiks ‘d'’",

    "Unnecessary prefix /b'/"
 => "Unødvendigt præfiks ‘b'’",

    "Unnecessary initial mutation"
 => "Unødvendig indledende mutation",

    "Initial mutation missing"
 => "Indledende mutation mangler",

    "Unnecessary lenition"
 => "Unødvendig lenition",

    "The second lenition is unnecessary"
 => "Anden lenition er unødvendig",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Ofte medfører forholdsordet ‘[_1]’ lenition, men dette tilfælde er uklart",

    "Lenition missing"
 => "Manglende lenition",

    "Unnecessary eclipsis"
 => "Unødvendig eklipse",

    "Eclipsis missing"
 => "Manglende eklipse",

    "The dative is used only in special phrases"
 => "Dativ bruges kun i særlige fraser",

    "The dependent form of the verb is required here"
 => "Den afhængige form af udsagnsordet er krævet her",

    "Unnecessary use of the dependent form of the verb"
 => "Unødvendig brug af den afhængige form af udsagnsordet",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "Den syntetiske (kombinerede) form, med endelsen ‘[_1]’ bruges ofte her",

    "Second (soft) mutation missing"
 => "Anden (blød) mutation mangler",

    "Third (breathed) mutation missing"
 => "Tredje (Aspireret) mutation mangler",

    "Fourth (hard) mutation missing"
 => "Fjerde (hård) mutation mangler",

    "Fifth (mixed) mutation missing"
 => "Femte (blandet) mutation mangler",

    "Fifth (mixed) mutation after 'th missing"
 => "Femte (blandet) mutation efter 'th mangler",

    "Aspirate mutation missing"
 => "Aspireret mutation mangler",

    "This word violates the rules of Igbo vowel harmony"
 => "Dette ord overtræder reglerne for vokalharmoni i igbo",

);
1;
