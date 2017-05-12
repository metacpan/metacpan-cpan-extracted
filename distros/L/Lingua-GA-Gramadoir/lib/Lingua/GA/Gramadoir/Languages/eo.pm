package Lingua::GA::Gramadoir::Languages::eo;
# Esperanto translations for Gramadoir.
# This file is distributed under the same license as the gramadoir package.
#
# Tim Morley <t_morley@argonet.co.uk>, 2005.
# Benno Schulenberg <benno@vertaalt.nl>, 2008.
# Felipe Castro <fefcas@gmail.com>, 2009.
#msgid ""
#msgstr ""
#"Project-Id-Version: GNU gramadoir 0.7\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-08-17 12:05-0500\n"
#"PO-Revision-Date: 2009-01-20 12:28-0300\n"
#"Last-Translator: Felipe Castro <fefcas@gmail.com>\n"
#"Language-Team: Esperanto <translation-team-eo@lists.sourceforge.net>\n"
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
 => "Linio %d: [_1]\n",

    "unrecognized option [_1]"
 => "agordo [_1] ne rekonita",

    "option [_1] requires an argument"
 => "agordo [_1] bezonas argumenton",

    "option [_1] does not allow an argument"
 => "agordo [_1] ne permesas argumenton",

    "error parsing command-line options"
 => "eraro dum analizado de agordaĵoj de komanda linio",

    "Unable to set output color to [_1]"
 => "Ne eblas agordi eligan koloron kiel [_1]n",

    "Language [_1] is not supported."
 => "La lingvo [_1] ne estas subtenata.",

    "An Gramadoir"
 => "An Gramadóir",

    "Try [_1] for more information."
 => "Provu [_1] por pli da informoj.",

    "version [_1]"
 => "versio [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Tiu programo estas libera; vidu la fontkodon por la kondiĉoj pri kopiado.\nEstas NENIU garantio, eĉ ne pri TAŬGECO POR VENDADO aŭ POR IU SPECIFA UZO,\nĝis la limo de la leĝo.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Uzado: [_1] ~[AGORDAĴOJ~] ~[DOSIEROJ~]",

    "Options for end-users:"
 => "Agordaĵoj por uzuloj:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan        raporti pri ĉiu eraro (t.e. ne uzi ~/.neamhshuim)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=KODO  elekti la kodigon de la teksto kontrolota",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=KODO   elekti la kodigon de la eligo",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx  elekti la lingvon por erarmesaĝoj",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=KOLORO   elekti la KOLORON uzendan por montri erarojn",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu        sendi misliterumitajn vortojn al ĉefeligujo",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell        proponi korektojn por misliterumaĵoj",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=DOSIERO  skribu eligon al DOSIERO",

    "    --help         display this help and exit"
 => "    --help          vidigi helpon kaj eliri",

    "    --version      output version information and exit"
 => "    --version       vidigi version de la programo kaj eliri",

    "Options for developers:"
 => "Agordaĵoj por programistoj:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          eligi simplan XML-an formaton por uzo kun aliaj aplikaĵoj",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html          krei HTML-an eligon por vidigo per TTT-legilo",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram    ne solvi dusencajn gramatikajn kategoriojn per ofteco",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml           skribi etikeditan XML-an fluon al ĉefeligujo, por sencimigo",

    "If no file is given, read from standard input."
 => "Se neniu dosieronomo estas donita, legi el ĉefenigujo",

    "Send bug reports to <[_1]>."
 => "Sendu cimraportojn al <[_1]>.",

    "There is no such file."
 => "Tiu dosiero ne ekzistas.",

    "Is a directory"
 => "Estas dosierujo",

    "Permission denied"
 => "Rajto rifuzita",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: ATENTO: problemo dum fermado de [_2]\n",

    "Currently checking [_1]"
 => "Daŭras kontroladon de [_1]",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     raporti pri nesolvitaj dusencaĵoj, ordigitaj laŭ ofteco",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        eligi ĉiujn etikedojn, ordigitaj laŭ ofteco (por unigram-xx.txt)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        trovi sendusencaĵigajn regulojn per la nesuperrigardata algoritmo de Brill",

    "[_1]: problem reading the database\n"
 => "[_1]: problemo pri legado de datumbazo\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: \"[_2]\" difektita ĉe [_3]\n",

    "conversion from [_1] is not supported"
 => "konverto el [_1] ne estas subtenata",

    "[_1]: illegal grammatical code\n"
 => "[_1]: nepermesata gramatika kodo\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: ne estas gramatikaj kodoj: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "[_1]: nerekonita eraro pri makroo: [_2]\n",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Vorto valida, sed maloftega en reala uzado. Ĉu estas la dezirata vorto?",

    "Repeated word"
 => "Vorto ripetita",

    "Unusual combination of words"
 => "Neofta kunmeto de vortoj",

    "The plural form is required here"
 => "La pluralo estas bezonata ĉi tie",

    "The singular form is required here"
 => "La singularo estas bezonata ĉi tie",

    "Plural adjective required"
 => "Adjektivo plurala estas bezonata",

    "Comparative adjective required"
 => "Adjektivo komparativa estas bezonata",

    "Definite article required"
 => "Difina artikolo bezonatas",

    "Unnecessary use of the definite article"
 => "Sennecesa uzo de la difina artikolo",

    "No need for the first definite article"
 => "Sennecesa uzo de la unua difina artikolo",

    "Unnecessary use of the genitive case"
 => "Sennecesa uzo de la genitivo",

    "The genitive case is required here"
 => "Genitivo bezonatas ĉi tie",

    "You should use the present tense here"
 => "Ĉi tie vi devus uzi nuntempon",

    "It seems unlikely that you intended to use the subjunctive here"
 => "Ŝajnas neprobable ke vi intencis uzi la subjunktivon ĉi tie",

    "Usually used in the set phrase /[_1]/"
 => "Kutime uzata en la fiksita frazo /[_1]/",

    "You should use /[_1]/ here instead"
 => "Ĉi tie vi devus anstataŭe uzi /[_1]/",

    "Non-standard form of /[_1]/"
 => "Nenormala formo de /[_1]/",

    "Derived from a non-standard form of /[_1]/"
 => "Derivita de nenormala formo de /[_1]/",

    "Derived incorrectly from the root /[_1]/"
 => "Neĝuste derivita el la radiko /[_1]/",

    "Unknown word"
 => "Nekonata vorto",

    "Unknown word: /[_1]/?"
 => "Nekonata vorto: /[_1]/?",

    "Valid word but /[_1]/ is more common"
 => "Valida vorto, sed /[_1]/ pli oftas",

    "Not in database but apparently formed from the root /[_1]/"
 => "Ne en la datumbazo sed ŝajne derivita el la radiko /[_1]/",

    "The word /[_1]/ is not needed"
 => "La vorto /[_1]/ ne bezonatas",

    "Do you mean /[_1]/?"
 => "Ĉu vi intencis /[_1]/?",

    "Derived form of common misspelling /[_1]/?"
 => "Derivita formo el ofta misliterumo /[_1]/?",

    "Not in database but may be a compound /[_1]/?"
 => "Ne en la datumbazo sed eble estas kunmetaĵo /[_1]/?",

    "Not in database but may be a non-standard compound /[_1]/?"
 => "Ne en la datumbazo sed eble estas nenormala kunmetaĵo /[_1]/?",

    "Possibly a foreign word (the sequence /[_1]/ is highly improbable)"
 => "Eble estas fremda vorto (la sinsekvo /[_1]/ estas maloftega)",

    "Gender disagreement"
 => "Genroj malsamas",

    "Number disagreement"
 => "Nombroj malsamas",

    "Case disagreement"
 => "Kazoj malsamas",

    "Prefix /h/ missing"
 => "Mankas prefikso /h/",

    "Prefix /t/ missing"
 => "Mankas prefikso /t/",

    "Prefix /d'/ missing"
 => "Mankas prefikso /d'/",

    "Unnecessary prefix /h/"
 => "Nebezonata prefikso /h/",

    "Unnecessary prefix /t/"
 => "Nebezonata prefikso /t/",

    "Unnecessary prefix /d'/"
 => "Nebezonata prefikso /d'/",

    "Unnecessary prefix /b'/"
 => "Nebezonata prefikso /b'/",

    "Unnecessary initial mutation"
 => "Komenca mutatio nenecesas",

    "Initial mutation missing"
 => "Komenca mutacio mankas",

    "Unnecessary lenition"
 => "Nebezonata aspiracio",

    "The second lenition is unnecessary"
 => "La dua aspiracio nenecesas",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Ofte la prepozicio /[_1]/ kaŭzas aspiracion, sed tiu ĉi kazo ne klaras",

    "Lenition missing"
 => "Aspiracio mankas",

    "Unnecessary eclipsis"
 => "Nebezonata eklipsumo",

    "Eclipsis missing"
 => "Eklipsumo mankas",

    "The dative is used only in special phrases"
 => "La dativo uziĝas nur en specialaj frazoj",

    "The dependent form of the verb is required here"
 => "La dependema formo de la verbo bezonatas ĉi tie",

    "Unnecessary use of the dependent form of the verb"
 => "Nebezonata uzo de la dependema formo de la verbo",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "La kunmetita formo, kiu finiĝas per /[_1]/, ofte uziĝas ĉi tie",

    "Second (soft) mutation missing"
 => "Dua (mola) mutacio mankas",

    "Third (breathed) mutation missing"
 => "Tria (spirata) mutacio mankas",

    "Fourth (hard) mutation missing"
 => "Kvara (malmola) mutacio mankas",

    "Fifth (mixed) mutation missing"
 => "Kvina (miksita) mutacio mankas",

    "Fifth (mixed) mutation after 'th missing"
 => "Kvina (miksita) mutacio post 'th mankas",

    "Aspirate mutation missing"
 => "Aspiracia mutacio mankas",

    "This word violates the rules of Igbo vowel harmony"
 => "Tiu ĉi vorto malrespektas la regulojn de la Igba vokal-harmonio",

    "Valid word but more often found in place of /[_1]/"
 => "Valida vorto, sed pli ofte trovita anstataŭ /[_1]/",

);
1;
