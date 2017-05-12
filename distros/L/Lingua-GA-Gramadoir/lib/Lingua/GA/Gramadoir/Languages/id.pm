package Lingua::GA::Gramadoir::Languages::id;
# Indonesian translations for gramadoir package.
# Copyright (C) 2008 Kevin P. Scannell
# This file is distributed under the same license as the gramadoir package.
# Andhika Padmawan <andhika.padmawan@gmail.com>, 2008.
#
#msgid ""
#msgstr ""
#"Project-Id-Version: gramadoir 0.7\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-09-05 17:20-0500\n"
#"PO-Revision-Date: 2008-08-18 13:35+0700\n"
#"Last-Translator: Andhika Padmawan <andhika.padmawan@gmail.com>\n"
#"Language-Team: Indonesian <translation-team-id@lists.sourceforge.net>\n"
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
 => "Baris %d: [_1]\n",

    "unrecognized option [_1]"
 => "opsi tak dikenal [_1]",

    "option [_1] requires an argument"
 => "opsi [_1] memerlukan adanya argumen",

    "option [_1] does not allow an argument"
 => "opsi [_1] tidak mengizinkan adanya argumen",

    "error parsing command-line options"
 => "galat mengurai opsi baris perintah",

    "Unable to set output color to [_1]"
 => "Tak dapat mengatur warna keluaran ke [_1]",

    "Language [_1] is not supported."
 => "Bahasa [_1] tidak didukung.",

    "An Gramadoir"
 => "An Gramadoir",

    "Try [_1] for more information."
 => "Coba [_1] untuk informasi lebih lanjut.",

    "version [_1]"
 => "versi [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Ini adalah perangkat lunak bebas; lihat sumber untuk kondisi penyalinan. TIDAK ada \ngaransi; tidak juga untuk PENJUALAN atau PENGGUNAAN UNTUK TUJUAN KHUSUS,\nsampai batas yang diizinkan oleh hukum.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Penggunaan: [_1] ~[OPSI~] ~[BERKAS~]",

    "Options for end-users:"
 => "Opsi untuk pengguna akhir:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan       laporkan semua galat (misalnya jangan gunakan ~/.neamhshuim)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=SAN  tentukan penyandian karakter dari teks untuk diperiksa",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=SAN   tentukan penyandian karakter untuk keluaran",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx pilih bahasa untuk pesan galat",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=COLOR   tentukan warna yang akan digunakan untuk menyorot galat",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       tulis kata salah eja ke keluaran standar",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       sarankan koreksi untuk salah eja",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=BERKAS  tulis keluaran ke BERKAS",

    "    --help         display this help and exit"
 => "    --help         tampilkan bantuan ini lalu keluar",

    "    --version      output version information and exit"
 => "    --version      keluaran informasi versi lalu keluar",

    "Options for developers:"
 => "Opsi untuk pengembang:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          keluaran dalam format XML sederhana untuk digunakan dengan aplikasi lain",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         menghasilkan keluaran HTML untuk ditampilkan dalam peramban web",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   jangan pisahkan bagian ambigu tuturan oleh frekuensi",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          tulis arus XML ke keluaran standar, untuk awakutu",

    "If no file is given, read from standard input."
 => "Jika tak ada berkas yang diberikan, baca dari masukan standar.",

    "Send bug reports to <[_1]>."
 => "Kirim laporan kutu ke <[_1]>.",

    "There is no such file."
 => "Tidak ada berkas seperti itu.",

    "Is a directory"
 => "Adalah direktori",

    "Permission denied"
 => "Hak akses ditolak",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: peringatan: masalah menutup [_2]\n",

    "Currently checking [_1]"
 => "Saat ini memeriksa [_1]",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     laporkan ambiguitas tak terpecahkan, diurutkan berdasarkan frekuensi",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        keluaran semua tag, diurutkan berdasarkan frekuensi (untuk unigram-xx.txt)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        temukan peraturan disambigu via algoritma tak diawasi Brill",

    "[_1]: problem reading the database\n"
 => "[_1]: masalah pembacaan basis data\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: `[_2]' terkorupsi di [_3]\n",

    "conversion from [_1] is not supported"
 => "konversi dari [_1] tidak didukung",

    "[_1]: illegal grammatical code\n"
 => "[_1]: kode gramatikal ilegal\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: tak ada kode tata bahasa: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "[_1]: makro galat tak dikenali: [_2]\n",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Kata sah tapi sangat jarang dalam penggunaan nyata. Apakah ini kata yang anda inginkan?",

    "Repeated word"
 => "Kata diulang",

    "Unusual combination of words"
 => "Kombinasi kata tak biasa",

    "The plural form is required here"
 => "Bentuk jamak diperlukan di sini",

    "The singular form is required here"
 => "Bentuk singular diperlukan di sini",

    "Plural adjective required"
 => "Adjektiva jamak diperlukan",

    "Comparative adjective required"
 => "Adjektiva komparatif diperlukan",

    "Definite article required"
 => "Artikel tertentu diperlukan",

    "Unnecessary use of the definite article"
 => "Penggunaan tak penting dari artikel tertentu",

    "No need for the first definite article"
 => "Tak perlu untuk artikel tertentu pertama",

    "Unnecessary use of the genitive case"
 => "Penggunaan tak penting dari huruf genitif",

    "The genitive case is required here"
 => "Huruf genitif diperlukan di sini",

    "You should use the present tense here"
 => "Anda harus menggunakan kala saat ini di sini",

    "You should use the conditional here"
 => "Anda harus menggunakan kala saat ini di sini",

    "It seems unlikely that you intended to use the subjunctive here"
 => "Kelihatannya tidak biasanya anda ingin menggunakan subjungtif",

    "Usually used in the set phrase /[_1]/"
 => "Biasanya digunakan di set frase /[_1]/",

    "You should use /[_1]/ here instead"
 => "Anda harus menggunakan /[_1]/ di sini",

    "Non-standard form of /[_1]/"
 => "Bentuk tak standar dari /[_1]/",

    "Derived from a non-standard form of /[_1]/"
 => "Diturunkan dari bentuk tak standar dari /[_1]/",

    "Derived incorrectly from the root /[_1]/"
 => "Diturunkan salah dari akar /[_1]/",

    "Unknown word"
 => "Kata tak dikenal",

    "Unknown word: /[_1]/?"
 => "kata tak dikenal: /[_1]/?",

    "Valid word but /[_1]/ is more common"
 => "Kata sah tapi /[_1]/ lebih umum",

    "Not in database but apparently formed from the root /[_1]/"
 => "Tak ada di basis data tapi tampaknya dibentuk dari akar /[_1]/",

    "The word /[_1]/ is not needed"
 => "kata /[_1]/ tidak diperlukan",

    "Do you mean /[_1]/?"
 => "Maksud anda /[_1]/",

    "Derived form of common misspelling /[_1]/?"
 => "Bentuk turunan dari salah eja umum /[_1]/",

    "Not in database but may be a compound /[_1]/?"
 => "Tak ada di basis data tapi mungkin majemuk /[_1]/?",

    "Not in database but may be a non-standard compound /[_1]/?"
 => "Tak ada di basis data tapi mungkin majemuk tak standar /[_1]/?",

    "Possibly a foreign word (the sequence /[_1]/ is highly improbable)"
 => "Mungkin kata asing (sekuensi /[_1]/ sangat tidak mungkin)",

    "Gender disagreement"
 => "Ketaksepakatan gender",

    "Number disagreement"
 => "Ketaksepakatan nomor",

    "Case disagreement"
 => "Ketaksepakatan huruf",

    "Prefix /h/ missing"
 => "Prefiks /h/ hilang",

    "Prefix /t/ missing"
 => "Prefiks /t/ hilang",

    "Prefix /d'/ missing"
 => "Prefiks /'/ hilang",

    "Unnecessary prefix /h/"
 => "Prefiks tak diperlukan /h/",

    "Unnecessary prefix /t/"
 => "Prefiks tak diperlukan /t/",

    "Unnecessary prefix /d'/"
 => "Prefiks tak diperlukan /d'/",

    "Unnecessary prefix /b'/"
 => "Prefiks tak diperlukan /b'/",

    "Unnecessary initial mutation"
 => "Mutasi awal tak diperlukan",

    "Initial mutation missing"
 => "Mutasi awal hilang",

    "Unnecessary lenition"
 => "Pelenisan tak diperlukan",

    "The second lenition is unnecessary"
 => "Pelenisan kedua tidak perlu",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Seringkali preposisi /[_1]/ menyebabkan pelenisan, tapi huruf ini tidak jelas",

    "Lenition missing"
 => "Pelenisan hilang",

    "Unnecessary eclipsis"
 => "Selang kata tak diperlukan",

    "Eclipsis missing"
 => "Selang kata hilang",

    "The dative is used only in special phrases"
 => "Datif hanya digunakan dalam frasa khusus",

    "The dependent form of the verb is required here"
 => "Bentuk ketergantungan kata kerja diperlukan di sini",

    "Unnecessary use of the dependent form of the verb"
 => "Penggunaan tak diperlukan dari bentuk ketergantungan kata kerja",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "Bentuk sintesis (digabungkan), diakhiri di /[_1]/, biasanya diperlukan di sini.",

    "Second (soft) mutation missing"
 => "Mutasi (halus) kedua hilang",

    "Third (breathed) mutation missing"
 => "Mutasi (takbersuara) ketiga hilang",

    "Fourth (hard) mutation missing"
 => "Mutasi (keras) keempat hilang",

    "Fifth (mixed) mutation missing"
 => "Mutasi (campuran) kelima hilang",

    "Fifth (mixed) mutation after 'th missing"
 => "Mutasi (campuran) kelima setelah 'th hilang",

    "Aspirate mutation missing"
 => "Mutasi aspirasi hilang",

    "This word violates the rules of Igbo vowel harmony"
 => "Kata ini melanggar aturan harmoni vokal Igbo",

    "Valid word but more often found in place of /[_1]/"
 => "Kata sah tapi lebih sering ditemukan di tempat /[_1]/",

);
1;
