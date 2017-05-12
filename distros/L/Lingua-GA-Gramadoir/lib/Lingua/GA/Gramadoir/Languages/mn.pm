package Lingua::GA::Gramadoir::Languages::mn;
# This file is distributed under the same license as the PACKAGE package.
# Copyright (C) 2004 Free Software Foundation, Inc.
# Sanlig Badral <badral@users.sourceforge.net>, 2004.
#
#msgid ""
#msgstr ""
#"Project-Id-Version: gramadoir-0.4\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-09-05 17:20-0500\n"
#"PO-Revision-Date: 2004-01-11 13:26+0100\n"
#"Last-Translator: Sanlig Badral <badral@users.sourceforge.net>\n"
#"Language-Team: Mongolian <openmn-translation@lists.sourceforge.net>\n"
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
 => "Мөр %d: [_1]\n",

    "unrecognized option [_1]"
 => "танигдахгүй сонголт [_1]",

    "option [_1] requires an argument"
 => "[_1] сонголт аргумент шаардаж байна",

    "option [_1] does not allow an argument"
 => "[_1] сонголт аргумент зөвшөөрөхгүй",

    "error parsing command-line options"
 => "error parsing command-line options",

    "Unable to set output color to [_1]"
 => "Unable to set output color to [_1]",

    "Language [_1] is not supported."
 => "[_1] хэл дэмжигдээгүй байна.",

    "An Gramadoir"
 => "Грамадойр",

    "Try [_1] for more information."
 => "Илүү мэдээллийн хувьд [_1] гэж оролд.",

    "version [_1]"
 => "хувилбар [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Энэ бол үнэгүй програм; эх код дах хуулах нөхцөлийн хар.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Хэрэглээ: [_1] ~[СОНГОЛТ~] ~[ФАЙЛ~]",

    "Options for end-users:"
 => "Эцсийн хэрэглэгчдийн сонголт:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan       бүх алдааг мэдээлэх (Ө.х. ~/.neamhshuim гэж хэрэглэхгүй)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=ENC  шалгагдах ёстой текстийн тэмдэгт кодчилолыг тодорхойлох",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=ENC   specify the character encoding for output",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx choose the language for error messages",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=COLOR   specify the color to use for highlighting errors",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       стандарт гаралт руу алдаатай үгсийг бичих",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       зөв бичгийн алдаа засалт санал болгох",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=FILE  write output to FILE",

    "    --help         display this help and exit"
 => "    --help         энэ тусламжийг үзүүлээд гарна",

    "    --version      output version information and exit"
 => "    --version      хувилбарын мэдээллийг үзүүлээд гарна",

    "Options for developers:"
 => "Хөгжүүлэгчдийн сонголт:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          output a simple XML format for use with other applications",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         Вэб хөтөчид харуулахад зориулсан HTML -р гаргах",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   хэллэгийн хэлбэлзэлээр ац утгат хэсгийг шийдвэрлэхгүй",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          Тагтай XML урсгал стандарт гаралт руу шинжлэн гаргах",

    "If no file is given, read from standard input."
 => "Хэрэв файл өгөгдөөгүй бол стандарт оролтоос уншина.",

    "Send bug reports to <[_1]>."
 => "<[_1]> рүү согогийн тайлан илгээх.",

    "There is no such file."
 => "Тийм файл алга.",

    "Is a directory"
 => "Энэ бол лавлах",

    "Permission denied"
 => "Хандалт хүчингүй",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: сануулга: [_2] асуудал хаагдав.\n",

    "Currently checking [_1]"
 => "Одоо шалгаж байна [_1]",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     шийдэгдээгүй ац утгыг хэлбэлзэлээр эрэмбэлэн тайлагнах",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        хэлбэлзэлээр эрэмбэлэн бүх тагийг гаргах (unigram-xx.txt -н хувьд)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        ухагдахууны тодорхойлолтын дүрмийг Биллийн шалгалтгүй алгоритмаар олох",

    "[_1]: problem reading the database\n"
 => "[_1]: өгөгдлийн бааз уншиж байхад алдаа\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: `[_2]' [_3]-д эвдэрчээ\n",

    "conversion from [_1] is not supported"
 => "[_1] -с хөрвүүлэх дэмжигдээгүй",

    "[_1]: illegal grammatical code\n"
 => "[_1]: хүчингүй дүрэмтэй код\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: дүрмийн код алга: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "танигдахгүй сонголт [_1]",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Хүчинтэй үг гэхдээ идэвхитэй хэрэглээнд туйлын ховор",

    "Repeated word"
 => "Давтагдсан үг",

    "Unusual combination of words"
 => "Сонин үгийн хослол байна даа",

    "The plural form is required here"
 => "Харъяалахын тийн ялгал энд шаардлагатай",

    "The singular form is required here"
 => "Харъяалахын тийн ялгал энд шаардлагатай",

    "Plural adjective required"
 => "тэмдэг нэрийн харьцуулал шаардлагатай",

    "Comparative adjective required"
 => "тэмдэг нэрийн харьцуулал шаардлагатай",

    "Definite article required"
 => "Definite article required",

    "Unnecessary use of the definite article"
 => "Хүйс тодорхойлох шаардлагагүй хэрэглээ",

    "No need for the first definite article"
 => "Хүйс тодорхойлох шаардлагагүй хэрэглээ",

    "Unnecessary use of the genitive case"
 => "Хүйс тодорхойлох шаардлагагүй хэрэглээ",

    "The genitive case is required here"
 => "Харъяалахын тийн ялгал энд шаардлагатай",

    "You should use the present tense here"
 => "Та оронд нь /[_1]/ гэж хэрэглэх ёстой",

    "You should use the conditional here"
 => "Та оронд нь /[_1]/ гэж хэрэглэх ёстой",

    "It seems unlikely that you intended to use the subjunctive here"
 => "It seems unlikely that you intended to use the subjunctive here",

    "Usually used in the set phrase /[_1]/"
 => " /[_1]/ хэллэгийн олонлогт үргэлж хэрэглэгддэг",

    "You should use /[_1]/ here instead"
 => "Та оронд нь /[_1]/ гэж хэрэглэх ёстой",

    "Non-standard form of /[_1]/"
 => "Стандарт бус хэлбэр: магад /[_1]/ байх?",

    "Derived from a non-standard form of /[_1]/"
 => "Derived from a non-standard form of /[_1]/",

    "Derived incorrectly from the root /[_1]/"
 => "Derived incorrectly from the root /[_1]/",

    "Unknown word"
 => "Мэдэгдэхүй үг",

    "Unknown word: /[_1]/?"
 => "Мэдэгдэхүй үг",

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
 => "Угтвар /h/ дутуу",

    "Prefix /t/ missing"
 => "Угтвар /t/ дутуу",

    "Prefix /d'/ missing"
 => "Угтвар /h/ дутуу",

    "Unnecessary prefix /h/"
 => "Угтвар шаардлагагүй /h/",

    "Unnecessary prefix /t/"
 => "Угтвар шаардлагагүй /t/",

    "Unnecessary prefix /d'/"
 => "Угтвар шаардлагагүй /h/",

    "Unnecessary prefix /b'/"
 => "Угтвар шаардлагагүй /h/",

    "Unnecessary initial mutation"
 => "шаардлагагүй зөөлрүүлэлт",

    "Initial mutation missing"
 => "Анхдагч өөрчлөлт дутуу",

    "Unnecessary lenition"
 => "шаардлагагүй зөөлрүүлэлт",

    "The second lenition is unnecessary"
 => "The second lenition is unnecessary",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Often the preposition /[_1]/ causes lenition, but this case is unclear",

    "Lenition missing"
 => "Зөөлрүүлэлт дутуу",

    "Unnecessary eclipsis"
 => "шаардлагагүй зөөлрүүлэлт",

    "Eclipsis missing"
 => "Eclipsis дутуу",

    "The dative is used only in special phrases"
 => "The dative is used only in special phrases",

    "The dependent form of the verb is required here"
 => "Харъяалахын тийн ялгал энд шаардлагатай",

    "Unnecessary use of the dependent form of the verb"
 => "Хүйс тодорхойлох шаардлагагүй хэрэглээ",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "The synthetic (combined) form, ending in /[_1]/, is often used here",

    "Second (soft) mutation missing"
 => "Анхдагч өөрчлөлт дутуу",

    "Third (breathed) mutation missing"
 => "Анхдагч өөрчлөлт дутуу",

    "Fourth (hard) mutation missing"
 => "Анхдагч өөрчлөлт дутуу",

    "Fifth (mixed) mutation missing"
 => "Анхдагч өөрчлөлт дутуу",

    "Fifth (mixed) mutation after 'th missing"
 => "Анхдагч өөрчлөлт дутуу",

    "Aspirate mutation missing"
 => "Анхдагч өөрчлөлт дутуу",

    "This word violates the rules of Igbo vowel harmony"
 => "This word violates the rules of Igbo vowel harmony",

    "#~ \"    --aspell       suggest corrections for misspellings (requires GNU \"#~ \"aspell)\""
 => "#~ \"    --aspell       зөв бичгийн алдаа засалт санал болгох (ГНУ aspell \"#~ \"шаардлагатай)\"",

    "#~ \"    --teanga=XX    specify the language of the text to be checked \"#~ \"(default=ga)\""
 => "#~ \"    --teanga=XX    шалгагдах текстийн хэлийг сонгоно (стандартаар=ga)\"",

    "aspell-[_1] is not installed"
 => "aspell-[_1] суулгагдаагүй байна",

    "Unknown word (ignoring remainder in this sentence)"
 => "Мэдэгдэхгүй үг (энэ өгүүлбэрийн үлдэгдлийг үл хэрэгсэх)",

    "[_1]: out of memory\n"
 => "[_1]: санах ойгоос халилаа\n",

    "[_1]: warning: check size of [_2]: %d?\n"
 => "[_1]: сануулга: [_2]-н хэмжээг шалгах: %d?\n",

    "problem with the `cuardach' command\n"
 => "`cuardach' тушаалд асуудал гарав\n",

);
1;
