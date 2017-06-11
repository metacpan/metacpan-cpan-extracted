#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 3;
use Test::Differences;
use Test::NoWarnings;

use Locale::Utils::Autotranslator;

my $auto_translator = Locale::Utils::Autotranslator->new(language => 'de');

eq_or_diff
    $auto_translator->with_paragraphs(
        " \t foo \n\nb ä \t r\n \n \n\n\n baz\nbam \t ",
        sub {
            return "-$_-";
        },
    ),
    " \t -foo- \n\n-b ä \t r-\n\n \n\n\n -baz\nbam- \t ",
    'with_paragraphs';
eq_or_diff
    $auto_translator->with_paragraphs(
        "foo\r\n\r\nbär\r\nbaz",
        sub {
            return "-$_-";
        },
    ),
    "-foo-\r\n\r\n-bär\r\nbaz-",
    'with_paragraphs (network line endings)';
