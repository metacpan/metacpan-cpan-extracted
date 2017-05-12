#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::TextDomain::OO');
    require_ok('Locale::TextDomain::OO::Lexicon::Hash');
}

Locale::TextDomain::OO::Lexicon::Hash
    ->new(
        logger => sub { note shift },
    )
    ->lexicon_ref({
        'de::cp1252' => [ # data equal to de/LC_MESSAGES/cp1252.po
            {
                msgid  => "",
                msgstr => ""
                    . "Project-Id-Version: \n"
                    . "POT-Creation-Date: \n"
                    . "PO-Revision-Date: \n"
                    . "Last-Translator: \n"
                    . "Language-Team: \n"
                    . "MIME-Version: 1.0\n"
                    . "Content-Type: text/plain; charset=CP1252\n"
                    . "Content-Transfer-Encoding: 8bit\n"
                    . "Plural-Forms: nplurals=2; plural=n != 1;\n",
            },
            {
                # __
                msgid  => "This are German umlauts: ä ö ü ß Ä Ö Ü.",
                msgstr => "Das sind deutsche Umlaute: ä ö ü ß Ä Ö Ü.",
            },
        ],
    });

my $loc = Locale::TextDomain::OO->new(
    language => 'de',
    domain   => 'cp1252',
    plugins  => [ qw( Expand::Gettext ) ],
    logger   => sub { note shift },
);
is
    $loc->__(
        'This are German umlauts: ä ö ü ß Ä Ö Ü.',
    ),
    'Das sind deutsche Umlaute: ä ö ü ß Ä Ö Ü.',
    '__';
