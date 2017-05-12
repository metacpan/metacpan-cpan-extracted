package Lingua::GA::Gramadoir::Languages::ga;
# Irish translations for gramadoir.
# Copyright (C) 2003 Free Software Foundation, Inc.
# This file is distributed under the same license as the gramadoir package.
# Kevin Patrick Scannell <scannell@SLU.EDU>, 2003, 2004, 2005.
#
#msgid ""
#msgstr ""
#"Project-Id-Version: gramadoir 0.7\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-09-05 17:20-0500\n"
#"PO-Revision-Date: 2008-08-17 12:08-0500\n"
#"Last-Translator: Kevin Scannell <kscanne@gmail.com>\n"
#"Language-Team: Irish <gaeilge-gnulinux@lists.sourceforge.net>\n"
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
 => "Líne %d: [_1]\n",

    "unrecognized option [_1]"
 => "rogha anaithnid [_1]",

    "option [_1] requires an argument"
 => "tá argóint de dhíth i ndiaidh na rogha [_1]",

    "option [_1] does not allow an argument"
 => "ní cheadaítear argóint i ndiaidh na rogha [_1]",

    "error parsing command-line options"
 => "earráid agus roghanna líne na n-orduithe á miondealú",

    "Unable to set output color to [_1]"
 => "Níorbh fhéidir dath an aschuir a shocrú mar [_1]",

    "Language [_1] is not supported."
 => "Níl an teanga [_1] ar fáil.",

    "An Gramadoir"
 => "An Gramadóir",

    "Try [_1] for more information."
 => "Bain triail as [_1] chun tuilleadh eolais a fháil.",

    "version [_1]"
 => "leagan [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Is saorbhogearra an ríomhchlár seo; féach ar an bhunchód le haghaidh\ncoinníollacha cóipeála.  Níl baránta AR BITH ann; go fiú níl baránta ann\nd'INDÍOLTACHT nó FEILIÚNACHT DO FHEIDHM AR LEITH, an oiread atá ceadaithe\nde réir dlí.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Úsáid: [_1] ~[ROGHANNA~] ~[COMHAD~]",

    "Options for end-users:"
 => "Roghanna d'úsáideoirí:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan       taispeáin gach earráid (.i. ná húsáid ~/.neamhshuim)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=CÓD  socraigh an t-ionchódú den téacs le seiceáil",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=CÓD   socraigh an t-ionchódú le haschur",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx socraigh an teanga de na teachtaireachtaí",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=DATH    aibhsigh earráidí sa DATH seo",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       scríobh focail mhílitrithe chuig an aschur caighdeánach",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       mol ceartúcháin d'fhocail mílitrithe",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=COMHAD scríobh aschur chuig COMHAD",

    "    --help         display this help and exit"
 => "    --help         taispeáin an chabhair seo agus scoir",

    "    --version      output version information and exit"
 => "    --version      taispeáin eolas faoin leagan agus scoir",

    "Options for developers:"
 => "Roghanna d'fhorbróirí:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          scríobh i bhformáid XML mar chomhéadan le feidhmchláir eile",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         aschur i gcruth HTML chun féachaint le brabhsálaí",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   ná réitigh ranna cainte ilchiallacha de réir minicíochta",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          scríobh sruth XML chuig aschur caighdeánach, chun dífhabhtú",

    "If no file is given, read from standard input."
 => "Mura bhfuil comhad ann, léigh ón ionchur caighdeánach.",

    "Send bug reports to <[_1]>."
 => "Seol tuairiscí fabhtanna chuig <[_1]>.",

    "There is no such file."
 => "Níl a leithéid de chomhad ann",

    "Is a directory"
 => "Is comhadlann é",

    "Permission denied"
 => "Cead diúltaithe",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: rabhadh: fadhb ag dúnadh [_2]\n",

    "Currently checking [_1]"
 => "[_1] á sheiceáil",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     taispeáin focail ilchiallacha, de réir minicíochta",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        taispeáin gach clib de réir minicíochta (do unigram-xx.txt)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        gin rialacha aonchiallacha le halgartam féinlathach de Brill",

    "[_1]: problem reading the database\n"
 => "[_1]: fadhb ag léamh an bhunachair sonraí\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: `[_2]' truaillithe ag [_3]\n",

    "conversion from [_1] is not supported"
 => "níl aon fháil ar thiontú ón ionchódú [_1]",

    "[_1]: illegal grammatical code\n"
 => "[_1]: cód gramadach neamhcheadaithe\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: níl aon chód gramadaí ann: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "[_1]: macra anaithnid earráide: [_2]\n",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Focal ceart ach an-neamhchoitianta - an é atá uait anseo?",

    "Repeated word"
 => "An focal céanna faoi dhó",

    "Unusual combination of words"
 => "Cor cainte aisteach",

    "The plural form is required here"
 => "Tá gá leis an leagan iolra anseo",

    "The singular form is required here"
 => "Tá gá leis an leagan uatha anseo",

    "Plural adjective required"
 => "Ba chóir duit aidiacht iolra a úsáid anseo",

    "Comparative adjective required"
 => "Ba chóir duit an bhreischéim a úsáid anseo",

    "Definite article required"
 => "Ba chóir duit an t-alt cinnte a úsáid",

    "Unnecessary use of the definite article"
 => "Níl gá leis an alt cinnte anseo",

    "No need for the first definite article"
 => "Níl gá leis an gcéad alt cinnte anseo",

    "Unnecessary use of the genitive case"
 => "Níl gá leis an leagan ginideach anseo",

    "The genitive case is required here"
 => "Tá gá leis an leagan ginideach anseo",

    "You should use the present tense here"
 => "Ba chóir duit an aimsir láithreach a úsáid anseo",

    "You should use the conditional here"
 => "Ba chóir duit an modh coinníollach a úsáid anseo",

    "It seems unlikely that you intended to use the subjunctive here"
 => "Ní dócha go raibh intinn agat an modh foshuiteach a úsáid anseo",

    "Usually used in the set phrase /[_1]/"
 => "Ní úsáidtear an focal seo ach san abairtín ‘[_1]’ de ghnáth",

    "You should use /[_1]/ here instead"
 => "Ba chóir duit ‘[_1]’ a úsáid anseo",

    "Non-standard form of /[_1]/"
 => "Foirm neamhchaighdeánach de ‘[_1]’",

    "Derived from a non-standard form of /[_1]/"
 => "Bunaithe ar fhoirm neamhchaighdeánach de ‘[_1]’",

    "Derived incorrectly from the root /[_1]/"
 => "Bunaithe go mícheart ar an bhfréamh ‘[_1]’",

    "Unknown word"
 => "Focal anaithnid",

    "Unknown word: /[_1]/?"
 => "Focal anaithnid: ‘[_1]’?",

    "Valid word but /[_1]/ is more common"
 => "Focal ceart ach tá ‘[_1]’ níos coitianta",

    "Not in database but apparently formed from the root /[_1]/"
 => "Focal anaithnid ach bunaithe ar ‘[_1]’ is dócha",

    "The word /[_1]/ is not needed"
 => "Níl gá leis an fhocal ‘[_1]’",

    "Do you mean /[_1]/?"
 => "An raibh ‘[_1]’ ar intinn agat?",

    "Derived form of common misspelling /[_1]/?"
 => "Bunaithe ar fhocal mílitrithe go coitianta ‘[_1]’?",

    "Not in database but may be a compound /[_1]/?"
 => "Focal anaithnid ach b'fhéidir gur comhfhocal ‘[_1]’ é?",

    "Not in database but may be a non-standard compound /[_1]/?"
 => "Focal anaithnid ach b'fhéidir gur comhfhocal neamhchaighdeánach ‘[_1]’ é?",

    "Possibly a foreign word (the sequence /[_1]/ is highly improbable)"
 => "B'fhéidir gur focal iasachta é seo (tá na litreacha ‘[_1]’ neamhchoitianta)",

    "Gender disagreement"
 => "Inscne mhícheart",

    "Number disagreement"
 => "Uimhir mhícheart",

    "Case disagreement"
 => "Tuiseal mícheart",

    "Prefix /h/ missing"
 => "Réamhlitir ‘h’ ar iarraidh",

    "Prefix /t/ missing"
 => "Réamhlitir ‘t’ ar iarraidh",

    "Prefix /d'/ missing"
 => "Réamhlitir ‘d'’ ar iarraidh",

    "Unnecessary prefix /h/"
 => "Réamhlitir ‘h’ gan ghá",

    "Unnecessary prefix /t/"
 => "Réamhlitir ‘t’ gan ghá",

    "Unnecessary prefix /d'/"
 => "Réamhlitir ‘d'’ gan ghá",

    "Unnecessary prefix /b'/"
 => "Réamhlitir ‘b'’ gan ghá",

    "Unnecessary initial mutation"
 => "Urú nó séimhiú gan ghá",

    "Initial mutation missing"
 => "Urú nó séimhiú ar iarraidh",

    "Unnecessary lenition"
 => "Séimhiú gan ghá",

    "The second lenition is unnecessary"
 => "Ní gá leis an dara séimhiú",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Leanann séimhiú an réamhfhocal ‘[_1]’ go minic, ach ní léir é sa chás seo",

    "Lenition missing"
 => "Séimhiú ar iarraidh",

    "Unnecessary eclipsis"
 => "Urú gan ghá",

    "Eclipsis missing"
 => "Urú ar iarraidh",

    "The dative is used only in special phrases"
 => "Ní úsáidtear an tabharthach ach in abairtí speisialta",

    "The dependent form of the verb is required here"
 => "Tá gá leis an fhoirm spleách anseo",

    "Unnecessary use of the dependent form of the verb"
 => "Níl gá leis an fhoirm spleách",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "Is an fhoirm tháite, leis an iarmhír ‘[_1]’, a úsáidtear go minic",

    "Second (soft) mutation missing"
 => "An dara claochlú (bog) ar iarraidh",

    "Third (breathed) mutation missing"
 => "An tríú claochlú (análach) ar iarraidh",

    "Fourth (hard) mutation missing"
 => "An ceathrú claochlú (crua) ar iarraidh",

    "Fifth (mixed) mutation missing"
 => "An cúigiú claochlú (measctha) ar iarraidh",

    "Fifth (mixed) mutation after 'th missing"
 => "An cúigiú claochlú (measctha) i ndiaidh ‘'th’ ar iarraidh",

    "Aspirate mutation missing"
 => "Claochlú análaithe ar iarraidh",

    "This word violates the rules of Igbo vowel harmony"
 => "Tagann an focal seo salach ar chomhréir na ngutaí in Íogbóis",

    "Valid word but more often found in place of /[_1]/"
 => "Focal ceart ach aimsítear é níos minice in ionad ‘[_1]’",

    "#~ \"    --aspell       suggest corrections for misspellings (requires GNU \"#~ \"aspell)\""
 => "#~ \"    --aspell       mol ceartúcháin d'fhocail mílitrithe (is gá le GNU \"#~ \"aspell)\"",

    "#~ \"    --teanga=XX    specify the language of the text to be checked \"#~ \"(default=ga)\""
 => "#~ \"    --teanga=XX    socraigh an teanga den téacs le seiceáil (loicthe=ga)\"",

    "aspell-[_1] is not installed"
 => "Níl aspell-[_1] ar fáil",

    "Unknown word (ignoring remainder in this sentence)"
 => "Focal anaithnid (scaoilfear an chuid eile san abairt seo)",

    "[_1]: out of memory\n"
 => "[_1]: cuimhne ídithe\n",

    "[_1]: warning: check size of [_2]: %d?\n"
 => "[_1]: rabhadh: deimhnigh méid de [_2]: %d?\n",

    "problem with the `cuardach' command\n"
 => "fadhb leis an ordú 'cuardach'\n",

);
1;
