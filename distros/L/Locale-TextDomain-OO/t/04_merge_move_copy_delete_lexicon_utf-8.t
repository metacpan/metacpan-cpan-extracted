#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 12;
use Test::NoWarnings;
use Test::Differences;
use Locale::TextDomain::OO::Lexicon::Hash;
use Locale::TextDomain::OO::Singleton::Lexicon;

my @logs;
my $logger_code = Locale::TextDomain::OO::Lexicon::Hash
    ->new(
        logger => sub { push @logs, shift },
    )
    ->lexicon_ref({
        'en-gb:cat:dom' => [
            {
                msgid  => "",
                msgstr => ""
                    . "Content-Type: text/plain; charset=UTF-8\n"
                    . "Plural-Forms: nplurals=1; plural=n != 1;\n",
            },
            {
                msgctxt      => "appointment",
                msgid        => "date for GBP",
                msgid_plural => "dates for GBP",
                msgstr       => [
                    "date for £",
                    "dates for £",
                ],
            },
        ],
    })
    ->logger;
my $lexicon = Locale::TextDomain::OO::Singleton::Lexicon->instance;
$lexicon->logger($logger_code);
eq_or_diff
    $lexicon->data,
    {
        'en-gb:cat:dom' => {
            '' => {
                charset     => 'UTF-8',
                nplurals    => 1,
                plural      => 'n != 1',
                plural_code => sub {},
            },
            "date for GBP\0dates for GBP\4appointment" => {
                msgstr => [
                    'date for £',
                    'dates for £',
                ],
            },
        },
        'i-default::' => {
            '' => {
                nplurals    => 2,
                plural      => 'n != 1',
                plural_code => sub {},
            },
        },
    },
    'create by hash';
eq_or_diff
    \@logs,
    [ 'Lexicon "en-gb:cat:dom" loaded from hash.' ],
    'logs';

@logs = ();
$lexicon->copy_lexicon('i-default::' => 'i-default:cat:dom');
eq_or_diff
    $lexicon->data,
    {
        'en-gb:cat:dom' => {
            q{} => {
                charset     => 'UTF-8',
                nplurals    => 1,
                plural      => 'n != 1',
                plural_code => sub {},
            },
            "date for GBP\0dates for GBP\4appointment" => {
                msgstr => [
                    'date for £',
                    'dates for £',
                ],
            },
        },
        'i-default::' => {
            q{} => {
                nplurals    => 2,
                plural      => 'n != 1',
                plural_code => sub {},
            },
        },
        'i-default:cat:dom' => {
            q{} => {
                nplurals    => 2,
                plural      => 'n != 1',
                plural_code => sub {},
            },
        },
    },
    'copy';
eq_or_diff
    \@logs,
    [ 'Lexicon "i-default::" copied to "i-default:cat:dom".' ],
    'logs';

@logs = ();
$lexicon->merge_lexicon('i-default::', 'en-gb:cat:dom' => 'en:cat:dom');
eq_or_diff
    $lexicon->data,
    {
        'en-gb:cat:dom' => {
            q{} => {
                charset     => 'UTF-8',
                nplurals    => 1,
                plural      => 'n != 1',
                plural_code => sub {},
            },
            "date for GBP\0dates for GBP\4appointment" => {
                msgstr => [
                    'date for £',
                    'dates for £',
                ],
            },
        },
        'en:cat:dom' => {
            q{} => {
                charset     => 'UTF-8',
                nplurals    => 1,
                plural      => 'n != 1',
                plural_code => sub {},
            },
            "date for GBP\0dates for GBP\4appointment" => {
                msgstr => [
                    'date for £',
                    'dates for £',
                ],
            },
        },
        'i-default::' => {
            q{} => {
                nplurals    => 2,
                plural      => 'n != 1',
                plural_code => sub {},
            },
        },
        'i-default:cat:dom' => {
            q{} => {
                nplurals    => 2,
                plural      => 'n != 1',
                plural_code => sub {},
            },
        },
    },
    'merge';
eq_or_diff
    \@logs,
    [ 'Lexicon "i-default::", "en-gb:cat:dom" merged to "en:cat:dom".' ],
    'logs';

@logs = ();
$lexicon->move_lexicon('i-default:cat:dom', 'i-default::dom');
eq_or_diff
    $lexicon->data,
    {
        'en-gb:cat:dom' => {
            q{} => {
                charset     => 'UTF-8',
                nplurals    => 1,
                plural      => 'n != 1',
                plural_code => sub {},
            },
            "date for GBP\0dates for GBP\4appointment" => {
                msgstr => [
                    'date for £',
                    'dates for £',
                ],
            },
        },
        'en:cat:dom' => {
            q{} => {
                charset     => 'UTF-8',
                nplurals    => 1,
                plural      => 'n != 1',
                plural_code => sub {},
            },
            "date for GBP\0dates for GBP\4appointment" => {
                msgstr => [
                    'date for £',
                    'dates for £',
                ],
            },
        },
        'i-default::' => {
            q{} => {
                nplurals    => 2,
                plural      => 'n != 1',
                plural_code => sub {},
            },
        },
        'i-default::dom' => {
            q{} => {
                nplurals    => 2,
                plural      => 'n != 1',
                plural_code => sub {},
            },
        },
    },
    'move';
eq_or_diff
    \@logs,
    [ 'Lexicon "i-default:cat:dom" moved to "i-default::dom".' ],
    'logs';

@logs = ();
my $deleted = $lexicon->delete_lexicon('i-default::');
eq_or_diff
    $lexicon->data,
    {
        'en-gb:cat:dom' => {
            q{} => {
                charset     => 'UTF-8',
                nplurals    => 1,
                plural      => 'n != 1',
                plural_code => sub {},
            },
            "date for GBP\0dates for GBP\4appointment" => {
                msgstr => [
                    'date for £',
                    'dates for £',
                ],
            },
        },
        'en:cat:dom' => {
            q{} => {
                charset     => 'UTF-8',
                nplurals    => 1,
                plural      => 'n != 1',
                plural_code => sub {},
            },
            "date for GBP\0dates for GBP\4appointment" => {
                msgstr => [
                    'date for £',
                    'dates for £',
                ],
            },
        },
        'i-default::dom' => {
            q{} => {
                nplurals    => 2,
                plural      => 'n != 1',
                plural_code => sub {},
            },
        },
    },
    'delete';
eq_or_diff
    \@logs,
    [ 'Lexicon "i-default::" deleted.' ],
    'logs';
eq_or_diff
    $deleted,
    {
        q{} => {
            nplurals    => 2,
            plural      => 'n != 1',
            plural_code => sub {},
        },
    },
    'deleted entry';
