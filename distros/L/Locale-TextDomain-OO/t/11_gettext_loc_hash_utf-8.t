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
                # loc_
                msgid  => "This is a text.",
                msgstr => "Das ist ein Text.",
            },
            {
                # loc_ umlaut
                msgid  => "§ book",
                msgstr => "§ Buch",
            },
            {
                # loc_x
                msgid  => "{name} is programming {language}.",
                msgstr => "{name} programmiert {language}.",
            },
            {
                # loc_n
                msgid         => "Singular",
                msgid_plural  => "Plural",
                msgstr_plural => [
                    "Einzahl",
                    "Mehrzahl",
                ],
            },
            {
                # loc_nx
                msgid         => "{shelves :num} shelf",
                msgid_plural  => "{shelves :num} shelves",
                msgstr_plural => [
                    "{shelves :num} Regal",
                    "{shelves :num} Regale",
                ],
            },
            {
                # loc_p
                msgctxt => "maskulin",
                msgid   => "Dear",
                msgstr  => "Sehr geehrter",
            },
            {
                # loc_px
                msgctxt => "maskulin",
                msgid   => "Dear {full name}",
                msgstr  => "Sehr geehrter {full name}",
            },
            {
                # loc_np
                msgctxt       => "appointment",
                msgid         => "date",
                msgid_plural  => "dates",
                msgstr_plural => [
                    "Date",
                    "Dates",
                ],
            },
            {
                # loc_npx
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
    plugins  => [ qw( Expand::Gettext::Loc ) ],
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
    $loc->loc_(
        'not existing text',
    ),
    'not existing text',
    'loc_ fallback';
is
    $loc->loc_(
        'This is a text.',
    ),
    'Das ist ein Text.',
    'loc_';
is
    $loc->loc_(
        '§ book',
    ),
    '§ Buch',
    'loc_ umlaut';
is
    $loc->loc_x(
        '{name} is programming {language}.',
        name     => 'Steffen',
        language => 'Perl',
    ),
    'Steffen programmiert Perl.',
    'loc_x';
is
    $loc->loc_x(
        '{name} is programming {language}.',
        name => 'Steffen',
    ),
    'Steffen programmiert {language}.',
    'loc_x (missing palaceholder)';
is
    $loc->loc_n(
        'Singular',
        'Plural',
        1,
    ),
    'Einzahl',
    'loc_n 1';
is
    $loc->loc_n(
        'Singular',
        'Plural',
        2,
    ),
    'Mehrzahl',
    'loc_n 2';
is
    $loc->loc_nx(
        '{shelves :num} shelf',
        '{shelves :num} shelves',
        1,
        shelves => 1,
    ),
    '1 Regal',
    'loc_nx 1';
is
    $loc->loc_nx(
        '{shelves :num} shelf',
        '{shelves :num} shelves',
        2,
        shelves => 2,
    ),
    '2 Regale',
    'loc_nx 2';
is
    $loc->loc_p(
        'maskulin',
        'Dear',
    ),
    'Sehr geehrter',
    'loc_p';
is
    $loc->loc_px(
        'maskulin',
        'Dear {full name}',
        'full name' => 'Steffen Winkler',
    ),
    'Sehr geehrter Steffen Winkler',
    'loc_px';
is
    $loc->loc_np(
        'appointment',
        'date',
        'dates',
        1,
    ),
    'Date',
    'loc_np 1';
is
    $loc->loc_np(
        'appointment',
        'date',
        'dates',
        2,
    ),
    'Dates',
    'loc_np 2';
is
    $loc->loc_npx(
        'appointment',
        'This is {dates :num} date.',
        'This are {dates :num} dates.',
        1,
        dates => 1,
    ),
    'Das ist 1 Date.',
    'loc_npx 1';
is
    $loc->loc_npx(
        'appointment',
        'This is {dates :num} date.',
        'This are {dates :num} dates.',
        2,
        dates => 2,
    ),
    'Das sind 2 Dates.',
    'loc_npx 2';
