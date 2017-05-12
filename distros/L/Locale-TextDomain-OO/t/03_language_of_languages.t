#!perl -T

use strict;
use warnings;

use Test::More tests => 7;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::TextDomain::OO');
    require_ok('Locale::TextDomain::OO::Lexicon::Hash');
}

my $loc = Locale::TextDomain::OO->new(
    languages => [ qw( de-DE de en-US en i-default ) ],
    plugins   => [ qw( Language::LanguageOfLanguages ) ],
    logger    => sub { note shift },
);
is
    $loc->language,
    'i-default',
    'language';
is
    $loc->translate(undef, 'Hello world!'),
    'Hello world!',
    'translate';

Locale::TextDomain::OO::Lexicon::Hash
    ->new(
        logger => sub { note shift },
    )
    ->lexicon_ref({
        'de::' => [
            {
                msgid  => "",
                msgstr => ""
                    . "Project-Id-Version: \n"
                    . "POT-Creation-Date: \n"
                    . "PO-Revision-Date: \n"
                    . "Last-Translator: \n"
                    . "Language-Team: \n"
                    . "MIME-Version: 1.0\n"
                    . "Content-Type: text/plain; charset=ISO-8859-1\n"
                    . "Content-Transfer-Encoding: 8bit\n"
                    . "Plural-Forms: nplurals=2; plural=n != 1;\n",
            },
            {
                msgid  => "Hello world!",
                msgstr => "Hallo Welt!",
            },
        ],
    });

$loc->languages( [ qw( de-DE de en-US en i-default ) ] );
is
    $loc->language,
    'de',
    'language';
is
    $loc->translate(undef, 'Hello world!'),
    'Hallo Welt!',
    'translate';
