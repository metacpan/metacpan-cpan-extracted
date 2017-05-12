#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 26;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::TextDomain::OO');
    require_ok('Locale::TextDomain::OO::Lexicon::Hash');
}

Locale::TextDomain::OO::Lexicon::Hash
    ->new(
        logger => sub {
            my ($message, $arg_ref ) = @_;
            is
                $message,
                'Lexicon "de:LC_MESSAGES:test" loaded from hash.',
                'message';
            is
                ref $arg_ref->{object},
                'Locale::TextDomain::OO::Lexicon::Hash',
                'logger object';
            is
                $arg_ref->{type},
                'debug',
                'logger type';
            is
                $arg_ref->{event},
                'lexicon,load',
                'logger event';
            return;
        },
    )
    ->lexicon_ref({
        'de:LC_MESSAGES:test' => [ # data equal to de/LC_MESSAGES/test.po
            {
                msgid  => "",
                msgstr => ""
                    . "Project-Id-Version: \n"
                    . "POT-Creation-Date: \n"
                    . "PO-Revision-Date: \n"
                    . "Last-Translator: \n"
                    . "Language-Team: \n"
                    . "MIME-Version: 1.0\n"
                    . "Content-Type: text/plain; charset=UTF-8\n"
                    . "Content-Transfer-Encoding: 8bit\n"
                    . "Plural-Forms: nplurals=2; plural=n != 1;\n",
            },
            {
                #
                msgid  => "This is a text.",
                msgstr => "Das ist ein Text.",
            },
            {
                # umlaut
                msgid  => "§ book",
                msgstr => "§ Buch",
            },
            {
                # x
                msgid  => "{name} is programming {language}.",
                msgstr => "{name} programmiert {language}.",
            },
            {
                # n
                msgid         => "Singular",
                msgid_plural  => "Plural",
                msgstr_plural => [
                    "Einzahl",
                    "Mehrzahl",
                ],
            },
            {
                # nx
                msgid         => "{shelves :num} shelf",
                msgid_plural  => "{shelves :num} shelves",
                msgstr_plural => [
                    "{shelves :num} Regal",
                    "{shelves :num} Regale",
                ],
            },
            {
                # p
                msgctxt => "maskulin",
                msgid   => "Dear",
                msgstr  => "Sehr geehrter",
            },
            {
                # px
                msgctxt => "maskulin",
                msgid   => "Dear {full name}",
                msgstr  => "Sehr geehrter {full name}",
            },
            {
                # np
                msgctxt       => "appointment",
                msgid         => "date",
                msgid_plural  => "dates",
                msgstr_plural => [
                    "Date",
                    "Dates",
                ],
            },
            {
                # npx
                msgctxt       => "appointment",
                msgid         => "This is {dates :num} date.",
                msgid_plural  => "This are {dates :num} dates.",
                msgstr_plural => [
                    "Das ist {dates :num} Date.",
                    "Das sind {dates :num} Dates.",
                ],
            },
        ],
    });

my $loc = Locale::TextDomain::OO->new(
    language => 'de',
    category => 'LC_MESSAGES',
    domain   => 'test',
    plugins  => [ qw( Expand::Gettext::Named ) ],
    logger   => sub {
            my ($message, $arg_ref ) = @_;
            is
                $message,
                'Using lexicon "de:LC_MESSAGES:test". msgstr not found for msgctxt=undef, msgid="not existing text".',
                'message';
            is
                ref $arg_ref->{object},
                'Locale::TextDomain::OO::Translator',
                'logger object';
            is
                $arg_ref->{type},
                'warn',
                'logger type';
            is
                $arg_ref->{event},
                'translation,fallback',
                'logger event';
            return;
    },
);
is
    $loc->locn(
        text => 'not existing text',
    ),
    'not existing text',
    'locn text fallback';
is
    $loc->locn({
        text => 'This is a text.',
    }),
    'Das ist ein Text.',
    'locn text';
is
    $loc->locn(
        text => '§ book',
    ),
    '§ Buch',
    'locn text umlaut';
is
    $loc->locn(
        text    => '{name} is programming {language}.',
        replace => {
            name     => 'Steffen',
            language => 'Perl',
        },
    ),
    'Steffen programmiert Perl.',
    'locn text with placeholders';
is
    $loc->locn(
        text    => '{name} is programming {language}.',
        replace => {
            name => 'Steffen',
        },
    ),
    'Steffen programmiert {language}.',
    'locn text and missing palaceholder';
is
    $loc->locn(
        plural => {
            singular => 'Singular',
            plural   => 'Plural',
            count    => 1,
        },
    ),
    'Einzahl',
    'locn plural 1';
is
    $loc->locn(
        plural => {
            singular => 'Singular',
            plural   => 'Plural',
            count    => 2,
        },
    ),
    'Mehrzahl',
    'locn plural 2';
is
    $loc->locn(
        plural => {
            singular => '{shelves :num} shelf',
            plural   => '{shelves :num} shelves',
            count    => 1,
        },
        replace => {
            shelves => 1,
        },
    ),
    '1 Regal',
    'locn plural 1 with placeholders';
is
    $loc->locn(
        plural => {
            singular => '{shelves :num} shelf',
            plural   => '{shelves :num} shelves',
            count    => 2,
        },
        replace => {
            shelves => 2,
        },
    ),
    '2 Regale',
    'locn plural 2 with placeholders';
is
    $loc->locn(
        context => 'maskulin',
        text    => 'Dear',
    ),
    'Sehr geehrter',
    'locn context';
is
    $loc->locn(
        context => 'maskulin',
        text    => 'Dear {full name}',
        replace => {
            'full name' => 'Steffen Winkler',
        },
    ),
    'Sehr geehrter Steffen Winkler',
    'locn context with placeholders';
is
    $loc->locn(
        context => 'appointment',
        plural  => {
            singular => 'date',
            plural   => 'dates',
            count    => 1,
        },
    ),
    'Date',
    'locn context plural 1';
is
    $loc->locn(
        context => 'appointment',
        plural  => {
            singular => 'date',
            plural   => 'dates',
            count    => 2,
        },
    ),
    'Dates',
    'locn context plural 2';
is
    $loc->locn(
        context => 'appointment',
        plural  => {
            singular => 'This is {dates :num} date.',
            plural   => 'This are {dates :num} dates.',
            count    => 1,
        },
        replace => {
            dates => 1,
        },
    ),
    'Das ist 1 Date.',
    'locn context plural 1 with placeholders';
is
    $loc->locn(
        context => 'appointment',
        plural  => {
            singular => 'This is {dates :num} date.',
            plural   => 'This are {dates :num} dates.',
            count    => 2,
        },
        replace => {
            dates => 2,
        },
    ),
    'Das sind 2 Dates.',
    'locn context plural 2 with placeholders';
