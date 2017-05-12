#!perl -T

use strict;
use warnings;

use Test::More tests => 10;
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    require_ok('Locale::TextDomain::OO');
    require_ok('Locale::TextDomain::OO::Lexicon::File::MO');
    require_ok('Locale::TextDomain::OO::Lexicon::Hash');
}

NPLURALS_DOES_NOT_MATCH: {
    throws_ok
        sub {
            Locale::TextDomain::OO::Lexicon::Hash
                ->new(
                    logger => sub { note shift },
                )
                ->lexicon_ref({
                    'de::' => [
                        {
                            msgid  => "",
                            msgstr => ""
                                . "Content-Type: text/plain; charset=ISO-8859-1\n"
                                . "Plural-Forms: nplurals=2; plural=n != 1;\n",
                        },
                        {
                            # __n
                            msgid         => "Singular",
                            msgid_plural  => "Plural",
                            msgstr_plural => [
                                "Einzahl",
                                "Mehrzahl",
                                "zu viel",
                            ],
                        },
                    ],
                });
        },
        qr{\A \QCount of msgstr_plural=3 but nplurals=2 for msgid="Singular" msgid_plural="Plural"}xms,
        'hash: nplurals is 2 but msgstr_plural contains 1 form more';
    throws_ok
        sub {
            Locale::TextDomain::OO::Lexicon::File::MO
                ->new(
                    logger => sub { note shift },
                )
                ->lexicon_ref({
                    search_dirs => [ './t/LocaleData' ],
                    decode      => 1,
                    data        => [
                        '*::' => '*/LC_MESSAGES/damaged.mo',
                    ],
                });
        },
        qr{\A \QCount of msgstr_plural=3 but nplurals=2 for msgid="Singular" msgid_plural="Plural"}xms,
        'damaged.mo: nplurals is 2 but msgstr_plural contains 1 form more';
}

X_WITHOUT_ARGS: {
    my $loc = Locale::TextDomain::OO->new(
        language => 'de',
        plugins  => [ qw( Expand::Gettext Expand::Maketext ) ],
    );
    Locale::TextDomain::OO::Lexicon::Hash
        ->new(
            logger => sub { note shift },
        )
        ->lexicon_ref({
            'de::' => [
                {
                    msgid  => "",
                    msgstr => ""
                        . "Content-Type: text/plain; charset=ISO-8859-1\n"
                        . "Plural-Forms: nplurals=2; plural=n != 1;\n",
                },
                {
                    # __x
                    msgid  => "{name} is programming {language}.",
                    msgstr => "{name} programmiert {language}.",
                },
            ],
        });
    is
        $loc->__x(
            '{name} is programming {language}.',
        ),
        '{name} programmiert {language}.',
        '__x without args';
}

throws_ok
    sub {
        Locale::TextDomain::OO->new(
            xxx => 'xxx',
        );
    },
    qr{\A \QFound unknown attribute(s) passed to the constructor: xxx}xms,
    'unknown attribute';

lives_ok
    sub {
        Locale::TextDomain::OO->new(
            plugins => [ qw( Expand::Maketext Expand::Gettext ) ],
        );
    },
    'same plugins';

throws_ok
    sub {
        Locale::TextDomain::OO->new(
            plugins => [ qw( Expand::Gettext ) ],
        );
    },
    qr{\A \QToo late to load plugins Expand::Gettext. Another method new was called before with plugins Expand::Gettext, Expand::Maketext}xms,
    'different plugins';
