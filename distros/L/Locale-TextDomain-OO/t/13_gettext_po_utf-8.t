#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 21;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::TextDomain::OO');
    require_ok('Locale::TextDomain::OO::Lexicon::File::PO');
}

Locale::TextDomain::OO::Lexicon::File::PO
    ->new(
        logger => sub {
            my ($message, $arg_ref ) = @_;
            $message =~ s{\\}{/}xmsg;
            like
                $message,
                qr{
                    \A
                    \QLexicon "\E
                    ( de | ru )
                    \Q::" loaded from file "t/LocaleData/\E
                    \1
                    \Q/LC_MESSAGES/test.po".\E
                    \z
                }xms,
                'message';
            is
                ref $arg_ref->{object},
                'Locale::TextDomain::OO::Lexicon::File::PO',
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
        search_dirs => [ './t/LocaleData' ],
        decode      => 1,
        data        => [
            '*::' => '*/LC_MESSAGES/test.po',
        ],
    });

my $loc = Locale::TextDomain::OO->new(
    language => 'ru',
    plugins  => [ qw( Expand::Gettext ) ],
    logger   => sub {
        my ($message, $arg_ref ) = @_;
        is
            $message,
            '',
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
);
$loc->expand_gettext->modifier_code(
    sub {
        my ( $value, $attribute ) = @_;
        $loc->language eq 'ru'
            or return $value;
        if ( $attribute eq 'accusative' ) {
            $value =~ s{ква}{кве}xms; # very primitive, only for this example
        }
        return $value;
    },
);
is
    $loc->__(
        'book',
    ),
    'книга',
    '__';
is
    $loc->__(
        '§ book',
    ),
    '§ книга',
    '__ utf-8';
is
    $loc->__x(
        'He lives in {town}.',
        town => 'Москва',
    ),
    'Он живет в Москве.',
    '__x utf-8';
is
    $loc->__nx(
        '{books :num} book',
        '{books :num} books',
        1,
        books => 1,
    ),
    '1 книга',
    '__nx 1';
is
    $loc->__nx(
        '{books :num} book',
        '{books :num} books',
        3,
        books => 3,
    ),
    '3 книги',
    '__nx 1';
is
    $loc->__nx(
        '{books :num} book',
        '{books :num} books',
        5,
        books => 5,
    ),
    '5 книг',
    '__nx 5';
is
    $loc->__p(
        'appointment',
        'date',
    ),
    'воссоединение',
    '__p';
is
    $loc->__npx(
        'appointment',
        'This is {dates :num} date.',
        'This are {dates :num} dates.',
        1,
        dates => 1,
    ),
    'Это 1 воссоединение.',
    '__npx 1';
is
    $loc->__npx(
        'appointment',
        'This is {dates :num} date.',
        'This are {dates :num} dates.',
        3,
        dates => 3,
    ),
    'Это 3 воссоединения.',
    '__npx 3';
is
    $loc->__npx(
        'appointment',
        'This is {dates :num} date.',
        'This are {dates :num} dates.',
        5,
        dates => 5,
    ),
    'Эти 5 воссоединения.',
    '__npx 5';
